
CREATE TABLE #YEET (
	 ThreePartID nvarchar(400) PRIMARY KEY CLUSTERED
	,Commands    nvarchar(max)
)
;

DECLARE @SQL nvarchar(max) = N'';

SELECT @SQL += N'
;WITH c AS (
	SELECT
		 ThreePartID = o.DBName + N''.'' + o.SchemaName + N''.'' + o.TableName
		,Command     = o.ColumnName + N'' = DATEADD(YEAR, 3, '' + o.ColumnName + N'')''
	FROM (
		SELECT
			 DBName     = N''' + QUOTENAME([name]) + N'''
			,SchemaName = QUOTENAME(OBJECT_SCHEMA_NAME([object_id]))
			,TableName  = QUOTENAME(OBJECT_NAME([object_id]))
			,ColumnName = QUOTENAME([name])
		FROM ' + QUOTENAME(name) + N'.sys.columns c
		WHERE system_type_id = 61
			AND is_computed = 0
			AND EXISTS (
				SELECT 1
				FROM ' + QUOTENAME(name) + N'.sys.tables t
				WHERE c.[object_id] = t.[object_id]
					AND OBJECTPROPERTY(t.[object_id], ''IsMsShipped'') = 0
			)
	) o
)
INSERT #YEET ( ThreePartID, Commands )
SELECT
	 c.ThreePartID
	,Commands =
		STUFF((
			SELECT N'', '' + c2.Command
			FROM c c2
			WHERE c.ThreePartID = c2.ThreePartID
			FOR XML PATH ('''')
		), 1, 2, N'''')
FROM c
GROUP BY c.ThreePartID
;
'
FROM sys.databases
WHERE database_id > 4
	AND is_read_only = 0
	AND state_desc = N'ONLINE'
	AND name = N'sandbox'
;

PRINT @SQL;

EXEC sys.sp_executesql @SQL;

SELECT *
FROM #YEET
;

DECLARE @SQL2 nvarchar(max) = N'';
SELECT @SQL2 += N'
UPDATE ' + ThreePartID + N'
	SET ' + Commands + N';'
FROM #YEET
;

PRINT SUBSTRING(@SQL2, 1    , 4000 );
PRINT SUBSTRING(@SQL2, 4001 , 8000 );
PRINT SUBSTRING(@SQL2, 8001 , 12000);
PRINT SUBSTRING(@SQL2, 12001, 16000);
PRINT SUBSTRING(@SQL2, 16001, 20000);
PRINT SUBSTRING(@SQL2, 20001, 24000);
PRINT SUBSTRING(@SQL2, 24001, 28000);
PRINT SUBSTRING(@SQL2, 28001, 32000);
PRINT SUBSTRING(@SQL2, 32001, 36000);
