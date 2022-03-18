
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
	 p.PolygonName
	,Journeys = COUNT(*)
	,Risks    = COUNT(DISTINCT jsf.PolicyNumber)
FROM dbo.RTS_JourneySummaryFinal jsf
INNER JOIN p
	ON p.Polygon.STIntersects(geography::Point(
		 CASE WHEN jsf.JourneyEndLatitude  BETWEEN -90  AND 90  THEN jsf.JourneyEndLatitude  ELSE -90 END
		,CASE WHEN jsf.JourneyEndLongitude BETWEEN -180 AND 180 THEN jsf.JourneyEndLongitude ELSE 180 END
		,4326
	)) = 1
LEFT JOIN dbo.SJ_BatchModeEnabler bme
	ON 1 = 0
GROUP BY p.PolygonName
ORDER BY 3 DESC
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
	 p.PolygonName
	,Journeys = COUNT(*)
	,Risks    = COUNT(DISTINCT jsf.PolicyNumber)
FROM dbo.RTS_JourneySummaryFinal jsf
INNER JOIN p
	ON p.Polygon.STIntersects(geography::Point(
		 CASE WHEN jsf.JourneyEndLatitude  BETWEEN -90  AND 90  THEN jsf.JourneyEndLatitude  ELSE -90 END
		,CASE WHEN jsf.JourneyEndLongitude BETWEEN -180 AND 180 THEN jsf.JourneyEndLongitude ELSE 180 END
		,4326
	)) = 1
GROUP BY p.PolygonName
ORDER BY 3 DESC
;


SELECT Polygon.ToString(), Centroid
FROM dbo.SJ_Polygons
WHERE PolygonName = 'Davyhulme East'
	AND DetailID = 1
;

select *
from dbo.vw_SJ_Polygons



