-- SWIGGY SALES ANALYSIS

-- Data Validation and Cleaning
-- Null Check
SELECT
	SUM(CASE WHEN State IS NULL THEN 1 ELSE 0 END) AS Null_State,
	SUM(CASE WHEN City IS NULL THEN 1 ELSE 0 END) AS Null_City,
	SUM(CASE WHEN Order_Date IS NULL THEN 1 ELSE 0 END) AS NULL_Order_Date,
	SUM(CASE WHEN Restaurant_Name IS NULL THEN 1 ELSE 0 END) AS Null_Restaurant_Name,
	SUM(CASE WHEN Location IS NULL THEN 1 ELSE 0 END) AS Null_Location,
	SUM(CASE WHEN Category IS NULL THEN 1 ELSE 0 END) AS Null_Category,
	SUM(CASE WHEN Dish_Name IS NULL THEN 1 ELSE 0 END) AS Null_Dish_Name,
	SUM(CASE WHEN Price_INR IS NULL THEN 1 ELSE 0 END) AS Null_Price_INR,
	SUM(CASE WHEN Rating IS NULL THEN 1 ELSE 0 END) AS Null_Rating,
	SUM(CASE WHEN Rating_Count IS NULL THEN 1 ELSE 0 END) AS Null_Rating_Count
FROM Swiggy_Data;

-- Blank/Empty String Check
SELECT * 
FROM Swiggy_Data
WHERE
State = '' OR City = '' OR Restaurant_Name = '' OR Location = '' OR Category = ''
OR Dish_Name = '' 

-- Duplicate Detection
SELECT 
State, City, Order_Date, Restaurant_Name, Location, Category,
Dish_Name, Price_INR, Rating, Rating_Count, Count(*) AS Count
FROM Swiggy_Data
GROUP BY State, City, Order_Date, Restaurant_Name, Location, Category,
Dish_Name, Price_INR, Rating, Rating_Count
HAVING COUNT(*) > 1;

-- Duplicate Removal
WITH CTE AS (
SELECT *, ROW_NUMBER() Over(
	PARTITION BY State, City, Order_Date, Restaurant_Name, Location, Category, Dish_Name, Price_INR, Rating, Rating_Count
	ORDER BY (SELECT NULL)
) AS rn
FROM Swiggy_Data
)
DELETE FROM CTE WHERE rn > 1

-- Dimensional Modelling (Star Schema)
-- Dimensions Table

--  dim_date → Year, Month, Quarter, Week
--  dim_location → State, City, Location
--  dim_restaurant → Restaurant_Name
--  dim_category → Cuisine/Category
--  dim_dish → Dish_Name
-- Central fact table:
--  fact_swiggy_orders → Price_INR, Rating, Rating_Count, foreign keys to all dimensions

-- dim_date
CREATE TABLE dim_date
(
	date_id INT IDENTITY(1,1) PRIMARY KEY,
	Full_Date DATE,
	Year INT,
	Month INT,
	Month_Name VARCHAR(20),
	Quarter INT,
	Day INT,
	Week INT
);

-- dim_location
CREATE TABLE dim_location (
	location_id INT IDENTITY(1,1) PRIMARY KEY,
	State VARCHAR(100),
	City VARCHAR(100),
	Location VARCHAR(200)
);

-- dim_restaurant
CREATE TABLE dim_restaurant (
	restaurant_id INT IDENTITY(1,1) PRIMARY KEY,
	Restaurant_Name VARCHAR(200)
);

-- dim_category
CREATE TABLE dim_category(
	category_id INT IDENTITY(1,1) PRIMARY KEY,
	Category VARCHAR(200)
);

--dim_dish
CREATE TABLE dim_dish
(
	dish_id INT IDENTITY(1,1) PRIMARY KEY,
	Dish_Name VARCHAR(200)
);

-- Fact Table - fact_swiggy_orders
CREATE TABLE fact_swiggy_orders
(
	order_id INT IDENTITY(1,1) PRIMARY KEY,

	Price_INR DECIMAL(10,2),
	Rating DECIMAL(4,2),
	Rating_Count INT,

	date_id INT,
	location_id INT,
	restaurant_id INT,
	category_id INT,
	dish_id INT,

	FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
	FOREIGN KEY (location_id) REFERENCES dim_location(location_id),
	FOREIGN KEY (restaurant_id) REFERENCES dim_restaurant(restaurant_id),
	FOREIGN KEY (category_id) REFERENCES dim_category(category_id),
	FOREIGN KEY (dish_id) REFERENCES dim_dish(dish_id)
);

-- INSERT DATA IN TABLES
-- dim_date
INSERT INTO dim_date (Full_Date, Year, Month, Month_Name, Quarter, Day, Week)
SELECT DISTINCT 
	Order_Date,
	YEAR(Order_Date),
	MONTH(Order_Date),
	DATENAME(MONTH, Order_Date),
	DATEPART(QUARTER, Order_Date),
	DAY(Order_Date),
	DATEPART(WEEK, Order_Date)
FROM Swiggy_Data
WHERE Order_Date IS NOT NULL;

-- dim_location
INSERT INTO dim_location (State, City, Location)
SELECT DISTINCT
	State,
	City,
	Location
FROM Swiggy_Data;

-- dim_restaurant
INSERT INTO dim_restaurant (Restaurant_Name)
SELECT DISTINCT
	Restaurant_Name
FROM Swiggy_Data;

-- dim_category
INSERT INTO dim_category (Category)
SELECT DISTINCT
	Category
FROM Swiggy_Data;

-- dim_dish
INSERT INTO dim_dish (Dish_Name)
SELECT DISTINCT
	Dish_Name
FROM Swiggy_Data;

-- fact_table - fact_swiggy_orders
INSERT INTO fact_swiggy_orders
(
	date_id,
	Price_INR,
	Rating,
	Rating_Count,
	location_id,
	restaurant_id,
	category_id,
	dish_id
)
SELECT
	dd.date_id,
	s.Price_INR,
	s.Rating,
	s.Rating_Count,
	dl.location_id,
	dr.restaurant_id,
	dc.category_id,
	dsh.dish_id
FROM Swiggy_Data s 
INNER JOIN dim_date dd ON dd.Full_Date = s.Order_Date
INNER JOIN dim_location dl ON dl.State = s.State AND dl.City = s.City AND dl.Location = s.Location
INNER JOIN dim_restaurant dr ON dr.Restaurant_Name = s.Restaurant_Name
INNER JOIN dim_category dc ON dc.Category = s.Category
INNER JOIN dim_dish dsh ON dsh.Dish_Name = s.Dish_Name

SELECT * FROM fact_swiggy_orders

SELECT * FROM fact_swiggy_orders f 
INNER JOIN dim_date d ON f.date_id = d.date_id
INNER JOIN dim_location dl ON dl.location_id = f.location_id
INNER JOIN dim_restaurant dr ON dr.restaurant_id = f.restaurant_id
INNER JOIN dim_category dc ON dc.category_id = f.category_id
INNER JOIN dim_dish dsh ON dsh.dish_id = f.dish_id;

-- KPI DEVELOPMENT
-- Basic KPIs

-- Total Orders
SELECT COUNT(*) AS Total_Orders
FROM fact_swiggy_orders;

-- Total Revenue (INR Million)
SELECT FORMAT(SUM(CONVERT(FLOAT,Price_INR))/1000000, 'N2') + ' INR Million'AS Total_Revenue
FROM fact_swiggy_orders;

-- Average Dish Price
SELECT FORMAT(AVG(CONVERT(FLOAT, Price_INR)), 'N2') + ' INR' AS Average_Dish_Price
FROM fact_swiggy_orders;

-- Average Rating
SELECT AVG(Rating) AS Avg_Rating
FROM fact_swiggy_orders;

-- GRANULAR REQUIREMENTS
-- Deep-Dive Business Analysis
-- Date-Based Analysis
-- Monthly Order Trends
SELECT 
d.Year, d.Month, d.Month_Name, COUNT(*) AS Total_Orders
FROM fact_swiggy_orders f 
INNER JOIN dim_date d ON d.date_id = f.date_id
GROUP BY d.Year, d.Month, d.Month_Name
ORDER BY COUNT(*) DESC;

-- Monthly Order Trends According to Price_INR
SELECT 
d.Year, d.Month, d.Month_Name, SUM(Price_INR) AS Total_Revenue
FROM fact_swiggy_orders f 
INNER JOIN dim_date d ON d.date_id = f.date_id
GROUP BY d.Year, d.Month, d.Month_Name
ORDER BY SUM(Price_INR) DESC;

-- Quarterly Trend
SELECT
d.Year,
d.Quarter,
COUNT(*) AS Total_Orders
FROM fact_swiggy_orders f 
INNER JOIN dim_date d ON d.date_id = f.date_id
GROUP BY d.Year, d.Quarter
ORDER BY COUNT(*) DESC;

-- Yearly Trend 
SELECT 
d.Year, 
COUNT(*) AS Total_Orders
FROM fact_swiggy_orders f 
INNER JOIN dim_date d ON d.date_id = f.date_id 
GROUP BY d.Year 
ORDER BY COUNT(*) DESC;

-- Order by day of week (Mon - Sun)
SELECT 
	DATENAME(WEEKDAY, d.Full_Date) AS Day_Name,
	COUNT(*) AS Total_Orders 
FROM fact_swiggy_orders f 
INNER JOIN dim_date d ON f.date_id = d.date_id
GROUP BY DATENAME(WEEKDAY, d.Full_Date), DATEPART(WEEKDAY, d.Full_Date)
ORDER BY DATEPART(WEEKDAY, d.Full_Date);

-- Location-Based Analysis
-- Top 10 cities by order volume 
SELECT TOP 10 
l.City,
COUNT(*) AS Total_Orders 
FROM fact_swiggy_orders f 
INNER JOIN dim_location l ON l.location_id = f.location_id 
GROUP BY l.City 
ORDER BY COUNT(*) DESC;

-- Top 10 cities by Sum of Sales
SELECT TOP 10 
l.City,
SUM(f.Price_INR) AS Total_Revenue 
FROM fact_swiggy_orders f 
INNER JOIN dim_location l ON l.location_id = f.location_id 
GROUP BY l.City 
ORDER BY SUM(f.Price_INR) DESC;

-- Revenue Contribution by States
SELECT
l.State, 
SUM(f.Price_INR) AS Total_Revenue 
FROM fact_swiggy_orders f 
INNER JOIN dim_location l ON l.location_id = f.location_id
GROUP BY l.State
ORDER BY SUM(f.Price_INR) DESC;

-- Food Performance
-- Top 10 restaurants by orders
SELECT TOP 10 
r.Restaurant_Name, 
COUNT(*) AS Total_Orders 
FROM fact_swiggy_orders f 
INNER JOIN dim_restaurant r ON f.restaurant_id = r.restaurant_id
GROUP BY r.Restaurant_Name 
ORDER BY COUNT(*) DESC;

-- Top categories by order volume
SELECT 
c.Category, 
COUNT(*) AS Total_Orders 
FROM fact_swiggy_orders f 
INNER JOIN dim_category c ON f.category_id = c.category_id 
GROUP BY c.Category 
ORDER BY COUNT(*) DESC;

-- Most Ordered Dish by order volume
SELECT 
dsh.Dish_Name,
COUNT(*) AS Total_Orders 
FROM fact_swiggy_orders f 
INNER JOIN dim_dish dsh ON dsh.dish_id = f.dish_id
GROUP BY dsh.Dish_Name
ORDER BY COUNT(*) DESC;

-- Cuisine Performance (Orders + Avg Price)
SELECT 
	c.Category,
	COUNT(*) AS Total_Orders,
	AVG(f.Rating) Avg_Rating 
FROM fact_swiggy_orders f 
INNER JOIN dim_category c ON c.category_id = f.category_id 
GROUP BY c.Category 
ORDER BY Total_Orders DESC;

-- Customer Spending Insights 
SELECT 
	CASE 
		WHEN CONVERT(FLOAT, Price_INR) < 100 THEN 'Under 100'
		WHEN CONVERT(FLOAT, Price_INR) BETWEEN 100 AND 199 THEN '100-199'
		WHEN CONVERT(FLOAT, Price_INR) BETWEEN 200 AND 299 THEN '200-299'
		WHEN CONVERT(FLOAT, Price_INR) BETWEEN 300 AND 499 THEN '300-499'
		ELSE '500+'
	END AS Price_Range, 
	COUNT(*) AS Total_Orders 
FROM fact_swiggy_orders 
GROUP BY 
	CASE 
		WHEN CONVERT(FLOAT, Price_INR) < 100 THEN 'Under 100'
		WHEN CONVERT(FLOAT, Price_INR) BETWEEN 100 AND 199 THEN '100-199'
		WHEN CONVERT(FLOAT, Price_INR) BETWEEN 200 AND 299 THEN '200-299'
		WHEN CONVERT(FLOAT, Price_INR) BETWEEN 300 AND 499 THEN '300-499'
		ELSE '500+'
	END 
ORDER BY Total_Orders DESC;

-- Rating Analysis 
SELECT 
Rating, 
COUNT(*) AS Rating_Count 
FROM fact_swiggy_orders f 
GROUP BY Rating 
ORDER BY COUNT(*) DESC;

