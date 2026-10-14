USE superstore;

TRUNCATE TABLE orders;

TRUNCATE TABLE orders;

LOAD DATA LOCAL INFILE 'C:/Users/ADMIN/Desktop/PROJECTS/tableau_superstore/orderss.csv'
INTO TABLE orders
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(@Row_ID, @Order_ID, @Order_Date, @Ship_Date, @Ship_Mode, @Customer_ID, @Customer_Name, @Segment, @Country, @City, @State, @Postal_Code, @Region, @Product_ID, @Category, @Sub_Category, @Product_Name, @Sales, @Quantity, @Discount, @Profit)
SET
Row_ID = NULLIF(@Row_ID, ''),
Order_ID = NULLIF(@Order_ID, ''),
Order_Date = CASE WHEN @Order_Date LIKE '%/%' THEN STR_TO_DATE(@Order_Date, '%m/%d/%Y') ELSE STR_TO_DATE(@Order_Date, '%Y-%m-%d') END,
Ship_Date = CASE WHEN @Ship_Date LIKE '%/%' THEN STR_TO_DATE(@Ship_Date, '%m/%d/%Y') ELSE STR_TO_DATE(@Ship_Date, '%Y-%m-%d') END,
Ship_Mode = NULLIF(@Ship_Mode, ''),
Customer_ID = NULLIF(@Customer_ID, ''),
Customer_Name = NULLIF(@Customer_Name, ''),
Segment = NULLIF(@Segment, ''),
Country = NULLIF(@Country, ''),
City = NULLIF(@City, ''),
State = NULLIF(@State, ''),
Postal_Code = NULLIF(@Postal_Code, ''),
Region = NULLIF(@Region, ''),
Product_ID = NULLIF(@Product_ID, ''),
Category = NULLIF(@Category, ''),
Sub_Category = NULLIF(@Sub_Category, ''),
Product_Name = NULLIF(@Product_Name, ''),
Sales = CAST(REPLACE(REPLACE(@Sales, '$', ''), ',', '') AS DECIMAL(10,2)),
Quantity = CAST(@Quantity AS UNSIGNED),
Discount = CAST(@Discount AS DECIMAL(4,2)),
Profit = CAST(REPLACE(REPLACE(@Profit, '$', ''), ',', '') AS DECIMAL(10,2));

USE superstore;

SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT Row_ID) AS unique_row_ids,
       MIN(Row_ID) AS min_id,
       MAX(Row_ID) AS max_id
FROM orders;

SELECT MIN(Order_Date), MAX(Order_Date),
       MIN(Ship_Date), MAX(Ship_Date)
FROM orders;

SELECT
  SUM(Order_Date IS NULL) AS null_order_dates,
  SUM(Sales IS NULL) AS null_sales,
  SUM(Profit IS NULL) AS null_profit,
  SUM(Product_Name IS NULL) AS null_product_names
FROM orders;

SELECT Product_Name, Sales, Quantity, Discount, Profit
FROM orders
WHERE Product_Name LIKE '%,%'
LIMIT 10;

SELECT ROUND(SUM(Sales), 2) AS total_sales,
       ROUND(SUM(Profit), 2) AS total_profit
FROM orders;

-- Do the returns match orders?
SELECT COUNT(*) AS matched_returns
FROM returns r
JOIN (SELECT DISTINCT Order_ID FROM orders) o
  ON r.`Order ID` = o.Order_ID;
  
  DESCRIBE returns;
SELECT * FROM returns LIMIT 5;

USE superstore;

-- Total Sales, Total Profit, Profit Margin
SELECT
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(Profit), 2) AS total_profit,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 2) AS profit_margin_pct,
    ROUND(AVG(Sales), 2) AS avg_line_item_sales
FROM orders;

SELECT
    COUNT(DISTINCT Order_ID) AS total_orders,
    ROUND(AVG(order_total), 2) AS avg_order_value,
    ROUND(MAX(order_total), 2) AS highest_order,
    ROUND(MIN(order_total), 2) AS lowest_order
FROM (
    SELECT Order_ID, SUM(Sales) AS order_total
    FROM orders
    GROUP BY Order_ID
) AS order_summary;

SELECT
    COUNT(DISTINCT Order_ID) AS total_orders,
    ROUND(AVG(order_profit), 2) AS avg_profit_per_order,
    SUM(order_profit > 0) AS profitable_orders,
    SUM(order_profit <= 0) AS unprofitable_orders
FROM (
    SELECT Order_ID, SUM(Profit) AS order_profit
    FROM orders
    GROUP BY Order_ID
) AS order_summary;

SELECT
    YEAR(Order_Date) AS year,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(Profit), 2) AS total_profit,
    COUNT(DISTINCT Order_ID) AS total_orders,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 2) AS margin_pct
FROM orders
GROUP BY YEAR(Order_Date)
ORDER BY year;

SELECT
    DATE_FORMAT(Order_Date, '%Y-%m') AS month,
    ROUND(SUM(Sales), 2) AS monthly_sales,
    ROUND(SUM(Profit), 2) AS monthly_profit,
    COUNT(DISTINCT Order_ID) AS monthly_orders,
    ROUND(
        SUM(Profit) / NULLIF(SUM(Sales), 0) * 100,
        2
    ) AS profit_margin_pct
FROM orders
GROUP BY DATE_FORMAT(Order_Date, '%Y-%m')
ORDER BY month;

SELECT
    YEAR(Order_Date)  AS yr,
    MONTH(Order_Date) AS mth,
    ROUND(SUM(Sales), 2) AS monthly_sales,
    ROUND(SUM(Profit), 2) AS monthly_profit,
    COUNT(DISTINCT Order_ID) AS monthly_orders,
    ROUND(
        SUM(Profit) / NULLIF(SUM(Sales), 0) * 100,
        2
    ) AS profit_margin_pct
FROM orders
GROUP BY YEAR(Order_Date), MONTH(Order_Date)
ORDER BY yr, mth;

USE superstore;

SELECT
    Category,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(Profit), 2) AS total_profit,
    ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS profit_margin_pct,
    COUNT(DISTINCT Order_ID) AS total_orders
FROM orders
GROUP BY Category
ORDER BY total_sales DESC;

SELECT
    Category,
    Sub_Category,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(Profit), 2) AS total_profit,
    ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS profit_margin_pct,
    SUM(Quantity) AS units_sold,
    ROUND(AVG(Discount) * 100, 2) AS avg_discount_pct
FROM orders
GROUP BY Category, Sub_Category
ORDER BY total_profit DESC;

SELECT
    Product_Name,
    Category,
    Sub_Category,
    COUNT(*) AS times_sold,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(Profit), 2) AS total_profit,
    ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS profit_margin_pct,
    SUM(Profit < 0) AS loss_making_sales,
    ROUND(SUM(Profit < 0) / COUNT(*) * 100, 1) AS pct_sales_at_loss,
    ROUND(AVG(Discount) * 100, 2) AS avg_discount_pct
FROM orders
GROUP BY Product_Name, Category, Sub_Category
HAVING SUM(Profit) < 0
   AND COUNT(*) >= 3
ORDER BY total_profit ASC
LIMIT 15;

SELECT
    Discount AS discount_rate,
    ROUND(Discount * 100, 1) AS discount_pct,
    COUNT(*) AS num_lines,
    COUNT(DISTINCT Order_ID) AS num_orders,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(Profit), 2) AS total_profit,
    ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS margin_pct
FROM orders
GROUP BY Discount
ORDER BY Discount;

SELECT
    DATE_FORMAT(Order_Date, '%Y-%m') AS month,
    ROUND(SUM(Sales), 2) AS sales,
    ROUND(SUM(Profit), 2) AS profit,
    ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS margin_pct,
    ROUND(AVG(Discount) * 100, 2) AS avg_discount_pct,
    ROUND(SUM(CASE WHEN Discount > 0.2 THEN Sales ELSE 0 END), 2) AS high_discount_sales,
    ROUND(
        SUM(CASE WHEN Discount > 0.2 THEN Sales ELSE 0 END)
        / NULLIF(SUM(Sales), 0) * 100,
        2
    ) AS pct_sales_above_20pct
FROM orders
GROUP BY DATE_FORMAT(Order_Date, '%Y-%m')
ORDER BY margin_pct ASC
LIMIT 10;

SELECT
    CASE WHEN Discount <= 0.20 THEN 'a) Up to 20%' ELSE 'b) Above 20%' END AS discount_band,
    COUNT(*) AS num_lines,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(Profit), 2) AS total_profit,
    ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS margin_pct,
    SUM(Profit < 0) AS loss_making_lines,
    ROUND(SUM(Profit < 0) / COUNT(*) * 100, 1) AS pct_lines_at_loss
FROM orders
GROUP BY discount_band
ORDER BY discount_band;

SELECT
    Category,
    ROUND(AVG(Discount) * 100, 2) AS avg_discount_pct,
    ROUND(SUM(Discount > 0.20) / COUNT(*) * 100, 1) AS pct_lines_above_20,
    ROUND(SUM(CASE WHEN Discount > 0.20 THEN Sales ELSE 0 END)
        / NULLIF(SUM(Sales), 0) * 100, 2) AS pct_sales_above_20,
    ROUND(SUM(CASE WHEN Discount <= 0.20 THEN Profit ELSE 0 END), 2) AS profit_up_to_20,
    ROUND(SUM(CASE WHEN Discount > 0.20 THEN Profit ELSE 0 END), 2) AS profit_above_20,
    ROUND(SUM(Profit), 2) AS total_profit
FROM orders
GROUP BY Category
ORDER BY profit_above_20 ASC;

USE superstore;

DESCRIBE people;

SELECT
    Region,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(Sales) / (SELECT SUM(Sales) FROM orders) * 100, 1) AS pct_of_sales,
    ROUND(SUM(Profit), 2) AS total_profit,
    ROUND(SUM(Profit) / (SELECT SUM(Profit) FROM orders) * 100, 1) AS pct_of_profit,
    ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS margin_pct,
    COUNT(DISTINCT Order_ID) AS num_orders,
    ROUND(SUM(Sales) / COUNT(DISTINCT Order_ID), 2) AS avg_order_value,
    ROUND(AVG(Discount) * 100, 2) AS avg_discount_pct
FROM orders
GROUP BY Region
ORDER BY total_sales DESC;

SELECT
    State,
    Region,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(Profit), 2) AS total_profit,
    ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0), 4) * 100 AS margin_pct,
    COUNT(DISTINCT Order_ID) AS num_orders
FROM orders
GROUP BY State, Region
ORDER BY total_sales DESC
LIMIT 15;

SELECT
    State,
    Region,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(Profit), 2) AS total_profit,
    ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS margin_pct,
    ROUND(AVG(Discount) * 100, 2) AS avg_discount_pct
FROM orders
GROUP BY State, Region
HAVING SUM(Sales) > 50000
   AND SUM(Profit) < 0
ORDER BY total_profit ASC;

SELECT
    Region,
    ROUND(SUM(CASE WHEN YEAR(Order_Date) = 2023 THEN Sales ELSE 0 END), 2) AS sales_2023,
    ROUND(SUM(CASE WHEN YEAR(Order_Date) = 2024 THEN Sales ELSE 0 END), 2) AS sales_2024,
    ROUND(SUM(CASE WHEN YEAR(Order_Date) = 2025 THEN Sales ELSE 0 END), 2) AS sales_2025,
    ROUND(SUM(CASE WHEN YEAR(Order_Date) = 2026 THEN Sales ELSE 0 END), 2) AS sales_2026
FROM orders
GROUP BY Region
ORDER BY Region;

USE superstore;

SHOW COLUMNS FROM people;

SELECT * FROM people;

-- 1. Drop and recreate the table with clean column names
DROP TABLE IF EXISTS people;

CREATE TABLE people (
    Regional_Manager VARCHAR(100),
    Region VARCHAR(50) PRIMARY KEY
);

-- 2. Insert the clean data
INSERT INTO people (Regional_Manager, Region) VALUES
('Sadie Pawthorne', 'West'),
('Chuck Magee', 'East'),
('Roxanne Rodriguez', 'Central'),
('Fred Suzuki', 'South');

-- 3. Run the joined regional analysis
SELECT
    o.Region,
    p.Regional_Manager,
    ROUND(SUM(o.Sales), 2) AS total_sales,
    ROUND(SUM(o.Sales) / (SELECT SUM(Sales) FROM orders) * 100, 1) AS pct_of_sales,
    ROUND(SUM(o.Profit), 2) AS total_profit,
    ROUND(SUM(o.Profit) / (SELECT SUM(Profit) FROM orders) * 100, 1) AS pct_of_profit,
    ROUND(SUM(o.Profit) / NULLIF(SUM(o.Sales), 0) * 100, 2) AS margin_pct,
    COUNT(DISTINCT o.Order_ID) AS num_orders,
    ROUND(AVG(o.Discount) * 100, 2) AS avg_discount_pct
FROM orders o
JOIN people p
    ON o.Region = p.Region
GROUP BY o.Region, p.Regional_Manager
ORDER BY margin_pct DESC;
