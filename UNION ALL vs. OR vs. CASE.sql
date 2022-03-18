SET STATISTICS IO, TIME ON;

USE RedTail;

-- ISNULL:
;WITH x AS (
	SELECT TOP (100) PolicyNumber
	FROM dbo.Association
)
SELECT 1
FROM dbo.Association a
INNER JOIN dbo.JourneyEvent je
	ON  CONVERT(bigint, a.IMEI) = je.IMEI
	AND je.EventTimeStamp > a.StartDate
	AND je.EventTimeStamp < ISNULL(a.EndDate, CURRENT_TIMESTAMP)
WHERE a.PolicyNumber IN (SELECT PolicyNumber FROM x)
;

;WITH x AS (
	SELECT TOP (100) PolicyNumber
	FROM dbo.Association
)
SELECT 1
FROM dbo.Association a
INNER JOIN dbo.JourneyEvent je
	ON  a.IMEI = je.IMEI
	AND je.EventTimeStamp > a.StartDate
	AND je.EventTimeStamp < COALESCE(a.EndDate, CURRENT_TIMESTAMP)
WHERE EXISTS (
	SELECT 1
	FROM x
	WHERE a.PolicyNumber = x.PolicyNumber
)
;

-- OR:
;WITH x AS (
	SELECT TOP (100) PolicyNumber
	FROM dbo.Association
)
SELECT 1
FROM dbo.Association a
INNER JOIN dbo.JourneyEvent je
	ON  CONVERT(bigint, a.IMEI) = je.IMEI
	AND je.EventTimeStamp > a.StartDate
	AND (je.EventTimeStamp < a.EndDate OR a.EndDate IS NULL)
WHERE a.PolicyNumber IN (SELECT PolicyNumber FROM x)
;


-- UNION ALL:
CREATE TABLE #Temp (PolicyNumber varchar(20) NOT NULL PRIMARY KEY);
INSERT #Temp (PolicyNumber)
SELECT TOP (100) PolicyNumber
FROM dbo.Association
;

;WITH x AS (
	SELECT TOP (100) PolicyNumber
	FROM dbo.Association
)
SELECT 1
FROM dbo.Association a
INNER JOIN dbo.JourneyEvent je
	ON  CONVERT(bigint, a.IMEI) = je.IMEI
	AND je.EventTimeStamp > a.StartDate
	AND je.EventTimeStamp < a.EndDate
WHERE a.PolicyNumber IN (SELECT PolicyNumber FROM #Temp)
UNION ALL
SELECT 1
FROM dbo.Association a
INNER JOIN dbo.JourneyEvent je
	ON  CONVERT(bigint, a.IMEI) = je.IMEI
	AND je.EventTimeStamp > a.StartDate
	AND a.EndDate IS NULL
WHERE a.PolicyNumber IN (SELECT PolicyNumber FROM #Temp)
;

/*
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
SQL Server parse and compile time: 
   CPU time = 47 ms, elapsed time = 51 ms.

-- ISNULL:
(2274083 rows affected)
Table 'JourneyEvent'. Scan count 91, logical reads 3593, physical reads 154, read-ahead reads 3215, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Workfile'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Association'. Scan count 2, logical reads 4711, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

(1 row affected)

 SQL Server Execution Times:
   CPU time = 703 ms,  elapsed time = 14167 ms.

-- OR:
(2274083 rows affected)
Table 'JourneyEvent'. Scan count 104, logical reads 19559, physical reads 131, read-ahead reads 15779, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Workfile'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Association'. Scan count 2, logical reads 4711, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

(1 row affected)

 SQL Server Execution Times:
   CPU time = 2672 ms,  elapsed time = 14829 ms.


-- UNION ALL:
(2274083 rows affected)
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Workfile'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Association'. Scan count 4, logical reads 9422, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'JourneyEvent'. Scan count 91, logical reads 3593, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

(1 row affected)

 SQL Server Execution Times:
   CPU time = 984 ms,  elapsed time = 14952 ms.
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.

Completion time: 2020-12-15T15:34:28.4606058+00:00


-- UNION ALL w/ TEMP TABLE:
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 5 ms.
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.
Table '#Temp_______________________________________________________________________________________________________________0000001D2C0A'. Scan count 0, logical reads 201, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Association'. Scan count 1, logical reads 6, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

(100 rows affected)

(1 row affected)

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 1 ms.
SQL Server parse and compile time: 
   CPU time = 12 ms, elapsed time = 12 ms.

(2274083 rows affected)
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Workfile'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Association'. Scan count 2, logical reads 9410, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table '#Temp_______________________________________________________________________________________________________________0000001D2C0A'. Scan count 2, logical reads 4, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'JourneyEvent'. Scan count 91, logical reads 3593, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

(1 row affected)

 SQL Server Execution Times:
   CPU time = 828 ms,  elapsed time = 14152 ms.
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.

Completion time: 2020-12-15T15:44:08.5396462+00:00

*/