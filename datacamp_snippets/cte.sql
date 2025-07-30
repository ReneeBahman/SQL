/*

-- dim_customer
customer_id | customer_name | country
------------|----------------|---------
1           | Alice          | Estonia
2           | Bob            | Latvia
3           | Charlie        | Estonia

-- fact_loans
loan_id | customer_id | amount | status     | start_date
--------|-------------|--------|------------|------------
101     | 1           | 5000   | active     | 2024-01-15
102     | 2           | 3000   | closed     | 2023-03-12
103     | 1           | 2500   | defaulted  | 2023-08-10
104     | 3           | 6000   | active     | 2025-06-01


*/

WITH loan_summary AS (
  SELECT 
    customer_id,
    COUNT(*) AS loan_count,
    SUM(amount) AS total_amount
  FROM fact_loans
  GROUP BY customer_id
)
SELECT 
    dc.customer_name,
    ls.loan_count,
    ls.total_amount
FROM loan_summary ls
JOIN dim_customer dc ON dc.customer_id = ls.customer_id;

SELECT 
    dc.country, 
    COUNT(fl1.loan_id) AS active, 
    COUNT(fl2.loan_id) AS closed, 
    COUNT(fl3.loan_id) AS defaulted
FROM dim_customer AS dc
LEFT JOIN fact_loans AS fl1 ON dc.customer_id = fl1.customer_id AND fl1.status = 'active'
LEFT JOIN fact_loans AS fl2 ON dc.customer_id = fl2.customer_id AND fl2.status = 'closed'
LEFT JOIN fact_loans AS fl3 ON dc.customer_id = fl3.customer_id AND fl3.status = 'defaulted'
GROUP BY dc.country;

SELECT 
    dc.country,
    SUM(CASE WHEN fl.status = 'active' THEN 1 ELSE 0 END) AS active,
    SUM(CASE WHEN fl.status = 'closed' THEN 1 ELSE 0 END) AS closed,
    SUM(CASE WHEN fl.status = 'defaulted' THEN 1 ELSE 0 END) AS defaulted
FROM dim_customer dc
JOIN fact_loans fl ON dc.customer_id = fl.customer_id
GROUP BY dc.country;

-- Step 1: Create the temp table
SELECT 
    country,
    CONVERT(INT, 0) AS active,
    CONVERT(INT, 0) AS closed,
    CONVERT(INT, 0) AS defaulted
INTO #loan_status_by_country
FROM dim_customer
GROUP BY country;

-- Step 2: Update each status column using JOINs
UPDATE t
SET t.active = x.active_count
FROM #loan_status_by_country t
JOIN (
    SELECT dc.country, COUNT(*) AS active_count
    FROM dim_customer dc
    JOIN fact_loans fl ON dc.customer_id = fl.customer_id
    WHERE fl.status = 'active'
    GROUP BY dc.country
) x ON t.country = x.country;

UPDATE t
SET t.closed = x.closed_count
FROM #loan_status_by_country t
JOIN (
    SELECT dc.country, COUNT(*) AS closed_count
    FROM dim_customer dc
    JOIN fact_loans fl ON dc.customer_id = fl.customer_id
    WHERE fl.status = 'closed'
    GROUP BY dc.country
) x ON t.country = x.country;

UPDATE t
SET t.defaulted = x.defaulted_count
FROM #loan_status_by_country t
JOIN (
    SELECT dc.country, COUNT(*) AS defaulted_count
    FROM dim_customer dc
    JOIN fact_loans fl ON dc.customer_id = fl.customer_id
    WHERE fl.status = 'defaulted'
    GROUP BY dc.country
) x ON t.country = x.country;

-- Step 3: Final result
SELECT * FROM #loan_status_by_country;

-- Step 1: Create temp table
SELECT 
    customer_name,
    CONVERT(INT, 0) AS loan_count,
    CONVERT(INT, 0) AS total_amount
INTO #customer_loans
FROM dim_customer;

-- Step 2: Update loan_count
UPDATE t
SET t.loan_count = x.cnt
FROM #customer_loans t
JOIN (
    SELECT dc.customer_name, COUNT(*) AS cnt
    FROM dim_customer dc
    JOIN fact_loans fl ON dc.customer_id = fl.customer_id
    GROUP BY dc.customer_name
) x ON t.customer_name = x.customer_name;

-- Step 3: Update total_amount
UPDATE t
SET t.total_amount = x.amt
FROM #customer_loans t
JOIN (
    SELECT dc.customer_name, SUM(fl.amount) AS amt
    FROM dim_customer dc
    JOIN fact_loans fl ON dc.customer_id = fl.customer_id
    GROUP BY dc.customer_name
) x ON t.customer_name = x.customer_name;

-- Step 4: Final result
SELECT * FROM #customer_loans;

