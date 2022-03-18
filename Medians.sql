
--SET STATISTICS IO, TIME ON;

SELECT TOP (1) PC = PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY NumPoints ASC) OVER ()
FROM dbo.vw_SJ_Polygons
;

--SELECT TOP (1) PC = PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY n ASC) OVER ()
--FROM (
--	SELECT n
--	FROM dbo.Numbers
--	UNION ALL
--	SELECT 32768
--) a
--;

--DECLARE @RC smallint = (SELECT COUNT(*) FROM dbo.vw_SJ_Polygons);
DECLARE @RC smallint;
SELECT @RC = SUM(p.[rows])
FROM sys.schemas s
INNER JOIN sys.tables t
	ON s.[schema_id] = t.[schema_id]
INNER JOIN sys.partitions p
	ON t.[object_id] = p.[object_id]
WHERE s.[name] = N'dbo'
	AND t.[name] = N'SJ_Polygons'
	AND p.[index_id] IN (0, 1)
;

SELECT Median = AVG(NumPoints * 1.0)
FROM (
	SELECT NumPoints
	FROM dbo.vw_SJ_Polygons
	ORDER BY NumPoints ASC
	OFFSET (@RC - 1) / 2 ROWS
	FETCH NEXT 2 - (@RC % 2) ROWS ONLY
) a
;
