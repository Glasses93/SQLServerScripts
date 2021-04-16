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

/****** Object:  StoredProcedure [dbo].[SJ_RowCounts]    Script Date: 20/01/2021 21:12:57 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO






ALTER   PROCEDURE [dbo].[SJ_RowCounts]
	 @DBName	sysname = NULL
	,@Lower		bigint  = 0
	,@Upper 	bigint  = 9223372036854775807
	,@Nolock	bit		= 0
	,@Debug		bit		= 0
AS
BEGIN
SET XACT_ABORT, NOCOUNT ON;

BEGIN TRY
DECLARE @SQL nvarchar(max) = N'';

IF @DBName IS NOT NULL
	AND DB_ID(@DBName) IS NULL
BEGIN
	RAISERROR('There is no database by the name ''%s'' on this server.', 16, 1, @DBName);
	RETURN;
END
;

DECLARE @NewLine nchar(2) = CHAR(13) + CHAR(10);

IF @DBName IS NOT NULL
	AND DB_ID(@DBName) IS NOT NULL
BEGIN
DECLARE @Context nvarchar(200) = QUOTENAME(@DBName) + N'.sys.sp_executesql';

SELECT @SQL =
N'
SELECT
	 [Database]	 = @DBName
	,[Schema]	 = s.[name]
	,[Table]	 = t.[name]
	,[RowCount]	 = SUM(p.[rows])
	,[# of Rows] = FORMAT(SUM(p.[rows]), ''N0'')
-- This statement is built dynamically and executed within the sandbox.dbo.SJ_RowCounts stored procedure.
FROM sys.schemas s --$nl$
INNER JOIN sys.tables t --$nl$
	ON s.[schema_id] = t.[schema_id]
INNER JOIN sys.partitions p --$nl$
	ON t.[object_id] = p.[object_id]
WHERE p.index_id IN (0, 1)
GROUP BY
	 t.[name]
	,s.[name]
HAVING SUM(p.[rows]) BETWEEN @Lower AND @Upper
'
;

IF @NoLock = 1
BEGIN
	SELECT @SQL = REPLACE(@SQL, N'--$nl$', N'WITH (NOLOCK)');
END
;

SELECT @SQL =
		N';WITH x AS ('
	+	@SQL + N')' + @NewLine
	+	N'SELECT [Database], [Schema], [Table], [# of Rows] FROM x' + @NewLine
	+	N'ORDER BY [Schema], [RowCount] DESC;'
;

IF @Debug = 1
BEGIN
	PRINT N'The following code was executed by this system procedure: ' + @Context + N'.' + @NewLine + @NewLine;
	PRINT @SQL;
END
;

EXEC @Context
	 @SQL
	,N'@DBName sysname, @Lower bigint, @Upper bigint'
	,@DBName
	,@Lower
	,@Upper
;

END
;

IF @DBName IS NULL
BEGIN
SELECT @SQL +=
N'UNION ALL
SELECT
	 [Database]	 = N''' + [name] + N'''
	,[Schema]	 = s.[name]
	,[Table]	 = t.[name]
	,[RowCount]  = SUM(p.[rows])
	,[# of Rows] = FORMAT(SUM(p.[rows]), ''N0'')
-- This statement is built dynamically and executed within the sandbox.dbo.SJ_RowCounts stored procedure.
FROM ' + QUOTENAME([name]) + N'.sys.schemas s --$nl$
INNER JOIN ' + QUOTENAME([name]) + N'.sys.tables t --$nl$
	ON s.[schema_id] = t.[schema_id]
INNER JOIN ' + QUOTENAME([name]) + N'.sys.partitions p --$nl$
	ON t.[object_id] = p.[object_id]
WHERE p.index_id IN (0, 1)
GROUP BY
	 t.[name]
	,s.[name]
HAVING SUM(p.[rows]) BETWEEN @Lower AND @Upper
'
FROM sys.databases
WHERE database_id > 4
	AND [name] != N'AdmiralDBA'
	AND state_desc = N'ONLINE'
;

IF @NoLock = 1
BEGIN
	SELECT @SQL = REPLACE(@SQL, N'--$nl$', N'WITH (NOLOCK)');
END
;

SELECT @SQL =
		N';WITH x AS (' + @NewLine
	+	STUFF(@SQL, 1, 11, N'') + N')' + @NewLine
	+	N'SELECT [Database], [Schema], [Table], [# of Rows] FROM x' + @NewLine
	+	N'ORDER BY [Database], [Schema], [RowCount] DESC;'
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


