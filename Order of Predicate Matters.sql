
--SET STATISTICS IO, TIME ON;

--SELECT *
--FROM RedTail.dbo.JourneyEvent je
--WHERE EXISTS (
--	SELECT 1
--	FROM RedTail.dbo.Association a
--	WHERE je.IMEI = CONVERT(bigint, a.IMEI)
--		AND je.EventTimeStamp > a.StartDate
--		AND je.EventTimeStamp < ISNULL(a.EndDate, CURRENT_TIMESTAMP)
--		AND a.PolicyNumber = 'ADAPT5349905001001'
--)
--OPTION (LOOP JOIN)
--;

--SELECT je.*
--FROM RedTail.dbo.JourneyEvent je
--INNER JOIN RedTail.dbo.Association a
--	ON  je.IMEI = CONVERT(bigint, a.IMEI)
--	AND je.EventTimeStamp > a.StartDate
--	AND je.EventTimeStamp < ISNULL(a.EndDate, CURRENT_TIMESTAMP)
--	AND a.PolicyNumber = 'ADAPT5349905001001'
--;

--SELECT TOP 1 *
--FROM RedTail.dbo.Association
--;

-- The order of predicate changes performance between this query and the next!
SELECT PolicyNumber
--INTO #T1
FROM RedTail.dbo.Association a
WHERE NOT EXISTS (
	SELECT 1
	FROM RedTail.dbo.JourneyEvent je2
	WHERE CONVERT(bigint, a.IMEI) = je2.IMEI
		AND je2.EventTimeStamp > a.StartDate
		AND a.EndDate IS NULL
		AND je2.EventTimeStamp >= '20201225'
		AND je2.EventTimeStamp <  '20201226'
)
	AND	NOT EXISTS (
		SELECT 1
		FROM RedTail.dbo.JourneyEvent je1
		WHERE CONVERT(bigint, a.IMEI) = je1.IMEI
			AND je1.EventTimeStamp > a.StartDate
			AND je1.EventTimeStamp < a.EndDate
			AND je1.EventTimeStamp >= '20201225'
			AND je1.EventTimeStamp <  '20201226'
	)
	AND StartDate <= '20201225'
	AND (
			EndDate > '20201225'
		OR	EndDate IS NULL
	)
	AND PolicyNumber LIKE 'P%'
GROUP BY PolicyNumber
;








SELECT PolicyNumber
--INTO #T1
FROM RedTail.dbo.Association a
WHERE NOT EXISTS (
	SELECT 1
	FROM RedTail.dbo.JourneyEvent je1
	WHERE CONVERT(bigint, a.IMEI) = je1.IMEI
		AND je1.EventTimeStamp > a.StartDate
		AND je1.EventTimeStamp < a.EndDate
		AND je1.EventTimeStamp >= '20201225'
		AND je1.EventTimeStamp <  '20201226'
)
	AND NOT EXISTS (
		SELECT 1
		FROM RedTail.dbo.JourneyEvent je2
		WHERE CONVERT(bigint, a.IMEI) = je2.IMEI
			AND je2.EventTimeStamp > a.StartDate
			AND a.EndDate IS NULL
			AND je2.EventTimeStamp >= '20201225'
			AND je2.EventTimeStamp <  '20201226'
	)
	AND StartDate <= '20201225'
	AND (
			EndDate > '20201225'
		OR	EndDate IS NULL
	)
	AND PolicyNumber LIKE 'P%'
GROUP BY PolicyNumber
;

;WITH x AS (
	SELECT PolicyNumber
	FROM RedTail.dbo.Association
	WHERE PolicyNumber LIKE 'P%'
		AND StartDate <= '20201225'
		AND (
				EndDate > '20201225'
			OR	EndDate IS NULL
		)
)
SELECT PolicyNumber
FROM x
EXCEPT
SELECT a.PolicyNumber
FROM RedTail.dbo.Association a
INNER JOIN RedTail.dbo.JourneyEvent je
	ON  CONVERT(bigint, a.IMEI) = je.IMEI
	AND je.EventTimeStamp > a.StartDate
	AND (
			je.EventTimeStamp < a.EndDate
		OR  a.EndDate IS NULL
	)
WHERE je.EventTimeStamp	>= '20201225'
	AND je.EventTimeStamp < '20201226'
	AND a.StartDate <= '20201225'
	AND (
			a.EndDate > '20201225'
		OR	a.EndDate IS NULL
	)
;

;WITH x AS (
	SELECT PolicyNumber
	FROM RedTail.dbo.Association
	WHERE PolicyNumber LIKE 'P%'
		AND StartDate <= CONVERT(date, '20201225')
		AND (
				EndDate > CONVERT(date, '20201225')
			OR	EndDate IS NULL
		)
)
SELECT PolicyNumber
FROM x
EXCEPT
SELECT a.PolicyNumber
FROM RedTail.dbo.Association a
INNER JOIN RedTail.dbo.JourneyEvent je
	ON  CONVERT(bigint, a.IMEI) = je.IMEI
	AND je.EventTimeStamp > a.StartDate
	AND (
			je.EventTimeStamp < a.EndDate
		OR  a.EndDate IS NULL
	)
WHERE je.EventTimeStamp	>= CONVERT(datetime, '20201225')
	AND je.EventTimeStamp < CONVERT(datetime, '20201226')
	AND a.StartDate <= CONVERT(date, '20201225')
	AND (
			a.EndDate > CONVERT(date, '20201225')
		OR	a.EndDate IS NULL
	)
;


SELECT PolicyNumber
--INTO #T1
FROM RedTail.dbo.Association a
WHERE NOT EXISTS (
	SELECT 1
	FROM RedTail.dbo.JourneyEvent je2
	WHERE CONVERT(bigint, a.IMEI) = je2.IMEI
		AND je2.EventTimeStamp > a.StartDate
		AND a.EndDate IS NULL
		AND je2.EventTimeStamp >= '20201225'
		AND je2.EventTimeStamp <  '20201226'
)
	AND	NOT EXISTS (
		SELECT 1
		FROM RedTail.dbo.JourneyEvent je1
		WHERE CONVERT(bigint, a.IMEI) = je1.IMEI
			AND je1.EventTimeStamp > a.StartDate
			AND je1.EventTimeStamp < a.EndDate
			AND je1.EventTimeStamp >= '20201225'
			AND je1.EventTimeStamp <  '20201226'
	)
	AND StartDate <= '20201225'
	AND (
			EndDate > '20201225'
		OR	EndDate IS NULL
	)
	AND PolicyNumber LIKE 'P%'
GROUP BY PolicyNumber
OPTION (USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'))
;


SELECT PolicyNumber
INTO #T1
FROM RedTail.dbo.Association a
WHERE NOT EXISTS (
	SELECT 1
	FROM RedTail.dbo.JourneyEvent je2
	WHERE CONVERT(bigint, a.IMEI) = je2.IMEI
		AND je2.EventTimeStamp > a.StartDate
		AND a.EndDate IS NULL
		AND je2.EventTimeStamp >= '20201225'
		AND je2.EventTimeStamp <  '20201226'
)
	AND StartDate <= '20201225'
	AND EndDate IS NULL
	AND PolicyNumber LIKE 'P%'
GROUP BY PolicyNumber
UNION ALL
SELECT PolicyNumber
--INTO #T1
FROM RedTail.dbo.Association a
WHERE NOT EXISTS (
	SELECT 1
	FROM RedTail.dbo.JourneyEvent je1
	WHERE CONVERT(bigint, a.IMEI) = je1.IMEI
		AND je1.EventTimeStamp > a.StartDate
		AND je1.EventTimeStamp < a.EndDate
		AND je1.EventTimeStamp >= '20201225'
		AND je1.EventTimeStamp <  '20201226'
)
	AND StartDate <= '20201225'
	AND EndDate   >  '20201225'
	AND PolicyNumber LIKE 'P%'
GROUP BY PolicyNumber
;

SELECT PolicyNumber
INTO #T2
FROM RedTail.dbo.Association a
WHERE NOT EXISTS (
	SELECT 1
	FROM RedTail.dbo.JourneyEvent je2
	WHERE CONVERT(bigint, a.IMEI) = je2.IMEI
		AND je2.EventTimeStamp > a.StartDate
		AND a.EndDate IS NULL
		AND je2.EventTimeStamp >= '20201225'
		AND je2.EventTimeStamp <  '20201226'
)
	AND StartDate <= '20201225'
	AND EndDate IS NULL
	AND PolicyNumber LIKE 'P%'
UNION
SELECT PolicyNumber
FROM RedTail.dbo.Association a
WHERE NOT EXISTS (
	SELECT 1
	FROM RedTail.dbo.JourneyEvent je1
	WHERE CONVERT(bigint, a.IMEI) = je1.IMEI
		AND je1.EventTimeStamp > a.StartDate
		AND je1.EventTimeStamp < a.EndDate
		AND je1.EventTimeStamp >= '20201225'
		AND je1.EventTimeStamp <  '20201226'
)
	AND StartDate <= '20201225'
	AND EndDate   >  '20201225'
	AND PolicyNumber LIKE 'P%'
;


-- Slow!
SELECT a.PolicyNumber
FROM RedTail.dbo.Association a
INNER JOIN RedTail.dbo.JourneyEvent je
	ON  CONVERT(bigint, a.IMEI) = je.IMEI
	AND je.EventTimeStamp > a.StartDate
	AND je.EventTimeStamp < ISNULL(a.EndDate, CURRENT_TIMESTAMP)
WHERE a.StartDate <= '20201225'
	AND (
			a.EndDate > '20201225'
		OR	a.EndDate IS NULL
	)
	AND a.PolicyNumber LIKE 'P%'
GROUP BY PolicyNumber
HAVING MAX(CASE WHEN je.EventTimeStamp >= '20201225' AND je.EventTimeStamp < '20201226' THEN 1 ELSE 0 END) = 0
;

-- Close!
SELECT PolicyNumber
--INTO #T2
FROM RedTail.dbo.Association a
WHERE NOT EXISTS (
	SELECT 1
	FROM RedTail.dbo.JourneyEvent je2
	WHERE CONVERT(bigint, a.IMEI) = je2.IMEI
		AND je2.EventTimeStamp > a.StartDate
		AND (je2.EventTimeStamp < a.EndDate OR a.EndDate IS NULL)
		AND je2.EventTimeStamp >= '20201225'
		AND je2.EventTimeStamp <  '20201226'
)
	AND StartDate <= '20201225'
	AND (
			EndDate > '20201225'
		OR	EndDate IS NULL
	)
	AND PolicyNumber LIKE 'P%'
GROUP BY PolicyNumber
;


SELECT PolicyNumber
INTO #T2
FROM RedTail.dbo.Association a
WHERE NOT EXISTS (
	SELECT 1
	FROM RedTail.dbo.JourneyEvent je2
	WHERE CONVERT(bigint, a.IMEI) = je2.IMEI
		AND je2.EventTimeStamp > a.StartDate
		AND je2.EventTimeStamp < ISNULL(a.EndDate, CURRENT_TIMESTAMP)
		AND je2.EventTimeStamp >= '20201225'
		AND je2.EventTimeStamp <  '20201226'
)
	AND StartDate <= '20201225'
	AND (
			EndDate > '20201225'
		OR	EndDate IS NULL
	)
	AND PolicyNumber LIKE 'P%'
GROUP BY PolicyNumber
;

SELECT *
FROM #T1
GROUP BY PolicyNumber
HAVING COUNT(*) > 1


SELECT *
FROM #T2;

SELECT *
FROM #T1
WHERE NOT EXISTS (
	SELECT 1
	FROM #T2
	WHERE #T1.PolicyNumber = #T2.PolicyNumber
)
;

SELECT *
FROM RedTail.dbo.Association
WHERE PolicyNumber = 'P67555394-1'
;


SELECT *
FROM RedTail.dbo.Association a
INNER JOIN RedTail.dbo.JourneyEvent je2
	ON  CONVERT(bigint, a.IMEI) = je2.IMEI
	AND je2.EventTimeStamp > a.StartDate
	AND je2.EventTimeStamp < ISNULL(a.EndDate, CURRENT_TIMESTAMP)
WHERE a.PolicyNumber = 'P67555394-1'
ORDER BY je2.EventTimeStamp
;

DROP TABLE #T1, #T2;