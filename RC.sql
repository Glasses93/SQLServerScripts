DECLARE @SQL nvarchar(max) = N'';

SELECT @SQL +=
N'UNION ALL
SELECT
	 [Database] = N''' + name + N'''
	,[Schema]   = s.name
	,[Table]    = t.name
	,[RowCount] = SUM(p.rows)
	,[RowCountFormatted] = FORMAT(SUM(p.rows), ''N0'')
FROM ' + QUOTENAME(name) + N'.sys.schemas s
INNER JOIN ' + QUOTENAME(name) + N'.sys.tables t
	ON  s.schema_id = t.schema_id
INNER JOIN ' + QUOTENAME(name) + N'.sys.partitions p
	ON  t.object_id = p.object_id
	AND p.index_id IN (0, 1)
GROUP BY
	 t.name
	,s.name
'
FROM sys.databases
WHERE name NOT IN (N'master', N'model', N'msdb', N'tempdb', N'AdmiralDBA')
;

SELECT @SQL = STUFF(@SQL, 1, 11, N'');

SELECT @SQL +=
N'ORDER BY
	 [Database]  ASC
	,[RowCount] DESC
;'
;

PRINT SUBSTRING(@SQL, 1      , 4000 );
PRINT SUBSTRING(@SQL, 4001 , 8000 );
PRINT SUBSTRING(@SQL, 8001 , 12000);
PRINT SUBSTRING(@SQL, 12001, 16000);
EXEC sys.sp_executesql @SQL;