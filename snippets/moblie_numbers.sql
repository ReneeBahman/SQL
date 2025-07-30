SELECT 
    viitenr, 
    CASE 
        WHEN contact_phone LIKE '+372%' THEN SUBSTR(contact_phone, 5)
        WHEN contact_phone LIKE '372%' THEN SUBSTR(contact_phone, 4)
        ELSE contact_phone 
    END AS SMS
FROM #baas 
WHERE 1=1
    AND aktiveerimata = 1 
    AND viitenr NOT IN ('1111451', '1250189', '2183226', '2435194', '2918844', 
                        '4846723', '7922929', '8831860', '9167436', '9772737', 
                        '4846723', '7553990')
    AND aindex IS NOT NULL 
    AND contact_phone IS NOT NULL 
    AND keel = 'eesti'
    AND contact_phone LIKE '5%';
