
/* use the "|" (pipe) character if you need to delimit more than one search string */
DECLARE @SearchString nvarchar(max) = N'';

IF (
        @SearchString NOT LIKE N'%[^%^_^|]%'
    OR  EXISTS (SELECT 1 FROM STRING_SPLIT(@SearchString, N'|') WHERE [value] = SPACE(0))
)
BEGIN
    RAISERROR(N'Please enter a valid search string.', 16, 1);
    RETURN;
END
;

DECLARE @Wildcard bit;
DECLARE @MaxLen   bigint = 9223372036854775807;

IF @SearchString LIKE N'%[.%_[]%'
BEGIN
    SET @Wildcard = 1
END
ELSE
BEGIN
    SET @Wildcard = 0
END
;

PRINT @Wildcard;

DROP TABLE IF EXISTS #SearchStrings;

CREATE TABLE #SearchStrings (
     SearchString       nvarchar(max) COLLATE Latin1_General_100_CI_AS_KS_WS NOT NULL
    ,SearchStringLength smallint                                             NOT NULL
)
;

INSERT #SearchStrings (
     SearchString
    ,SearchStringLength
)
SELECT
         [value]
    ,LEN([value])
FROM STRING_SPLIT(@SearchString, N'|')
;

DROP TABLE IF EXISTS #DataSets;

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
         r.*
        ,DataSet     = ca0.ds.value('@Name'                           , 'nvarchar(260)')
        ,DataSource  = ca0.ds.value('(Query/DataSourceName/text())[1]', 'nvarchar(260)')
        ,CommandText =
            REPLACE(
            REPLACE(
            REPLACE(
                ca0.ds.value('(Query/CommandText/text())[1]', 'nvarchar(max)')
            ,N'[', SPACE(0))
            ,N']', SPACE(0))
            ,N'"', SPACE(0))
    FROM Reports r
    CROSS APPLY r.ReportXML.nodes('/Report/DataSets/DataSet') ca0(ds)
),
[T-SQL] AS (
    SELECT
         ss.SearchString
        ,ss.SearchStringLength
        ,ds.ItemID
        ,ds.[Path]
        ,ds.[Name]
        ,ds.[Description]
        ,ds.DataSet
        ,ds.DataSource
        ,OccurrenceNo = 1
        ,ca0.OccurrenceIndex
        ,[LineNo]    = 1 + ca0.OccurrenceIndex - LEN(REPLACE(LEFT(ds.CommandText, ca0.OccurrenceIndex), nchar(10), SPACE(0)))
        ,CommandText = SUBSTRING(ds.CommandText, ca0.OccurrenceIndex +  1, @MaxLen                        )
        ,[Sample]    = SUBSTRING(ds.CommandText, ca0.OccurrenceIndex - 25, 25 + ss.SearchStringLength + 25)
    FROM #SearchStrings ss
    INNER JOIN DataSets ds
        ON ds.CommandText LIKE N'%' + ss.SearchString + N'%'
    CROSS APPLY (VALUES(PATINDEX(N'%' + ss.SearchString + N'%', ds.CommandText))) ca0(OccurrenceIndex)
),
XPath AS (
    SELECT
         ss.SearchString
        ,ss.SearchStringLength
        ,r.ItemID
        ,r.[Path]
        ,r.[Name]
        ,r.[Description]
        ,DataSet      = ca0.ds.value('@Name'                           , 'nvarchar(260)')
        ,DataSource   = ca0.ds.value('(Query/DataSourceName/text())[1]', 'nvarchar(260)')
        ,OccurrenceNo = 1
        ,ca2.OccurrenceIndex
        ,[LineNo] = 1 + ca2.OccurrenceIndex - LEN(REPLACE(LEFT(ca1.CommandText, ca2.OccurrenceIndex), nchar(10), SPACE(0)))
        ,ca1.CommandText
        ,[Sample] = SUBSTRING(ca1.CommandText, ca2.OccurrenceIndex - 25, 25 + ss.SearchStringLength + 25)
    FROM Reports r
    CROSS JOIN (
         SELECT
             SearchString
            ,SearchStringLength
            ,LowerSearchString = LOWER(SearchString)
        FROM #SearchStrings
    ) ss
    CROSS APPLY r.ReportXML.nodes('/Report/DataSets/DataSet[fn:contains(fn:lower-case((Query/CommandText/text())[1]), sql:column("ss.LowerSearchString"))]') ca0(ds)
    CROSS APPLY (VALUES(ca0.ds.value('(Query/CommandText/text())[1]', 'nvarchar(max)'))) ca1(CommandText)
    CROSS APPLY (VALUES(CHARINDEX(ss.SearchString, ca1.CommandText))) ca2(OccurrenceIndex)
)
SELECT *
INTO #DataSets
FROM [T-SQL]
WHERE @Wildcard = 1
UNION ALL
SELECT *
FROM XPath
WHERE @Wildcard = 0
OPTION (RECOMPILE)
;

/*
SELECT *
FROM ##DataSets
ORDER BY
     SearchString
    ,ItemID
    ,DataSet
;
*/

DROP TABLE IF EXISTS #Occurrences;

;WITH [T-SQL] AS (
    SELECT
         SearchString
        ,SearchStringLength
        ,ItemID
        ,[Path]
        ,[Name]
        ,[Description]
        ,DataSet
        ,DataSource
        ,OccurrenceNo
        ,OccurrenceIndex
        ,[LineNo]
        ,CommandText
        ,[Sample]
    FROM #DataSets

    UNION ALL

    SELECT
         T.SearchString
        ,T.SearchStringLength
        ,T.ItemID
        ,T.[Path]
        ,T.[Name]
        ,T.[Description]
        ,T.DataSet
        ,T.DataSource
        ,OccurrenceNo = T.OccurrenceNo + 1
        ,ca0.OccurrenceIndex
        ,[LineNo]    = T.[LineNo] + ca0.OccurrenceIndex - LEN(REPLACE(LEFT(T.CommandText, ca0.OccurrenceIndex), nchar(10), SPACE(0)))
        ,CommandText = SUBSTRING(T.CommandText, ca0.OccurrenceIndex +  1, @MaxLen                       )
        ,[Sample]    = SUBSTRING(T.CommandText, ca0.OccurrenceIndex - 25, 25 + T.SearchStringLength + 25)
    FROM [T-SQL] T
    CROSS APPLY (VALUES(PATINDEX(N'%' + T.SearchString + N'%', T.CommandText))) ca0(OccurrenceIndex)
    WHERE ca0.OccurrenceIndex > 0
),
XPath AS (
    SELECT
         SearchString
        ,SearchStringLength
        ,ItemID
        ,[Path]
        ,[Name]
        ,[Description]
        ,DataSet
        ,DataSource
        ,OccurrenceNo
        ,OccurrenceIndex
        ,[LineNo]
        ,CommandText
        ,[Sample]
    FROM #DataSets

    UNION ALL

    SELECT
         X.SearchString
        ,X.SearchStringLength
        ,X.ItemID
        ,X.[Path]
        ,X.[Name]
        ,X.[Description]
        ,X.DataSet
        ,X.DataSource
        ,OccurrenceNo = X.OccurrenceNo + 1
        ,ca0.OccurrenceIndex
        ,[LineNo] = ca0.OccurrenceIndex - LEN(REPLACE(LEFT(X.CommandText, ca0.OccurrenceIndex), nchar(10), SPACE(0))) + 1
        ,X.CommandText
        ,[Sample] = SUBSTRING(X.CommandText, ca0.OccurrenceIndex - 25, 25 + X.SearchStringLength + 25)
    FROM XPath X
    CROSS APPLY (VALUES(CHARINDEX(X.SearchString, X.CommandText, X.OccurrenceIndex + 1))) ca0(OccurrenceIndex)
    WHERE ca0.OccurrenceIndex > 0
)
SELECT
     SearchString
    ,ItemID
    ,[Path]
    ,[Name]
    ,[Description]
    ,DataSet
    ,DataSource
    ,OccurrenceNo
    ,[LineNo]
    ,[Sample]
INTO #Occurrences
FROM [T-SQL]
WHERE @Wildcard = 1
UNION ALL
SELECT
     SearchString
    ,ItemID
    ,[Path]
    ,[Name]
    ,[Description]
    ,DataSet
    ,DataSource
    ,OccurrenceNo
    ,[LineNo]
    ,[Sample]
FROM XPath 
WHERE @Wildcard = 0
OPTION (
     RECOMPILE
    ,MAXRECURSION 32767
)
;

/*
SELECT *
FROM #Occurrences
ORDER BY
     SearchString
    ,ItemID
    ,DataSet
    ,OccurrenceNo
;
*/

;WITH el3 AS (
    SELECT
         ItemPath
        ,TimeEnd
        ,UserName
        ,rn = ROW_NUMBER() OVER (PARTITION BY ItemPath ORDER BY TimeEnd DESC)
    FROM ReportServer.dbo.ExecutionLog3 el3
    WHERE [Status] = N'rsSuccess'
        AND [Source] = 'Live'
        AND EXISTS (
            SELECT 1
            FROM #DataSets ds
            WHERE el3.ItemPath = ds.[Path]
        )
),
s AS (
    SELECT
         Report_OID
        ,SubscriptionsLastStatus =
            STUFF((
                SELECT nchar(13) + nchar(10) + char(149) + SPACE(1) + s2.LastStatus
                FROM ReportServer.dbo.Subscriptions s2
                WHERE s1.Report_OID = s2.Report_OID
                    AND s2.InactiveFlags = 0
                    AND s2.LastStatus IS NOT NULL
                FOR XML PATH(''), TYPE).value('text()[1]', 'nvarchar(max)')
            , 1, 2, SPACE(0))
    FROM ReportServer.dbo.Subscriptions s1
    WHERE InactiveFlags = 0
        AND LastStatus IS NOT NULL
        AND EXISTS (
            SELECT 1
            FROM #DataSets ds
            WHERE s1.Report_OID = ds.ItemID
        )
    GROUP BY Report_OID
)
SELECT
     o.SearchString
    ,o.[Name]
    ,o.[Path]
    ,o.[Description]
    ,o.DataSet
    ,o.DataSource
    ,o.OccurrenceNo
    ,o.[LineNo]
    ,o.[Sample]
    ,s.SubscriptionsLastStatus
    ,LastRunTimeEnd  = el3.TimeEnd
    ,LastRunTimeUser = el3.UserName
FROM #Occurrences o
LEFT OUTER JOIN s
    ON  o.ItemID = s.Report_OID
LEFT OUTER JOIN el3
    ON  o.[Path] = el3.ItemPath
    AND el3.rn   = 1
ORDER BY
     o.SearchString
    ,o.[Name]
    ,o.[Path]
    ,o.DataSet
    ,o.OccurrenceNo
;

/*
SELECT
     ItemID
    ,[Path]
    ,[Name]
    ,[Description]
INTO #MoreReports
FROM dbo.[Catalog] c
WHERE EXISTS (
    SELECT 1
    FROM dbo.[DataSource] ds
    WHERE c.ItemID = ds.ItemID 
        AND ds.[Name] = N'PBSDWSSAS'
)
    AND NOT EXISTS (
        SELECT 1
        FROM #DataSets ds
        WHERE c.ItemID = ds.ItemID
    )
;

SELECT *
FROM #MoreReports
ORDER BY
     [Name]
    ,[Path]
;

;WITH el3 AS (
    SELECT
         ItemPath
        ,TimeEnd
        ,UserName
        ,rn = ROW_NUMBER() OVER (PARTITION BY ItemPath ORDER BY TimeEnd DESC)
    FROM ReportServer.dbo.ExecutionLog3
    WHERE [Status] = N'rsSuccess'
        AND [Source] = 'Live'
),
s AS (
    SELECT
         Report_OID
        ,SubscriptionsLastStatus =
            STUFF((
                SELECT nchar(13) + nchar(10) + char(149) + SPACE(1) + s2.LastStatus
                FROM ReportServer.dbo.Subscriptions s2
                WHERE s1.Report_OID = s2.Report_OID
                FOR XML PATH(N''), TYPE).value(N'text()[1]', 'nvarchar(max)')
                    AND s2.InactiveFlags = 0
                    AND s2.LastStatus IS NOT NULL
            , 1, 2, SPACE(0))
    FROM ReportServer.dbo.Subscriptions s1
    WHERE InactiveFlags = 0
        AND LastStatus IS NOT NULL
    GROUP BY Report_OID
)
SELECT
     mr.[Name]
    ,mr.[Path]
    ,mr.[Description]
    ,DataSource = N'PBSDWSSAS'
    ,s.SubscriptionsLastStatus
    ,LastRunTimeEnd  = el3.TimeEnd
    ,LastRunTimeUser = el3.UserName
FROM #MoreReports mr
LEFT OUTER JOIN s
    ON  mr.ItemID = s.Report_OID
LEFT OUTER JOIN el3
    ON  mr.[Path] = el3.ItemPath
    AND el3.rn   = 1
ORDER BY
     mr.[Name]
    ,mr.[Path]
;
*/
