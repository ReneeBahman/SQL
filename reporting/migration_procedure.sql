CREATE PROCEDURE alias_schema.spr_proc_anonymous()
BEGIN 

DECLARE @ref_date DATETIME; 
SET @ref_date = '2025-01-01'; 

-- Temporary base table
SELECT src.*,
       CONVERT(DATE, NULL) AS end_date, 
       CONVERT(VARCHAR(32), NULL) AS service_name,
       CONVERT(INT, NULL) AS index_col,
       CONVERT(INT, NULL) AS client_id,
       CONVERT(VARCHAR(12), NULL) AS phone_number,
       CONVERT(INT, NULL) AS product_id,
       CONVERT(VARCHAR(30), NULL) AS product_name,
       CONVERT(DATE, NULL) AS start_date, 
       CONVERT(DATE, NULL) AS close_date, 
       CONVERT(SMALLINT, 1) AS total_base,
       CONVERT(SMALLINT, 0) AS contract_terminated,
       CONVERT(SMALLINT, 0) AS migrated,
       CONVERT(SMALLINT, 1) AS unmigrated,
       CONVERT(SMALLINT, 0) AS device_available,
       CONVERT(SMALLINT, 0) AS technician_pending,
       CONVERT(SMALLINT, 0) AS closed_account,
       CONVERT(SMALLINT, 1) AS inactive,
       CONVERT(SMALLINT, 1) AS active_contract,
       1 AS record_count
INTO #temp_table
FROM alias_schema.tbl_migration src
WHERE date_field = '2024-12-20';

-- Contract end date update
UPDATE #temp_table AS t 
SET t.end_date = DATE(c.end_date),
    t.service_name = c.service_name
FROM alias_system.client cl 
JOIN alias_system.contract c ON c.client_id = cl.id 
JOIN alias_system.agreement a ON a.main_contract_id = c.main_contract_id 
WHERE cl.ref_number = CAST(t.ref_number AS VARCHAR)
AND t.main_contract_id = CAST(c.main_contract_id AS VARCHAR)
AND a.contract_number = t.phone_number
AND CAST(c.service_code AS VARCHAR) = t.service_code
AND c.status != 'cancelled'
ORDER BY ISNULL(c.end_date, '2099-01-01') DESC;

-- Contract termination update
UPDATE #temp_table 
SET contract_terminated = 1,
    active_contract = 0 
WHERE ref_number IN (SELECT ref_number FROM #temp_table WHERE end_date IS NOT NULL);

-- Deceased clients update
UPDATE #temp_table AS t 
SET t.contract_terminated = 1,
    t.unmigrated = 0,
    t.active_contract = 0, 
    t.inactive = 0
FROM alias_system.client c 
WHERE c.client_code = t.ssid
AND c.status = 'deceased';

-- Migration data update
UPDATE #temp_table AS t
SET t.index_col = c.index_col,
    t.client_id = c.client_id,
    t.phone_number = c.phone_number,
    t.product_id = c.product_id,
    t.product_name = c.product_name,
    t.start_date = DATE(c.start_date),
    t.close_date = DATE(c.close_date),
    migrated = 1,
    unmigrated = 0
FROM alias_data.client_data cl  
INNER JOIN alias_data.contract_data c
        ON c.client_id = cl.client_number
        AND c.start_date >= @ref_date
        AND (c.close_date >= @ref_date OR c.close_date IS NULL)
        AND c.contract_type = 7
INNER JOIN alias_data.package_data p ON c.product_id = p.package_id
WHERE cl.tax_id = t.ssid
ORDER BY CASE WHEN p.product_group = 'Service Group A' THEN 0 ELSE 1 END, ISNULL(c.close_date, '2099-01-01') DESC;

-- Technician pending update
UPDATE #temp_table 
SET technician_pending = 1,
    inactive = 0
FROM #temp_table AS t 
JOIN alias_data.work_order AS w ON CAST(t.client_id AS VARCHAR) = w.client_number
WHERE planned_date >= @ref_date;

-- Device available update
UPDATE #temp_table
SET device_available = 1,
    technician_pending = 0,
    inactive = 0
FROM #temp_table AS t 
JOIN alias_data.contract_data c ON t.index_col = c.parent_id 
AND c.product_id IN (75, 4039)
AND c.description LIKE '%device%'
AND c.start_date >= @ref_date;

-- Final closure update
UPDATE #temp_table AS t
SET closed_account = 1,
    inactive = 0, 
    device_available = 0, 
    technician_pending = 0
WHERE phone_number IN (SELECT phone_number FROM #temp_table WHERE close_date IS NOT NULL);

SELECT * FROM #temp_table;

END
GO