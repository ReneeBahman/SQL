📊 ETL Procedure: Customer Loan Summary
This repository contains a Sybase SQL–compatible end-to-end ETL pipeline designed to demonstrate:

OLTP data modeling with 5 normalized source tables

A robust ETL procedure (etl_customer_summary) with retry logic and transactional control

A reporting output table (rpt_customer_loan_summary)

A SQL view (vw_customer_loan_summary) for analytics tools like Tableau or Power BI

💼 Originally designed as part of an ETL support demonstration project. Suitable for Sybase/SQL Server environments in banking, telecom, or enterprise data teams.


🏗️ Data Model (OLTP)
The ETL is built on a sample banking data model including the following tables:

customers: Basic customer profile

addresses: Customer address records (1:N relationship)

loan_types: Categorical definitions for loan types

loans: All loan records including status and date

payments: Payment history per loan

📎 See [data_model_for_etl.txt](./data_model_for_etl.txt) for column-level mock data.


⚙️ What the Procedure Does
sql
Copy
Edit
EXEC etl_customer_summary '2025-07-28';
This procedure:

Deletes any previous summary records for that load_date

Aggregates key metrics: total loans, total paid, active/defaulted loans, address count

Inserts transformed results into the reporting table

Retries automatically on failure (up to 3 times, with a 5-minute delay between attempts)

📈 Output View
vw_customer_loan_summary provides a cleaned interface for BI reporting:

sql
Copy
Edit
SELECT * FROM vw_customer_loan_summary WHERE load_date = CURRENT_DATE;
📁 Files in This Repo
File	Purpose
etl_customer_summary.sql	Full procedure and ETL logic with DDL + data
data_model_for_etl.txt Sample data model & mock records
README.md	This documentation
