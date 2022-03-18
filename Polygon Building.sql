
DECLARE @Poly geography = geography::STGeomFromText(

'POLYGON((

))'

,4326)

--.MakeValid()
.ReorientObject()
.Reduce(8)
;


SELECT @Poly.STNumPoints();

IF @Poly.STIsValid() = 1
SELECT Test = @Poly.STIntersects(geography::Point(

51.712098, -3.921945

, 4326));

IF @Poly.STIsValid() = 
1
BEGIN

INSERT sandbox.dbo.SJ_Polygons (PolygonName, Artist, OSMIdentity, Polygon, ETL)
SELECT
	 LTRIM(RTRIM('   Caerphilly '))
	,      LTRIM(RTRIM(  '    OSM - Original (Reduced) '))
	,         2750677
	,@Poly
	,0

;

END
;

SELECT
	 PolygonName
	,Artist
	,OSMIdentity
	,Valid
	,NumPoints
	,NumPolygons
	,Length
	,SurfaceArea
	,SRID
	,ETL
	,InsertedDate
FROM sandbox.dbo.SJ_Polygons
ORDER BY InsertedDate DESC
;





/*
-- DROP TABLE sandbox.dbo.SJ_Polygons;
CREATE TABLE sandbox.dbo.SJ_Polygons (
	 PolygonName																varchar(100)	NOT NULL
	,Artist																		varchar(100)	NOT NULL
	,OSMIdentity																integer	        	NULL
	,Polygon																	geography		NOT NULL
	,Valid        AS CONVERT(bit     , Polygon.STIsValid()          ) PERSISTED								CONSTRAINT CHK_SJPolygons_Valid CHECK ( Valid = 1 AND Valid IS NOT NULL )
	,NumPoints    AS CONVERT(integer , Polygon.STNumPoints()        ) PERSISTED
	,NumPolygons  AS CONVERT(tinyint , Polygon.STNumGeometries()    ) PERSISTED
	,Length       AS (     Polygon.STLength() * 0.000621371         ) PERSISTED
	,SurfaceArea  AS (     Polygon.STArea()   * SQUARE(0.000621371) ) PERSISTED
	,SRID         AS CONVERT(smallint, Polygon.STSrid               ) PERSISTED								CONSTRAINT CHK_SJPolygons_SRID CHECK ( SRID = 4326 AND SRID IS NOT NULL )
	,ETL																		bit				NOT NULL
	,InsertedDate																smalldatetime	NOT NULL	CONSTRAINT DF_SJPolygons_InsertedDate DEFAULT CURRENT_TIMESTAMP

	,CONSTRAINT PK_SJPolygons_PolygonNameArtist PRIMARY KEY CLUSTERED (
		 PolygonName ASC
		,Artist      ASC
	 )
)
;

CREATE SPATIAL INDEX IX_SJPolygons_Polygon
ON sandbox.dbo.SJ_Polygons (Polygon)
;

CREATE OR ALTER TRIGGER dbo.TR_SJPolygons
ON sandbox.dbo.SJ_Polygons
INSTEAD OF INSERT, UPDATE, DELETE
AS
	PRINT 'Computer says no...' + REPLICATE(CHAR(13), 5) + '...Speak to Steve.';
GO

DISABLE TRIGGER dbo.TR_SJPolygons
ON sandbox.dbo.SJ_Polygons
;

ENABLE TRIGGER dbo.TR_SJPolygons
ON sandbox.dbo.SJ_Polygons
;

SELECT *
FROM sandbox.sys.Triggers t1
INNER JOIN sandbox.sys.Trigger_Events t2
	ON t1.Object_ID = t2.Object_ID
;
*/