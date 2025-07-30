SELECT c.ssid as Social_sec_nr, c.cust_number, cs.contract_id,  cs.serv_id as service_code, cs.service_name, cs.packet, 'Main_base' as CRM, c.language as cust_language, 
  CASE
          WHEN SUBSTRING(ssid,1,1) in ('3','5') THEN 'man'
          WHEN SUBSTRING(ssid,1,1) in ('4','6') THEN 'woman'
          ELSE 'undefined'

      END as sex,
CASE 
          WHEN SUBSTRING(ssid,1,1) in ('3','4') THEN '19' + SUBSTRING(ssid,2,2) 
          WHEN SUBSTRING(ssid,1,1) in ('4','6') THEN '20' + SUBSTRING(ssid,2,2) 
          ELSE 'undefined'

      END as 'birthyear', 
CAST(year(GETDATE()) as INT) as 'year'

INTO  #MBF

FROM sfor.Customer_Services as cs
JOIN sfor.customer as c on (s.id = cs.cust_id and c.segment in ('private', 'business') )
WHERE c.end_dt is null 
and cs.service_code in (2453, 2463, 3379) 
; 

SELECT *, CAST(CASE
      WHEN  birthyear = 'undefined' THEN NULL
      ELSE  birthyear
  END as INTEGER) as b_year
INTO #MFB
FROM #MFB1
; 

SELECT ssid, cust_number, contract_id, service_code, service_name, packet, crm, cust_language, sex, 
    CASE 
      WHEN year - b_year BETWEEN 0 and 20 THEN 'up to 20'
      WHEN year - b_year BETWEEN 21 and 40 THEN '21 to 40'
      WHEN year - b_year BETWEEN 41 and 60 THEN '41 to 60'
      WHEN year - b_year >= 61 THEN '60 +'
  END as age_group

FROM #MFB
; 