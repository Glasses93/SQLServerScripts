
SET STATISTICS IO, TIME ON;

;WITH x AS (
	SELECT
		 *
		,Island = JourneyRN - ROW_NUMBER() OVER (PARTITION BY PolicyNumber ORDER BY JourneyRN ASC)
	FROM sandbox.dbo.RTS_ParkingBase WITH (INDEX(4))
	WHERE MilesFromRA > 1
),
y AS (
	SELECT
		 PolicyNumber
		,DaysDiff = DATEDIFF(DAY, MIN(JourneyEndTime), MAX(NextJourneyStartTime))
	FROM x
	GROUP BY
		 PolicyNumber
		,Island
)
SELECT
	 PolicyNumber
	,MaxDaysDiff = MAX(DaysDiff)
--INTO sandbox.dbo.SJ_RTS_DaysAwayFromHome
FROM y
GROUP BY PolicyNumber
;

;WITH x AS (
	SELECT
		 *
		,Island = JourneyRN - ROW_NUMBER() OVER (PARTITION BY PolicyNumber ORDER BY JourneyRN ASC)
	FROM sandbox.dbo.RTS_ParkingBase
	WHERE MilesFromRA > 1
),
y AS (
	SELECT
		 PolicyNumber
		,DaysDiff = DATEDIFF(DAY, MIN(JourneyEndTime), MAX(NextJourneyStartTime))
	FROM x
	GROUP BY
		 PolicyNumber
		,Island
)
SELECT
	 PolicyNumber
	,MaxDaysDiff = MAX(DaysDiff)
--INTO sandbox.dbo.SJ_RTS_DaysAwayFromHome
FROM y
GROUP BY PolicyNumber
;


;WITH x AS (
	SELECT
		 *
		,Island = JourneyRN - ROW_NUMBER() OVER (PARTITION BY PolicyNumber ORDER BY JourneyRN ASC)
	FROM sandbox.dbo.RTS_ParkingBase
	LEFT JOIN dbo.SJ_BatchModeEnabler bme
		ON 1 = 0
	WHERE MilesFromRA > 1
),
y AS (
	SELECT
		 PolicyNumber
		,DaysDiff = DATEDIFF(DAY, MIN(JourneyEndTime), MAX(NextJourneyStartTime))
	FROM x
	GROUP BY
		 PolicyNumber
		,Island
)
SELECT
	 PolicyNumber
	,MaxDaysDiff = MAX(DaysDiff)
--INTO sandbox.dbo.SJ_RTS_DaysAwayFromHome
FROM y
GROUP BY PolicyNumber
;









SELECT TOP 1 *
FROM dbo.RTS_ParkingBase

CREATE UNIQUE NONCLUSTERED INDEX FNCIX ON dbo.RTS_ParkingBase (PolicyNumber, JourneyRN)
INCLUDE (JourneyEndTime, NextJourneyStartTime)
WHERE MilesFromRA > 1
;

CREATE NONCLUSTERED COLUMNSTORE INDEX FNCCSIX ON dbo.RTS_ParkingBase (PolicyNumber, JourneyRN, JourneyEndTime, NextJourneyStartTime)
WHERE MilesFromRA > 1
;








SELECT *
FROM dbo.RTS_DaysAwayFromHome
EXCEPT
SELECT *
FROM dbo.SJ_RTS_DaysAwayFromHome
;

;WITH Recursion AS (
	SELECT
		 PolicyNumber
		,IMEI
		,Journey_ID
		,JourneyRN
		,JourneyEndTime
		,MilesFromRA
		,NextJourneyStartTime
		,CASE WHEN MilesFromRA > 1 THEN JourneyEndTime ELSE NULL END DaysNoParkStart
	FROM Sandbox.dbo.RTS_ParkingBase
	WHERE JourneyRN = 1

	UNION ALL

	SELECT
		 a.PolicyNumber
		,a.IMEI
		,a.Journey_ID
		,a.JourneyRN 
		,a.JourneyEndTime
		,a.MilesFromRA
		,a.NextJourneyStartTime
		,CASE 
			WHEN a.MilesFromRA > 1 AND b.MilesFromRA > 1 THEN b.DaysNoParkStart
			WHEN a.MilesFromRA > 1 						 THEN a.JourneyEndTime
														 ELSE NULL
		 END DaysNoParkStart
	FROM Sandbox.dbo.RTS_ParkingBase a
	INNER JOIN Recursion b
		ON  a.PolicyNumber = b.PolicyNumber
		AND a.JourneyRN = b.JourneyRN + 1
)
SELECT
	 PolicyNumber
	,MAX(DATEDIFF(DAY, DaysNoParkStart, NextJourneyStartTime)) MaxCDaysNoParkLTE01Miles
FROM Recursion
GROUP BY PolicyNumber
OPTION (MAXRECURSION 32767)
;


--CREATE CLUSTERED INDEX CIX ON dbo.RTS_LogSummary (RunTime DESC, TimeFinished ASC);
--CREATE CLUSTERED INDEX CIX ON dbo.AppAssociation_Log (ScriptStartTime DESC, StepFinishTime ASC);
--CREATE CLUSTERED INDEX CIX ON dbo.RedTailPolygons_Log (ScriptStartTime DESC, QueryFinishTime ASC);