
;WITH g AS (
	SELECT
		 t.*
		,Points = CASE WHEN t.Latitude IS NOT NULL AND t.Longitude IS NOT NULL THEN geography::Point(t.Latitude, t.Longitude, 4326) END
		,rn     = ROW_NUMBER() OVER (PARTITION BY t.Latitude, t.Longitude ORDER BY (SELECT NULL))
	FROM Vodafone.dbo.Trip_COVID t
	LEFT JOIN dbo.SJ_BatchModeEnabler bme
		ON 1 = 0
	WHERE t.Latitude IS NOT NULL
		AND t.Longitude IS NOT NULL
)
INSERT dbo.SJ_VFRoadData WITH (TABLOCK) (
	 RoadID
	,Country
	,County
	,City
	,PostCode
	,Street
	,StreetType
	,RoadSpeedLimit
	,Points
)
SELECT
	 RoadID = CONVERT(integer, ISNULL(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)), -1))
	,Country
	,County
	,City
	,PostCode
	,Street
	,StreetType     = CONVERT(char(1), StreetType)
	,RoadSpeedLimit = CONVERT(tinyint, RoadSpeedLimit)
	,Points         = geography::UnionAggregate(Points)
--INTO dbo.SJ_VFRoadData
FROM g
--WHERE 1 = 2
WHERE rn = 1
GROUP BY
	 Country
	,County
	,City
	,PostCode
	,Street
	,StreetType
	,RoadSpeedLimit
;

-- 1089563

ALTER TABLE dbo.SJ_VFRoadData
ADD CONSTRAINT PK__SJ_VFRoadData__RoadID PRIMARY KEY CLUSTERED (RoadID ASC)
;

CREATE SPATIAL INDEX SIX2__SJ_VFRoadData__Points
ON dbo.SJ_VFRoadData (Points)
--USING GEOGRAPHY_GRID WITH (
--	 GRIDS = (
--		 LEVEL_1 = HIGH
--		,LEVEL_2 = HIGH
--		,LEVEL_3 = HIGH
--		,LEVEL_4 = HIGH
--	 )
--	,CELLS_PER_OBJECT = 8192
--)
;

INSERT dbo.SJ_VFRoadData2 WITH (TABLOCK) (
	 RoadID
	,Country
	,County
	,City
	,PostCode
	,Street
	,StreetType
	,RoadSpeedLimit
	,Points
)
SELECT
	 a.RoadID
	,a.Country
	,a.County
	,a.City
	,a.PostCode
	,a.Street
	,a.StreetType
	,a.RoadSpeedLimit
	,Points = CASE WHEN ca.ls LIKE 'LINESTRING%' THEN geography::STGeomFromText(ca.ls, 4326) ELSE a.Points END
FROM dbo.SJ_VFRoadData a
CROSS APPLY (
	SELECT ls = REPLACE(REPLACE(REPLACE(REPLACE(a.Points.ToString(), N'MULTIPOINT', N'LINESTRING'), N'), (', N','), N' (', N' '), N'))', N')')
) ca
;

DROP TABLE dbo.SJ_VFRoadData;

EXEC sys.sp_rename N'dbo.SJ_VFRoadData2', N'SJ_VFRoadData', 'OBJECT';

ALTER TABLE dbo.SJ_VFRoadData
ADD CONSTRAINT PK__SJ_VFRoadData__RoadID PRIMARY KEY CLUSTERED (RoadID ASC)
;

CREATE SPATIAL INDEX SIX__SJ_VFRoadData__Points
ON dbo.SJ_VFRoadData (Points)
;

SELECT
	 jsf.PolicyNumber
	,jsf.IMEI
	,jsf.Journey_ID
	,jsf.JourneyStartTime
	,jsf.JourneyEndTime
	,jsf.JourneyEndLatitude
	,jsf.JourneyEndLongitude
	,ca.*
FROM dbo.RTS_JourneySummaryFinal jsf
LEFT JOIN dbo.SJ_BatchModeEnabler bme
	ON 1 = 0
OUTER APPLY (
	SELECT TOP (1)
		 rd.Country
		,rd.County
		,rd.City
		,rd.Street
		,rd.RoadSpeedLimit
		,rd.PostCode
	FROM dbo.SJ_VFRoadData rd
	WHERE rd.Points.STDistance(geography::Point(jsf.JourneyEndLatitude, jsf.JourneyEndLongitude, 4326)) <= 100
	ORDER BY rd.Points.STDistance(geography::Point(jsf.JourneyEndLatitude, jsf.JourneyEndLongitude, 4326)) ASC
) ca
WHERE jsf.Journey_ID = 102966464
ORDER BY ca.RoadSpeedLimit ASC
--OPTION (RECOMPILE)
;

;WITH x AS (
	SELECT
		 *
		,rn = ROW_NUMBER() OVER (PARTITION BY jsf.Journey_ID ORDER BY rd.Points.STDistance(geography::Point(jsf.JourneyEndLatitude, jsf.JourneyEndLongitude, 4326)) ASC)
	FROM dbo.RTS_JourneySummaryFinal jsf
	LEFT JOIN dbo.SJ_VFRoadData rd
		ON rd.Points.STDistance(geography::Point(jsf.JourneyEndLatitude, jsf.JourneyEndLongitude, 4326)) <= 100
	LEFT JOIN dbo.SJ_BatchModeEnabler bme
		ON 1 = 0
	WHERE jsf.Journey_ID = 102966464
)
SELECT
	 PolicyNumber
	,IMEI
	,Journey_ID
	,JourneyStartTime
	,JourneyEndTime
	,JourneyEndLatitude
	,JourneyEndLongitude
	,Country
	,County
	,City
	,Street
	,RoadSpeedLimit
	,PostCode
FROM x
WHERE RN = 1
ORDER BY RoadSpeedLimit ASC
;

select top 1 * from dbo.RTS_JourneySummaryFinal


SELECT
	 jsf.PolicyNumber
	,jsf.IMEI
	,jsf.Journey_ID
	,jsf.JourneyStartTime
	,jsf.JourneyEndTime
	,jsf.JourneyEndLatitude
	,jsf.JourneyEndLongitude
	,ca.*
FROM dbo.RTS_JourneySummaryFinal jsf
OUTER APPLY (
	SELECT TOP (1)
		 rd.Street
		,rd.RoadSpeedLimit
		,rd.PostCode
	FROM dbo.SJ_VFRoadData rd
	WHERE rd.Points.STDistance(geography::Point(jsf.JourneyEndLatitude, jsf.JourneyEndLongitude, 4326)) <= 50
	ORDER BY rd.Points.STDistance(geography::Point(jsf.JourneyEndLatitude, jsf.JourneyEndLongitude, 4326)) ASC
) ca
ORDER BY ca.RoadSpeedLimit ASC
;

