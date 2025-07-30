CREATE PROCEDURE anon_schema.spr_Anon_Procedure()
BEGIN

-- Finding sent messages
SELECT 
    msg_id, recipient_number, batch_id, created_at, sent_status, sender_id, sender_name, sender_number, 1 AS count
INTO #sent_messages
FROM anon_schema.message_log
WHERE 1 = 1
AND sender_number = '37256109311';

-- Creating event-to-customer and phone number mapping  
SELECT 
    ev.customer_id,
    cust.tax_id AS customer_tax_id, 
    SUBSTRING(event_description, 1, CHARINDEX(' ', event_description) - 1) AS phone_number, 
    DATE(ev.event_date)
INTO #event_mapping
FROM anon_schema.customer_events AS ev
JOIN anon_schema.customer_info cust 
    ON cust.customer_internal_id = ev.customer_id
WHERE 1 = 1
AND ev.event_type LIKE '%ANON_EVENT%'
AND DATE(ev.event_date) >= '2025-01-01'
AND CHARINDEX(' ', event_description) > 0;

SELECT * FROM #event_mapping;

-- Searching for responses  
SELECT 
    res.response_id,
    CASE
        WHEN res.sender_number LIKE '+372%' THEN SUBSTR(res.sender_number, 5)
        WHEN res.sender_number LIKE '372%' THEN SUBSTR(res.sender_number, 4)
        ELSE res.sender_number 
    END AS respondent_number,
    
    evt.customer_id AS customer_id,
    evt.customer_id AS mapped_customer_id, 
    res.message_content AS response_message,
    res.message_id AS response_message_id,
    res.received_at AS message_received_at,
    1 AS count
FROM 
    anon_schema.message_response res 

LEFT JOIN #event_mapping evt
    ON evt.phone_number = CASE 
                            WHEN res.sender_number LIKE '+372%' THEN SUBSTR(res.sender_number, 5)
                            WHEN res.sender_number LIKE '372%' THEN SUBSTR(res.sender_number, 4)
                            ELSE res.sender_number 
                         END
WHERE 
    1 = 1 
    AND recipient_number = '37256109311' 
    AND DATE(res.received_at) >= '2024-12-01'
ORDER BY message_received_at;

END;
GO
