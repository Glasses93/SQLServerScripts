
USE sandbox;

SET STATISTICS IO, TIME ON;

;WITH x AS (
	SELECT *
	FROM dbo.RTS_JourneySummaryFinal js
	WHERE EXISTS (
		SELECT 1
		FROM dbo.SJ_Polygons p
		WHERE p.PolygonName IN ('Battlefield')
			AND p.DetailID = 4
			AND p.Polygon.STIntersects(geography::Point(js.JourneyEndLatitude, js.JourneyEndLongitude, 4326)) = 1
	)
)
SELECT
	 p.PolygonName
	,x.*
FROM x
CROSS APPLY (
	SELECT TOP (1) p.PolygonName
	FROM dbo.SJ_Polygons p
	WHERE p.PolygonName IN ('Battlefield')
		AND p.DetailID = 1
		AND p.Polygon.STIntersects(geography::Point(x.JourneyEndLatitude, x.JourneyEndLongitude, 4326)) = 1
) p
;

;WITH x AS (
	SELECT TOP (2147483647) *
	FROM dbo.RTS_JourneySummaryFinal js
	WHERE EXISTS (
		SELECT 1
		FROM dbo.SJ_Polygons p
		WHERE p.PolygonName IN ('Gwynedd')
			AND p.DetailID = 4
			AND p.Polygon.STIntersects(geography::Point(js.JourneyEndLatitude, js.JourneyEndLongitude, 4326)) = 1
	)
)
SELECT *
FROM x
WHERE EXISTS (
	SELECT 1
	FROM dbo.SJ_Polygons p
	WHERE p.PolygonName IN ('Gwynedd')
		AND p.DetailID = 1
		AND p.Polygon.STIntersects(geography::Point(x.JourneyEndLatitude, x.JourneyEndLongitude, 4326)) = 1
)
OPTION ( USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE') )
;





SELECT
	 pc.pcd
	,x.JourneyEndLatitude
	,x.JourneyEndLongitude
FROM dbo.RTS_JourneySummaryFinal x
OUTER APPLY (
	SELECT TOP (1) pc.pcd
	FROM dbo.SJ_ONSPostcodeDirectory_202008 pc
	WHERE pc.Coordinate.STDistance(geography::Point(x.JourneyEndLatitude, x.JourneyEndLongitude, 4326)) <= 1000
	ORDER BY pc.Coordinate.STDistance(geography::Point(x.JourneyEndLatitude, x.JourneyEndLongitude, 4326)) ASC
) pc
;

SELECT
	 pc.pcd
	,x.JourneyEndLatitude
	,x.JourneyEndLongitude
FROM dbo.RTS_JourneySummaryFinal x
OUTER APPLY (
	SELECT TOP (1) pc.pcd
	FROM dbo.SJ_ONSPostcodeDirectory_202008 pc --WITH ( SPATIAL_WINDOW_MAX_CELLS = 4096 )
	WHERE pc.Coordinate.STDistance(geography::Point(x.JourneyEndLatitude, x.JourneyEndLongitude, 4326)) <= 1000
	ORDER BY pc.Coordinate.STDistance(geography::Point(x.JourneyEndLatitude, x.JourneyEndLongitude, 4326)) ASC
) pc
--OPTION (USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'))
;

;WITH y AS (
	SELECT
		 x.*
		,pc.pcd
		,RN = ROW_NUMBER() OVER (PARTITION BY x.Journey_ID ORDER BY pc.Coordinate.STDistance(geography::Point(x.JourneyEndLatitude, x.JourneyEndLongitude, 4326)) ASC)
	FROM dbo.RTS_JourneySummaryFinal x
	LEFT OUTER JOIN dbo.SJ_ONSPostcodeDirectory_202008 pc
		ON pc.Coordinate.STDistance(geography::Point(x.JourneyEndLatitude, x.JourneyEndLongitude, 4326)) <= 2000
)
SELECT *
FROM y
WHERE RN = 1
;

;WITH Polygons AS (
	SELECT
		 PolygonName
		,Polygon
	FROM dbo.SJ_Polygons
	WHERE DetailID = 2
		AND Artist LIKE '%Local%'
)
SELECT TOP (100000)
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
FROM dbo.SJ_PolygonRTJE1 je
INNER JOIN Polygons p
	ON p.Polygon.STIntersects(je.Coordinate) = 1
;

--INSERT dbo.SJ_ONSPostcodeDirectory_202008 WITH ( TABLOCK ) (
--	 Y
--	,X
--	,pcd
--	,rgn
--	,oslaua
--	,dointr
--	,doterm
--	,usertype
--	,osgrdind
--	,ur01ind
--	,imd
--	,Coordinate
--	,Country
--)
--SELECT
--	 Y
--	,X
--	,pcd
--	,rgn
--	,oslaua
--	,dointr
--	,doterm
--	,usertype
--	,osgrdind
--	,ur01ind
--	,imd
--	,CASE WHEN X IS NOT NULL AND Y IS NOT NULL THEN geography::Point(Y, X, 4326) END
--	,Country
--FROM dbo.SJ_ONSPostcodeDirectory_202008_2
--WHERE X IS NOT NULL
--	AND Y IS NOT NULL
--;

--ALTER TABLE dbo.SJ_ONSPostcodeDirectory_202008
--ADD CONSTRAINT PK__SJ_ONSPostcodeDirectory__pcd PRIMARY KEY CLUSTERED ( pcd ASC )
--;


SELECT SUM(NumPoints)
FROM sandbox.dbo.vw_SJ_Polygons
WHERE Artist = 'ONS - Wards (December 2019 Boundaries UK BGC)'
;

SET STATISTICS IO, TIME ON;

SELECT
	 p.PolygonName
	,COALESCE(COUNT(*), 0)
FROM dbo.SJ_Polygons p
INNER JOIN dbo.RTS_JourneySummaryFinal x
	ON p.Polygon.STIntersects(geography::Point(x.JourneyEndLatitude, x.JourneyEndLongitude, 4326)) = 1
WHERE p.Artist = 'ONS - Wards (December 2019 Boundaries UK BGC)'
	AND p.DetailID = 1
GROUP BY p.PolygonName
ORDER BY 2 DESC
;
