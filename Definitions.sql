
DECLARE
     @SchemaName sysname = N'DataFeed'
    ,@ViewName   sysname = N'vwLCR'
;

SELECT
     sch = s.[name]
    ,vw  = v.[name]
    ,m.[definition]
FROM sys.schemas s
INNER JOIN sys.views v
    ON s.[schema_id] = v.[schema_id]
INNER JOIN sys.sql_modules m
    ON v.[object_id] = m.[object_id]
WHERE s.[name] = @SchemaName
    AND v.[name] = @ViewName
ORDER BY
     s.[name]
    ,v.[name]
;
GO

DECLARE
     @SchemaName    sysname = N'DW'
    ,@ProcedureName sysname = N'up'
;

;WITH l AS (
     SELECT *
     FROM (
         VALUES
             (N'MERGE fact.factmortgagebalance')
            ,(N'INSERT fact.factmortgagebalance')
            ,(N'INSERT INTO fact.factmortgagebalance')
            ,(N'DELETE fact.factmortgagebalance')
            ,(N'DELETE FROM fact.factmortgagebalance')
            ,(N'UPDATE FROM fact.factmortgagebalance')
     ) v(l)
)
SELECT
     sch = s.[name]
    ,sp  = o.[name]
    ,m.[definition]
FROM sys.schemas s
INNER JOIN sys.objects o
    ON s.[schema_id] = o.[schema_id]
INNER JOIN sys.sql_modules m
    ON o.[object_id] = m.[object_id]
WHERE o.[type] = 'P'
    --AND s.[name] = @SchemaName
    --AND o.[name] = @ProcedureName
    AND REPLACE(REPLACE(REPLACE(m.[definition], N'"', SPACE(0)), N'[', SPACE(0)), N']', SPACE(0)) LIKE N'%etl.FactMortgageBalance%'
    --AND EXISTS (
    --    SELECT 1
    --    FROM l
    --    WHERE REPLACE(REPLACE(REPLACE(m.[definition], N'"', SPACE(0)), N'[', SPACE(0)), N']', SPACE(0)) LIKE N'%' + l.l + N'%'
    --)
ORDER BY
     s.[name]
    ,o.[name]
;
GO

DECLARE 
     @SQL nvarchar(max) = N''
    ,@q   nchar(1)      = nchar(39)
;

SELECT @SQL +=
N'UNION ALL
SELECT
     db  = ' + QUOTENAME([name], @q) + N' COLLATE Latin1_General_CI_AS
    ,sch = s.[name] COLLATE Latin1_General_CI_AS
    ,sp  = o.[name] COLLATE Latin1_General_CI_AS
    ,def = m.[definition] COLLATE Latin1_General_CI_AS
FROM ' + QUOTENAME([name]) + N'.sys.schemas s
INNER JOIN ' + QUOTENAME([name]) + N'.sys.objects o
    ON s.[schema_id] = o.[schema_id]
INNER JOIN ' + QUOTENAME([name]) + N'.sys.sql_modules m
    ON o.[object_id] = m.[object_id]
WHERE o.[type] = ' + QUOTENAME(N'P', @q) + N'
    AND m.[definition] LIKE N' + QUOTENAME(N'%monthsinarrears%', @q) + N'
'
FROM [master].sys.databases
WHERE [database_id] > 4
    AND [state] = 0
    AND [user_access] = 0
    AND HAS_DBACCESS([name]) = 1
;

SELECT @SQL = STUFF(@SQL, 1, 11, SPACE(0)) + N';';

PRINT @SQL;
EXEC sys.sp_executesql @SQL;



/*
;WITH vw AS (

)
,def AS (

)
,f AS (
    SELECT *
    FROM vw
    FULL OUTER JOIN def
        ON vw. = def.
    WHERE NOT EXISTS (
        SELECT vw.*
        INTERSECT
        SELECT def.*
    )
)
,e AS (
    SELECT *
    FROM vw
    EXCEPT
    SELECT *
    FROM def

    UNION ALL

    SELECT *
    FROM def
    UNION ALL
    SELECT *
    FROM vw
)
SELECT *
FROM
;
*/
