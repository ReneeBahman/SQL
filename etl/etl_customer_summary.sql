-- ETL Procedure: Enhanced Banking Model (Customer Loan Summary)
-- Description: Stored procedure version of an ETL pipeline using 5 OLTP tables (Sybase SQL compatible)
-- Author: Renee Bahman (with ChatGPT)
-- Use Case: Sybase-ready version for Luminor role (SQL/ETL demonstration)

-- Step 0: DDL for OLTP Source Tables
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'customers') DROP TABLE customers;
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    country VARCHAR(100)
);

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'addresses') DROP TABLE addresses;
CREATE TABLE addresses (
    address_id INT PRIMARY KEY,
    customer_id INT,
    street VARCHAR(100),
    city VARCHAR(100),
    postal_code VARCHAR(20)
);

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'loan_types') DROP TABLE loan_types;
CREATE TABLE loan_types (
    loan_type_id INT PRIMARY KEY,
    type_name VARCHAR(50)
);

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'loans') DROP TABLE loans;
CREATE TABLE loans (
    loan_id INT PRIMARY KEY,
    customer_id INT,
    loan_type_id INT,
    amount DECIMAL(12,2),
    status VARCHAR(20),
    start_date DATE
);

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'payments') DROP TABLE payments;
CREATE TABLE payments (
    payment_id INT PRIMARY KEY,
    loan_id INT,
    amount_paid DECIMAL(12,2),
    payment_date DATE
);

-- Step 0a: Sample Inserts
INSERT INTO customers VALUES
(1, 'Alice', 'Estonia'),
(2, 'Bob', 'Latvia'),
(3, 'Charlie', 'Estonia');

INSERT INTO addresses VALUES
(1, 1, 'Oak St 12', 'Tallinn', '10115'),
(2, 1, 'Birch Ave 7', 'Tartu', '51010'),
(3, 2, 'Maple Rd 22', 'Riga', 'LV-1050'),
(4, 3, 'Pine Blvd 3', 'Pärnu', '80011');

INSERT INTO loan_types VALUES
(1, 'Personal'),
(2, 'Mortgage'),
(3, 'Auto');

INSERT INTO loans VALUES
(101, 1, 1, 5000.00, 'active', '2024-01-15'),
(102, 2, 2, 3000.00, 'closed', '2023-03-12'),
(103, 1, 3, 2500.00, 'defaulted', '2023-08-10'),
(104, 3, 1, 6000.00, 'active', '2025-06-01');

INSERT INTO payments VALUES
(1, 101, 1000.00, '2024-02-10'),
(2, 101, 1500.00, '2024-03-15'),
(3, 102, 3000.00, '2023-04-01'),
(4, 103, 500.00, '2023-09-01'),
(5, 104, 2000.00, '2025-06-30');

-- Step 1: Reporting Table
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'rpt_customer_loan_summary') DROP TABLE rpt_customer_loan_summary;
CREATE TABLE rpt_customer_loan_summary (
    customer_id INT,
    customer_name VARCHAR(100),
    country VARCHAR(100),
    total_loans INT,
    total_paid DECIMAL(12,2),
    active_loans INT,
    defaulted_loans INT,
    address_count INT,
    load_date DATE
);

-- Step 2: ETL Stored Procedure (Sybase T-SQL)
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'etl_customer_summary') DROP PROCEDURE etl_customer_summary;
GO
CREATE PROCEDURE etl_customer_summary
    @run_date DATE
AS
BEGIN
    DECLARE @retry_count INT
    DECLARE @max_retries INT
    DECLARE @success BIT
    DECLARE @retry_delay_seconds VARCHAR(8)

    SELECT @retry_count = 0,
           @max_retries = 3,
           @success = 0,
           @retry_delay_seconds = '00:05:00'

    WHILE @retry_count < @max_retries AND @success = 0
    BEGIN
        BEGIN TRANSACTION
        BEGIN TRY
            DELETE FROM rpt_customer_loan_summary WHERE load_date = @run_date;

            INSERT INTO rpt_customer_loan_summary (
                customer_id, customer_name, country, total_loans,
                total_paid, active_loans, defaulted_loans, address_count, load_date)
            SELECT
                c.customer_id,
                c.customer_name,
                c.country,
                COUNT(DISTINCT l.loan_id),
                ISNULL(SUM(p.amount_paid), 0),
                COUNT(CASE WHEN l.status = 'active' THEN 1 END),
                COUNT(CASE WHEN l.status = 'defaulted' THEN 1 END),
                COUNT(DISTINCT a.address_id),
                @run_date
            FROM customers c
            LEFT JOIN loans l ON c.customer_id = l.customer_id AND l.start_date <= @run_date
            LEFT JOIN payments p ON l.loan_id = p.loan_id AND p.payment_date <= @run_date
            LEFT JOIN addresses a ON c.customer_id = a.customer_id
            GROUP BY c.customer_id, c.customer_name, c.country;

            COMMIT TRANSACTION
            SELECT @success = 1
        END TRY
        BEGIN CATCH
            ROLLBACK TRANSACTION
            SELECT @retry_count = @retry_count + 1
            PRINT 'Retry ' + CAST(@retry_count AS VARCHAR) + ' failed: ' + ERROR_MESSAGE()
            IF @retry_count < @max_retries
                WAITFOR DELAY @retry_delay_seconds
        END CATCH
    END

    IF @success = 0
        RAISERROR('ETL failed after 3 retries on %s', 16, 1, @run_date)
END
GO

-- Step 3: Sample Execution
-- EXEC etl_customer_summary '2025-07-28';

-- Step 4: Optional View
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'vw_customer_loan_summary') DROP VIEW vw_customer_loan_summary;
GO
CREATE VIEW vw_customer_loan_summary AS
SELECT 
    customer_name,
    country,
    total_loans,
    total_paid,
    active_loans,
    defaulted_loans,
    address_count,
    load_date
FROM rpt_customer_loan_summary
ORDER BY total_paid DESC;
GO
