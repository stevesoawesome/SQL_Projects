-- ----------------------------------------------------------------------------------
-- -----------------------------Creating The Dataset---------------------------------
-- ----------------------------------------------------------------------------------

/*
This section will be the creation of the database in addition to the table as well.
Instead of inserting the rows, I will be importing the dataset via CSV file.
*/

CREATE DATABASE IF NOT EXISTS SalesDataWalmart;

-- Using the newly created database so I can add a table to it.
USE ChatGPT_Examples;

CREATE TABLE IF NOT EXISTS sales(
	invoice_id VARCHAR(30) NOT NULL PRIMARY KEY,
    branch VARCHAR(5) NOT NULL,
    city VARCHAR(30) NOT NULL,
    customer_type VARCHAR(30) NOT NULL,
    gender VARCHAR(10) NOT NULL,
    product_line VARCHAR(100) NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    quantity INT NOT NULL,
    VAT FLOAT(6, 4) NOT NULL,
    total DECIMAL(10, 2) NOT NULL,
    date DATETIME NOT NULL,
    time TIME NOT NULL,
    payment_method VARCHAR(15) NOT NULL,
    cogs DECIMAL(10, 2) NOT NULL,
    gross_margin_percentage FLOAT(11, 9) NOT NULL,
    gross_income DECIMAL(10, 2) NOT NULL,
    rating FLOAT(2, 1) NOT NULL
    );
    
-- Verifying content was fully imported.
SELECT DISTINCT *
FROM sales;


-- ----------------------------------------------------------------------------------
-- ---------------------------Data Manipulation--------------------------------------
-- ----------------------------------------------------------------------------------

/*
Creating a new column, time_of_day to categorize each record into Morning,
Afternoon, and Evening time frames.  This can then be used to derive insights
for trends and patterns for time of sales.
*/

-- Creating a query to display the time of day for each record.
SELECT
	time,
    CASE
		WHEN time BETWEEN '00:00:00' AND '12:00:00' THEN 'Morning'
        WHEN time BETWEEN '12:01:00' AND '16:00:00' THEN 'Afternoon'
        ELSE 'Evening'
	END AS timezone
FROM sales;

-- Adding the time_of_day column.
ALTER TABLE sales ADD COLUMN time_of_day VARCHAR(20);

-- Adding the time of day entries into the newly created column.
UPDATE sales
SET time_of_day = (
	CASE
		WHEN time BETWEEN '00:00:00' AND '12:00:00' THEN 'Morning'
		WHEN time BETWEEN '12:01:00' AND '16:00:00' THEN 'Afternoon'
		ELSE 'Evening'
	END);


/*
Add a new column named day_name, that contains the extracted day of the week
(Mon, Tues, Wed, Thur, Fri).  This will help us answer the question on which
day of the week each branch is busiest.
*/

-- Running a query to get the days of the week and verify that works.
SELECT
	date,
    DAYNAME(date) AS day_name
FROM sales;

-- Adding the day_name column to the sales table.
ALTER TABLE sales ADD COLUMN day_name VARCHAR(10);

-- Updating the day_name column with the day of the week.
UPDATE sales
SET day_name = DAYNAME(date);


/*
Adding a new column called month_name, that contains the extracted month of
the year, on which the transaction took place.  This can help us determine
which month of the year has the most sales and profits, or which months were
the best for particular branches/cities
*/

-- Running a query to get the month name and verify accuracy.
SELECT
	date,
    MONTHNAME(date) AS month_name
FROM sales;

-- Adding a new column for month_name.
ALTER TABLE sales ADD COLUMN month_name VARCHAR(9);

-- Adding the month values to the month_name columns.
UPDATE sales
SET month_name = MONTHNAME(date);


-- ----------------------------------------------------------------------------------
-- ---------------------------Answering Business Questions---------------------------
-- ----------------------------------------------------------------------------------

-- ---------------------
-- Generic Questions: --
-- ---------------------

-- How many unique cities does the data have?
SELECT DISTINCT city
FROM sales;


-- Which city is each branch located within?
SELECT
	DISTINCT city,
    branch
FROM sales;


-- ---------------------
-- Product Questions: --
-- ---------------------

-- How many unique product lines does the data have?
SELECT COUNT(DISTINCT product_line)
FROM sales;


-- What is the most common payment method?
SELECT
	payment_method,
    COUNT(*) AS num_of_entries
FROM sales
GROUP BY payment_method
ORDER BY num_of_entries DESC;


-- What is the most selling product line?
SELECT product_line, COUNT(*) AS num_of_sales
FROM sales
GROUP BY product_line
ORDER BY num_of_sales DESC;


-- What is the total revenue by month?
SELECT
	month_name AS month,
    SUM(total) AS total_revenue
FROM sales
GROUP BY month
ORDER BY total_revenue DESC;
    

-- What month had the largest COGS?
SELECT
	month_name AS month,
    SUM(cogs) AS total_cost_of_goods
FROM sales
GROUP BY month
ORDER BY total_cost_of_goods DESC;


-- What product line had the largest revenue?
SELECT
	product_line,
    SUM(total) AS total_revenue
FROM sales
GROUP BY product_line
ORDER BY total_revenue DESC;


-- What is the city with the largest revenue?
SELECT
	city,
    SUM(total) AS total_revenue
FROM sales
GROUP BY city
ORDER BY total_revenue DESC;


-- What product line had the largest VAT?
SELECT
	product_line,
    AVG(VAT) AS avg_vat
FROM sales
GROUP BY product_line
ORDER BY avg_vat DESC;


-- Fetch each product line and add a column to those product line showing "Good", "Bad". Good if its
-- greater than average sales
SELECT
    product_line,
    CASE
		WHEN SUM(total) > (SELECT SUM(total)/COUNT(DISTINCT product_line) FROM sales) THEN 'Good'
        ELSE 'Bad' END AS better_than_avg
FROM sales
GROUP BY product_line;


-- Which branch sold more products than average product sold?
SELECT
	branch,
    SUM(quantity) AS num_sold
FROM sales
GROUP BY branch
HAVING SUM(quantity) > (SELECT SUM(quantity) / COUNT(DISTINCT Branch) FROM sales);


-- What is the most common product line by gender?
SELECT
	gender,
    product_line,
    COUNT(gender) AS total_gender
FROM sales
GROUP BY gender, product_line
ORDER BY total_gender DESC;


-- What is the average rating of each product line?
SELECT
	product_line,
    ROUND(AVG(rating), 2) AS avg_rating
FROM sales
GROUP BY product_line
ORDER BY avg_rating DESC;


-- -------------------
-- Sales Questions: --
-- -------------------

-- Number of sales made in each time of the day per weekday
SET @day = 'Friday';

SELECT
    time_of_day,
    SUM(total) AS total_sales
FROM sales
WHERE day_name = @day
GROUP BY time_of_day
ORDER BY total_sales DESC;

-- Which of the customer types brings the most revenue?
SELECT
	customer_type,
    SUM(total) AS total_revenue
FROM sales
GROUP BY customer_type
ORDER BY total_revenue DESC;


-- Which city has the largest tax percent/ VAT (Value Added Tax)?
SELECT
	city,
    AVG(VAT) AS avg_vat
FROM sales
GROUP BY city
ORDER BY avg_vat DESC;


-- Which customer type pays the most in VAT?
SELECT
	customer_type,
    AVG(VAT) AS avg_vat
FROM sales
GROUP BY customer_type
ORDER BY avg_vat DESC;


-- ----------------------
-- Customer Questions: --
-- ----------------------

-- How many unique customer types does the data have?
SELECT
	COUNT(DISTINCT customer_type) AS num_customer_types
FROM sales;


-- How many unique payment methods does the data have?
SELECT
	COUNT(DISTINCT payment_method) AS num_payment_methds
FROM sales;


-- What is the most common customer type?
SELECT
	customer_type,
    COUNT(*) AS num_of
FROM sales
GROUP BY customer_type
ORDER BY num_of;

-- Which customer type buys the most?
SELECT
	customer_type,
    SUM(quantity) AS total_purchase
FROM sales
GROUP BY customer_type
ORDER BY total_purchase;


-- What is the gender of most of the customers?
SELECT
	gender,
    COUNT(*) AS num_of
FROM sales
GROUP BY gender
ORDER BY num_of DESC;


-- What is the gender distribution per branch?
SELECT
	gender,
    branch,
    COUNT(*) AS num_of
FROM sales
GROUP BY branch, gender
ORDER BY branch;


-- Which time of the day do customers submit the most ratings?
SELECT
	time_of_day,
    COUNT(rating) AS num_of_ratings
FROM sales
GROUP BY time_of_day;


-- Which time of the day do customers give most ratings per branch?
SET @branch = 'B';

SELECT
	time_of_day,
    COUNT(rating) AS num_of_ratings
FROM sales
WHERE branch = @branch
GROUP BY time_of_day
ORDER BY num_of_ratings DESC;


-- Which day of the week has the best avg ratings?
SELECT
	day_name,
    AVG(rating) AS avg_rating
FROM sales
GROUP BY day_name
ORDER BY avg_rating DESC;


-- Which day of the week has the best average ratings per branch?
SET @branch = 'B';

SELECT
	day_name,
    AVG(rating) AS avg_rating
FROM sales
WHERE branch = @branch
GROUP BY day_name
ORDER BY avg_rating DESC;


-- ----------------------------------------------------------------------------------
-- -------------------------------Advanced Practice----------------------------------
-- ----------------------------------------------------------------------------------

/*
Getting the total income for each day.  Comparing that to a seven day moving average.
Outputting whether it was a Beat, Miss, or Meet to make it easier to compare and
categorize in the future.
*/

WITH ma_avg AS(
SELECT
	date,
    SUM(gross_income) AS total_income,
    ROUND(AVG(SUM(gross_income)) OVER(ORDER BY date ROWS BETWEEN 7 PRECEDING AND 1 FOLLOWING), 2) AS seven_day_avg
FROM sales
GROUP BY date
)
SELECT
	date,
    total_income,
    seven_day_avg,
    CASE
		WHEN total_income > seven_day_avg THEN 'Beat'
        WHEN total_income < seven_day_avg THEN 'Missed'
        ELSE 'Meet' END AS outcome
FROM ma_avg
ORDER BY date;




/*
Showing the day of the week that generates the most income.

Utilizing a CTE and CASE statement to convert days of the week
from numbers to something more familiar.

Added difference between current and previous rank and percentage
difference (from the higher rank's total income).

Finally, added difference in percentage current total_income is
compared to the highest earning day.
*/

WITH dbuse AS (
SELECT DAYOFWEEK(date) AS weekday, SUM(total) AS total_income, RANK() OVER(ORDER BY SUM(total) DESC) AS ranking
FROM sales
GROUP BY weekday
ORDER BY weekday
)
SELECT
	CASE
		WHEN weekday = 1 THEN 'Monday'
        WHEN weekday = 2 THEN 'Tuesday'
        WHEN weekday = 3 THEN 'Wednesday'
        WHEN weekday = 4 THEN 'Thursday'
        WHEN weekday = 5 THEN 'Friday'
        WHEN weekday = 6 THEN 'Saturday'
        WHEN weekday = 7 THEN 'Sunday'
	END AS weekday_name,
    total_income,
    ranking,
    total_income-LAG(total_income) OVER(ORDER BY ranking) AS difference,
    CONCAT(ROUND(ABS(total_income-LAG(total_income) OVER(ORDER BY ranking))/LAG(total_income)
		OVER(ORDER BY ranking) * 100, 2), '%') AS perc_diff_vs_prev_day,
	CONCAT(ROUND(ABS(total_income-FIRST_VALUE(total_income) OVER(ORDER BY ranking))/FIRST_VALUE(total_income)
		OVER(ORDER BY ranking) * 100, 2), '%') AS perc_diff_vs_highest_day
FROM dbuse
ORDER BY ranking;




/* 
Showing the average, max, and min reviews for each product line, seperated by gender.
*/
SELECT
	product_line,
    gender,
    ROUND(AVG(rating), 2) AS avg_rating,
    ROUND(MAX(rating), 2) AS max_rating,
    ROUND(MIN(rating), 2) AS min_rating
FROM sales
GROUP BY product_line, gender
ORDER BY product_line;




/*
Displays the customer type and their total purchase for each product_line.
Additionally, outputs if a normal shopper or member bought more for that
product line.
*/
WITH details AS(
SELECT
	customer_type,
    product_line,
    SUM(quantity) AS total_purchase
FROM sales
GROUP BY customer_type, product_line
ORDER BY 2, 1)

SELECT
	a.customer_type,
    a.product_line,
    a.total_purchase,
    CASE
		WHEN a.total_purchase > b.total_purchase THEN a.customer_type
        ELSE b.customer_type END AS who_bought_more
FROM details a
JOIN details b
	ON a.product_line=b.product_line
    AND a.customer_type != b.customer_type;
