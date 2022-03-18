SELECT *
FROM sandbox.dbo.vw_SJ_Polygons
;

SELECT Polygon.ToString()
FROM sandbox.dbo.SJ_Polygons
WHERE PolygonName IN ('Vale of White Horse')
	AND DetailID IN (2, 4)
;

--SET STATISTICS IO, TIME ON;
--SET STATISTICS IO, TIME OFF;

;WITH x AS (
	SELECT
		 Polygon
		,PolygonName
	FROM sandbox.dbo.SJ_Polygons
	WHERE PolygonName IN ('Vale of White Horse', 'Broadland')
		AND DetailID = 4
)
SELECT
	 EventTimeStamp
	,DeltaTripDistance
	,Coordinate = geography::Point(t.Latitude, t.Longitude, 4326)
INTO #Temp
FROM staging.dbo.VodaTrip_RAW t
WHERE EXISTS (
	SELECT 1
	FROM x
	WHERE x.Polygon.STIntersects(geography::Point(t.Latitude, t.Longitude, 4326)) = 1
)
;

;WITH x AS (
	SELECT
		 Polygon
		,PolygonName
	FROM sandbox.dbo.SJ_Polygons
	WHERE PolygonName IN ('Vale of White Horse', 'Broadland')
		AND DetailID = 1
)
SELECT
	 x.PolygonName
	,t.EventTimeStamp
	,t.DeltaTripDistance
FROM #Temp t
INNER JOIN x
	ON x.Polygon.STIntersects(t.Coordinate) = 1
;

select polygon.ToString()
from sandbox.dbo.SJ_Polygons
where polygonname = 'Monmouthshire'
and detailid = 4
;



;WITH x AS (
	SELECT
		 Polygon
		,PolygonName
	FROM sandbox.dbo.SJ_Polygons
	WHERE PolygonName IN ('Vale of White Horse')
		AND DetailID = 4
)
SELECT t.*
FROM sandbox.dbo.RTS_JourneySummaryFinal t
INNER JOIN x
	ON x.Polygon.STIntersects(geography::Point(t.JourneyStartLatitude, t.JourneyStartLongitude, 4326)) = 1
;
