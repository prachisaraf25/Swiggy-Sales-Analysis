# 🍽️ Swiggy Sales Analysis using SQL Server

An end-to-end SQL Server data analytics project that analyzes Swiggy sales data using SQL. The project covers data cleaning, Star Schema dimensional modeling, ETL, KPI development, and business analysis to generate meaningful insights from raw sales data.

## 📌 Project Objectives

* Validate and clean raw data
* Detect and remove duplicate records
* Design a Star Schema data warehouse
* Build dimension and fact tables
* Perform ETL using SQL
* Generate business KPIs
* Analyze sales trends and customer behavior

## 🛠️ Tech Stack

* SQL Server
* T-SQL
* SQL Server Management Studio (SSMS)

## 📊 Analysis Performed

### Data Cleaning

* Null value checks
* Blank value validation
* Duplicate detection
* Duplicate removal using CTE and `ROW_NUMBER()`

### Data Warehouse

* `dim_date`
* `dim_location`
* `dim_restaurant`
* `dim_category`
* `dim_dish`
* `fact_swiggy_orders`

### KPIs

* Total Orders
* Total Revenue
* Average Dish Price
* Average Rating

### Business Analysis

* Monthly, Quarterly, and Yearly Trends
* Orders by Day of Week
* Top Cities by Orders and Revenue
* State-wise Revenue Analysis
* Top Restaurants
* Top Food Categories
* Most Ordered Dishes
* Customer Spending Analysis
* Rating Distribution

## 🧠 SQL Concepts Used

* CTEs
* `ROW_NUMBER()`
* Aggregate Functions
* Joins
* `GROUP BY`
* `CASE`
* Date Functions
* Star Schema Modeling
* ETL

## 📂 Files

* `Swiggy Sales Analysis.sql` – Complete SQL script containing data cleaning, dimensional modeling, ETL, KPI queries, and business analysis.
* `Swiggy_Data.csv` – Source dataset used for analysis.
