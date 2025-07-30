/*
from 2017/07 how to query data from 1 year back with datediff or other date difference functionality  

Solution 1: Converting to Date and Using DATEDIFF
Since 2017/07 represents a year and month but lacks a day component, you can append '-01' to create a valid date format (YYYY/MM/01).
*/

SELECT * 
FROM your_table 
WHERE DATEDIFF(YEAR, CONVERT(DATE, start_period + '/01', 111), GETDATE()) = 1;

/*
Solution 2: Using Direct Date Comparison
Alternatively, you can calculate the cutoff date manually:

*/

SELECT * 
FROM your_table 
WHERE CONVERT(DATE, start_period + '/01', 111) = DATEADD(YEAR, -1, CONVERT(DATE, FORMAT(GETDATE(), 'yyyy/MM') + '/01', 111));
