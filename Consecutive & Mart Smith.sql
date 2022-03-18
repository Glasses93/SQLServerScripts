
-- Martin Smith:

SET STATISTICS IO, TIME ON;

SELECT IMEI
FROM RedTail.dbo.Association
WHERE IMEI IS NOT NULL
GROUP BY IMEI
HAVING MAX(CASE WHEN YEAR(SentDate) != 2016 THEN 1 ELSE 0 END) = 0
;


SELECT IMEI
FROM RedTail.dbo.Association a
LEFT JOIN dbo.SJ_BatchModeEnabler bme
	ON 1 = 0
WHERE IMEI IS NOT NULL
GROUP BY IMEI
HAVING MAX(CASE WHEN YEAR(SentDate) != 2016 THEN 1 ELSE 0 END) = 0
;


SELECT CONVERT(varchar(200), IMEI)
FROM RedTail.dbo.Association a
LEFT JOIN dbo.SJ_BatchModeEnabler bme
	ON 1 = 0
WHERE IMEI IS NOT NULL
GROUP BY CONVERT(varchar(200), IMEI)
HAVING MAX(CASE WHEN YEAR(SentDate) != 2016 THEN 1 ELSE 0 END) = 0
;

SELECT DISTINCT IMEI
FROM RedTail.dbo.Association a1
WHERE IMEI IS NOT NULL
	AND NOT EXISTS (
		SELECT 1
		FROM RedTail.dbo.Association a2
		WHERE a1.IMEI = a2.IMEI
			AND YEAR(a2.SentDate) != 2016
	)
;

CREATE TABLE #Temp (ItemID integer NOT NULL, OrderDate datetime2(0) NOT NULL, CONSTRAINT PK PRIMARY KEY CLUSTERED (ItemID ASC, OrderDate ASC));

INSERT #Temp WITH (TABLOCK)
SELECT 10, DATEADD(MINUTE, n, '20150101')
FROM dbo.Numbers
;

SELECT *
FROM #Temp
ORDER BY ItemID, OrderDate
;

SET STATISTICS IO, TIME ON;

SELECT ItemID
FROM #Temp
GROUP BY ItemID
HAVING MAX(CASE WHEN YEAR(OrderDate) = 2016 THEN 1 ELSE 0 END) = 0
;

SELECT DISTINCT ItemID
FROM #Temp a1
WHERE NOT EXISTS (
	SELECT 1
	FROM #Temp a2
	WHERE a1.ItemID = a2.ItemID
		AND YEAR(a2.OrderDate) = 2016
)
;

SELECT DISTINCT ItemID
FROM #Temp a1
WHERE NOT EXISTS (
	SELECT 1
	FROM #Temp a2
	WHERE a1.ItemID = a2.ItemID
		AND a2.OrderDate >= '20160101'
		AND a2.OrderDate <  '20170101'
)
;

ALTER TABLE #Temp ADD CONSTRAINT PK PRIMARY KEY CLUSTERED (OrderDate, ItemID);


-- Islands:

SELECT V.N, ID = IDENTITY(INTEGER, 1, 1)
INTO #LELO
FROM (
	VALUES
		 (1)
		,(2)
		,(1)
		,(1)
		,(1)
		,(3)
		,(3)
		,(4)
		,(3)
		,(3)
) V(N)
;

SELECT *
FROM #LELO
ORDER BY ID
;

SELECT *, ROW_NUMBER() OVER (ORDER BY ID), RN = ID - ROW_NUMBER() OVER (ORDER BY ID)
FROM #LELO
WHERE N = 1
ORDER BY ID
;
