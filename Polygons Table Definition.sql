
USE staging;

CREATE TABLE staging.dbo.Polygons (
	 PolygonName																varchar(40)		NOT NULL
	,Artist																		varchar(40)		NOT NULL
	,OSMIdentity																int		        	NULL
	,Polygon																	geography		NOT NULL
	,Valid        AS CONVERT(bit     , Polygon.STIsValid()      ) PERSISTED									CONSTRAINT CHK_Polygons_Valid CHECK ( Valid = 1 AND Valid IS NOT NULL )
	,NumPoints    AS CONVERT(int     , Polygon.STNumPoints()    ) PERSISTED
	,NumPolygons  AS CONVERT(tinyint , Polygon.STNumGeometries()) PERSISTED
	,Length       AS Polygon.STLength() * 0.000621371         	  PERSISTED
	,SurfaceArea  AS Polygon.STArea()   * SQUARE(0.000621371) 	  PERSISTED
	,SRID         AS CONVERT(smallint, Polygon.STSrid) 			  PERSISTED									CONSTRAINT CHK_Polygons_SRID CHECK ( SRID = 4326 AND SRID IS NOT NULL )
	,ETL																		bit				NOT NULL
	,InsertedDate																smalldatetime	NOT NULL	CONSTRAINT DF_Polygons_InsertedDate DEFAULT CURRENT_TIMESTAMP

	CONSTRAINT PK_Polygons_PolygonNameArtist PRIMARY KEY CLUSTERED (PolygonName ASC, Artist ASC)
)
;

CREATE SPATIAL INDEX IX_Polygons_Polygon ON staging.dbo.Polygons (Polygon);

INSERT staging.dbo.Polygons (PolygonName, Artist, Polygon, ETL)
SELECT
	 PolygonName
	,Artist
	,Polygon
	,ETL
FROM sandbox.dbo.SJ_Polygons
WHERE (
		ETL = 1
	OR  PolygonName = 'British Isles'
)
;