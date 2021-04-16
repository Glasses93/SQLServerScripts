/*    ==Scripting Parameters==

    Source Server Version : SQL Server 2016 (13.0.5850)
    Source Database Engine Edition : Microsoft SQL Server Standard Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2016
    Target Database Engine Edition : Microsoft SQL Server Standard Edition
    Target Database Engine Type : Standalone SQL Server
*/

USE [sandbox]
GO

/****** Object:  StoredProcedure [dbo].[SJ_Indices]    Script Date: 20/01/2021 21:21:57 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER       PROCEDURE [dbo].[SJ_Indices] @Debug bit = 0
AS
BEGIN
SET XACT_ABORT, NOCOUNT ON;

BEGIN TRY
DECLARE @SQL nvarchar(max) = N'';

SELECT @SQL += N'
UNION ALL
SELECT [Database] = N''' + [name] + N''', s.[name], t.[object_id], t.[name], i.index_id, i.[name], c.column_id, ic.index_column_id,
		CASE ic.is_included_column WHEN 0 THEN CAST(c.[name] AS VARCHAR(5000)) ELSE '''' END, 
		CASE ic.is_included_column WHEN 1 THEN CAST(c.[name] AS VARCHAR(5000)) ELSE '''' END, 1, i.type_desc,
		i.filter_definition
	FROM  ' + QUOTENAME([name]) + N'.sys.schemas AS s WITH (NOLOCK)
		JOIN ' + QUOTENAME([name]) + N'.sys.tables AS t WITH (NOLOCK) ON s.[schema_id] = t.[schema_id]
			JOIN ' + QUOTENAME([name]) + N'.sys.indexes AS i WITH (NOLOCK) ON i.[object_id] = t.[object_id]
				JOIN ' + QUOTENAME([name]) + N'.sys.index_columns AS ic WITH (NOLOCK) ON ic.index_id = i.index_id AND ic.[object_id] = i.[object_id]
					JOIN ' + QUOTENAME([name]) + N'.sys.columns AS c WITH (NOLOCK) ON c.column_id = ic.column_id AND c.[object_id] = ic.[object_id]
						AND ic.index_column_id = 1
'
FROM sys.databases WITH (NOLOCK)
WHERE database_id > 4
	AND [name] != N'AdmiralDBA'
	AND state_desc = N'ONLINE'
;

SELECT @SQL = STUFF(@SQL, 1, 11, N'');

SELECT @SQL += N'
UNION ALL
SELECT N''' + [name] + N''', s.[name], t.[object_id], t.[name], i.index_id, i.[name], c.column_id, ic.index_column_id,
		CASE ic.is_included_column WHEN 0 THEN CAST(cte.ColumnNames + '', '' + c.[name] AS VARCHAR(5000))  ELSE cte.ColumnNames END, 
		CASE  
			WHEN ic.is_included_column = 1 AND cte.IncludeColumns != '''' THEN CAST(cte.IncludeColumns + '', '' + c.[name] AS VARCHAR(5000))
			WHEN ic.is_included_column = 1 AND cte.IncludeColumns  = '''' THEN CAST(c.[name] AS VARCHAR(5000)) 
			ELSE '''' 
		END,
		cte.NumberOfColumns + 1, i.type_desc,
		i.filter_definition
	FROM  ' + QUOTENAME([name]) + N'.sys.schemas AS s WITH (NOLOCK)
		JOIN ' + QUOTENAME([name]) + N'.sys.tables AS t WITH (NOLOCK) ON s.[schema_id] = t.[schema_id]
			JOIN ' + QUOTENAME([name]) + N'.sys.indexes AS i WITH (NOLOCK) ON i.[object_id] = t.[object_id]
				JOIN ' + QUOTENAME([name]) + N'.sys.index_columns AS ic WITH (NOLOCK) ON ic.index_id = i.index_id AND ic.[object_id] = i.[object_id]
					JOIN ' + QUOTENAME([name]) + N'.sys.columns AS c WITH (NOLOCK) ON c.column_id = ic.column_id AND c.[object_id] = ic.[object_id] 
					JOIN CTE_Indexes cte ON cte.Column_index_ID + 1 = ic.index_column_id
						and cte.[Database] = N''' + [name] + N'''
					--JOIN CTE_Indexes cte ON cte.ColumnID + 1 = ic.index_column_id  
							AND cte.IndexID = i.index_id AND cte.ObjectID = ic.[object_id]
'
FROM sys.databases WITH (NOLOCK)
WHERE database_id > 4
	AND [name] != N'AdmiralDBA'
	AND state_desc = N'ONLINE'
;

SELECT @SQL =
N'
;WITH CTE_Indexes ([Database], SchemaName, ObjectID, TableName, IndexID, IndexName, ColumnID, column_index_id, ColumnNames, IncludeColumns, NumberOfColumns, IndexType, Filter_Definition)
AS
(
' + @SQL
;

SELECT @SQL +=
N'
), cte2 ([Database], [Schema], ObjectID, [Table], IndexID, [Index], ColumnID, column_index_id, KeyColumns, IncludedColumns, NumberOfColumns, IndexType, FilterDefinition, LastColRecord) AS (
SELECT *, RANK() OVER (PARTITION BY [Database], SchemaName, ObjectID, IndexID ORDER BY NumberOfColumns DESC) AS LastColRecord FROM CTE_Indexes
)
SELECT [Database], [Schema], [Table], [Index], IndexType = LEFT(IndexType, 1) + LOWER(RIGHT(IndexType, LEN(IndexType) - 1)), KeyColumns, IncludedColumns, FilterDefinition FROM cte2
WHERE LastColRecord = 1
ORDER BY [Database], [Schema], [Table], indexid, [Index]
;'
;

IF @Debug = 1
BEGIN
	PRINT SUBSTRING(@SQL, 1    , 4000 );
	PRINT SUBSTRING(@SQL, 4001 , 8000 );
	PRINT SUBSTRING(@SQL, 8001 , 12000);
	PRINT SUBSTRING(@SQL, 12001, 16000);
	PRINT SUBSTRING(@SQL, 16001, 20000);
	PRINT SUBSTRING(@SQL, 20001, 24000);
	PRINT SUBSTRING(@SQL, 24001, 28000);
	PRINT SUBSTRING(@SQL, 28001, 32000);
END
;

EXEC sys.sp_executesql @SQL;
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRANSACTION;
	END
	;

	;THROW;
END CATCH
;
END
;
GO


