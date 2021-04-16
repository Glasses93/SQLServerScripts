SELECT srv = @@SERVERNAME, db = DB_NAME(), sch = s.[name], tbl = t.[name], stat = st.[name], [stats_date] = STATS_DATE(st.[object_id], st.[stats_id]), ddsh.*
FROM sys.schemas s
INNER JOIN sys.tables t
	ON s.[schema_id] = t.[schema_id]
INNER JOIN sys.stats st
	ON t.[object_id] = st.[object_id]
CROSS APPLY sys.dm_db_stats_histogram(st.[object_id], st.[stats_id]) ddsh
WHERE t.[name] = N'SJ_Polygons'
ORDER BY s.[name], st.[name] DESC, ddsh.[step_number]
;

SELECT
	 srv	= @@SERVERNAME
	,db		= DB_NAME()
	,sch	= s.[name]
	,tbl	= t.[name]
	,stat	= st.[name]
	,col	= c.[name]
	,st.*
FROM sys.schemas s
INNER JOIN sys.tables t
	ON s.[schema_id] = t.[schema_id]
INNER JOIN sys.columns c
	ON t.[object_id] = c.[object_id]
INNER JOIN sys.stats st
	ON t.[object_id] = st.[object_id]
INNER JOIN sys.stats_columns sc
	ON  t.[object_id] = sc.[object_id]
	AND st.[stats_id] = sc.[stats_id]
	AND c.[column_id] = sc.[column_id]
WHERE s.[name] = N'dbo'
	AND t.[name] = N'AppAssociation'
ORDER BY sch, st.[stats_id], c.[column_id]
;
