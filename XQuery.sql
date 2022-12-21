
DECLARE @SearchString nvarchar(max) = N'executeSQL';

DROP TABLE IF EXISTS #SearchStrings;

CREATE TABLE #SearchStrings (SearchString nvarchar(max) NOT NULL);

INSERT #SearchStrings (SearchString)
SELECT [value]
FROM STRING_SPLIT(@SearchString, N'|')
;

SELECT *
FROM #SearchStrings
;

;WITH XMLNAMESPACES (
    DEFAULT 'http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition'
           ,'http://schemas.microsoft.com/SQLServer/reporting/reportdesigner' AS rd
),  
Reports AS (
    SELECT
         ItemID
        ,[Path]
        ,[Name]
        ,[Description]
        ,ReportXML = TRY_CONVERT(xml, TRY_CONVERT(varbinary(max), Content))
    FROM ReportServer.dbo.[Catalog]
    WHERE Content IS NOT NULL
        AND [Type] = 2
		--AND [Name] = N'EID'
),
DataSets AS (
    SELECT
         r.ItemID
		,ss.ss
        ,r.[Path]
        ,r.[Name]
        ,r.[Description]
		,DataSet    = ca0.ds.value('@Name', 'nvarchar(260)')
		,DataSource = ca0.ds.value('(Query/DataSourceName/text())[1]', 'nvarchar(260)')
    FROM Reports r
	CROSS JOIN (SELECT SearchString, LOWER(SearchString) FROM #SearchStrings) ss(ss, sslower)
    CROSS APPLY ReportXML.nodes('/Report/DataSets/DataSet[fn:contains(fn:lower-case((Query/CommandText/text())[1]), sql:column("ss.sslower"))]') ca0(ds)
)
SELECT *
FROM DataSets
;


;WITH XMLNAMESPACES (
    DEFAULT 'http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition'
           ,'http://schemas.microsoft.com/SQLServer/reporting/reportdesigner' AS rd
),
Reports AS (
    SELECT
         ItemID
        ,[Path]
        ,[Name]
        ,[Description]
        ,ReportXML = TRY_CONVERT(xml, TRY_CONVERT(varbinary(max), Content))
    FROM ReportServer.dbo.[Catalog]
    WHERE Content IS NOT NULL
        AND [Type] = 2
),
DataSets AS (
    SELECT
         r.*
		,DataSet     = ca0.ds.value('@Name', 'nvarchar(260)')
        ,DataSource  = ca0.ds.value('(Query/DataSourceName/text())[1]', 'nvarchar(260)')
        ,CommandText =
            REPLACE(
            REPLACE(
            REPLACE(
                ca0.ds.value('(Query/CommandText/text())[1]', 'nvarchar(max)')
			,N'[', N'')
			,N']', N'')
			,N'"', N'')
    FROM Reports r
    CROSS APPLY ReportXML.nodes('/Report/DataSets/DataSet') ca0(ds)
),
[TSQL] AS (
	SELECT
		 ss.SearchString
		,ds.ItemID
		,ds.[Path]
		,ds.[Name]
		,ds.[Description]
		,ds.DataSet
		,ds.DataSource
	FROM #SearchStrings ss
	INNER JOIN DataSets ds
		ON ds.CommandText LIKE N'%' + ss.SearchString + N'%'
)
SELECT *
FROM [TSQL]
OPTION (RECOMPILE)
;