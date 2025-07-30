-- Create temporary cancellation dataset
SELECT 
    req.id AS reason_id,
    req.session_id AS session_ref,
    req.submitted_at AS submitted_timestamp,
    DATE(req.submitted_at) AS submitted_date,
    DATEFORMAT(req.submitted_at,'yyyy/mm') AS period_label,
    CASE 
        WHEN req.resolved_at IS NULL THEN 'Chain Open' 
        ELSE 'Chain Closed' 
    END AS chain_status,
    reqcon.system_origin AS system_name,
    CONVERT(INT, NULL) AS customer_id,
    CONVERT(VARCHAR(20), NULL) AS national_id,
    CONVERT(VARCHAR(255), NULL) AS plan_name,
    CONVERT(VARCHAR(10), NULL) AS plan_code,
    CONVERT(VARCHAR(255), NULL) AS plan_group,
    CONVERT(VARCHAR(255), NULL) AS plan_type,
    CONVERT(VARCHAR(255), NULL) AS plan_technology,
    CONVERT(VARCHAR(255), NULL) AS plan_category,
    reqcon.contract_key AS contract_id,
    reqcon.subscription_key AS subscription_id,
    CONVERT(DATE, NULL) AS contract_closed,
    CONVERT(VARCHAR(100), NULL) AS contract_status,
    CONVERT(VARCHAR(64), NULL) AS customer_segment,
    CONVERT(VARCHAR(20), NULL) AS language,
    req.created_by AS opened_by,
    CONVERT(VARCHAR(255), NULL) AS opened_by_name,
    CONVERT(VARCHAR(255), NULL) AS channel_name,
    CONVERT(VARCHAR(255), NULL) AS channel_type,
    CONVERT(VARCHAR(255), NULL) AS channel_group,
    DATE(req.submitted_at) AS opened_on,
    req.modified_by AS updated_by,
    CONVERT(VARCHAR(255), NULL) AS updated_by_name,
    CONVERT(VARCHAR(255), NULL) AS update_channel_name,
    CONVERT(VARCHAR(255), NULL) AS update_channel_type,
    CONVERT(VARCHAR(255), NULL) AS update_channel_group,
    DATE(req.modified_at) AS updated_on,
    req.modified_at AS updated_timestamp,
    req.resolved_by AS closed_by,
    CONVERT(VARCHAR(255), NULL) AS closed_by_name,
    CONVERT(VARCHAR(255), NULL) AS close_channel_name,
    CONVERT(VARCHAR(255), NULL) AS close_channel_type,
    CONVERT(VARCHAR(255), NULL) AS close_channel_group,
    DATE(req.resolved_at) AS closed_on,
    CONVERT(VARCHAR(255), NULL) AS final_closer,
    CONVERT(VARCHAR(255), NULL) AS closer_fullname,
    CONVERT(VARCHAR(255), NULL) AS closer_channel_name,
    CONVERT(VARCHAR(255), NULL) AS closer_channel_group,
    CONVERT(VARCHAR(255), NULL) AS closer_channel_type,
    req.resolved_at AS closed_timestamp,
    reqcon.client_id,
    reqcon.system_origin,
    reqcon.contract_key,
    req.resolved_at,
    DATEADD(DD, -1, DATEADD(MM, 1, DATE(DATEFORMAT(DATEADD(MM, 0, req.resolved_at), 'YYYY-MM-01')))) AS followup_check,
    CONVERT(INT, NULL) AS initial_star_contract_id,
    CONVERT(INT, NULL) AS final_star_contract_id,
    CONVERT(INT, NULL) AS initial_epd_contract_id,
    CONVERT(INT, NULL) AS final_epd_contract_id,
    CONVERT(VARCHAR(255), NULL) AS initial_status,
    CONVERT(VARCHAR(255), NULL) AS final_status,
    CONVERT(VARCHAR(255), NULL) AS primary_service,
    CONVERT(INT, NULL) AS is_tv_flag,
    CONVERT(INT, NULL) AS is_net_flag,
    CONVERT(INT, NULL) AS survey_id,
    CONVERT(VARCHAR(255), NULL) AS survey_question,
    CONVERT(VARCHAR(255), NULL) AS cancel_reason,
    CONVERT(VARCHAR(255), NULL) AS cancel_sub_reason,
    CONVERT(VARCHAR(255), NULL) AS cancel_reason_group,
    CONVERT(VARCHAR(255), NULL) AS competitor_name,
    CONVERT(VARCHAR(255), NULL) AS retention_action,
    CONVERT(VARCHAR(255), NULL) AS competitor_offer,
    CONVERT(VARCHAR(255), NULL) AS offer_details
INTO #cancel_data
FROM src_data.cancel_requests req
INNER JOIN src_data.cancel_request_contracts reqcon ON req.id = reqcon.reason_id
WHERE DATEFORMAT(req.submitted_at, 'yyyy/mm') = '2024/12';

-- Update follow-up check date based on resolution
UPDATE #cancel_data
SET followup_check = DATEADD(DAY, 10, closed_timestamp)
WHERE DATEADD(DAY, 10, closed_timestamp) > followup_check;

-- Handle unresolved cancellations
UPDATE #cancel_data
SET followup_check = DATEADD(DAY, -1, DATE(GETDATE()))
WHERE closed_timestamp IS NULL;

-- Initial contract IDs based on system
UPDATE #cancel_data
SET initial_star_contract_id = contract_id
WHERE system_origin = 'legacy';

UPDATE #cancel_data
SET initial_epd_contract_id = contract_id
WHERE system_origin = 'modern';

-- Chain follow-up for legacy to legacy
UPDATE cd
SET final_star_contract_id = hist1.contract_id,
    contract_closed = hist1.ended_at,
    final_closer = hist1.closed_by
FROM #cancel_data cd
JOIN legacy_data.contract_history hist1 ON hist1.chain_id = hist0.chain_id
JOIN legacy_data.contract_history hist0 ON cd.contract_id = hist0.contract_id
WHERE cd.system_origin = 'legacy'
  AND DATE(cd.followup_check) BETWEEN hist1.started_at AND ISNULL(hist1.ended_at, '2099-01-01');

-- Chain follow-up for legacy to modern
UPDATE cd
SET final_epd_contract_id = c1.contract_id,
    contract_closed = c1.ended_at,
    final_closer = c1.closed_by
FROM #cancel_data cd
JOIN legacy_data.contract_history hist1 ON hist1.chain_id = hist0.chain_id
JOIN legacy_data.contract_history hist0 ON cd.contract_id = hist0.contract_id
JOIN src_data.contracts c0 ON hist0.contract_id = c0.previous_contract_id
JOIN src_data.contracts c1 ON c0.chain_id = c1.chain_id
WHERE cd.system_origin = 'legacy'
  AND DATE(cd.followup_check) BETWEEN c1.started_at AND ISNULL(c1.ended_at, '2099-01-01');

-- Chain follow-up for modern to modern
UPDATE cd
SET final_epd_contract_id = c1.contract_id,
    contract_closed = c1.ended_at,
    final_closer = c1.closed_by
FROM #cancel_data cd
JOIN src_data.contracts c1 ON c1.chain_id = c0.chain_id
JOIN src_data.contracts c0 ON cd.contract_id = c0.contract_id
WHERE cd.system_origin = 'modern'
  AND DATE(cd.followup_check) BETWEEN c1.started_at AND ISNULL(c1.ended_at, '2099-01-01');

-- Update service info from products
UPDATE cd
SET primary_service = 
  CASE 
    WHEN pr.type IN ('data_plan', 'mobile_data') THEN 'Internet'
    WHEN pr.type = 'tv_plan' THEN 'TV'
    ELSE 'Unknown'
  END,
  is_tv_flag = CASE WHEN pr.type = 'tv_plan' THEN 1 ELSE 0 END,
  is_net_flag = CASE WHEN pr.type IN ('data_plan', 'mobile_data') THEN 1 ELSE 0 END
FROM #cancel_data cd
JOIN src_data.contracts c ON cd.initial_epd_contract_id = c.contract_id
JOIN src_data.products pr ON c.product_id = pr.product_id;

-- Service classification for legacy
UPDATE cd
SET primary_service = CASE
  WHEN sv.has_tv = 1 AND sv.has_net = 1 THEN 'TV+NET'
  WHEN sv.has_tv = 1 THEN 'TV'
  WHEN sv.has_net = 1 THEN 'NET'
  ELSE 'Unknown'
END
FROM #cancel_data cd
JOIN legacy_data.contract_history ch ON cd.initial_star_contract_id = ch.contract_id
JOIN legacy_data.services sv ON ch.service_id = sv.service_id;

-- Update client info
UPDATE #cancel_data
SET customer_id = client_id
WHERE system_origin = 'modern';

UPDATE cd
SET customer_segment = cust.segment,
    national_id = cust.national_id,
    language = cust.language
FROM #cancel_data cd
JOIN dim_data.clients cust ON cd.client_id = cust.client_key
WHERE cd.system_origin = 'modern';

UPDATE cd
SET customer_segment = cust.type,
    customer_id = cust.account_number,
    national_id = cust.tax_id,
    language = cust.preferred_language
FROM #cancel_data cd
JOIN legacy_data.customers cust ON cd.client_id = cust.client_id
WHERE cd.system_origin = 'legacy';
