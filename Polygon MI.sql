

SELECT
	 PolicyNumber
	,IMEI = CONVERT(bigint, IMEI)
	,StartDate
	,EndDate = COALESCE(EndDate, '20200810')
INTO #Tempzz
FROM RedTail.dbo.Association
WHERE PolicyNumber IN (
	SELECT PolicyNumber
	FROM RedTail.dbo.Association
	WHERE ( EndDate > '20200101' OR EndDate IS NULL )
		AND PolicyNumber LIKE 'P%'
)
;

SELECT *
FROM #TEMPZZ

CREATE CLUSTERED INDEX IX_Tempzz_EndDate
ON #Tempzz (EndDate ASC)
;

CREATE TABLE #Tempzz2 (
	 EffectiveDate 	date		PRIMARY KEY
	,NumMonitored	smallint	NOT NULL
)
;

DECLARE @Day date = '20200101';

WHILE @Day < '20200701'
BEGIN

	INSERT #Tempzz2 (EffectiveDate, NumMonitored)
	SELECT
		 @Day
		,COUNT(DISTINCT PolicyNumber)
	FROM #Tempzz
	WHERE StartDate <= @Day AND EndDate >  @Day
	;

	SET @Day = DATEADD(DAY, 1, @Day);

END
;

SELECT *
FROM #TEMPZZ2

CREATE TABLE #Tempzz3 (
	 EffectiveDate	date		NOT NULL
	,PolygonName 	varchar(30)	NOT NULL
	,NumDriving		smallint	NOT NULL
)
;

DECLARE @Day 	  	date 			= '20200101';
DECLARE @DayStart 	datetime2(0) 	= '2020-01-01T00:00:00';
DECLARE @DayEnd   	datetime2(0) 	= DATEADD(DAY, 1, @DayStart);

WHILE @Day < '20200701'
BEGIN

	INSERT #Tempzz3 (EffectiveDate, PolygonName, NumDriving)
	SELECT
		 @Day
		,rps.PolygonName
		,COUNT(DISTINCT a.PolicyNumber)
	FROM sandbox.dbo.SJ_RedTailPolygonSummary rps
	INNER JOIN #Tempzz a
		ON  rps.IMEI = a.IMEI
		AND rps.FirstTimeStamp >= a.StartDate
		AND rps.FirstTimeStamp <  a.EndDate
		AND rps.FirstTimeStamp >= @DayStart
		AND rps.FirstTimeStamp <  @DayEnd
	GROUP BY rps.PolygonName
	;
	
	SET @Day = DATEADD(DAY, 1, @Day);
	SET @DayStart  = DATEADD(DAY, 1, @DayStart);
	SET @DayEnd    = DATEADD(DAY, 1, @DayStart);

END
;


SELECT MONTH(a.EffectiveDate), a.PolygonName, AVG(a.NumDriving * 1.0 / b.NumMonitored)
FROM  #Tempzz3 a
INNER JOIN #Tempzz2 b
ON a.EffectiveDate = b.EffectiveDate
AND a.EffectiveDate != '20200630'
GROUP BY MONTH(a.EffectiveDate), a.PolygonName
ORDER BY MONTH(a.EffectiveDate), a.PolygonName
;






SELECT
	 PolygonName
	,Journeys = COUNT(Journey_ID)
FROM sandbox.dbo.SJ_RedTailPolygonSummary
GROUP BY PolygonName
;

/*
SELECT
	 FirstLatitude
	,FirstLongitude
FROM sandbox.dbo.SJ_RedTailPolygonSummary
WHERE PolygonName = 'Outside British Isles'

UNION
*/

SELECT
	 LastLatitude
	,LastLongitude
FROM sandbox.dbo.SJ_RedTailPolygonSummary
WHERE PolygonName = 'Outside British Isles'
;

SELECT
	 PolygonName
	,[DistanceOver70MPH %] = SUM(MilesOver70MPH        ) / NULLIF(SUM(CAST(MilesDriven   AS BIGINT)), 0)
	,[TimeOver70MPH %]     = SUM(SecondsOver70MPH * 1.0) / NULLIF(SUM(CAST(SecondsDriven AS BIGINT)), 0)
	,MilesDriven           = SUM(CAST(MilesDriven AS BIGINT))
FROM sandbox.dbo.SJ_RedTailPolygonSummary
WHERE MetresDriven >= HaversineMetresDriven
GROUP BY PolygonName
ORDER BY 1 ASC
;

SELECT
	 PolygonName
	,[NightDistance %] = SUM(NightMiles  ) / NULLIF(SUM(CAST(MilesDriven AS BIGINT)), 0)
	,[NightTime %]     = SUM(NightMinutes) / NULLIF(SUM(MinutesDriven), 0)
	,MilesDriven       = SUM(CAST(MilesDriven AS BIGINT))
FROM sandbox.dbo.SJ_RedTailPolygonSummary
WHERE MetresDriven >= HaversineMetresDriven
GROUP BY PolygonName
ORDER BY 1 ASC
;

SELECT
	 PolygonName
	,AverageSpeedMPH = AVG(AverageSpeedMPH)
FROM sandbox.dbo.SJ_RedTailPolygonSummary
WHERE AverageSpeedMPH < MaxSpeedMPH
GROUP BY PolygonName
ORDER BY 1 ASC
;

SELECT
	 PolygonName
	,[Over100MPH %] = COUNT(CASE WHEN MaxSpeedMPH > 100 THEN 1 ELSE NULL END) / NULLIF(COUNT(IMEI) * 1.0, 0)
	,Journeys       = COUNT(IMEI)
FROM sandbox.dbo.SJ_RedTailPolygonSummary
GROUP BY PolygonName
ORDER BY 1 ASC
;

SELECT
	 PolygonName
	,[Efficiency %] = SUM(CAST(HaversineMetres AS BIGINT)) / NULLIF(SUM(CAST(MetresDriven AS BIGINT)) * 1.0, 0)
	,MilesDriven      = SUM(CAST(MilesDriven AS BIGINT))
FROM sandbox.dbo.SJ_RedTailPolygonSummary
GROUP BY PolygonName
ORDER BY 1 ASC
;

SELECT
	 IMEI
	,Polygons = COUNT(DISTINCT PolygonName)
FROM sandbox.dbo.SJ_RedTailPolygonSummary
WHERE PolygonName IN (
	 -- 13 polygons:
	 'Outside British Isles'
	,'London'
	,'Cardiff'
	,'Bristol'
	,'Birmingham'
	,'Manchester'
	,'Liverpool'
	,'Leicester'
	,'Nottingham'
	,'Leeds'
	,'Glasgow'
	,'Edinburgh'
	,'Sheffield'
	,'Northern Ireland'
	,'Ireland'
)
GROUP BY IMEI
ORDER BY 2 DESC
;

SELECT DISTINCT
	 IMEI
	,PolygonName
FROM sandbox.dbo.SJ_RedTailPolygonSummary
WHERE IMEI IN (
	 356917057342896
	,356917057287737
)
ORDER BY
	 1 ASC
	,2 ASC
;


















/*
Birmingham
Bristol
Cardiff
East Midlands
Edinburgh
England
Glasgow
Ireland
Leeds
Leicester
Liverpool
London
Manchester
North East England
North West England
Northern Ireland
Nottingham
Scotland
Sheffield
South East England
South West England
Wales
West Midlands
Yorkshire and the Humber
*/