WITH numbered_customers AS (
    SELECT customer_id, other_columns,
           ROW_NUMBER() OVER (ORDER BY customer_id) AS rn
    FROM customers
    WHERE some_condition
)
SELECT customer_id, other_columns,
       CASE 
           WHEN (rn % 2) = 0 THEN 'A'
           ELSE 'B'
       END AS sub_audience
FROM numbered_customers;
