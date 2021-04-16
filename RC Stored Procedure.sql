CREATE OR ALTER PROCEDURE dbo.SJ_RowCounts
	 @DBName	sysname = NULL
	,@Lower		bigint  = 0
	,@Upper 	bigint  = 9223372036854775807
	,@Debug		bit		= 0
AS
BEGIN

SET NOCOUNT ON;

DECLARE @SQL nvarchar(max) = N'';

IF @DBName IS NOT NULL
	AND DB_ID(@DBName) IS NULL
BEGIN
	PRINT 'There is no database by this name on this server.';
	RETURN;
END
;

IF @DBName IS NOT NULL
	AND DB_ID(@DBName) IS NOT NULL
BEGIN
DECLARE @Context nvarchar(200) = QUOTENAME(@DBName) + N'.sys.sp_executesql';

SELECT @SQL = N'
SELECT
	 [Database]          = @DBName
	,[Schema]            = s.name
	,[Table]             = t.name
	,[RowCount]          = SUM(p.rows)
	,[RowCountFormatted] = FORMAT(SUM(p.rows), ''N0'')
FROM sys.schemas s WITH ( NOLOCK )
INNER JOIN sys.tables t WITH ( NOLOCK )
	ON  s.schema_id = t.schema_id
INNER JOIN sys.partitions p WITH ( NOLOCK )
	ON  t.object_id = p.object_id
	AND p.index_id IN (0, 1)
GROUP BY
	 t.name
	,s.name
HAVING SUM(p.rows) BETWEEN @Lower AND @Upper
ORDER BY
	 [Database]  ASC
	,[RowCount] DESC
;'
;

EXEC @Context
	 @SQL
	,N'@DBName sysname, @Lower bigint, @Upper bigint'
	,@DBName
	,@Lower
	,@Upper
;

IF @Debug = 1
BEGIN
	PRINT @SQL;
	PRINT @Context;
END
;
END
;

IF @DBName IS NULL
BEGIN
SELECT @SQL +=
N'UNION ALL
SELECT
	 [Database]          = N''' + name + N'''
	,[Schema]            = s.name
	,[Table]             = t.name
	,[RowCount]          = SUM(p.rows)
	,[RowCountFormatted] = FORMAT(SUM(p.rows), ''N0'')
FROM ' + QUOTENAME(name) + N'.sys.schemas s WITH ( NOLOCK )
INNER JOIN ' + QUOTENAME(name) + N'.sys.tables t WITH ( NOLOCK )
	ON  s.schema_id = t.schema_id
INNER JOIN ' + QUOTENAME(name) + N'.sys.partitions p WITH ( NOLOCK )
	ON  t.object_id = p.object_id
	AND p.index_id IN (0, 1)
GROUP BY
	 t.name
	,s.name
HAVING SUM(p.rows) BETWEEN @Lower AND @Upper
'
FROM sys.databases WITH ( NOLOCK )
WHERE name NOT IN (N'master', N'model', N'msdb', N'tempdb', N'AdmiralDBA')
;

SELECT @SQL = STUFF(@SQL, 1, 11, N'');

SELECT @SQL +=
N'ORDER BY
	 [Database]  ASC
	,[RowCount] DESC
;'
;

IF @Debug = 1
BEGIN
	PRINT SUBSTRING(@SQL, 1    , 4000 );
	PRINT SUBSTRING(@SQL, 4001 , 8000 );
	PRINT SUBSTRING(@SQL, 8001 , 12000);
	PRINT SUBSTRING(@SQL, 12001, 16000);
END
;

EXEC sys.sp_executesql
	 @SQL
	,N'@Lower bigint, @Upper bigint'
	,@Lower
	,@Upper
;
END
;
	
END
;
