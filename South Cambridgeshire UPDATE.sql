SELECT PolygonName, Polygon.ToString()
FROM sandbox.dbo.SJ_Polygons
WHERE DetailID = 2
	AND PolygonName IN ('Cambridge', 'South Cambridgeshire')
;

PRINT @@TRANCOUNT;

BEGIN TRAN;

DELETE dbo.SJ_Polygons
WHERE PolygonName = 'South Cambridgeshire'
	AND DetailID IN (2, 3)
;

UPDATE p1
	SET p1.Polygon = p1.Polygon.STDifference(p2.Polygon)
FROM sandbox.dbo.SJ_Polygons p1
INNER JOIN sandbox.dbo.SJ_Polygons p2
	ON  p1.PolygonName = 'South Cambridgeshire'
	AND p2.PolygonName = 'Cambridge'
	AND p1.DetailID = 1
	AND p2.DetailID = 1
;

INSERT dbo.SJ_Polygons (PolygonName, Artist, DetailID, DetailDesc, Country, Polygon)
SELECT PolygonName, Artist, 2, 'Reduce(100)', Country, Polygon.Reduce(100)
FROM dbo.SJ_Polygons
WHERE PolygonName = 'South Cambridgeshire'
	AND DetailID = 1
UNION ALL
SELECT PolygonName, Artist, 3, 'Reduced(1000)', Country, Polygon.Reduce(1000)
FROM dbo.SJ_Polygons
WHERE PolygonName = 'South Cambridgeshire'
	AND DetailID = 1
;

SELECT DetailID, Polygon.ToString()
FROM dbo.SJ_Polygons
WHERE PolygonName = 'South Cambridgeshire'
;

-- COMMIT TRAN;
-- ROLLBACK TRAN;

-- ALTER TABLE dbo.SJ_Polygons ENABLE TRIGGER TR_DML_Polygons;