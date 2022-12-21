
-- delimiter: 휱

DECLARE
	 @SearchString nvarchar(255) = N'%R123%'
	,@MinLen       smallint      = 4
;

IF (
		@SearchString IS NULL
	OR  @MinLen       IS NULL
	OR  EXISTS (SELECT 1 FROM STRING_SPLIT(@SearchString, N'휱') WHERE [value] NOT LIKE N'%[^%^_]%')
	OR  @MinLen <= 0
)
BEGIN
    RAISERROR(N'Please enter a valid search string and/or minimum length.', 11, 1);
    RETURN;
END
;

DECLARE @q nchar(1) = nchar(39);

DECLARE @SQL nvarchar(max) =
N'
DECLARE @ss nvarchar(255) = N' + QUOTENAME(@SearchString, @q) + N';

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DROP TABLE IF EXISTS #s;

SELECT
	 n =                       [value]
	,v = CONVERT(varchar(255), [value])
INTO #s
FROM STRING_SPLIT(@ss, N' + QUOTENAME(N'휱', @q) + N')
;

DROP TABLE IF EXISTS #Results;

CREATE TABLE #Results (
     SearchString   nvarchar(255)
	,[Database]     sysname
    ,[Schema]       sysname
    ,[Table]        sysname
    ,[Column]       sysname
    ,ArbitraryValue nvarchar(1000)
)
;

'
;

SELECT --*
    @SQL +=
N'INSERT #Results (SearchString,[Database],[Schema],[Table],[Column],ArbitraryValue) SELECT s.n,DB_NAME(),N'
	+	QUOTENAME(s.[name], @q)
	+	N',N'
	+	QUOTENAME(t.[name], @q)
	+	N',N'
	+	QUOTENAME(c.[name], @q)
	+	N',LEFT(' + IIF(c.[system_type_id] IN (35, 99), N'CONVERT(nvarchar(1000),oa.' + QUOTENAME(c.[name]) + N')', N'oa.' + QUOTENAME(c.[name])) + N',1000) '
	+	N'FROM #s s OUTER APPLY (SELECT TOP 1 x.' + QUOTENAME(c.[name]) + N' FROM ' + QUOTENAME(s.[name]) + N'.' + QUOTENAME(t.[name]) + N' x WHERE x.' + QUOTENAME(c.[name]) + N' LIKE ' + IIF(c.[system_type_id] IN (35, 167, 175), N's.v', N's.n') + N') oa;
'
FROM sys.schemas s
INNER JOIN sys.tables t
    ON s.[schema_id] = t.[schema_id]
INNER JOIN sys.columns c
    ON t.[object_id] = c.[object_id]
WHERE c.[system_type_id] IN (35, 99, 167, 175, 231, 239)
    AND s.[name] IN (N'MSO', N'', N'')
    AND(
            c.[max_length] >= IIF(c.[system_type_id] IN (35, 167, 175), @MinLen, @MinLen * 2)
        OR  c.[max_length]  = -1
    )
ORDER BY
     s.[schema_id]
    ,t.[object_id]
    ,c.[column_id]
;

SELECT @SQL += N'
SELECT
	 *
	,CRLF = REPLICATE(char(13) + char(10), 2)
FROM #Results
WHERE ArbitraryValue IS NOT NULL
ORDER BY
	 [Database]
	,[Schema]
	,[Table]
	,[Column]
	,SearchString
;
'
; 

SELECT [SQL] = @SQL;
