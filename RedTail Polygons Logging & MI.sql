SELECT
	 *
	,MinutesTaken =
		DATEDIFF(
			 SECOND
			,LAG(QueryEndTime, 1, NULL) OVER (PARTITION BY ScriptStartTime ORDER BY QueryEndTime ASC)
			,QueryEndTime
		) / 60.0
	,MinutesTakenThusFar =
		DATEDIFF(
			 SECOND
			,ScriptStartTime
			,QueryEndTime
		) / 60.0
	,TotalMinutesTaken =
		DATEDIFF(
			 SECOND
			,ScriptStartTime
			,CASE WHEN Query = 'Final insert' THEN QueryEndTime END
		) / 60.0
FROM sandbox.dbo.SJ_PolyLogs
ORDER BY
	 ScriptStartTime DESC
	,QueryEndTime    DESC
;

SELECT TOP (1000) *
FROM sandbox.dbo.SJ_RedTailPolygons
;

SELECT
	 PolygonName
	,IMEICount				= COUNT(DISTINCT IMEI)
	,JourneyCount			= COUNT(*)
	,JourneysPct            = COUNT(*) / (SUM(COUNT(*)) OVER () * 1.0)
	,Mileage				= SUM(MilesDriven)
	,AvgMilesPerRisk        = SUM(MilesDriven) / COUNT(DISTINCT IMEI)
	,AvgMilesPerTrip        = SUM(MilesDriven) / COUNT(*)
	,MileagePct				= SUM(MilesDriven) / NULLIF(SUM(SUM(MilesDriven)) OVER (), 0)
	,HoursDriven			= SUM(MinutesDriven) / 60
	,AvgHoursPerRisk        = (SUM(MinutesDriven) / 60) / COUNT(DISTINCT IMEI)
	,AvgMinutesPerTrip      = SUM(MinutesDriven) / COUNT(*)
	,HoursPct				= SUM(CONVERT(bigint, SecondsDriven)) / NULLIF(SUM(SUM(CONVERT(bigint, SecondsDriven))) OVER () * 1.0, 0)
	,Efficiency				= SUM(CONVERT(bigint, HaversineMetres)) / NULLIF((SUM(CONVERT(bigint, MetresDriven)) * 1.0), 0)
	,NightMiles				= SUM(NightMiles)
	,NightMilesPct			= SUM(NightMiles) / NULLIF(SUM(SUM(NightMiles)) OVER (), 0)
	,NightMilesPctMiles		= SUM(NightMiles) / NULLIF(SUM(MilesDriven), 0)
	,NightHours				= SUM(NightMinutes) / 60
	,NightHoursPct			= SUM(NightMinutes) / NULLIF(SUM(SUM(NightMinutes)) OVER (), 0)
	,AverageSpeedMPH        = SUM(MilesDriven) / NULLIF(SUM(MinutesDriven) / 60, 0)
	,AverageMaxSpeedMPH     = AVG(CONVERT(bigint, MaxSpeedMPH) * 1.0)
	,MilesOver70MPH			= SUM(MilesOver70MPH)
	,MilesOver70MPHPct		= SUM(MilesOver70MPH) / NULLIF(SUM(SUM(MilesOver70MPH)) OVER (), 0)
	,MilesOver70MPHPctMiles = SUM(MilesOver70MPH) / NULLIF(SUM(MilesDriven), 0)
	,HoursOver70MPH			= SUM(SecondsOver70MPH) / 3600.0
	,HoursOver70MPHPct		= SUM(SecondsOver70MPH) / NULLIF(SUM(SUM(SecondsOver70MPH)) OVER () * 1.0, 0)
	,HoursOver70MPHPctHours = SUM(SecondsOver70MPH) / NULLIF(SUM(CONVERT(bigint, SecondsDriven)) * 1.0, 0)
	,DistanceFromPrevTest	= SUM(CONVERT(bigint, MetresDriven)) / NULLIF(SUM(CONVERT(bigint, HaversineMetresDriven) * 1.0), 0)
	,EventCount             = SUM(CONVERT(bigint, EventCount))
FROM sandbox.dbo.SJ_RedTailPolygons
GROUP BY PolygonName
ORDER BY 1 ASC
;

--CREATE TABLE sandbox.dbo.SJ_PolygonsMI (
--	 Country						varchar(20)			NULL
--	,[Local Authority District]		varchar(30)		NOT NULL
--	,[Calendar Year]				smallint		NOT NULL
--	,[Calendar Month]				varchar(15)		NOT NULL
--	,[# Calendar Month]				tinyint			NOT NULL
--	,[# Risks Driving]				smallint		NOT NULL
--	,[# Trips]						integer			NOT NULL
--	,[Mileage]						decimal(9, 2)		NULL
--	,[Average Mileage Per Risk]		decimal(9, 4)		NULL
--	,[Average Mileage Per Trip]		decimal(9, 5)		NULL

--	,CONSTRAINT PK__SJ_PolygonsMI__LocalAuthorityDistrictCalendarYear#CalendarMonth PRIMARY KEY CLUSTERED (
--		 [Local Authority District] ASC
--		,[Calendar Year]			ASC
--		,[# Calendar Month]			ASC
--	 )
--)
--;

--INSERT sandbox.dbo.SJ_PolygonsMI (
--	 Country
--	,[Local Authority District]
--	,[Calendar Year]
--	,[Calendar Month]
--	,[# Calendar Month]
--	,[# Risks Driving]
--	,[# Trips]
--	,[Mileage]
--	,[Average Mileage Per Risk]
--	,[Average Mileage Per Trip]
--)
--SELECT
--	 [Country] =
--		CASE
--			WHEN rp.PolygonName = 'Cardiff'					THEN 'Wales'
--			WHEN rp.PolygonName IN ('Edinburgh', 'Glasgow') THEN 'Scotland'
--															ELSE 'England'
--		END
--	,[Local Authority District] = rp.PolygonName
--	,[Calendar Year]	        = YEAR(rp.FirstTimeStamp)
--	,[Calendar Month]	        = DATENAME(MONTH, rp.FirstTimeStamp)
--	,[# Calendar Month]         = MONTH(rp.FirstTimeStamp)
--	,[# Risks Driving]	        = COUNT(DISTINCT a.PolicyNumber)
--	,[# Trips]     	            = COUNT(*)
--	,[Mileage]                  = SUM(rp.MilesDriven)
--	,[Average Mileage Per Risk] = SUM(rp.MilesDriven) / COUNT(DISTINCT a.PolicyNumber)
--	,[Average Mileage Per Trip] = SUM(rp.MilesDriven) / COUNT(*)
--FROM DataSummary.dbo.RedTailPolygons rp
--INNER JOIN RedTail.dbo.Association a
--	ON  rp.IMEI            = CONVERT(bigint, a.IMEI)
--	AND rp.FirstTimeStamp >= a.StartDate
--	AND (
--			rp.FirstTimeStamp < a.EndDate
--		OR  a.EndDate IS NULL
--	)
--WHERE rp.PolygonName IN (
--	 'Birmingham'
--	,'Bristol'
--	,'Cardiff'
--	,'Edinburgh'
--	,'Glasgow'
--	,'Isle of Wight'
--	,'Leeds'
--	,'Leicester'
--	,'Liverpool'
--	,'Manchester'
--	,'Nottingham'
--	,'Sheffield'
--)
--GROUP BY
--	 CASE
--		WHEN rp.PolygonName = 'Cardiff'					THEN 'Wales'
--		WHEN rp.PolygonName IN ('Edinburgh', 'Glasgow') THEN 'Scotland'
--														ELSE 'England'
--	 END
--	,rp.PolygonName
--	,YEAR(rp.FirstTimeStamp)
--	,MONTH(rp.FirstTimeStamp)
--	,DATENAME(MONTH, rp.FirstTimeStamp)
--;

--INSERT sandbox.dbo.SJ_PolygonsMI (
--	 Country
--	,[Local Authority District]
--	,[Calendar Year]
--	,[Calendar Month]
--	,[# Calendar Month]
--	,[# Risks Driving]
--	,[# Trips]
--	,[Mileage]
--	,[Average Mileage Per Risk]
--	,[Average Mileage Per Trip]
--)
--SELECT
--	 [Country]                  = p.Country
--	,[Local Authority District] = rp.PolygonName
--	,[Calendar Year]	        = YEAR(rp.FirstTimeStamp)
--	,[Calendar Month]	        = DATENAME(MONTH, rp.FirstTimeStamp)
--	,[# Calendar Month]         = MONTH(rp.FirstTimeStamp)
--	,[# Risks Driving]	        = COUNT(DISTINCT a.PolicyNumber)
--	,[# Trips]     	            = COUNT(*)
--	,[Mileage]                  = SUM(rp.MilesDriven)
--	,[Average Mileage Per Risk] = SUM(rp.MilesDriven) / COUNT(DISTINCT a.PolicyNumber)
--	,[Average Mileage Per Trip] = SUM(rp.MilesDriven) / COUNT(*)
--FROM sandbox.dbo.SJ_RedTailPolygons rp
--INNER JOIN RedTail.dbo.Association a
--	ON  rp.IMEI            = a.IMEI
--	AND rp.FirstTimeStamp >= a.StartDate
--	AND (
--			rp.FirstTimeStamp < a.EndDate
--		OR  a.EndDate IS NULL
--	)
--INNER JOIN sandbox.dbo.SJ_Polygons p
--	ON  rp.PolygonName = p.PolygonName
--	AND p.DetailID     = 2
--GROUP BY
--	 p.Country
--	,rp.PolygonName
--	,YEAR(rp.FirstTimeStamp)
--	,MONTH(rp.FirstTimeStamp)
--	,DATENAME(MONTH, rp.FirstTimeStamp)
--;

SELECT
	 [Country]
	,[Local Authority District]
	,[Calendar Year]
	,[Calendar Month]
	,[# Calendar Month]
	,[# Risks Driving]
	,[# Trips]
	,[Mileage]
	,[Average Mileage Per Risk]
	,[Average Mileage Per Trip]
FROM sandbox.dbo.SJ_PolygonsMI
ORDER BY
	 [Country]                  ASC
	,[Local Authority District] ASC
	,[Calendar Year]            ASC
	,[# Calendar Month]         ASC
;

SELECT
	 t1.[Country]
	,t1.[Local Authority District]
	,t1.[Calendar Month]
	,t1.[# Calendar Month]
	,[Average Mileage Per Risk (2020)]          = t1.[Average Mileage Per Risk]
	,[Average Mileage Per Risk (2019)]          = COALESCE(t2.[Average Mileage Per Risk], 0)
	,[Average Mileage Per Risk (2020 vs. 2019)] = t1.[Average Mileage Per Risk] / NULLIF(t2.[Average Mileage Per Risk], 0)
	,[Mileage (2020)]          = t1.Mileage
	,[Mileage (2019)]          = COALESCE(t2.Mileage, 0)
	,[Mileage (2020 vs. 2019)] = t1.Mileage / NULLIF(t2.Mileage, 0)
	,[Average Mileage Per Trip (2020)]          = t1.[Average Mileage Per Trip]
	,[Average Mileage Per Trip (2019)]          = COALESCE(t2.[Average Mileage Per Trip], 0)
	,[Average Mileage Per Trip (2020 vs. 2019)] = t1.[Average Mileage Per Trip] / NULLIF(t2.[Average Mileage Per Trip], 0)
FROM sandbox.dbo.SJ_PolygonsMI t1
LEFT OUTER JOIN sandbox.dbo.SJ_PolygonsMI t2
	ON  t1.[Local Authority District] = t2.[Local Authority District]
	AND t1.[# Calendar Month]         = t2.[# Calendar Month]
	AND t1.[Calendar Year]            = t2.[Calendar Year] + 1
WHERE t1.[Calendar Year] = 2020
	AND t1.[# Calendar Month] IN (3, 4, 5, 6, 7, 8, 9, 10)
ORDER BY
	 t1.[Country]                  ASC
	,t1.[Local Authority District] ASC
	,t1.[# Calendar Month]         ASC
;

;WITH x AS (
	SELECT
		 t1.[Country]
		,t1.[Local Authority District]
		,t1.[Calendar Month]
		,[Average Mileage Per Risk (2020 vs. 2019)] = t1.[Average Mileage Per Risk] / NULLIF(t2.[Average Mileage Per Risk], 0)
	FROM sandbox.dbo.SJ_PolygonsMI t1
	LEFT OUTER JOIN sandbox.dbo.SJ_PolygonsMI t2
		ON  t1.[Local Authority District] = t2.[Local Authority District]
		AND t1.[# Calendar Month]         = t2.[# Calendar Month]
		AND t1.[Calendar Year]            = t2.[Calendar Year] + 1
	WHERE t1.[Calendar Year] = 2020
		AND t1.[# Calendar Month] IN (4, 5, 6, 7, 8, 9, 10)
)
SELECT
	 Country
	,[Local Authority District]
	,p.April
	,p.May
	,p.June
	,p.July
	,p.August
	,p.September
	,p.October
FROM x
PIVOT (
	MAX([Average Mileage Per Risk (2020 vs. 2019)]) FOR [Calendar Month] IN (April, May, June, July, August, September, October)
) p
ORDER BY
	 Country                    ASC
	,[Local Authority District] ASC
;

;WITH x AS (
	SELECT
		 t1.[Country]
		,t1.[Local Authority District]
		,t1.[Calendar Month]
		,[Average Mileage Per Risk (2020 vs. Previous CM)] = t1.[Average Mileage Per Risk] / NULLIF(t2.[Average Mileage Per Risk], 0)
	FROM sandbox.dbo.SJ_PolygonsMI t1
	LEFT OUTER JOIN sandbox.dbo.SJ_PolygonsMI t2
		ON  t1.[Local Authority District] = t2.[Local Authority District]
		AND t1.[Calendar Year]            = t2.[Calendar Year]
		AND t1.[# Calendar Month]         = t2.[# Calendar Month] + 1
	WHERE t1.[Calendar Year] = 2020
		AND t1.[# Calendar Month] IN (4, 5, 6, 7, 8, 9, 10)
)
SELECT
	 Country
	,[Local Authority District]
	,p.April
	,p.May
	,p.June
	,p.July
	,p.August
	,p.September
	,p.October
FROM x
PIVOT (
	MAX([Average Mileage Per Risk (2020 vs. Previous CM)]) FOR [Calendar Month] IN (April, May, June, July, August, September, October)
) p
ORDER BY
	 Country                    ASC
	,[Local Authority District] ASC
;

;WITH x AS (
	SELECT
		 t1.[Country]
		,t1.[Local Authority District]
		,t1.[Calendar Month]
		,[Mileage vs. Previous Year] = t1.[Mileage] / NULLIF(t2.[Mileage], 0)
	FROM sandbox.dbo.SJ_PolygonsMI t1
	LEFT OUTER JOIN sandbox.dbo.SJ_PolygonsMI t2
		ON  t1.[Local Authority District] = t2.[Local Authority District]
		AND t1.[# Calendar Month]         = t2.[# Calendar Month]
		AND t1.[Calendar Year]            = t2.[Calendar Year] + 1
	WHERE t1.[Calendar Year] = 2020
		AND t1.[# Calendar Month] IN (4, 5, 6, 7, 8, 9, 10)
)
SELECT
	 Country
	,[Local Authority District]
	,p.April
	,p.May
	,p.June
	,p.July
	,p.August
	,p.September
	,p.October
FROM x
PIVOT (
	MAX([Mileage vs. Previous Year]) FOR [Calendar Month] IN (April, May, June, July, August, September, October)
) p
ORDER BY
	 Country                    ASC
	,[Local Authority District] ASC
;

;WITH x AS (
	SELECT
		 t1.Country
		,t1.[Local Authority District]
		,t1.[Calendar Month]
		,[Mileage (2020 vs. Previous CM)] = t1.[Mileage] / NULLIF(t2.[Mileage], 0)
	FROM sandbox.dbo.SJ_PolygonsMI t1
	LEFT OUTER JOIN sandbox.dbo.SJ_PolygonsMI t2
		ON  t1.[Local Authority District] = t2.[Local Authority District]
		AND t1.[Calendar Year]            = t2.[Calendar Year]
		AND t1.[# Calendar Month]         = t2.[# Calendar Month] + 1
	WHERE t1.[Calendar Year] = 2020
		AND t1.[# Calendar Month] IN (4, 5, 6, 7, 8, 9, 10)
)
SELECT
	 Country
	,[Local Authority District]
	,p.April
	,p.May
	,p.June
	,p.July
	,p.August
	,p.September
	,p.October
FROM x
PIVOT (
	MAX([Mileage (2020 vs. Previous CM)]) FOR [Calendar Month] IN (April, May, June, July, August, September, October)
) p
ORDER BY
	 Country                    ASC
	,[Local Authority District] ASC
;

;WITH x AS (
	SELECT
		 t1.Country
		,t1.[Local Authority District]
		,t1.[Calendar Month]
		,[Average Mileage Per Trip (2020 vs. 2019)] = t1.[Average Mileage Per Trip] / NULLIF(t2.[Average Mileage Per Trip], 0)
	FROM sandbox.dbo.SJ_PolygonsMI t1
	LEFT OUTER JOIN sandbox.dbo.SJ_PolygonsMI t2
		ON  t1.[Local Authority District] = t2.[Local Authority District]
		AND t1.[# Calendar Month]         = t2.[# Calendar Month]
		AND t1.[Calendar Year]            = t2.[Calendar Year] + 1
	WHERE t1.[Calendar Year] = 2020
		AND t1.[# Calendar Month] IN (4, 5, 6, 7, 8, 9, 10)
)
SELECT
	 Country
	,[Local Authority District]
	,p.April
	,p.May
	,p.June
	,p.July
	,p.August
	,p.September
	,p.October
FROM x
PIVOT (
	MAX([Average Mileage Per Trip (2020 vs. 2019)]) FOR [Calendar Month] IN (April, May, June, July, August, September, October)
) p
ORDER BY
	 Country                    ASC
	,[Local Authority District] ASC
;

;WITH x AS (
	SELECT
		 t1.Country
		,t1.[Local Authority District]
		,t1.[Calendar Month]
		,[Average Mileage Per Trip (2020 vs. Previous CM)] = t1.[Average Mileage Per Trip] / NULLIF(t2.[Average Mileage Per Trip], 0)
	FROM sandbox.dbo.SJ_PolygonsMI t1
	LEFT OUTER JOIN sandbox.dbo.SJ_PolygonsMI t2
		ON  t1.[Local Authority District] = t2.[Local Authority District]
		AND t1.[Calendar Year]            = t2.[Calendar Year]
		AND t1.[# Calendar Month]         = t2.[# Calendar Month] + 1
	WHERE t1.[Calendar Year] = 2020
		AND t1.[# Calendar Month] IN (4, 5, 6, 7, 8, 9, 10)
)
SELECT
	 Country
	,[Local Authority District]
	,p.April
	,p.May
	,p.June
	,p.July
	,p.August
	,p.September
	,p.October
FROM x
PIVOT (
	MAX([Average Mileage Per Trip (2020 vs. Previous CM)]) FOR [Calendar Month] IN (April, May, June, July, August, September, October)
) p
ORDER BY
	 Country                    ASC
	,[Local Authority District] ASC
;
