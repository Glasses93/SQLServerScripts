
/*
Database compatibility level of 110 or more is required for building polygons spanning more than a single hemisphere
(not that you're planning on doing that)
however I'm certain we can still insert them into Sandbox from another compatible database #confused.
*/

USE DNA;



-- Store polygon in a variable (which only lives as long as the query batch) in order to test/insert:
DECLARE @Polygon GEOGRAPHY =

GEOGRAPHY::STGeomFromText(

'POLYGON((

-- Insert single polygon WKT data here following the left-hand rule = Longitude1 Latitude1, Longitude2 Latitude2, ..., Longitude1 Latitude1:



))'

,4326
)
-- Uncomment this function if the polygon is oriented the wrong way:
--.ReorientObject()
;



-- Store test points in a variable (which only lives as long as the query batch) to test against polygon:
DECLARE @Point GEOGRAPHY =

GEOGRAPHY::Point(

-- Insert Latitude and Longitude (respectively) of test points here = Latitude, Longitude:
51.883353, -3.450928

,4326
)
;



-- Test validity of the polygon:
SELECT [Valid Polygon?] = @Polygon.STIsValid();

-- Test validity of the point:
SELECT [Valid Point?]   = @Point.STIsValid();

-- If both of the above are valid, run the test:
SELECT [Point Inside Polygon?] = @Polygon.STIntersects( @Point );





/*
If test is successful, insert the polygon into your table while naming the other three columns appropriately.
Feel free to get rid of the OSMIdentity column as it isn't mandatory.
*/

INSERT Sandbox.dbo.EB_Polygons (PolygonName, Artist, Polygon, OSMIdentity)
SELECT
	'Steve''s Park'
	,'OSM - Original'
	,@Polygon
	,357283
;


/*
In order to produce a simpler (fewer points) polygon, consider the Reduce() function:
https://docs.microsoft.com/en-us/sql/t-sql/spatial-geography/reduce-geography-data-type?view=sql-server-ver15

The higher you take x in the below function, the fewer points there are in the polygon.
I tend to reduce polygons to around the 1,000 points mark, but do so as you see fit.
Once you find a suitable x value, insert this now reduced polygon into your table (remember to change the polygon name and x value in the insert statement also).
*/

SELECT ReducedPolygonPoints = ( SELECT Polygon FROM Sandbox.dbo.EB_Polygons WHERE PolygonName = 'The polygon you most recently inserted' ).Reduce(x).STNumPoints();



INSERT Sandbox.dbo.EB_Polygons (PolygonName, Artist, Polygon, OSMIdentity)
SELECT
	'Steve''s Park'
	,'OSM - Original (reduced)'
	,( SELECT Polygon FROM Sandbox.dbo.EB_Polygons WHERE PolygonName = 'The polygon you most recently inserted' ).Reduce(x)
	,357283
;











-- Typical use case:

;WITH Polygons AS (
	SELECT
		 PolygonName
		,Artist
		,Polygon
	FROM Sandbox.dbo.EB_Polygons
	WHERE Valid = 1
		AND SRID = 4326
		AND PolygonName IN (
			 'Brecon Beacons National Park'
			/*
			,''
			,''
			*/
		)
		/*
		If you're returning more than one version of the same polygon (i.e. reduced and original) be wary of
		minor contradictory results on the polygon borders:
		*/
		AND Artist LIKE 'OSM - Original%Reduce%'
)
SELECT
	 p.PolygonName
	,p.Artist
	,js.PolicyNumber
	,js.IMEI
	,js.Journey_ID
	,js.JourneyStartTime
	,js.JourneyEndTime
	,js.JourneyEndLatitude
	,js.JourneyEndLongitude
-- This table is built each day by the RedTail Score - you're welcome to SELECT from it but try not to modify it!:
FROM Sandbox.dbo.RTS_JourneySummaryFinal js
INNER JOIN Polygons p
	ON p.Polygon.STIntersects(GEOGRAPHY::Point(js.JourneyEndLatitude, js.JourneyEndLongitude, 4326)) = 1
;












-- Table definition:

/*
--DROP TABLE IF EXISTS Sandbox.dbo.EB_Polygons;

CREATE TABLE Sandbox.dbo.EB_Polygons (
	 PolygonName	VARCHAR(50)		NOT NULL
	,Artist			VARCHAR(30)		NOT NULL
	,Polygon		GEOGRAPHY		NOT NULL

	,Valid 			AS Polygon.STIsValid()						PERSISTED 	CONSTRAINT CHK_EBPolygons_Valid CHECK (Valid = 1 AND Valid IS NOT NULL)
	,NumPoints 		AS Polygon.STNumPoints()					PERSISTED
	,NumPolygons	AS Polygon.STNumGeometries()				PERSISTED
	,Length       	AS Polygon.STLength() *        0.000621371	PERSISTED
	,SurfaceArea  	AS Polygon.STArea()   * SQUARE(0.000621371)	PERSISTED
	,SRID         	AS CAST(Polygon.STSrid AS SMALLINT) 		PERSISTED	CONSTRAINT CHK_EBPolygons_SRID CHECK (SRID = 4326 AND SRID IS NOT NULL)
	
	,OSMIdentity	INT					NULL
	,InsertedDate	SMALLDATETIME	NOT NULL								CONSTRAINT DF_EBPolygons_InsertedDate DEFAULT GETDATE()

	CONSTRAINT PK_EBPolygons_PolygonNameArtist PRIMARY KEY CLUSTERED (PolygonName ASC, Artist ASC)
)
;

CREATE SPATIAL INDEX IX_EBPolygons_Polygon ON Sandbox.dbo.EB_Polygons (Polygon);
*/
