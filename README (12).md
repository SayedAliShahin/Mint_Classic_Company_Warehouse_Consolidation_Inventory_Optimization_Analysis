# Mint_Classic_Company_Inventory_Optimization_Analysis (Case Study)
## Business scenario
**Mint Classic Company**, a retailer of classic model cars and vehicles, is evaluating whether it can **close one of its warehouses** to **reduce operational costs** while maintaining sufficient inventory and its regular fulfillment service, which aims to ship an order within 24 hours. The main business question of this project is:

> **Can Mint Classics close Warehouse D and redistribute its inventory across Warehouses A, B, and C without significantly affecting inventory availability, customer coverage, or order-shipping performance?**

The goal is not only to write SQL queries, but to run a structured business analysis, evaluate operational risks, and build a defensible recommendation supported by data.

## Data Overview
The analysis uses the `mintclassics` (Classic Models) MySQL database. The main tables are:

| Table | Key columns used | Purpose in the analysis |
|---|---|---|
| `warehouses` | warehouseCode, warehousePctCap | Reported capacity utilization per warehouse |
| `products` | productCode, productName, productScale, quantityInStock, warehouseCode, buyPrice | Product-to-warehouse assignment, current stock, cost value |
| `orderdetails` | orderNumber, productCode, quantityOrdered, priceEach | Quantities sold, revenue, gross profit |
| `orders` | orderNumber, customerNumber, status, orderDate, requiredDate, shippedDate | Demand period, order status, shipping dates |
| `customers` | customerNumber, customerName, country, state | Customer and regional associations |

Key relationships:
- Products are assigned to warehouses through `products.warehouseCode` (verified as a one-to-one product-to-warehouse relationship).
- Orders connect to products through `orderdetails`.
- Orders connect to customers through `orders.customerNumber`.

**Data validation:** All tables were checked for missing values, duplicates, orphaned keys, and logical inconsistencies (for example, `requiredDate` or `shippedDate` earlier than `orderDate`, zero or negative quantities and prices). No serious issues were found. Missing values in `customers` (state, postal code, sales rep, credit limit) and the 14 missing `shippedDate` values in `orders` (cancelled, on-hold, or in-progress orders) are expected and do not affect the analysis.

> **[`ER Diagram.png`]**

## Skills & Tools
- SQL Data Analysis (MySQL): CTEs, window functions, conditional aggregation, `CASE` classification, multi-table joins
- Data Cleaning and Validation
- Exploratory Data Analysis (EDA)
- Inventory Analysis (stock coverage, demand trend, risk classification)
- Scenario Analysis (inventory redistribution)

## Summary
Evaluated the feasibility of closing one warehouse by **analyzing warehouse inventory, profit contribution, reported capacity, customer associations, product demand, and order status.** **Warehouse D was selected as the closure candidate to assess** because it holds the fewest products, the lowest inventory units, the lowest inventory value, and the lowest profit contribution. However, it also reports the **highest capacity utilization (75%)**, so the assessment focuses on whether its inventory can be reduced and redistributed to Warehouses A, B, and C.

All 76 customers associated with Warehouse D also have an association with at least one other warehouse, and a preliminary redistribution scenario places all 79,380 units across A, B, and C. A stock-coverage and demand-trend screening shows that **every Warehouse D product has more than 15 months of estimated coverage**, which suggests inventory could be reduced before any transfer.

> **[TO COMPLETE: one-sentence final verdict on closing Warehouse D (supported / conditionally feasible / not sufficiently supported), plus the 1 or 2 main conditions or risks behind it. Write this after the items in the Solution section are done]**

## Solution
First of all, **Warehouse D was selected for assessment** based on the initial warehouse comparison:

| Metric | A | B | C | D |
|---|---:|---:|---:|---:|
| Products | 25 | 38 | 24 | 23 |
| Inventory units | 131,688 | 219,183 | 124,880 | 79,380 |
| Inventory value (buy cost) | 6,664,996.94 | 14,059,337.71 | 5,704,259.82 | 4,105,721.76 |
| Reported capacity utilization (%) | 72 | 67 | 50 | 75 |
| Reported remaining capacity (%) | 28 | 33 | 50 | 25 |

Warehouse D has the smallest footprint in products, units, and value (and the lowest gross profit, about 727,183 or 19.1% of the total), but **the highest reported utilization**, which makes capacity feasibility the main concern. Because `warehousePctCap` is undocumented, any conversion of it into unit capacity is an assumption, not confirmed physical capacity.

On the customer side, **76 customers were associated with products assigned to Warehouse D, and all 76 also had an association with at least one other warehouse** (56 with A, B, C and D; 15 with B, C and D; 3 with A, B and D; 2 with A, C and D). This suggests alternative warehouse associations exist, but it does not prove that other warehouses physically fulfilled those orders or could maintain the same service level after closure.

A **preliminary product-scale-based relocation scenario** allocates all of Warehouse D's 79,380 units:

| Receiving warehouse | Product scales | Incoming units | Current units | New total units | Increase |
|---|---|---:|---:|---:|---:|
| A | 1:700 and 1:72 | 20,676 | 131,688 | 152,364 | 15.70% |
| B | 1:18 and 1:12 | 34,430 | 219,183 | 253,613 | 15.71% |
| C | 1:32, 1:24 and 1:50 | 24,274 | 124,880 | 149,154 | 19.44% |

This scenario has not been proven optimal or physically feasible, because product scale alone does not establish storage compatibility.

On the other hand, **Warehouse D's inventory should be reviewed for potential overstock before it is relocated.** Using shipped-order demand from January 2003 to May 2005 (29 calendar months), **all 23 products have more than 15 months of stock coverage, and several exceed 200 months** (for example, Chicago Surface Lines Streetcar at 275 months and Mercedes Tour Bus at 247 months). High coverage alone does not prove overstock, so coverage was combined with the demand trend (first 12 months versus the recent period). Products were then screened with working rules:

| Condition | Classification | Products | Units |
|---|---|---:|---:|
| Coverage above 60 months and demand declining | High Priority | 4 | 18,682 |
| Coverage above 60 months and demand stable or increasing | High Stock - Monitor | 13 | 54,493 |
| Coverage 24 to 60 months and demand declining | Moderate Priority | 1 | 737 |
| Other combinations | Lower Priority | 5 | 5,468 |

The four High Priority products are the **Mercedes Tour Bus, Collectable Wooden Train, Titanic, and 1926 Ford Fire Engine**. The Mercedes Tour Bus and Collectable Wooden Train stand out with more than 230 months of coverage and declining demand. Titanic and 1926 Ford Fire Engine only just meet the rule (the Fire Engine has 61.93 months of coverage and -0.85% demand change), so their classification is sensitive to the 60-month threshold. Several high-coverage products have rising demand (for example HMS Bounty at +73.12% and 1957 Chevy Pickup at +35.73%), so they are flagged for monitoring rather than reduction. These thresholds are working assumptions, not established inventory-management standards.

> **[TO COMPLETE: financial exposure. Add a result table with `SUM(quantityInStock * buyPrice)` for each risk category (High Priority, Monitor, Moderate, Lower) and its share of the 4,105,721.76 total inventory value of Warehouse D. State that this is purchase-cost value, not revenue or profit]**
>
> **[TO COMPLETE: product importance. Add total revenue and gross profit (`quantityOrdered * priceEach` and `quantityOrdered * (priceEach - buyPrice)`) for the 4 High Priority products, to show whether they are commercially minor or still meaningful]**
>
> **[TO COMPLETE: redistribution implications. Add which receiving warehouse (A, B or C) each High Priority product goes to, based on its `productScale`, and how many units would be avoided if these products were sold down first]**
>
> **[TO COMPLETE: capacity feasibility. Add the estimated utilization of A, B and C after relocation (from the units-per-capacity-point query), with and without the High Priority sell-down, and state the linear-capacity assumption explicitly]**

Finally, at the order level, about **92% of all orders are shipped and the overall cancellation rate is only about 2%.** Products assigned to Warehouse D show the highest cancellation rate among the four warehouses (around 3%), which is still small overall. Order status and customer associations are screening indicators only, since the database does not show which warehouse physically fulfilled an order.

> **[TO COMPLETE: (1) shipment trend of Warehouse D-assigned products over time and the main countries/regions they serve, from your regional query; (2) final recommendation; (3) the extra data management would need before closing, e.g. confirmed physical capacity, order-level fulfillment records, inventory planning parameters]**

## Approach
Firstly, all tables were cleaned and validated, followed by an exploratory analysis of warehouse inventory, profit contribution, and reported capacity to identify the least-used warehouse. Warehouse D was selected as the closure candidate based on its lowest product count, inventory units, inventory value, and profit contribution, while noting that its reported utilization is the highest. Then customers and regions associated with Warehouse D were compared with the other warehouses to see whether alternative warehouse associations exist. Continued by building a preliminary inventory redistribution scenario based on product scale and calculating the inventory increase of each receiving warehouse. Then, Warehouse D's products were evaluated for potential overstock using **stock coverage** (current stock divided by average monthly shipped demand over 29 calendar months, shipped orders only) and **demand trend** (average monthly demand in the first 12 months versus the recent period, 2004-01-06 to 2005-05-31). Finally, a `CASE`-based risk classification combined both indicators, to identify which products should be considered for sell-down, reduced purchasing, or transfer before any closure.

The full SQL code is available in `Query_Script.sql`.

## Project Assumptions & Limitations
1. **Capacity is unverified:** `warehousePctCap` is undocumented (units, volume, or physical space are unknown). Any unit-capacity estimate assumes capacity scales linearly with units and is a scenario, not confirmed capacity.
2. **Assignment is not fulfillment:** `products.warehouseCode` shows where a product is assigned, not which warehouse shipped an order. Customer overlap therefore shows association only, not proven service coverage.
3. **24-hour shipping cannot be verified:** Dates have no timestamps, and `shippedDate` shows dispatch, not delivery.
4. **Demand and inventory are screening data:** Stock coverage uses historical shipped quantities (not a forecast) and a single `quantityInStock` snapshot. The database has no reorder points, safety stock, lead times, or inventory aging, so high coverage is a risk signal, not proof of overstock.
5. **Relocation is a preliminary scenario:** `productScale` is a product classification, not a measure of storage space, so the allocation is not proven optimal or physically feasible.
6. **Thresholds and periods are working assumptions:** The 60/24-month coverage cut-offs are not industry standards. The 29-month demand period includes partial months at both ends, so products near a threshold (for example 1926 Ford Fire Engine at 61.93 months) should be read with caution.
