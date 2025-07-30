WITH LatestContracts AS (
    SELECT
        ContractID,
        CustomerID,
        ContractOpened,
        ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY ContractOpened DESC) AS rn
    FROM Contracts
)
SELECT *
FROM LatestContracts
WHERE rn = 1;