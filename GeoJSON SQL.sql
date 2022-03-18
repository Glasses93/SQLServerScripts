
DECLARE @JSON nvarchar(max) =
N'{
"type": "FeatureCollection",
"name": "Wards__December_2019__Boundaries_UK_BGC",
"crs": { "type": "name", "properties": { "name": "urn:ogc:def:crs:OGC:1.3:CRS84" } },
"features": [
]
}'
;

DROP TABLE IF EXISTS #Polygon, #MultiPolygon;

-- Polygons:

SELECT
	 p.PolygonID
	,p.PolygonName
	,p.CountryCode
	,WKT =
		'(' + STUFF((
			SELECT ', ' + JSON_VALUE([value], '$[0]') + ' ' + JSON_VALUE([value], '$[1]')
			FROM OPENJSON(sp.SubPolygons)
			ORDER BY CONVERT(integer, [key]) ASC
			FOR XML PATH('')
		), 1, 2, '') + ')'
INTO #Polygon
FROM OPENJSON(@JSON, '$.features') WITH (
	 PolygonID		smallint		'$.properties.OBJECTID'
	,PolygonName	varchar(100)	'$.properties.WD19NM'
	,CountryCode	varchar(20)		'$.properties.WD19CD'
	,PolygonType	varchar(15)		'$.geometry.type'
	,Polygons		nvarchar(max)	'$.geometry.coordinates' AS JSON
) p
CROSS APPLY (
	SELECT *
	FROM OPENJSON(p.Polygons) WITH (
		SubPolygons	nvarchar(max)	'$' AS JSON
	)
	WHERE p.PolygonType = 'Polygon'
) sp
;

INSERT sandbox.dbo.SJ_Polygons2 (PolygonName, DetailID, DetailDesc, Country, Artist, Polygon)
SELECT
	 PolygonName
	,1
	,'Original'
	,CASE LEFT(CountryCode, 1)
		WHEN 'E' THEN 'England' WHEN 'W' THEN 'Wales' WHEN 'S' THEN 'Scotland' WHEN 'N' THEN 'Northern Ireland'
	 END
	,'ONS - Wards (December 2019 Boundaries UK BGC)'
	,Polygon =
		CASE WHEN
			geography::STGeomFromText(
				'POLYGON (' + STUFF((
					SELECT ', ' + x2.WKT
					FROM #Polygon AS x2
					WHERE x.PolygonID = x2.PolygonID
					FOR XML PATH('')
				), 1, 2, '') + ')'
			, 4326).MakeValid().EnvelopeAngle() >= 90
		THEN
			geography::STGeomFromText(
				'POLYGON (' + STUFF((
					SELECT ', ' + x2.WKT
					FROM #Polygon AS x2
					WHERE x.PolygonID = x2.PolygonID
					FOR XML PATH('')
				), 1, 2, '') + ')'
			, 4326).MakeValid().ReorientObject()
		ELSE
			geography::STGeomFromText(
				'POLYGON (' + STUFF((
					SELECT ', ' + x2.WKT
					FROM #Polygon AS x2
					WHERE x.PolygonID = x2.PolygonID
					FOR XML PATH('')
				), 1, 2, '') + ')'
			, 4326).MakeValid()
		END
FROM #Polygon x
GROUP BY
	 PolygonID
	,PolygonName
	,CountryCode
;

-- MultiPolygon:

;WITH x AS (
	SELECT
		 p.PolygonID
		,p.PolygonName
		,p.CountryCode
		,mp.MultiPolygons
		,WKT =
			'(' + STUFF((
				SELECT ', ' + JSON_VALUE([value], '$[0]') + ' ' + JSON_VALUE([value], '$[1]')
				FROM OPENJSON(sp.SubPolygons)
				ORDER BY CONVERT(integer, [key]) ASC
				FOR XML PATH('')
			), 1, 2, '') + ')'
	FROM OPENJSON(@JSON, '$.features') WITH (
		 PolygonID		smallint		'$.properties.OBJECTID'
		,PolygonName	varchar(100)	'$.properties.WD19NM'
		,CountryCode	varchar(20)		'$.properties.WD19CD'
		,PolygonType	varchar(15)		'$.geometry.type'
		,Polygons		nvarchar(max)	'$.geometry.coordinates' AS JSON
	) p
	CROSS APPLY (
		SELECT *
		FROM OPENJSON(p.Polygons) WITH (
			MultiPolygons	nvarchar(max)	'$' AS JSON
		)
		WHERE p.PolygonType = 'MultiPolygon'
	) mp
	CROSS APPLY OPENJSON(mp.MultiPolygons) WITH (
		SubPolygons	nvarchar(max)	'$' AS JSON
	) sp
)
SELECT
	 PolygonID
	,PolygonName
	,CountryCode =
		CASE LEFT(CountryCode, 1)
			WHEN 'E' THEN 'England' WHEN 'W' THEN 'Wales' WHEN 'S' THEN 'Scotland' WHEN 'N' THEN 'Northern Ireland'
		END
	,WKT =
		'(' + STUFF((
			SELECT ', ' + x2.WKT
			FROM x AS x2
			WHERE x.PolygonID       = x2.PolygonID
				AND x.MultiPolygons = x2.MultiPolygons
			FOR XML PATH('')
		), 1, 2, '') + ')'
INTO #MultiPolygon
FROM x
GROUP BY
	 PolygonID
	,PolygonName
	,MultiPolygons
	,CASE LEFT(CountryCode, 1)
		WHEN 'E' THEN 'England' WHEN 'W' THEN 'Wales' WHEN 'S' THEN 'Scotland' WHEN 'N' THEN 'Northern Ireland'
	 END
;

INSERT sandbox.dbo.SJ_Polygons2 (PolygonName, DetailID, DetailDesc, Country, Artist, Polygon)
SELECT
	 PolygonName
	,1
	,'Original'
	,CountryCode
	,'ONS - Wards (December 2019 Boundaries UK BGC)'
	,CASE WHEN
		geography::STGeomFromText(
			'MULTIPOLYGON (' + STUFF((
				SELECT ', ' + y2.WKT
				FROM #MultiPolygon AS y2
				WHERE y.PolygonID = y2.PolygonID
				FOR XML PATH('')
			), 1, 2, '') + ')'
		, 4326).MakeValid().EnvelopeAngle() >= 90
	 THEN
		geography::STGeomFromText(
			'MULTIPOLYGON (' + STUFF((
				SELECT ', ' + y2.WKT
				FROM #MultiPolygon AS y2
				WHERE y.PolygonID = y2.PolygonID
				FOR XML PATH('')
			), 1, 2, '') + ')'
		, 4326).MakeValid().ReorientObject()
	 ELSE
		geography::STGeomFromText(
			'MULTIPOLYGON (' + STUFF((
				SELECT ', ' + y2.WKT
				FROM #MultiPolygon AS y2
				WHERE y.PolygonID = y2.PolygonID
				FOR XML PATH('')
			), 1, 2, '') + ')'
		, 4326).MakeValid()
	 END
FROM #MultiPolygon y
GROUP BY
	 PolygonID
	,PolygonName
	,CountryCode
;
