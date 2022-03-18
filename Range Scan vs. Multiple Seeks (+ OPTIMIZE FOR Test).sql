
SET STATISTICS IO, TIME ON;

DROP TABLE IF EXISTS #YEET;

SELECT DISTINCT ExternalContractNumber
INTO #YEET
FROM Vodafone.dbo.Trip
WHERE ExternalContractNumber >= N'0'
	AND ExternalContractNumber < N'P6'
;

SELECT *
FROM #YEET
;

ALTER TABLE #YEET ALTER COLUMN ExternalContractNumber nvarchar(20) NOT NULL;
ALTER TABLE #YEET ADD PRIMARY KEY (ExternalContractNumber);

DROP TABLE IF EXISTS #YEET2, #YEET3, #YEET4;

-- Fewer logical reads, though higher % cost, sometimes slower due to CXPACKET waits:
SELECT YEET = 1
INTO #YEET2
FROM Vodafone.dbo.Trip
WHERE ExternalContractNumber >= N'0'
	AND ExternalContractNumber < N'P61'
--OPTION (MAXDOP 1)
;

SELECT YEET = 1
INTO #YEET2x
FROM Vodafone.dbo.Trip
WHERE ExternalContractNumber >= N'0'
	AND ExternalContractNumber < N'P61'
OPTION (MAXDOP 1)
;


SELECT YEET = 1
INTO #YEET3
FROM Vodafone.dbo.Trip
WHERE ExternalContractNumber IN (SELECT ExternalContractNumber FROM #YEET)
OPTION (USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'))
;

DBCC SHOW_STATISTICS('Vodafone.dbo.Trip', TripPlateNumberTimeStamp);

SELECT YEET = 1
INTO #YEET4
FROM Vodafone.dbo.Trip
WHERE ExternalContractNumber = N'ADMTEST01-2W'
UNION ALL
SELECT YEET = 1
FROM Vodafone.dbo.Trip
WHERE ExternalContractNumber = N'ADMTEST01-3W'
;



-- Are memory grants affected by these?
DECLARE @PolicyNumber varchar(20) = 'P65042770%';

SELECT *
FROM CMTSERV.dbo.AppAssociation
WHERE Account_ID LIKE @PolicyNumber
;

SELECT *
FROM CMTSERV.dbo.AppAssociation
WHERE Account_ID LIKE @PolicyNumber
OPTION (OPTIMIZE FOR (@PolicyNumber = 'P63744869'))
;
