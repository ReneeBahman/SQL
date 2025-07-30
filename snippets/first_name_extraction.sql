/* how to extract first name

In Sybase SQL, you can use the CHARINDEX and SUBSTRING functions to extract the first name (the portion of the string before the space). Here's how you can do it:


*/


SELECT 
    SUBSTRING(customer_name, 1, CHARINDEX(' ', customer_name) - 1) AS first_name
FROM 
    your_table
WHERE 
    CHARINDEX(' ', customer_name) > 0;

/*

Explanation:
CHARINDEX(' ', customer_name): Finds the position of the first space in the customer_name field.

SUBSTRING(customer_name, 1, CHARINDEX(' ', customer_name) - 1): Extracts the substring starting from the first character up to the character before the space.

WHERE CHARINDEX(' ', customer_name) > 0: Ensures there is a space in the customer_name to avoid errors.

Notes:
If there is a chance that the field might not contain a space (e.g., only a single name), you may want to handle those cases separately. For instance:

*/

SELECT 
    CASE 
        WHEN CHARINDEX(' ', customer_name) > 0 
        THEN SUBSTRING(customer_name, 1, CHARINDEX(' ', customer_name) - 1)
        ELSE customer_name
    END AS first_name
FROM 
    your_table;


/*
This fallback will return the full name if no space is found.
*/