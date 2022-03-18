
USE sandbox;

INSERT dbo.SJ_PolygonRTJE1 WITH (TABLOCK) (
IMEI, Journey_ID, JourneyEvent_RawID, EventOrder, EventTimeStamp, TimeElapsed, Latitude, Longitude, Coordinate, DistanceFromPrevPosition, TravelSpeedMPH, HaversineMetresDriven
)
SELECT
IMEI, Journey_ID, JourneyEvent_RawID, EventOrder, EventTimeStamp, TimeElapsed, Latitude, Longitude, Coordinate, DistanceFromPrevPosition, TravelSpeedMPH, HaversineMetresDriven
FROM staging.dbo.PolygonRTJE1
;

ALTER TABLE dbo.SJ_PolygonRTJE1 ADD CONSTRAINT PK PRIMARY KEY (Journey_ID ASC, JourneyEvent_RawID ASC);

CREATE SPATIAL INDEX SIX
ON dbo.SJ_PolygonRTJE1 (Coordinate)
USING GEOGRAPHY_GRID WITH (
	 GRIDS			  = (LEVEL_1 = HIGH, LEVEL_2 = HIGH, LEVEL_3 = HIGH, LEVEL_4 = HIGH)
	,CELLS_PER_OBJECT = 8192
)
;

;WITH p AS (
	SELECT
		 PolygonName
		,Polygon
	FROM dbo.SJ_Polygons
	WHERE (
			(Artist = 'ONS - Wards (December 2019 Boundaries UK BGC)'                AND DetailID = 1)
		OR	(Artist = 'ONS - Local Authority Districts (May 2020 Boundaries UK BFE)' AND DetailID = 2)
	)
)
SELECT
	 PolygonName = COALESCE(p.PolygonName, 'Not mapped')
	,je.*
INTO dbo.SJ_PolygonRTJE2
FROM dbo.SJ_PolygonRTJE1 je
INNER JOIN p
	ON p.Polygon.STIntersects(geography::Point(
		 CASE WHEN je.Latitude  BETWEEN -90  AND 90  THEN je.Latitude  ELSE -90 END
		,CASE WHEN je.Longitude BETWEEN -180 AND 180 THEN je.Longitude ELSE 180 END
		,4326
	)) = 1
;


SELECT PolygonName, SUM(DistanceFromPrevPosition) / 1609.344, AVG(TravelSpeedMPH * 1.0)
FROM dbo.SJ_PolygonRTJE2
GROUP BY PolygonName
ORDER BY 3 DESC
;
