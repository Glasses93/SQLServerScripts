
EXEC sys.sp_executesql
N'
SELECT
	 [Database] = DB_NAME()
	,[Schema]   = s.[name]
	,[Table]    = t.[name]
	,[Index]    = i.[name]
	,ips.*
FROM sys.schemas s
INNER JOIN sys.tables t
	ON s.[schema_id] = t.[schema_id]
INNER JOIN sys.indexes i
	ON t.[object_id] = i.[object_id]
CROSS APPLY sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID(QUOTENAME(s.[name]) + N''.'' + QUOTENAME(t.[name])), i.[index_id], NULL, N''DETAILED'') ips
WHERE t.[name] = @tbl
ORDER BY [Schema], ips.[index_id], ips.[index_level], ips.[alloc_unit_type_desc]
;'
,N'@tbl sysname'
,Dates

