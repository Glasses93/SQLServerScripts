
DROP TABLE IF EXISTS #Hours;
CREATE TABLE #Hours (
	 HourID		smallint	NOT NULL IDENTITY(1, 1)
	,HourStart	datetime	NOT NULL
)
;

;WITH x AS (
	SELECT [Hour] = DATEADD(HOUR, n - 1, '20200401')
	FROM dbo.Numbers
	WHERE n BETWEEN 1 AND DAY(EOMONTH('20200401')) * 24
)
INSERT #Hours (HourStart)
SELECT HourStart = [Hour]
FROM x
ORDER BY HourStart ASC
;

ALTER TABLE #Hours ADD PRIMARY KEY CLUSTERED (HourStart ASC);

--SELECT *
--FROM #Hours
--ORDER BY HourStart ASC
--;

;WITH x AS (
	SELECT *
	FROM #Hours h
	WHERE NOT EXISTS (
		SELECT 1
		FROM CMTSERV.dbo.CMTTripSummary_EL ts
		WHERE ts.Trip_Start_Local >= '20200401'
			AND ts.Trip_Start_Local < '20200501'
			AND h.HourStart = DATEADD(HOUR, DATEDIFF(HOUR, '20200101', ts.Trip_Start_Local), '20200101')
	)
	UNION ALL
	SELECT 606, CONVERT(datetime, '2020-04-26T05:00:00.000')
	UNION ALL
	SELECT 77 , CONVERT(datetime, '2020-04-04T04:00:00.000')
	UNION ALL
	SELECT 607, CONVERT(datetime, '2020-04-26T06:00:00.000')
),
y AS (
	SELECT
		 *
		,ContiguousHour =
			CASE WHEN DATEDIFF(HOUR, HourStart, LEAD(HourStart, 1, NULL) OVER (ORDER BY HourStart ASC)) = 1
				THEN 1
				ELSE 0
			END
	FROM x
),
z AS (
	SELECT
		 HourStart
		,ContiguousHour
		,[Group] = HourID - ROW_NUMBER() OVER (ORDER BY HourStart ASC)
	FROM y
	WHERE ContiguousHour = 1
)
SELECT
	 HourStart = MIN(HourStart)
	,HourEnd   = DATEADD(HOUR, 2, MAX(HourStart))
	,[Hours]   = DATEDIFF(HOUR, MIN(HourStart), DATEADD(HOUR, 2, MAX(HourStart)))
	,Summary   =
			'The date range of absent driving begins at '
		+	CONVERT(varchar(20), MIN(HourStart), 113)
		+	' (inclusive) and ends at '
		+	CONVERT(varchar(20), DATEADD(HOUR,  2, MAX(HourStart)), 113)
		+	' (exclusive).'
FROM z
GROUP BY [Group]
ORDER BY
	 [Hours]   DESC
	,HourStart ASC
;

;WITH x(ts) AS (
	SELECT Trip_Start_Local
	FROM CMTSERV.dbo.CMTTripSummary_EL
	WHERE Trip_Start_Local >= DATETIMEFROMPARTS(YEAR(CURRENT_TIMESTAMP) - 1, 1, 1, 0, 0, 0, 0) -- '20200101' 
		AND Trip_Start_Local < DATETIMEFROMPARTS(YEAR(CURRENT_TIMESTAMP) - 1, 5, 1, 0, 0, 0, 0) -- '20200501'
	UNION ALL
	SELECT ca.d
	FROM dbo.Dates d
	CROSS APPLY (
		SELECT CONVERT(datetime, [Date])
		UNION ALL
		SELECT DATEADD(MILLISECOND, -3, CONVERT(datetime, DATEADD(MONTH, 1, [Date])))
	) ca(d)
	WHERE d.[Date] >= DATEFROMPARTS(YEAR(CURRENT_TIMESTAMP) - 1, 1, 1)
		AND d.[Date] < DATEFROMPARTS(YEAR(CURRENT_TIMESTAMP) - 1, 5, 1)
		AND DAY(d.[Date]) = 1
),
y AS (
	SELECT
		 [Year]			  = YEAR(ts)
		,[Calendar Month] = MONTH(ts)
		,MinutesDiff =
			DATEDIFF(
				 MINUTE
				,LAG(ts, 1, NULL) OVER (
					PARTITION BY YEAR(ts), MONTH(ts)
					ORDER BY     ts ASC
				 )
				,ts
			)
	FROM x
)
SELECT
	 [Year]
	,[Calendar Month]
	,BiggestGap = MAX(MinutesDiff)
FROM y
GROUP BY
	 [Year]
	,[Calendar Month]
ORDER BY
	 [Year]
	,[Calendar Month]
;

;WITH x(ts) AS (
	SELECT Trip_Start_Local
	FROM CMTSERV.dbo.CMTTripSummary_EL
	WHERE Trip_Start_Local >= DATETIMEFROMPARTS(YEAR(CURRENT_TIMESTAMP) - 1, 1, 1, 0, 0, 0, 0) -- '20200101' 
		AND Trip_Start_Local < DATETIMEFROMPARTS(YEAR(CURRENT_TIMESTAMP) - 1, 5, 1, 0, 0, 0, 0) -- '20200501'
	UNION ALL
	SELECT ca.d
	FROM dbo.Dates d
	CROSS APPLY (
		SELECT CONVERT(datetime, [Date])
		UNION ALL
		SELECT DATEADD(MILLISECOND, -3, CONVERT(datetime, DATEADD(MONTH, 1, [Date])))
	) ca(d)
	WHERE d.[Date] >= DATEFROMPARTS(YEAR(CURRENT_TIMESTAMP) - 1, 1, 1)
		AND d.[Date] < DATEFROMPARTS(YEAR(CURRENT_TIMESTAMP) - 1, 5, 1)
		AND DAY(d.[Date]) = 1
),
y AS (
	SELECT
		 [Year]					= YEAR(ts)
		,[Calendar Month]		= MONTH(ts)
		,[Previous Timestamp]	=
			LAG(ts, 1, NULL) OVER (
				PARTITION BY YEAR(ts), MONTH(ts)
				ORDER BY     ts ASC
			)
		,[Timestamp]			= ts
		,[Time Difference (m)]	=
			DATEDIFF(
				 MINUTE
				,LAG(ts, 1, NULL) OVER (
					PARTITION BY YEAR(ts), MONTH(ts)
					ORDER BY     ts ASC
				 )
				,ts
			)
	FROM x
),
z AS (
	SELECT
		 *
		,rn = ROW_NUMBER() OVER (PARTITION BY [Year], [Calendar Month] ORDER BY [Time Difference (m)] DESC)
	FROM y
)
SELECT
	 [Year]
	,[Calendar Month]
	,[Previous Timestamp]
	,[Timestamp]
	,[Time Difference (m)]
FROM z
WHERE rn = 1
ORDER BY
	 [Year]
	,[Calendar Month]
;
