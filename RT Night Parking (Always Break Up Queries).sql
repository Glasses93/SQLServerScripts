
-- Lesson learned: Breaking up queries can save you a fortune because Index Spools can be a bitch.

SET STATISTICS IO, TIME ON;

DROP TABLE IF EXISTS #NightTimes;

SELECT
	 NightStartTime = ISNULL(DATEADD(HOUR, -2, CONVERT(datetime, d)), '20200101')
	,NightEndTime   = ISNULL(DATEADD(HOUR,  4, CONVERT(datetime, d)), '20200101')
INTO #NightTimes
FROM dbo.Dates
WHERE d >= '20150101'
	AND d < '20190101'
;

-- The below keys in opposite order will not yield an index seek as I guess the engine can work better
-- with the >= seek than the < seek(?):
ALTER TABLE #NightTimes ADD PRIMARY KEY CLUSTERED (
	 NightStartTime ASC
	--,NightEndTime	ASC
)
;

--DROP INDEX IF EXISTS NCIX ON #Journeys;
--CREATE NONCLUSTERED INDEX NCIX ON #Journeys (
--	 JourneyEndTime
--	,NextJourneyStartTime
--)
--INCLUDE (PolicyNumber)
--;

--SELECT
--	 PolicyNumber
--	,JourneyEndTime
--	,NextJourneyStartTime =
--		LEAD(JourneyStartTime, 1, NULL) OVER (
--			PARTITION BY PolicyNumber
--			ORDER BY	 JourneyEndTime ASC
--		)
--INTO #Journeys
--FROM DataSummary.dbo.RedTailScoreJourney
--WHERE PolicyNumber LIKE 'AD%'
--;

;WITH x AS (
	SELECT
		 PolicyNumber
		,JourneyEndTime
		,NextJourneyStartTime =
			LEAD(JourneyStartTime, 1, NULL) OVER (
				PARTITION BY PolicyNumber
				ORDER BY	 JourneyEndTime ASC
			)
	FROM DataSummary.dbo.RedTailScoreJourney
	WHERE PolicyNumber LIKE 'AD%'
)
SELECT
	 x.PolicyNumber
	,NightHoursParked =
			SUM(DATEDIFF(
				 SECOND
				,CASE WHEN x.JourneyEndTime       > y.NightStartTime THEN x.JourneyEndTime       ELSE y.NightStartTime END
				,CASE WHEN x.NextJourneyStartTime < y.NightEndTime   THEN x.NextJourneyStartTime ELSE y.NightEndTime   END
			))
		/	3600.0
--INTO #T1
FROM #NightTimes y
INNER JOIN x
	ON  x.NextJourneyStartTime >= y.NightStartTime
	AND x.JourneyEndTime       <  y.NightEndTime
--LEFT OUTER JOIN dbo.SJ_BatchModeEnabler bme
--	ON 1 = 0
GROUP BY x.PolicyNumber
--ORDER BY NightHoursParked DESC
;

SELECT *
FROM #T1
ORDER BY NightHoursParked DESC
;

SELECT *
FROM DataSummary.dbo.RedTailScoreJourney
WHERE PolicyNumber = 'ADAPT7417731001001'
ORDER BY PolicyNumber, JourneyEndTime
;

