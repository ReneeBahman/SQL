CREATE PROCEDURE alias_schema.spr_proc_anonymous(@param_start_period VARCHAR(7) DEFAULT 'mm-3', @param_end_period VARCHAR(7) DEFAULT 'mm0')
BEGIN 
 SET @param_start_period = alias_fn.fn_convert_period(@param_start_period);
 SET @param_end_period = alias_fn.fn_convert_period(@param_end_period);

SELECT 
       COUNT(*) AS id, 
       call_data.start_period,
       call_data.start_time,
       call_data.duration,
       CASE
         WHEN call_data.target_number LIKE '+372%' THEN SUBSTRING(call_data.target_number, 5)
         WHEN call_data.target_number LIKE '372%' THEN SUBSTRING(call_data.target_number, 4)
         ELSE call_data.target_number
       END AS target_number,
       call_data.call_direction, 
       call_data.agent_ref,
       call_data.client_ref, 
       call_data.subscriber_ref, 
       call_data.client_number,
       call_data.main_client_ref,
       call_data.client_identifier, 
       CASE 
        WHEN call_data.client_identifier LIKE 'crmA%' AND call_data.client_identifier != 'crmA0' THEN 'CRM_A'
        WHEN call_data.client_identifier LIKE 'crmB%' THEN 'CRM_B'
        WHEN call_data.client_identifier = 'crmA0' AND call_data.main_client_ref != 0 THEN 'CRM_B'
        ELSE 'OTHER' 
       END AS crm_category, 
       staff.fullname, 
       staff.level_1, 
       staff.level_3
INTO #temp_calls
FROM alias_system.call_records call_data
JOIN alias_system.agent_info agent ON (call_data.agent_ref = agent.agent_ref AND DATE(call_data.start_time) BETWEEN DATE(agent.start_time) AND DATE(ISNULL(agent.end_time, '9999-01-01')))  
JOIN alias_system.staff_info staff ON (agent.comment_field = staff.username AND DATE(call_data.start_time) BETWEEN DATE(staff.valid_from) AND DATE(staff.valid_to))
WHERE DATE_FORMAT(call_data.start_time, 'yyyy/mm') BETWEEN @param_start_period AND @param_end_period  
AND (call_data.client_number != 0 OR call_data.main_client_ref != 0)
ORDER BY start_period;

-- Contract Data A
SELECT customer_id, service_number, contract_index, product_id, product_name, start_date, end_date, contract_type 
INTO #contracts_A 
FROM alias_data.contract_info contract
JOIN alias_data.client_info client ON contract.customer_id = client.client_number 
WHERE customer_id IN (SELECT client_number FROM #temp_calls WHERE crm_category = 'CRM_A') 
AND (contract_type IN (7, 1) OR product_id IN (SELECT index FROM alias_data.product WHERE product_group IN ('Group_A', 'Group_B', 'Group_C')))
AND product_id NOT IN (9999) -- Exclude specific products
AND client.business_type = 'individual'
AND (DATE_FORMAT(end_date, 'yyyy/mm') BETWEEN @param_start_period AND @param_end_period OR end_date IS NULL)
AND start_date <= GETDATE();

-- Contract Data B
SELECT CAST(client.ref_number AS INT) AS customer_id, contract.contract_number AS service_number, contract.contract_id AS contract_index, contract.product_code AS product_id, contract.product_name, contract.start_date, contract.end_date, 99 AS contract_type
INTO #contracts_B
FROM alias_system.client_data client
JOIN alias_system.contract_details contract ON contract.client_id = client.id 
WHERE client.id IN (SELECT main_client_ref FROM #temp_calls WHERE crm_category = 'CRM_B')
AND client.type = 'individual'
AND (DATE_FORMAT(contract.end_date, 'yyyy/mm') BETWEEN @param_start_period AND @param_end_period OR contract.end_date IS NULL) 
AND contract.is_active = 1 
AND DATE(contract.start_date) <= GETDATE()
AND DATE(contract.start_date) IS NOT NULL;

SELECT temp_calls.*, 
       contract_A.contract_index, 
       contract_A.service_number, 
       contract_A.contract_type, 
       contract_A.start_date, 
       contract_A.end_date,
       CONVERT(SMALLINT, 0) AS active_home_services,
       CONVERT(SMALLINT, 0) AS home_contract_expiry_30d,
       CONVERT(SMALLINT, 0) AS home_contract_expiry_60d,
       CONVERT(SMALLINT, 0) AS active_phone_services,
       CONVERT(SMALLINT, 0) AS phone_contract_expiry_30d,
       CONVERT(SMALLINT, 0) AS phone_contract_expiry_60d
INTO #merged_contracts
FROM #temp_calls temp_calls
JOIN #contracts_A contract_A ON temp_calls.client_number = contract_A.customer_id AND DATE(temp_calls.start_time) BETWEEN contract_A.start_date AND ISNULL(contract_A.end_date, '2099-12-31')
AND temp_calls.crm_category = 'CRM_A'
UNION 
SELECT temp_calls.*, 
       contract_B.contract_index, 
       contract_B.service_number, 
       contract_B.contract_type,
       contract_B.start_date, 
       contract_B.end_date, 
       CONVERT(SMALLINT, 0) AS active_home_services,
       CONVERT(SMALLINT, 0) AS home_contract_expiry_30d,
       CONVERT(SMALLINT, 0) AS home_contract_expiry_60d,
       CONVERT(SMALLINT, 0) AS active_phone_services,
       CONVERT(SMALLINT, 0) AS phone_contract_expiry_30d,
       CONVERT(SMALLINT, 0) AS phone_contract_expiry_60d
FROM #temp_calls temp_calls
JOIN #contracts_B contract_B ON temp_calls.client_number = contract_B.customer_id AND DATE(temp_calls.start_time) BETWEEN contract_B.start_date AND ISNULL(contract_B.end_date, '2099-12-31')
AND temp_calls.crm_category = 'CRM_B';

UPDATE #merged_contracts 
SET active_home_services = 1 
WHERE contract_type IN (3, 4, 7, 99);

UPDATE #merged_contracts 
SET active_phone_services = 1 
WHERE contract_type IN (1);

UPDATE #merged_contracts 
SET home_contract_expiry_30d = 1 
WHERE active_home_services = 1 
AND ISNULL(end_date, '2099-01-01') <= DATEADD(DAY, 30, start_time);

UPDATE #merged_contracts 
SET home_contract_expiry_60d = 1 
WHERE home_contract_expiry_30d = 1 
AND ISNULL(end_date, '2099-01-01') BETWEEN DATEADD(DAY, 31, start_time) AND DATEADD(DAY, 60, start_time);

UPDATE #merged_contracts 
SET phone_contract_expiry_30d = 1 
WHERE active_phone_services = 1 
AND ISNULL(end_date, '2099-01-01') <= DATEADD(DAY, 30, start_time);

UPDATE #merged_contracts 
SET phone_contract_expiry_60d = 1 
WHERE phone_contract_expiry_30d = 1 
AND ISNULL(end_date, '2099-01-01') BETWEEN DATEADD(DAY, 31, start_time) AND DATEADD(DAY, 60, start_time);

DELETE FROM #merged_contracts 
WHERE (active_phone_services = 0 AND active_home_services = 0);

SELECT * FROM #merged_contracts;

END
GO