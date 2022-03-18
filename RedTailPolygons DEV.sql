
DROP TABLE IF EXISTS #BST;
CREATE TABLE #BST (
	 [Year]		smallint		NOT NULL
	,StartTime	datetime2(0)	NOT NULL
	,EndTime	datetime2(0)	NOT NULL
)
;

DECLARE @Year smallint = 2015;

WHILE @Year <= YEAR(CURRENT_TIMESTAMP)
BEGIN

	;WITH LastWeekOfMarch ([Date]) AS (
		SELECT DATETIMEFROMPARTS(@Year, 03, 25, 01, 00, 00, 000)
				
		UNION ALL
				
		SELECT DATEADD(DAY, 1, [Date])
		FROM LastWeekOfMarch
		WHERE MONTH(DATEADD(DAY, 1, [Date])) < 4
	),
	LastWeekOfOctober ([Date]) AS (
		SELECT DATETIMEFROMPARTS(@Year, 10, 25, 01, 00, 00, 000)
				
		UNION ALL
				
		SELECT DATEADD(DAY, 1, [Date])
		FROM LastWeekOfOctober
		WHERE MONTH(DATEADD(DAY, 1, [Date])) < 11
	)
	INSERT #BST ([Year], StartTime, EndTime)
	SELECT
		 @Year
		,lsm.[Date]
		,lso.[Date]
	FROM LastWeekOfMarch lsm
	CROSS JOIN (
		SELECT [Date]
		FROM LastWeekOfOctober
		WHERE DATENAME(WEEKDAY, [Date]) = 'Sunday'
	) lso
	WHERE DATENAME(WEEKDAY, lsm.[Date]) = 'Sunday'
	OPTION (MAXRECURSION 6)
	;
			
	SET @Year += 1;

END
;


CREATE TABLE sandbox.dbo.SJ_PolygonRTJE1 (
	 IMEI						bigint			NOT NULL
	,Journey_ID					integer			NOT NULL
	,JourneyEvent_RawID			bigint			NOT NULL
	,EventOrder					tinyint				NULL
	,EventTimeStamp				datetime2(0)		NULL
	,TimeElapsed				integer				NULL
	,Latitude					float(53)		NOT	NULL
	,Longitude					float(53)		NOT	NULL
	,Coordinate					geography			NULL
	,DistanceFromPrevPosition	smallint	    	NULL
	,TravelSpeedMPH				tinyint				NULL
	,HaversineMetresDriven		integer				NULL
)
;

-- DROP TABLE IF EXISTS sandbox.dbo.SJ_PolygonRTJE2;
CREATE TABLE sandbox.dbo.SJ_PolygonRTJE2 (
	 IMEI						bigint			NOT NULL
	,Journey_ID					integer			NOT NULL
	,EventOrder					tinyint				NULL
	,EventTimeStamp				datetime2(0)		NULL
	,TimeElapsed				integer				NULL
	,Latitude					float(53)		NOT	NULL
	,Longitude					float(53)		NOT	NULL
	,DistanceFromPrevPosition	smallint	    	NULL
	,TravelSpeedMPH				tinyint				NULL
	,HaversineMetresDriven		integer				NULL
	,PolygonName				varchar(30)		NOT NULL
)
;

SET STATISTICS IO, TIME ON;

;WITH Polygons AS (
	SELECT
		 PolygonName
		,Polygon
	FROM sandbox.dbo.SJ_Polygons
	WHERE DetailID = 2
		AND PolygonName != 'England'
)
INSERT sandbox.dbo.SJ_PolygonRTJE2 WITH ( TABLOCK ) (
	IMEI     , Journey_ID			   , EventTimeStamp, EventOrder           , TimeElapsed, Latitude,
	Longitude, DistanceFromPrevPosition, TravelSpeedMPH, HaversineMetresDriven, PolygonName
)
SELECT
	 je.IMEI
	,je.Journey_ID
	,je.EventTimeStamp
	,je.EventOrder
	,je.TimeElapsed
	,je.Latitude
	,je.Longitude
	,je.DistanceFromPrevPosition
	,je.TravelSpeedMPH
	,je.HaversineMetresDriven
	,p.PolygonName
FROM staging.dbo.PolygonRTJE1 je
INNER JOIN Polygons p
	ON p.Polygon.STIntersects(je.Coordinate) = 1
;

;WITH Polygons AS (
	SELECT
		 PolygonName
		,Polygon
	FROM staging.dbo.Polygons
	WHERE ETL = 1
)
--INSERT sandbox.dbo.SJ_PolygonRTJE2 WITH ( TABLOCK ) (
--	IMEI     , Journey_ID			   , EventTimeStamp, EventOrder           , TimeElapsed, Latitude,
--	Longitude, DistanceFromPrevPosition, TravelSpeedMPH, HaversineMetresDriven, PolygonName
--)
SELECT
	 je.IMEI
	,je.Journey_ID
	,je.EventTimeStamp
	,je.EventOrder
	,je.TimeElapsed
	,je.Latitude
	,je.Longitude
	,je.DistanceFromPrevPosition
	,je.TravelSpeedMPH
	,je.HaversineMetresDriven
	,p.PolygonName
FROM staging.dbo.PolygonRTJE1 je
INNER JOIN Polygons p
	ON p.Polygon.STIntersects(je.Coordinate) = 1
;

sys.sp_help N'dbo.SJ_PolygonRTJE1';

SELECT COUNT(*)
FROM sandbox.dbo.SJ_PolygonRTJE2


-- DROP TABLE IF EXISTS sandbox.dbo.SJ_PolygonRTJE3;
CREATE TABLE sandbox.dbo.SJ_PolygonRTJE3 (
	 IMEI					bigint			NOT NULL
	,Journey_ID				int				NOT NULL
	,PolygonName			varchar(30)		NOT NULL
	,FirstTimeStamp			datetime2(0)		NULL
	,LastTimeStamp			datetime2(0)		NULL
	,FirstLatitude			float(53)		NOT	NULL
	,FirstLongitude			float(53)		NOT	NULL
	,LastLatitude			float(53)		NOT	NULL
	,LastLongitude			float(53)		NOT	NULL
	,HaversineMetres		integer				NULL
	,MetresDriven 			integer				NULL
	,MilesDriven			numeric(9, 5)		NULL
	,SecondsDriven 			integer				NULL
	,MinutesDriven			numeric(9, 4)		NULL
	,MaxSpeedMPH			tinyint				NULL
	,MilesOver70MPH			numeric(9, 5)		NULL
	,SecondsOver70MPH		integer				NULL
	,EventCount				smallint			NULL
	,NightMiles				numeric(9, 5) 		NULL
	,NightMinutes			numeric(9, 5) 		NULL
	,HaversineMetresDriven	integer				NULL
	,AverageSpeedMPH		numeric(9, 4)		NULL
	,DistancePctOfJourney	numeric(9, 8)		NULL
	,TimePctOfJourney		numeric(9, 8)		NULL
	,EventsPctOfJourney		numeric(9, 8)		NULL
)
;

;WITH RowNumbers AS (
	SELECT
		 je.IMEI
		,je.Journey_ID
		,EventTimeStamp = CASE WHEN bst.StartTime IS NOT NULL THEN DATEADD(HOUR, 1, je.EventTimeStamp) ELSE je.EventTimeStamp END
		,je.EventOrder
		,je.TimeElapsed
		,je.Latitude
		,je.Longitude
		,je.DistanceFromPrevPosition
		,je.TravelSpeedMPH
		,je.HaversineMetresDriven
		,je.PolygonName
		,RowNumAsc 	=
			ROW_NUMBER() OVER (
				PARTITION BY je.IMEI, je.Journey_ID, je.PolygonName
				ORDER BY	 je.EventTimeStamp ASC , je.EventOrder ASC
			)
		,RowNumDesc =
			ROW_NUMBER() OVER (
				PARTITION BY je.IMEI, je.Journey_ID, je.PolygonName
				ORDER BY je.EventTimeStamp DESC, je.EventOrder DESC
			)
	FROM sandbox.dbo.SJ_PolygonRTJE2 je
	LEFT JOIN #BST bst
		ON  je.EventTimeStamp >= bst.StartTime
		AND je.EventTimeStamp <  bst.EndTime
)
INSERT sandbox.dbo.SJ_PolygonRTJE3 WITH ( TABLOCK ) (
	PolygonName , IMEI         , Journey_ID  , FirstTimeStamp       , LastTimeStamp, FirstLatitude , FirstLongitude  , 
	LastLatitude, LastLongitude, MetresDriven, SecondsDriven        , MaxSpeedMPH  , MilesOver70MPH, SecondsOver70MPH, 
	NightMiles  , NightMinutes , EventCount  , HaversineMetresDriven, MilesDriven  , MinutesDriven , AverageSpeedMPH
)
SELECT
	 PolygonName
	,IMEI
	,Journey_ID
	,FirstTimeStamp   	   = MIN(EventTimeStamp)
	,LastTimeStamp    	   = MAX(EventTimeStamp)
	,FirstLatitude    	   = SUM(CASE RowNumAsc  WHEN 1 THEN Latitude  END)
	,FirstLongitude   	   = SUM(CASE RowNumAsc  WHEN 1 THEN Longitude END)
	,LastLatitude     	   = SUM(CASE RowNumDesc WHEN 1 THEN Latitude  END)
	,LastLongitude    	   = SUM(CASE RowNumDesc WHEN 1 THEN Longitude END)
	,MetresDriven     	   = SUM(DistanceFromPrevPosition)
	,SecondsDriven    	   = SUM(TimeElapsed)
	,MaxSpeedMPH	  	   = MAX(TravelSpeedMPH)
	,MilesOver70MPH   	   = SUM(CASE WHEN TravelSpeedMPH > 70 THEN DistanceFromPrevPosition ELSE 0 END) / 1609.344
	,SecondsOver70MPH 	   = SUM(CASE WHEN TravelSpeedMPH > 70 THEN TimeElapsed              ELSE 0 END)
	,NightMiles		  	   = SUM(CASE WHEN ( DATEPART(HOUR, EventTimeStamp) >= 22 OR DATEPART(HOUR, EventTimeStamp) < 4 ) THEN DistanceFromPrevPosition ELSE 0 END) / 1609.344
	,NightMinutes          = SUM(CASE WHEN ( DATEPART(HOUR, EventTimeStamp) >= 22 OR DATEPART(HOUR, EventTimeStamp) < 4 ) THEN TimeElapsed              ELSE 0 END) / 60.0
	,EventCount       	   = COUNT(*)
	,HaversineMetresDriven = SUM(HaversineMetresDriven)
	,MilesDriven 		   = SUM(DistanceFromPrevPosition) / 1609.344
	,MinutesDriven 		   = SUM(TimeElapsed) / 60.0
	,AverageSpeedMPH 	   = ( SUM(DistanceFromPrevPosition) / NULLIF(SUM(TimeElapsed), 0) ) * 2.23694
FROM RowNumbers
GROUP BY
	 PolygonName
	,IMEI
	,Journey_ID
;

SELECT
	 PolygonName
	,COUNT(DISTINCT IMEI)
	,COUNT(DISTINCT Journey_ID)
	,SUM(MilesDriven)
	,SUM(SecondsDriven) / 3600.0
	,SUM(EventCount)
	,MAX(MaxSpeedMPH)
	,SUM(MilesOver70MPH)
	,SUM(SecondsOver70MPH) / 60.0
	,SUM(NightMiles)
	,SUM(NightMinutes) / 60.0
	,SUM(MilesDriven) / ( NULLIF(SUM(MinutesDriven) / 60.0, 0) )
FROM sandbox.dbo.SJ_PolygonRTJE3
GROUP BY PolygonName
ORDER BY 4 DESC
;
