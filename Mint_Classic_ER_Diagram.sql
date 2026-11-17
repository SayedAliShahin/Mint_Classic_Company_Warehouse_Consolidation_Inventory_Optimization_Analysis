# Business Problem:
# Mint Classic Company wants to close one of its warehourses to reduce operational 
# costs without affecting the 24 hours shipment sercices? (If anay)


# Undrestand Data 
# Data overview and ER diagram
USE mintclassics;
SHOW TABLES;
DESCRIBE products;
DESCRIBE warehouses;
SELECT * FROM warehouses;

# -- ---------  Data Cleaning and Validating (nulls, blanks, duplicates, inconsistencies, data errors)-- ---------------------

-- ---------------------------------------- Customer table  ------------------------------------ 
-- missing values and nulls
select count(*) as count_of_all, 
    sum(case when customernumber is null or customernumber = '' then 1 else 0 end) as missing_cust_num,
	sum(case when customerName is null or customerName = '' then 1 else 0 end) as missing_cust_name,
	sum(case when phone is null or phone = '' then 1 else 0 end) as missingcust_phone,
	sum(case when addressline1 is null or addressLine1 = '' then 1 else 0 end) as missing_cust_addressline1,
	sum(case when addressLine2 is null or addressLine2 = '' then 1 else 0 end) as missing_cust_addressline2,
	sum(case when city is null or city = '' then 1 else 0 end) as missing_cust_city,
	sum(case when state is null or state = '' then 1 else 0 end) as missing_cust_state,
	sum(case when postalCode is null or postalCode = '' then 1 else 0 end) as missing_cust_postalcode,
	sum(case when country is null or country = '' then 1 else 0 end) as missing_cust_country,
	sum(case when salesRepEmployeeNumber is null or salesRepEmployeeNumber = '' then 1 else 0 end) as missing_cust_salesRepEmployeeNumber,
	sum(case when creditLimit is null or creditLimit = '' then 1 else 0 end) as missing_cust_creditlimit
from customers;
# culumn cust_addressline2 consist 100 nulls which is not a serious problem since we have the addressline1 filled all
# column cust_State has 73 nulls
# cust_postalcode cosnist of 7 nulls which is normal
# column salesRepEmployeeNumber consist of 22 nulls
# column cust_creditlimit consist of 24 nulls
# Above missings are normal for customer table which is not a major table for our analysis

-- Duplicate
select 
	customerNumber,
	count(*) as totalcount
from customers
group by customerNumber
having totalcount > 1;
# No duplicates found


-- ---------------------------------- employees table  ------------------------------------ 
# missing or nulls values
select count(*) as total_count,
	sum(case when employeenumber is null or employeenumber = "" then 1 else 0 end) as empnumbmissing,
    sum(case when lastname is null or lastname = "" then 1 else 0 end) as emplastanamemissing,
    sum(case when firstname is null or firstname = "" then 1 else 0 end) as empfirstnamemissing,
    sum(case when extension is null or extension = "" then 1 else 0 end) as empextensionmissing,
    sum(case when email is null or email = "" then 1 else 0 end) as empemailmissing,
    sum(case when officecode is null or officecode = "" then 1 else 0 end) as empofficecodemissing,
    sum(case when reportsto is null or reportsTo = "" then 1 else 0 end) as empreportstomissing,
    sum(case when jobtitle is null or jobtitle = "" then 1 else 0 end) as empjobtitlemissing
from employees;
# All fine, no serious missing found

# Duplicates
select
	employeenumber,
    count(*) as totalcount
from employees
group by employeeNumber
having count(*) > 1;
# No duplicates found

-- ---------------------------------- offices table  ------------------------------------ 
# missing and null values values
select count(*) as CountOfAll,
	sum(case when officecode is null or officecode = "" then 1 else 0 end) as officecode_missing,
    sum(case when city is null or city = "" then 1 else 0 end) as city_missing,
    sum(case when phone is null or phone = "" then 1 else 0 end) as phone_missing,
    sum(case when addressline1 is null or addressline1 = "" then 1 else 0 end) as addressline1_missing,
    sum(case when addressline2 is null or addressline2 = "" then 1 else 0 end) as addressline2_missing,
    sum(case when state is null or state = "" then 1 else 0 end) as state_missing,
    sum(case when country is null or country = "" then 1 else 0 end) as country_missing,
    sum(case when postalcode is null or postalcode = "" then 1 else 0 end) as postalcode_missing,
    sum(case when territory is null or territory = "" then 1 else 0 end) as territory_missing
from offices;
# No serous missing or null values found

# Duplicates
select
	officecode,
    count(*) as count
from offices
group by officecode
having count(*) > 1;
# No duplicates found

-- ---------------------------------- orderdetails table  ------------------------------------ 
# missing values
select count(*) countOfAll,
	sum(case when ordernumber is null or ordernumber = "" then 1 else 0 end) as "ordernumber missing",
    sum(case when productcode is null or productcode = "" then 1 else 0 end) as "productcode missing",
    sum(case when quantityordered is null or quantityordered = "" then 1 else 0 end) as "quantityordered missing",
    sum(case when priceeach is null or priceeach = "" then 1 else 0 end) as "priceeach missing",
    sum(case when orderlinenumber is null or orderlinenumber = "" then 1 else 0 end) as "orderlinenumber missing"
from orderdetails;
# No missing values found

# Duplicates
select
	ordernumber,
    productCode,
    count(*) as duplicateCount
from orderdetails
group by orderNumber, productCode
having count(*) > 1;
# No duplicates found

# Inconsistencies
# 0 and <0 values in price and quantity
select count(*) as count
from orderdetails
where quantityOrdered = 0 or quantityOrdered is null;

-- quanitity bellow 1 and 0 prices
select count(*) as count
from orderdetails
where priceEach < 1 or quantityOrdered < 1;
# All data fine


-- ---------------------------------- orders table  ------------------------------------ 
# Missing and null values
select count(*) as countOfAll,
	sum(case when orderNumber is null then 1 else 0 end) as "ordernumber missing",
    sum(case when orderDate is null then 1 else 0 end) as "orderdate missing",
    sum(case when requiredDate is null then 1 else 0 end) as "requireddate missing",
    sum(case when shippedDate is null then 1 else 0 end) as "shippeddate missing",
    sum(case when "status" is null or 'status' = "" then 1 else 0 end) as "status missing",
    sum(case when comments is null or comments = "" then 1 else 0 end) as "comments missing",
    sum(case when customernumber is null or customernumber = "" then 1 else 0 end) as "customernumber missing"
from orders;
# No serious missing values found. 14 shippeddate missing comes from the order status which are canclled, hold or in progress

# Duplicates
select 
	count(*) as countofall,
	ordernumber,
    customernumber
from orders
group by ordernumber, customernumber
having count(*) > 1;
# No duplcate values found

# Inconsistencies
# Checking Date columns sequences
SELECT
	orderNumber,
    orderdate,
    requiredDate
FROM mintclassics.orders
where requiredDate < orderdate;

# dates login and order
SELECT
	orderNumber,
    orderdate,
    shippeddate
FROM mintclassics.orders
where shippeddate < orderdate;
# All fine


-- ---------------------------------- payments table  ------------------------------------ 
# Missing and null values
select count(*) countofall,
	sum(case when customernumber is null or customernumber = "" then 1 else 0 end) as "customernumber missing",
    sum(case when checknumber is null or checknumber = "" then 1 else 0 end) as "checknumber missing",
    sum(case when paymentdate is null then 1 else 0 end) as "paymentdate missing",
    sum(case when amount is null or amount = "" then 1 else 0 end) as "amount missing"
from payments;
# No missing or null values found

# Duplicates
select count(*) as count,
	customernumber, 
    checknumber
from payments
group by checkNumber, customerNumber
having count(*) > 1;
# No duplicate values found


-- ---------------------------------- productlines table  ------------------------------------ 
select count(*) as countofall,
	sum(case when productline is null or productLine = "" then 1 else 0 end) as "productline missing",
    sum(case when textdescription is null or textdescription = "" then 1 else 0 end) as "textdescription missing",
    sum(case when htmldescription is null or htmldescription = "" then 1 else 0 end) as "htmldescription missing",
    sum(case when image is null or image = "" then 1 else 0 end) as "image missing"
from productlines;
# No improtant missing or null values

# Duplicates
select count(*) as count,
	productline
from productlines
group by productLine
having count(*) > 1;
# No duplicates found

-- ---------------------------------- productlines table  ------------------------------------
select count(*) countofall,
	sum(case when productcode is null or productcode = "" then 1 else 0 end) as "productcode missing",
    sum(case when productname is null or productname = "" then 1 else 0 end) as "productname missing",
    sum(case when productLine is null or productLine = "" then 1 else 0 end) as "productLine missing",
    sum(case when productScale is null or productScale = "" then 1 else 0 end) as "productScale missing",
    sum(case when productVendor is null or productVendor = "" then 1 else 0 end) as "productVendor missing",
    sum(case when productDescription is null or productDescription = "" then 1 else 0 end) as "productDescription missing",
    sum(case when quantityInStock is null or quantityInStock = "" then 1 else 0 end) as "quantityInStock missing",
    sum(case when warehouseCode is null or warehouseCode = "" then 1 else 0 end) as "warehouseCode missing",
    sum(case when buyPrice is null or buyPrice = "" then 1 else 0 end) as "buyPrice missing",
    sum(case when MSRP is null or MSRP = "" then 1 else 0 end) as "MSRP missing"
from products;
# No missing or null values found

# Duplicates
select count(*) as count,
	productCode,
    productLine,
    warehouseCode
from products
group by productCode, productLine, warehousecode
having count(*) > 1;
# No duplicates found

# Checking 1-to-1 product and warehouse relationship
select 
	productcode,
    count(distinct warehousecode) as count_of_warehouse
from products
group by productcode;
# All 1-to-1 realtionship

# Orphaned products Foreign Keys
select 
	p.productcode,
    p.warehousecode
from products p
left join warehouses w
	on p.warehouseCode = w.warehouseCode
where w.warehouseCode is  null;
# No orphaned product primary keys found


-- ---------------------------------- productlines table  ------------------------------------
# No missing, null or duplicata values found

# Orpahned Primary Key
select p.productCode, w.warehousecode
from warehouses w
left join products p
	on w.warehouseCode = p.warehouseCode
where p.productCode is null;
# No orphaned primary keys found
### Overall, tables are clean, contains reliable data and required data and is ready for analysis###




-- ------------------ Explore (EDA)	(Capacity, stock, utilization, sales volume, and shipping time per warehouse) ------------
# what is the total items sold? Total Revenue? Total Cost? Total Profit? Average Order Value?
select
	sum(quantityordered) as total_items_sold,
	sum(quantityordered * priceeach)as total_revenue,
    SUM(quantityOrdered * buyPrice) AS total_cost,
    SUM(quantityOrdered * (priceEach - buyPrice)) AS gross_profit,
    avg(quantityOrdered * priceEach) as "avg order value",
    avg(quantityOrdered) as "avg order"
from orderdetails od
join products p
 on od.productCode = p.productCode;
# 105516 total items sold, with average order of 35, generating 9604190 total revenue. While costing a total of 5778310 total cost and 3825880 total gross profit



# Top 5 high revenue performing producst?
select 
	p.productname,
    sum(od.quantityordered * priceeach) as total_revenue,
    w.warehousename
from products p
join orderdetails od
	on p.productCode = od.productCode
join warehouses w
	on w.warehouseCode = p.warehouseCode
group by p.productName, p.productName, w.warehousename
order by total_revenue desc
limit 5;
# "1992 Ferrari 360 Spider red", "2001 Ferrari Enzo" and "1952 Alpine Renault 1300" are the top performing products
# 4 of 5 high performing products shipped from "East" warehouse

# top 10 customers based on thier average order value
select 
	c.customerNumber,
    c.customername,
    avg(od.quantityordered * od.priceeach) as avg_order_value
from customers c
join orders o
	on c.customerNumber = o.customerNumber
join orderdetails od
	on od.orderNumber = o.orderNumber
group by c.customerNumber
order by avg_order_value desc
limit 10;




# How many items each warehouse contains? What is the total orders per warehouse? 
# How much is the total revenue for each warehouse? How much of each warehouse space is used and how much is available?
WITH Inventory AS (
    SELECT
        warehouseCode,
        COUNT(*) AS distinct_products,
        SUM(quantityInStock) AS total_inventory
    FROM products
    GROUP BY warehouseCode
),

Sales AS (
    SELECT
        p.warehouseCode,
        COUNT(DISTINCT od.orderNumber) AS total_orders,
        SUM(od.quantityOrdered * od.priceEach) AS total_revenue,
        SUM(
            od.quantityOrdered * (od.priceEach - p.buyPrice)
        ) AS gross_profit
    FROM products p
    JOIN orderdetails od
        ON p.productCode = od.productCode
    GROUP BY p.warehouseCode
),

Scale AS (
    SELECT
        warehouseCode,
        productScale,
        ROW_NUMBER() OVER (
            PARTITION BY warehouseCode
            ORDER BY SUM(quantityInStock) DESC, productScale
        ) AS "rank"
    FROM products
    GROUP BY warehouseCode, productScale
)

SELECT
    w.warehouseCode,
    i.distinct_products,
    i.total_inventory,
    s.total_orders,
    ROUND(s.total_revenue, 2) AS total_revenue,
    ROUND(s.gross_profit, 2) AS gross_profit,
    ROUND(
        s.gross_profit / NULLIF(SUM(s.gross_profit) OVER (), 0) * 100,
        2
    ) AS profit_share_pct,
    w.warehousePctCap AS utilization_pct,
    100 - w.warehousePctCap AS available_capacity_pct,
    scl.productScale AS dominant_product_scale
FROM warehouses w

LEFT JOIN Inventory i
    ON w.warehouseCode = i.warehouseCode
LEFT JOIN Sales s
    ON w.warehouseCode = s.warehouseCode

LEFT JOIN Scale as scl 
    ON w.warehouseCode = scl.warehouseCode
    AND scl.rank = 1

ORDER BY s.total_revenue DESC;
# warehouse "b" is leading with the highest total revenue and profit share (39%)
# Warehouse "d" contains the least amount of itmes (79380), the lowest total profit (727183, 19.1%), 25% free space
	-- "1:18" is dominant product scale of warehouses "b" and "c"  which makes the physical absorbtion practical for warehouse "d"
	-- warehouse "d" is the potential closure nominate




# Time-series analysis
# Monthly revenue by warehouse
select 
   (o.orderdate) as "Year",
   month(o.orderdate) as "Month#",
    monthname(o.orderdate) as "Month",
    sum(od.quantityordered * od.priceeach) as monthly_revenue,
    SUM(
    od.quantityOrdered * (od.priceEach - p.buyPrice)
) as monthly_profit
from orderdetails od
join orders o
	on od.orderNumber = o.orderNumber
join products p
	on p.productCode = od.productCode
group by o.orderDate;


    


# Order Stutus
# Percentage stustus complete
select 
	status,
    count(distinct ordernumber) as total_orders,
    count(distinct orderNumber) * 100 / (SELECT COUNT(DISTINCT orderNumber) FROM orders) as percentage
from orders
group by status
order by total_orders desc;
# Over, Mint Classic company has 92% order shipped-order and only about 2% cancellation rate

# Cancellation rate by warehouse-assigned products
select
	w.warehouseCode,
    count(distinct o.orderNumber) as total_orders,
	count(distinct case when status = "Shipped" then o.orderNumber end) as "# of Shipped orders",
    count(distinct case when status = "Cancelled" then o.orderNumber end) as "# of cancelled orders",
    count(distinct case when status = "On hold" then o.orderNumber end) as "# of On hold orders",
    count(distinct case when status = "In progress" then o.orderNumber end) as "# of in progress orders",
    count(distinct case when status = "disputed" then o.orderNumber end) as "# of disputed orders",
    count(distinct case when status = "resolved" then o.orderNumber end) as "# of resolved orders",
	round(count(distinct case when o.status = "cancelled" then o.ordernumber end) * 100 / count(distinct o.orderNumber), 2) as "Cancellation rate"
from warehouses w
join products p
	on w.warehouseCode = p.warehouseCode
join orderdetails od
	on p.productCode = od.productCode
join orders o 
    on od.orderNumber = o.orderNumber
group by w.warehouseCode;
# wharehouse "d" has the highest cancellation rate of around 3%, however it is not much as considered overall



-- --------------------------------- warehouse "d" closure feasibility analysis ---------------------------------------------------------

# Which customers and regions does Warehouse D serve?
select 
	c.country, c.state, p.warehousecode,
    count(distinct o.ordernumber) as total_orders,
    count(distinct c.customernumber) as total_customers,
    sum(od.quantityOrdered * od.priceeach) as revenue
FROM orders o
JOIN customers c
    ON o.customerNumber = c.customerNumber
JOIN orderdetails od
    ON o.orderNumber = od.orderNumber
JOIN products p
    ON od.productCode = p.productCode
WHERE o.status <> 'Cancelled'
GROUP BY
    c.country,
    c.state,
    p.warehouseCode
ORDER BY
    c.country,
    c.state,
    p.warehouseCode;
# Warehouse "d" serves all of the regions beside other warehouses, all region are envolved at least with one alternative warehouses

# Warehouses summary table of % used space and remainging capicity %
select 
	p.warehouseCode,
	count(distinct p.productCode) as total_products,
    sum(p.quantityInStock) as total_units,
    sum(p.quantityInStock * p.buyPrice) as inventory_value,
    w.warehousePctCap,
    100 - w.warehousePctCap as "remaining_cap_%"
from products p
join warehouses w
	on p.warehouseCode = w.warehouseCode
group by p.warehouseCode;

# warehouse D's Customer overlab 
SELECT
    c.customerNumber,
    c.customerName,
    c.country,
    c.state,
    GROUP_CONCAT(
        DISTINCT p.warehouseCode
        ORDER BY p.warehouseCode
    ) AS warehouses_used,
    COUNT(DISTINCT od.orderNumber) AS total_orders,
    COUNT(DISTINCT CASE
    WHEN p.warehouseCode <> 'd'
    THEN p.warehouseCode
END) AS alternative_warehouses
FROM customers c
JOIN orders o
    ON c.customerNumber = o.customerNumber
JOIN orderdetails od
    ON o.orderNumber = od.orderNumber
JOIN products p
    ON od.productCode = p.productCode
WHERE o.status <> 'Cancelled'
GROUP BY
    c.customerNumber,
    c.customerName,
    c.country,
    c.state
HAVING SUM(
    CASE WHEN p.warehouseCode = 'D' THEN 1 ELSE 0 END
) > 0
ORDER BY c.country, c.customerName;
# All of the customers served by warehouse "d" are involved at least with two alternative warehouse, so d's closure most probably will not
# affect the services



# Productscales units per warehouses
Select 
	productScale,
    sum(case when warehouseCode = "a" then quantityInStock else 0 end) as A_units,
	sum(case when warehouseCode = "b" then quantityInStock else 0 end) as B_units,
	sum(case when warehouseCode = "c" then quantityInStock else 0 end) as C_units,
	sum(case when warehouseCode = "d" then quantityInStock else 0 end) as D_units
from products
group by productscale;
# Product scale 1:18 is the dominant scale of warehouses "b", "c" and "d"
# warehouse "d" contains 7 different product scales and 



# Inventory relocation Possibility
with warehouse_units_cap as (
SELECT
    warehouseCode,
    SUM(quantityInStock) AS total_units,
    warehousePctCap,
    ROUND(
        SUM(quantityInStock) / warehousePctCap,
        2
    ) AS units_per_capacity_point
FROM products
JOIN warehouses USING (warehouseCode)
GROUP BY warehouseCode, warehousePctCap)

select 
	wuc.warehouseCode,
    wuc.total_units,
    wuc.units_per_capacity_point,
    w.warehousePctCap as "Utilized_Cap_%",
    100 - w.warehousePctCap as "remaining_cap_%",
    round(wuc.units_per_capacity_point * (100 - w.warehousepctcap), 2) as "estimated_rewaraining_units_cap"
from warehouse_units_cap as wuc
join warehouses w
	on wuc.warehousecode = w.warehouseCode
group by wuc.warehouseCode;
# Warehouse C and B appear to be the strongest candidates for inventory redistribution based on their reported 
# utilization rates. However, the dataset does not define the methodology used to calculate warehouse capacity. 
# Therefore, the estimated remaining unit capacity is treated as a scenario-based estimate, not a confirmed physical storage capacity.


# Warehouse D's each product scale share %
SELECT
    productScale,
    SUM(quantityInStock) AS total_units,
    ROUND(
        SUM(quantityInStock) * 100.0 /
        (SELECT SUM(quantityInStock)
         FROM products
         WHERE warehouseCode = 'd'),
        2
    ) AS inventory_share_pct
FROM products
WHERE warehouseCode = 'd'
GROUP BY productScale
ORDER BY total_units DESC;



# Inventory increase percentage after relocatoin scenario
WITH incoming_inventory AS (
    SELECT
        CASE
            WHEN productScale IN ('1:700', '1:72') THEN 'a'
            WHEN productScale IN ('1:18', '1:12') THEN 'b'
            WHEN productScale IN ('1:32', '1:24', '1:50') THEN 'c'
        END AS destination_warehouse,
        SUM(quantityInStock) AS incoming_units
    FROM products
    WHERE warehouseCode = 'd'
    GROUP BY destination_warehouse
),

current_inventory AS (
    SELECT
        warehouseCode,
        SUM(quantityInStock) AS current_units
    FROM products
    WHERE warehouseCode IN ('a', 'b', 'c')
    GROUP BY warehouseCode
)

SELECT
    c.warehouseCode,
    c.current_units,
    i.incoming_units,
    c.current_units + i.incoming_units AS new_total_units,

    ROUND(
        i.incoming_units * 100.0 / c.current_units,
        2
    ) AS inventory_increase_pct
FROM current_inventory c
JOIN incoming_inventory i
    ON c.warehouseCode = i.destination_warehouse
ORDER BY c.warehouseCode;



# Warehouse D Overstock Analysis
with num_of_months as (
	SELECT
        MIN(orderDate) AS start_date,
        MAX(orderDate) AS end_date,
        timestampdiff(month, MIN(orderDate),  MAX(orderDate)) + 1 as months_covered
    FROM orders
    WHERE status = 'Shipped'
),

product_demand as (
	select 
		od.productCode,
        SUM(od.quantityOrdered) AS total_shipped
    FROM orderdetails od
    JOIN orders o
        ON od.orderNumber = o.orderNumber
    WHERE o.status = 'Shipped'
    GROUP BY od.productCode)
    
Select 
	p.productCode,
    p.productName,
    p.quantityInStock AS current_stock,
    coalesce(pd.total_shipped, 0) as total_shipped,
    round(coalesce(pd.total_shipped, 0) / (nom.months_covered), 2) as avg_monthly_demand,
	case WHEN COALESCE(pd.total_shipped, 0) > 0
			THEN ROUND(
				p.quantityInStock /
				(pd.total_shipped / nom.months_covered),
				2
			)
			ELSE NULL
		END AS stock_coverage_months
FROM products p
LEFT JOIN product_demand pd
    ON p.productCode = pd.productCode
CROSS JOIN num_of_months nom
WHERE p.warehouseCode = 'd'
ORDER BY stock_coverage_months DESC;
# analysis showed that all 23 products in Warehouse D have more than 15 months of stock coverage.



#  products Demand trend and change percentage
WITH demand_comparison AS (
    SELECT
        od.productCode,
        SUM(CASE
            WHEN o.orderDate < '2004-01-06'
            THEN od.quantityOrdered ELSE 0
        END) / 12 AS first_avg_monthly_demand,
        SUM(CASE
            WHEN o.orderDate >= '2004-01-06'
            THEN od.quantityOrdered ELSE 0
        END) / 17 AS recent_avg_monthly_demand
    FROM orderdetails od
    JOIN orders o
        ON od.orderNumber = o.orderNumber
    JOIN products p
        ON od.productCode = p.productCode
    WHERE o.status = 'Shipped'
      AND p.warehouseCode = 'd'
      AND o.orderDate <= '2005-05-31'
    GROUP BY od.productCode
)
SELECT
    productCode,
    ROUND(first_avg_monthly_demand, 2) AS first_avg_monthly_demand,
    ROUND(recent_avg_monthly_demand, 2) AS recent_avg_monthly_demand,
    ROUND(
        (recent_avg_monthly_demand - first_avg_monthly_demand)
        / first_avg_monthly_demand * 100,
        2
    ) AS demand_change_pct
FROM demand_comparison
ORDER BY demand_change_pct desc;



# Before closing Warehouse D, which products should the business consider selling down, reducing future purchases of, or transferring to another warehouse?
WITH num_of_months AS (
    SELECT
        MIN(orderDate) AS start_date,
        MAX(orderDate) AS end_date,
        TIMESTAMPDIFF(
            MONTH,
            MIN(orderDate),
            MAX(orderDate)
        ) + 1 AS months_covered  # +1 includes the starting calendar month, counting 29 calendar months (January 2003–May 2005), including partial months at both ends.
    FROM orders
    WHERE status = 'Shipped'
),

product_demand AS (
    SELECT
        od.productCode,
        SUM(od.quantityOrdered) AS total_shipped
    FROM orderdetails od
    JOIN orders o
        ON od.orderNumber = o.orderNumber
    WHERE o.status = 'Shipped'
    GROUP BY od.productCode
),

demand_trend AS (
    SELECT
        od.productCode,
        SUM(CASE
            WHEN o.orderDate < '2004-01-06'
            THEN od.quantityOrdered ELSE 0
        END) / 12 AS first_avg_monthly,
        SUM(CASE
            WHEN o.orderDate >= '2004-01-06'
            THEN od.quantityOrdered ELSE 0
        END) / 17 AS recent_avg_monthly
    FROM orderdetails od
    JOIN orders o
        ON od.orderNumber = o.orderNumber
    JOIN products p
        ON od.productCode = p.productCode
    WHERE o.status = 'Shipped'
      AND p.warehouseCode = 'd'
      AND o.orderDate <= '2005-05-31'
    GROUP BY od.productCode
)

SELECT
    p.productCode,
    p.productName,
    p.quantityInStock AS current_stock,
    COALESCE(pd.total_shipped, 0) AS total_shipped,
    ROUND(
        COALESCE(pd.total_shipped, 0) / nom.months_covered, 2) AS avg_monthly_demand,
    CASE
        WHEN COALESCE(pd.total_shipped, 0) > 0
        THEN ROUND(
            p.quantityInStock / (pd.total_shipped / nom.months_covered), 2) 
        ELSE NULL
    END AS stock_coverage_months,
    ROUND(dt.first_avg_monthly, 2) AS first_avg_monthly,
    ROUND(dt.recent_avg_monthly, 2) AS recent_avg_monthly,
    ROUND(
        (dt.recent_avg_monthly - dt.first_avg_monthly)
        / dt.first_avg_monthly * 100,
        2
    ) AS demand_change_pct,
    CASE
    WHEN COALESCE(pd.total_shipped, 0) = 0
        THEN 'No Demand'
    WHEN p.quantityInStock / (pd.total_shipped / nom.months_covered) > 60
         AND (dt.recent_avg_monthly - dt.first_avg_monthly)
             / dt.first_avg_monthly * 100 < 0
        THEN 'High Priority'
    WHEN p.quantityInStock / (pd.total_shipped / nom.months_covered) > 60
         AND (dt.recent_avg_monthly - dt.first_avg_monthly)
             / dt.first_avg_monthly * 100 >= 0
        THEN 'High Stock - Monitor'
    WHEN p.quantityInStock / (pd.total_shipped / nom.months_covered) BETWEEN 24 AND 60
         AND (dt.recent_avg_monthly - dt.first_avg_monthly)
             / dt.first_avg_monthly * 100 < 0
        THEN 'Moderate Priority'
    ELSE 'Lower Priority'
END AS inventory_risk
FROM products p
LEFT JOIN product_demand pd
    ON p.productCode = pd.productCode
LEFT JOIN demand_trend dt
    ON p.productCode = dt.productCode
CROSS JOIN num_of_months nom
WHERE p.warehouseCode = 'd'
ORDER BY stock_coverage_months DESC;