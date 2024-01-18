/*
This section will be the creation of the database in addition to the table as well.
Instead of inserting the rows, I will be importing the dataset via CSV file.
*/

CREATE DATABASE IF NOT EXISTS SalesDataWalmart;

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
FROM sales


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
ORDER BY date


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
ORDER BY ranking


-- Comparing reviews per product line, separated by gender.
SELECT
	product_line,
    gender,
    AVG(rating) AS avg_rating
FROM sales
GROUP BY product_line, gender
ORDER BY product_line