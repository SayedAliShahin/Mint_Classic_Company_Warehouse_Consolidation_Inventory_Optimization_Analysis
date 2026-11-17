# Mint Classics Warehouse D Analysis: Optimized SQL Script

Reorganized and cleaned version of the original script ([`Mint_Classic_Warehouse_D_Analysis_Original.md`](Mint_Classic_Warehouse_D_Analysis_Original.md)), focused on the main question: *can Warehouse D be closed and its inventory redistributed to Warehouses A, B and C?*

## What changed

**Organization**
- Seven numbered sections that follow the analysis flow: setup, validation, EDA, Warehouse D assessment, inventory risk, operational indicators, pending work.
- One comment style, lowercase warehouse codes, uppercase keywords, and a header that lists the status filters and key limitations.

**Fixes**
- The missing-status check compared the text `'status'` instead of the column, so it always returned 0.
- `rank` (a reserved word in MySQL 8) is no longer used as an alias.
- The capacity estimate no longer rounds before multiplying, and its redundant outer query was removed.
- The monthly time series grouped by `orderDate` instead of month and ignored warehouses. It is now monthly shipped units, revenue and profit by warehouse (6.3).
- The top-5 products query had a duplicated `GROUP BY` column and now groups by product and warehouse.

**Removed (not needed for the closure question)**
- Validation of `employees`, `offices`, `payments` and `productlines`, and the top 10 customers by average order value.
- The separate stock-coverage and demand-trend queries, which are now covered by the single query in Section 5.
- The standalone warehouse summary, which is now part of the master comparison (3.3).

**Improved**
- The inventory risk query uses CTEs, so the coverage and trend formulas are written once instead of four times.
- Period lengths (29, 12 and 17 months) are derived from the data instead of hard-coded.
- The risk `CASE` handles products with no demand (`No Demand`) and products with no first-period demand (`New Demand - Review`).
- The relocation scenario has an `ELSE 'unallocated'` branch and a total check, so no Warehouse D units can silently drop out.
- A summary of customers by warehouse combination (4.1) reproduces the 76-customer breakdown.
- Temporary tables (`tmp_d_customers`, `tmp_d_allocation`, `tmp_d_inventory_risk`) are session-only. They avoid repeating joins and let the pending steps reuse the risk classification and destination warehouse.
- Two new referential checks (order lines without a product or order) and a missing-`shippedDate`-by-status check.

**Not changed:** the analytical logic and order-status filters, so the results match the original run. Result comments in the code are taken from the original run.

## Notes
- Section 7 lists the remaining analysis steps as comments only. They still need to be written and run.
- Query 6.2 groups non-shipped, non-cancelled orders as "other" instead of splitting them by label. Check the exact status labels with query 6.1 first.
- The script was syntax-checked on MariaDB 10.11 with a small synthetic dataset, not on the full Mint Classics database or MySQL 8. Run it on your database and compare the key results (79,380 units for Warehouse D, 76 customers, and the allocation totals) before publishing.

```sql
/* =============================================================================
   MINT CLASSICS - WAREHOUSE D CLOSURE FEASIBILITY ANALYSIS (optimized script)
   Database : mintclassics (MySQL 8.0+)

   Business question:
   Can Mint Classics close Warehouse D and redistribute its inventory across
   Warehouses A, B and C without significantly affecting inventory availability,
   customer coverage, or order-shipping performance?

   CONTENTS
   1. Setup and data understanding
   2. Data validation
   3. Exploratory analysis and warehouse comparison
   4. Warehouse D closure assessment
        4.1 Customers and regions associated with Warehouse D
        4.2 Product-scale mix
        4.3 Relocation scenario
        4.4 Estimated capacity (scenario-based)
   5. Warehouse D inventory risk (stock coverage + demand trend)
   6. Operational indicators (order status, cancellations, monthly shipments)
   7. Pending analysis (to be written)

   STATUS FILTERS USED (kept as in the original script so results reproduce)
   - Warehouse comparison / EDA revenue and profit : all order statuses
   - Customer and region association               : status <> 'Cancelled'
   - Demand, stock coverage, demand trend          : status = 'Shipped' only

   KEY LIMITATIONS (see README)
   - products.warehouseCode is an ASSIGNMENT, not proof of physical fulfillment.
   - warehousePctCap is undocumented; unit-capacity estimates are assumptions.
   - Dates have no timestamps, so 24-hour shipping cannot be verified.
   - Coverage thresholds (60 / 24 months) are working assumptions.
============================================================================= */


/* =============================================================================
   1. SETUP AND DATA UNDERSTANDING
============================================================================= */
USE mintclassics;

SHOW TABLES;
DESCRIBE products;
DESCRIBE warehouses;
SELECT * FROM warehouses;


/* =============================================================================
   2. DATA VALIDATION
   Scope: tables used in the analysis (customers, orders, orderdetails,
   products, warehouses). The employees, offices, payments and productlines
   tables were checked in the original script (no issues) and are not used here.
============================================================================= */

-- 2.1 customers: missing values and duplicate keys
SELECT
    COUNT(*)                                              AS total_rows,
    SUM(customerNumber IS NULL)                           AS missing_customer_number,
    SUM(customerName IS NULL OR customerName = '')        AS missing_customer_name,
    SUM(country IS NULL OR country = '')                  AS missing_country,
    SUM(state IS NULL OR state = '')                      AS missing_state,
    COUNT(*) - COUNT(DISTINCT customerNumber)             AS duplicate_customer_numbers
FROM customers;
-- Result (original run): no duplicates. Nulls in state (73), addressLine2 (100),
-- postalCode (7), salesRepEmployeeNumber (22) and creditLimit (24) are normal
-- and not used in this analysis.


-- 2.2 orders: missing values, duplicate keys and invalid date sequences
SELECT
    COUNT(*)                                              AS total_rows,
    SUM(orderDate IS NULL)                                AS missing_order_date,
    SUM(requiredDate IS NULL)                             AS missing_required_date,
    SUM(shippedDate IS NULL)                              AS missing_shipped_date,
    SUM(status IS NULL OR status = '')                    AS missing_status,
    SUM(customerNumber IS NULL)                           AS missing_customer_number,
    COUNT(*) - COUNT(DISTINCT orderNumber)                AS duplicate_order_numbers,
    SUM(requiredDate < orderDate)                         AS required_before_order,
    SUM(shippedDate < orderDate)                          AS shipped_before_order
FROM orders;

-- Missing shippedDate should only occur for orders that were not shipped
SELECT
    status,
    COUNT(*)                  AS total_orders,
    SUM(shippedDate IS NULL)  AS missing_shipped_date
FROM orders
GROUP BY status
ORDER BY total_orders DESC;
-- Result (original run): no duplicates or invalid dates. The 14 missing
-- shippedDate values come from cancelled, on-hold or in-progress orders.


-- 2.3 orderdetails: missing values, duplicate keys and invalid quantity / price
SELECT
    COUNT(*)                                                        AS total_rows,
    SUM(orderNumber IS NULL OR productCode IS NULL)                 AS missing_keys,
    SUM(quantityOrdered IS NULL OR quantityOrdered <= 0)            AS invalid_quantity,
    SUM(priceEach IS NULL OR priceEach <= 0)                        AS invalid_price,
    COUNT(*) - COUNT(DISTINCT orderNumber, productCode)             AS duplicate_order_lines
FROM orderdetails;
-- Result (original run): no missing, duplicate or invalid values.


-- 2.4 products: missing values and duplicate keys
SELECT
    COUNT(*)                                                        AS total_rows,
    SUM(productName IS NULL OR productName = '')                    AS missing_product_name,
    SUM(productScale IS NULL OR productScale = '')                  AS missing_product_scale,
    SUM(quantityInStock IS NULL)                                    AS missing_stock,
    SUM(warehouseCode IS NULL OR warehouseCode = '')                AS missing_warehouse_code,
    SUM(buyPrice IS NULL)                                           AS missing_buy_price,
    COUNT(*) - COUNT(DISTINCT productCode)                          AS duplicate_product_codes
FROM products;
-- Result (original run): no missing or duplicate values.


-- 2.5 Referential integrity (expected result for each check: 0 rows)

-- Products assigned to more than one warehouse (1-to-1 assignment check)
SELECT productCode, COUNT(DISTINCT warehouseCode) AS warehouses_assigned
FROM products
GROUP BY productCode
HAVING COUNT(DISTINCT warehouseCode) > 1;

-- Products pointing to a warehouse that does not exist
SELECT p.productCode, p.warehouseCode
FROM products p
LEFT JOIN warehouses w ON p.warehouseCode = w.warehouseCode
WHERE w.warehouseCode IS NULL;

-- Warehouses with no assigned products
SELECT w.warehouseCode
FROM warehouses w
LEFT JOIN products p ON w.warehouseCode = p.warehouseCode
WHERE p.productCode IS NULL;

-- Order lines whose product is missing from products (would drop out of warehouse analysis)
SELECT od.orderNumber, od.productCode
FROM orderdetails od
LEFT JOIN products p ON od.productCode = p.productCode
WHERE p.productCode IS NULL;

-- Order lines whose order is missing from orders
SELECT od.orderNumber, od.productCode
FROM orderdetails od
LEFT JOIN orders o ON od.orderNumber = o.orderNumber
WHERE o.orderNumber IS NULL;
-- Result (original run, first three checks): no orphaned keys.
-- The last two checks were added in this version and have not been run on the full database yet.

-- Conclusion: tables are clean and ready for analysis.


/* =============================================================================
   3. EXPLORATORY ANALYSIS AND WAREHOUSE COMPARISON
============================================================================= */

-- 3.1 Overall sales performance (all order statuses)
-- Cost uses the current products.buyPrice (assumed constant over time).
SELECT
    SUM(od.quantityOrdered)                                         AS total_items_sold,
    ROUND(SUM(od.quantityOrdered * od.priceEach), 2)                AS total_revenue,
    ROUND(SUM(od.quantityOrdered * p.buyPrice), 2)                  AS total_cost,
    ROUND(SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)), 2) AS gross_profit,
    ROUND(AVG(od.quantityOrdered * od.priceEach), 2)                AS avg_order_line_value,
    ROUND(AVG(od.quantityOrdered), 2)                               AS avg_quantity_per_line
FROM orderdetails od
JOIN products p ON od.productCode = p.productCode;
-- Result (original run): 105,516 items sold; revenue 9,604,190; cost 5,778,310;
-- gross profit 3,825,880; average quantity per order line about 35.


-- 3.2 Top 5 products by revenue and their warehouse
SELECT
    p.productCode,
    p.productName,
    w.warehouseCode,
    w.warehouseName,
    ROUND(SUM(od.quantityOrdered * od.priceEach), 2) AS total_revenue
FROM products p
JOIN orderdetails od ON p.productCode = od.productCode
JOIN warehouses w    ON p.warehouseCode = w.warehouseCode
GROUP BY p.productCode, p.productName, w.warehouseCode, w.warehouseName
ORDER BY total_revenue DESC
LIMIT 5;
-- Result (original run): 4 of the top 5 products are assigned to the "East" warehouse.


-- 3.3 Master warehouse comparison: inventory, value, sales, profit share, capacity
WITH inventory AS (
    SELECT
        warehouseCode,
        COUNT(*)                          AS distinct_products,
        SUM(quantityInStock)              AS total_units,
        SUM(quantityInStock * buyPrice)   AS inventory_value
    FROM products
    GROUP BY warehouseCode
),
sales AS (
    SELECT
        p.warehouseCode,
        COUNT(DISTINCT od.orderNumber)                           AS total_orders,
        SUM(od.quantityOrdered * od.priceEach)                   AS total_revenue,
        SUM(od.quantityOrdered * (od.priceEach - p.buyPrice))    AS gross_profit
    FROM products p
    JOIN orderdetails od ON p.productCode = od.productCode
    GROUP BY p.warehouseCode
),
scale_rank AS (
    SELECT
        warehouseCode,
        productScale,
        ROW_NUMBER() OVER (
            PARTITION BY warehouseCode
            ORDER BY SUM(quantityInStock) DESC, productScale
        ) AS scale_position
    FROM products
    GROUP BY warehouseCode, productScale
)
SELECT
    w.warehouseCode,
    i.distinct_products,
    i.total_units,
    ROUND(i.inventory_value, 2)                                              AS inventory_value,
    s.total_orders,
    ROUND(s.total_revenue, 2)                                                AS total_revenue,
    ROUND(s.gross_profit, 2)                                                 AS gross_profit,
    ROUND(s.gross_profit / NULLIF(SUM(s.gross_profit) OVER (), 0) * 100, 2)  AS profit_share_pct,
    w.warehousePctCap                                                        AS utilization_pct,
    100 - w.warehousePctCap                                                  AS remaining_capacity_pct,
    sr.productScale                                                          AS dominant_product_scale
FROM warehouses w
LEFT JOIN inventory  i  ON w.warehouseCode = i.warehouseCode
LEFT JOIN sales      s  ON w.warehouseCode = s.warehouseCode
LEFT JOIN scale_rank sr ON w.warehouseCode = sr.warehouseCode
                       AND sr.scale_position = 1
ORDER BY s.total_revenue DESC;
-- Result (original run): Warehouse B leads in revenue and profit share (about 39%).
-- Warehouse D has the fewest products and units (79,380), the lowest inventory
-- value and the lowest gross profit (727,183; 19.1% share), but the highest
-- reported utilization (75%) and 25% remaining capacity.
-- 1:18 is the dominant scale in B and C (and D), which supports physical absorption.
-- => Warehouse D is selected as the closure candidate to assess.


/* =============================================================================
   4. WAREHOUSE D CLOSURE ASSESSMENT
============================================================================= */

-- 4.1 Customers and regions associated with Warehouse D

-- Regions: orders, customers and revenue by country, state and assigned warehouse
SELECT
    c.country,
    c.state,
    p.warehouseCode,
    COUNT(DISTINCT o.orderNumber)                    AS total_orders,
    COUNT(DISTINCT c.customerNumber)                 AS total_customers,
    ROUND(SUM(od.quantityOrdered * od.priceEach), 2) AS revenue
FROM orders o
JOIN customers c     ON o.customerNumber = c.customerNumber
JOIN orderdetails od ON o.orderNumber = od.orderNumber
JOIN products p      ON od.productCode = p.productCode
WHERE o.status <> 'Cancelled'
GROUP BY c.country, c.state, p.warehouseCode
ORDER BY c.country, c.state, p.warehouseCode;

-- Customers associated with Warehouse D and the warehouses they are associated with.
-- Stored in a session-only temporary table so detail and summary use one join.
DROP TEMPORARY TABLE IF EXISTS tmp_d_customers;
CREATE TEMPORARY TABLE tmp_d_customers AS
SELECT
    c.customerNumber,
    c.customerName,
    c.country,
    c.state,
    GROUP_CONCAT(DISTINCT p.warehouseCode ORDER BY p.warehouseCode) AS warehouses_used,
    COUNT(DISTINCT o.orderNumber)                                   AS total_orders,
    COUNT(DISTINCT CASE WHEN p.warehouseCode <> 'd'
                        THEN p.warehouseCode END)                   AS alternative_warehouses
FROM customers c
JOIN orders o        ON c.customerNumber = o.customerNumber
JOIN orderdetails od ON o.orderNumber = od.orderNumber
JOIN products p      ON od.productCode = p.productCode
WHERE o.status <> 'Cancelled'
GROUP BY c.customerNumber, c.customerName, c.country, c.state
HAVING SUM(p.warehouseCode = 'd') > 0;

-- Detail: one row per customer associated with Warehouse D
SELECT * FROM tmp_d_customers ORDER BY country, customerName;

-- Summary: customers by warehouse combination
SELECT
    warehouses_used,
    COUNT(*)                    AS customers,
    MIN(alternative_warehouses) AS min_alternative_warehouses
FROM tmp_d_customers
GROUP BY warehouses_used
ORDER BY customers DESC;
-- Result (original run): 76 customers; 56 with A,B,C,D; 15 with B,C,D; 3 with A,B,D;
-- 2 with A,C,D. All have at least one alternative warehouse association.
-- Limitation: association is based on product assignment, not proven fulfillment.


-- 4.2 Product-scale mix

-- Units per product scale in each warehouse
SELECT
    productScale,
    SUM(CASE WHEN warehouseCode = 'a' THEN quantityInStock ELSE 0 END) AS a_units,
    SUM(CASE WHEN warehouseCode = 'b' THEN quantityInStock ELSE 0 END) AS b_units,
    SUM(CASE WHEN warehouseCode = 'c' THEN quantityInStock ELSE 0 END) AS c_units,
    SUM(CASE WHEN warehouseCode = 'd' THEN quantityInStock ELSE 0 END) AS d_units
FROM products
GROUP BY productScale
ORDER BY productScale;

-- Share of each product scale in Warehouse D
SELECT
    productScale,
    SUM(quantityInStock) AS total_units,
    ROUND(SUM(quantityInStock) * 100.0 / SUM(SUM(quantityInStock)) OVER (), 2) AS inventory_share_pct
FROM products
WHERE warehouseCode = 'd'
GROUP BY productScale
ORDER BY total_units DESC;
-- Result (original run): 1:18 is the dominant scale in B, C and D;
-- Warehouse D holds 7 different product scales.


-- 4.3 Relocation scenario (preliminary; scale-based, not proven optimal)

-- Product-level allocation of Warehouse D stock (reused in Section 5)
DROP TEMPORARY TABLE IF EXISTS tmp_d_allocation;
CREATE TEMPORARY TABLE tmp_d_allocation AS
SELECT
    productCode,
    productName,
    productScale,
    quantityInStock,
    CASE
        WHEN productScale IN ('1:700', '1:72')          THEN 'a'
        WHEN productScale IN ('1:18', '1:12')           THEN 'b'
        WHEN productScale IN ('1:32', '1:24', '1:50')   THEN 'c'
        ELSE 'unallocated'
    END AS destination_warehouse
FROM products
WHERE warehouseCode = 'd';

-- Allocation check: every unit must be allocated (total should equal 79,380)
SELECT
    destination_warehouse,
    SUM(quantityInStock) AS incoming_units
FROM tmp_d_allocation
GROUP BY destination_warehouse WITH ROLLUP;

-- Inventory after relocation
WITH incoming AS (
    SELECT destination_warehouse, SUM(quantityInStock) AS incoming_units
    FROM tmp_d_allocation
    GROUP BY destination_warehouse
),
current_inventory AS (
    SELECT warehouseCode, SUM(quantityInStock) AS current_units
    FROM products
    WHERE warehouseCode IN ('a', 'b', 'c')
    GROUP BY warehouseCode
)
SELECT
    c.warehouseCode,
    c.current_units,
    i.incoming_units,
    c.current_units + i.incoming_units                       AS new_total_units,
    ROUND(i.incoming_units * 100.0 / c.current_units, 2)     AS inventory_increase_pct
FROM current_inventory c
JOIN incoming i ON c.warehouseCode = i.destination_warehouse
ORDER BY c.warehouseCode;
-- Result (original run): A +20,676 (15.70%), B +34,430 (15.71%), C +24,274 (19.44%).


-- 4.4 Estimated capacity (scenario-based)
-- ASSUMPTION: warehousePctCap is undocumented. Capacity is assumed to scale
-- linearly with units (units per capacity point = units / utilization %).
-- The result is an estimate, NOT confirmed physical capacity.
SELECT
    p.warehouseCode,
    SUM(p.quantityInStock)                                   AS total_units,
    w.warehousePctCap                                        AS utilized_cap_pct,
    100 - w.warehousePctCap                                  AS remaining_cap_pct,
    ROUND(SUM(p.quantityInStock) / w.warehousePctCap, 2)     AS units_per_capacity_point,
    ROUND(SUM(p.quantityInStock) / w.warehousePctCap
          * (100 - w.warehousePctCap))                       AS est_remaining_units
FROM products p
JOIN warehouses w ON p.warehouseCode = w.warehouseCode
GROUP BY p.warehouseCode, w.warehousePctCap
ORDER BY p.warehouseCode;
-- Result (original run): Warehouses C and B show the most remaining capacity.


/* =============================================================================
   5. WAREHOUSE D INVENTORY RISK (stock coverage + demand trend)

   Stock coverage (months) = current stock / average monthly shipped demand
   Demand change (%)       = (recent avg monthly - first avg monthly)
                             / first avg monthly * 100
   Demand uses status = 'Shipped' only.

   Periods (derived from the data in the params CTE):
   - Total  : first to last shipped order date (2003-01-06 to 2005-05-31),
              29 calendar months touched (includes partial months at both ends)
   - First  : 2003-01-06 to 2004-01-05 (12 months)
   - Recent : 2004-01-06 to 2005-05-31 (17 calendar months)

   Classification thresholds (60 and 24 months) are WORKING ASSUMPTIONS.
   High coverage alone does not prove overstock.
============================================================================= */
DROP TEMPORARY TABLE IF EXISTS tmp_d_inventory_risk;
CREATE TEMPORARY TABLE tmp_d_inventory_risk AS
WITH params AS (
    SELECT
        DATE '2004-01-06' AS split_date,
        TIMESTAMPDIFF(MONTH, MIN(orderDate), MAX(orderDate)) + 1 AS months_total,
        TIMESTAMPDIFF(MONTH, MIN(orderDate), DATE '2004-01-06' - INTERVAL 1 DAY) + 1 AS months_first,
        TIMESTAMPDIFF(MONTH, DATE '2004-01-06', MAX(orderDate)) + 1 AS months_recent
    FROM orders
    WHERE status = 'Shipped'
),
demand AS (
    SELECT
        od.productCode,
        SUM(od.quantityOrdered) AS total_shipped,
        SUM(CASE WHEN o.orderDate <  pr.split_date THEN od.quantityOrdered ELSE 0 END) AS first_shipped,
        SUM(CASE WHEN o.orderDate >= pr.split_date THEN od.quantityOrdered ELSE 0 END) AS recent_shipped
    FROM orderdetails od
    JOIN orders o ON od.orderNumber = o.orderNumber
    CROSS JOIN params pr
    WHERE o.status = 'Shipped'
    GROUP BY od.productCode
),
metrics AS (
    SELECT
        p.productCode,
        p.productName,
        p.productScale,
        p.quantityInStock                                   AS current_stock,
        p.buyPrice,
        COALESCE(d.total_shipped, 0)                        AS total_shipped,
        COALESCE(d.total_shipped, 0) / pr.months_total      AS avg_monthly_demand,
        p.quantityInStock
            / NULLIF(d.total_shipped / pr.months_total, 0)  AS stock_coverage_months,
        d.first_shipped  / pr.months_first                  AS first_avg_monthly,
        d.recent_shipped / pr.months_recent                 AS recent_avg_monthly,
        (d.recent_shipped / pr.months_recent - d.first_shipped / pr.months_first)
            / NULLIF(d.first_shipped / pr.months_first, 0) * 100 AS demand_change_pct
    FROM products p
    LEFT JOIN demand d ON p.productCode = d.productCode
    CROSS JOIN params pr
    WHERE p.warehouseCode = 'd'
)
SELECT
    m.productCode,
    m.productName,
    m.productScale,
    m.current_stock,
    m.buyPrice,
    m.total_shipped,
    ROUND(m.avg_monthly_demand, 2)     AS avg_monthly_demand,
    ROUND(m.stock_coverage_months, 2)  AS stock_coverage_months,
    ROUND(m.first_avg_monthly, 2)      AS first_avg_monthly,
    ROUND(m.recent_avg_monthly, 2)     AS recent_avg_monthly,
    ROUND(m.demand_change_pct, 2)      AS demand_change_pct,
    CASE
        WHEN m.total_shipped = 0
            THEN 'No Demand'
        WHEN m.first_avg_monthly IS NULL OR m.first_avg_monthly = 0
            THEN 'New Demand - Review'
        WHEN m.stock_coverage_months > 60 AND m.demand_change_pct < 0
            THEN 'High Priority'
        WHEN m.stock_coverage_months > 60 AND m.demand_change_pct >= 0
            THEN 'High Stock - Monitor'
        WHEN m.stock_coverage_months BETWEEN 24 AND 60 AND m.demand_change_pct < 0
            THEN 'Moderate Priority'
        ELSE 'Lower Priority'
    END AS inventory_risk,
    a.destination_warehouse
FROM metrics m
LEFT JOIN tmp_d_allocation a ON m.productCode = a.productCode;

-- Product-level risk classification for Warehouse D (23 products)
SELECT *
FROM tmp_d_inventory_risk
ORDER BY stock_coverage_months DESC;
-- Result (original run): all 23 products have more than 15 months of coverage;
-- several exceed 200 months. Mercedes Tour Bus and Collectable Wooden Train
-- combine very high coverage with declining demand.


/* =============================================================================
   6. OPERATIONAL INDICATORS
   Order status is a screening indicator only: the database does not show which
   warehouse physically fulfilled an order.
============================================================================= */

-- 6.1 Order status distribution
SELECT
    status,
    COUNT(*)                                        AS total_orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_orders
FROM orders
GROUP BY status
ORDER BY total_orders DESC;
-- Result (original run): about 92% of orders are shipped; about 2% are cancelled.


-- 6.2 Order status by warehouse-assigned products
-- "Other" groups every status that is neither Shipped nor Cancelled (on hold,
-- in process, disputed, resolved), so the query does not depend on exact labels.
-- Check the exact labels with query 6.1 before splitting them out.
SELECT
    p.warehouseCode,
    COUNT(DISTINCT o.orderNumber)                                              AS total_orders,
    COUNT(DISTINCT CASE WHEN o.status = 'Shipped'   THEN o.orderNumber END)    AS shipped_orders,
    COUNT(DISTINCT CASE WHEN o.status = 'Cancelled' THEN o.orderNumber END)    AS cancelled_orders,
    COUNT(DISTINCT CASE WHEN o.status NOT IN ('Shipped', 'Cancelled')
                        THEN o.orderNumber END)                                AS other_status_orders,
    ROUND(COUNT(DISTINCT CASE WHEN o.status = 'Cancelled' THEN o.orderNumber END)
          * 100.0 / COUNT(DISTINCT o.orderNumber), 2)                          AS cancellation_rate_pct
FROM products p
JOIN orderdetails od ON p.productCode = od.productCode
JOIN orders o        ON od.orderNumber = o.orderNumber
GROUP BY p.warehouseCode
ORDER BY p.warehouseCode;
-- Result (original run): Warehouse D has the highest cancellation rate (about 3%),
-- which is still small overall.


-- 6.3 Monthly shipped quantity, revenue and profit by warehouse (shipped orders)
SELECT
    DATE_FORMAT(o.orderDate, '%Y-%m')                               AS order_month,
    p.warehouseCode,
    SUM(od.quantityOrdered)                                         AS units_shipped,
    ROUND(SUM(od.quantityOrdered * od.priceEach), 2)                AS revenue,
    ROUND(SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)), 2) AS gross_profit
FROM orderdetails od
JOIN orders o   ON od.orderNumber = o.orderNumber
JOIN products p ON od.productCode = p.productCode
WHERE o.status = 'Shipped'
GROUP BY DATE_FORMAT(o.orderDate, '%Y-%m'), p.warehouseCode
ORDER BY order_month, p.warehouseCode;


/* =============================================================================
   7. PENDING ANALYSIS (to be written)
   Helper tables available in this session: tmp_d_allocation, tmp_d_inventory_risk
============================================================================= */

-- 7.1 Inventory risk summary
--     Count products and units per inventory_risk category and their share of
--     Warehouse D's 79,380 units (hint: GROUP BY inventory_risk on tmp_d_inventory_risk).

-- 7.2 Financial exposure
--     Purchase-cost value (current_stock * buyPrice) per risk category.
--     This is inventory COST value, not revenue or profit.

-- 7.3 Product importance
--     Revenue and gross profit of the High Priority products. High coverage does
--     not mean a product is commercially unimportant.

-- 7.4 Redistribution implications
--     Destination warehouse (A, B or C) of each High Priority product, and units
--     that would NOT need to move if these products were sold down first.

-- 7.5 Post-relocation capacity test
--     Estimated utilization of A, B and C after relocation, with and without the
--     sell-down. State the linear-capacity assumption from Section 4.4 explicitly.

-- 7.6 Shipping performance by warehouse-assigned products
--     DATEDIFF(shippedDate, orderDate) and share of orders shipped after
--     requiredDate. Dates only: the 24-hour requirement cannot be verified, and
--     shippedDate is dispatch, not delivery.
```
