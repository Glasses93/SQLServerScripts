
DECLARE @ReportName nvarchar(425) = N'Arrears History';

DROP TABLE IF EXISTS #Reports;

SELECT
     [Name]
    ,[Path]
    ,[Description]
    ,ReportXML = TRY_CONVERT(xml, TRY_CONVERT(varbinary(max), Content))
INTO #Reports
FROM dbo.[Catalog]
WHERE Content IS NOT NULL
    AND [Type] = 2
    AND [Name] = @ReportName
;

-- xml
SELECT *
FROM #Reports
;

-- report data sources
;WITH XMLNAMESPACES (
    DEFAULT 'http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition'
           ,'http://schemas.microsoft.com/SQLServer/reporting/reportdesigner' AS rd
)
SELECT
     r.[Name]
    ,r.[Path]
    ,DataSourceLabel     = oa0.ds.value('@Name'                          , 'nvarchar(max)'   )
    ,DataSourceReference = oa0.ds.value('(DataSourceReference/text())[1]', 'nvarchar(260)'   )
    ,SecurityType        = oa0.ds.value('(rd:SecurityType/text())[1]'    , 'varchar(50)'     )
FROM #Reports r
OUTER APPLY r.ReportXML.nodes('/Report/DataSources/DataSource') oa0(ds)
ORDER BY
     r.[Path]
    ,DataSourceLabel
;

-- report parameters
;WITH XMLNAMESPACES (
    DEFAULT 'http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition'
           ,'http://schemas.microsoft.com/SQLServer/reporting/reportdesigner' AS rd
)
SELECT
     r.[Name]
    ,r.[Path]
    ,Parameter  =     oa0.rp.value('@Name'                 , 'sysname'      )
    ,Prompt     =     oa0.rp.value('(Prompt/text())[1]'    , 'nvarchar(max)')
    ,DataType   =     oa0.rp.value('(DataType/text())[1]'  , 'varchar(10)'  )
    ,[Hidden]   = IIF(oa0.rp.value('(Hidden/text())[1]'    , 'char(4)'      ) = 'true', 1, 0)
    ,MultiValue = IIF(oa0.rp.value('(MultiValue/text())[1]', 'char(4)'      ) = 'true', 1, 0)
FROM #Reports r
OUTER APPLY r.ReportXML.nodes('/Report/ReportParameters/ReportParameter') oa0(rp)
ORDER BY
     r.[Path]
    ,Parameter
;

-- report parameters default values
;WITH XMLNAMESPACES (
    DEFAULT 'http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition'
           ,'http://schemas.microsoft.com/SQLServer/reporting/reportdesigner' AS rd
)
SELECT
     r.[Name]
    ,r.[Path]
    ,Parameter    = oa0.rp.value('@Name', 'sysname')
    ,DefaultValue =
        ISNULL(
             oa1.df.value('text()[1]'             , 'nvarchar(max)')
            ,oa2.df.value('(ValueField/text())[1]', 'nvarchar(max)')
        )
    ,DataSet = oa2.df.value('(DataSetName/text())[1]', 'nvarchar(260)')
FROM #Reports r
OUTER APPLY r.ReportXML.nodes('/Report/ReportParameters/ReportParameter') oa0(rp)
OUTER APPLY      oa0.rp.nodes('DefaultValue/Values/Value'               ) oa1(df)
OUTER APPLY      oa0.rp.nodes('DefaultValue/DataSetReference'           ) oa2(df)
ORDER BY
     r.[Path]
    ,Parameter
    ,DefaultValue
;

-- report parameters available values
;WITH XMLNAMESPACES (
    DEFAULT 'http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition'
           ,'http://schemas.microsoft.com/SQLServer/reporting/reportdesigner' AS rd
)
SELECT
     r.[Name]
    ,r.[Path]
    ,Parameter      = oa0.rp.value('@Name', 'sysname')
    ,AvailableLabel =
        ISNULL(
             oa1.av.value('(Label/text())[1]'     , 'nvarchar(max)')
            ,oa2.av.value('(LabelField/text())[1]', 'nvarchar(max)')
        )
    ,AvailableValue =
        ISNULL(
             oa1.av.value('(Value/text())[1]'     , 'nvarchar(max)')
            ,oa2.av.value('(ValueField/text())[1]', 'nvarchar(max)')
        )
    ,DataSet = oa2.av.value('(DataSetName/text())[1]', 'nvarchar(260)')
FROM #Reports r
OUTER APPLY r.ReportXML.nodes('/Report/ReportParameters/ReportParameter'  ) oa0(rp)
OUTER APPLY      oa0.rp.nodes('ValidValues/ParameterValues/ParameterValue') oa1(av)
OUTER APPLY      oa0.rp.nodes('ValidValues/DataSetReference'              ) oa2(av)
ORDER BY
     r.[Path]
    ,Parameter
    ,AvailableLabel
;

-- dataset queries
;WITH XMLNAMESPACES (
    DEFAULT 'http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition'
           ,'http://schemas.microsoft.com/SQLServer/reporting/reportdesigner' AS rd
)
SELECT
     r.[Name]
    ,r.[Path]
    ,DataSet       = oa0.ds.value('@Name'                                           , 'nvarchar(260)')
    ,DataSource    = oa0.ds.value('(Query/DataSourceName/text())[1]'                , 'nvarchar(260)')
    ,CommandText   = oa0.ds.value('(Query/CommandText/text())[1]'                   , 'nvarchar(max)')
    ,SharedDataSet = oa0.ds.value('(SharedDataSet/SharedDataSetReference/text())[1]', 'nvarchar(260)')
    ,CommandType   =  
        ISNULL(
             oa1.qd.value('
                declare default element namespace "http://schemas.microsoft.com/AnalysisServices/QueryDefinition";
                declare namespace xsi           = "http://www.w3.org/2001/XMLSchema-instance"                    ;
                declare namespace xsd           = "http://www.w3.org/2001/XMLSchema"                             ;

                (QueryDefinition/CommandType/text())[1]', 'varchar(20)'
             )
            ,'T-SQL'
        )
FROM #Reports r
OUTER APPLY r.ReportXML.nodes('/Report/DataSets/DataSet') oa0(ds)
OUTER APPLY      oa0.ds.nodes('Query/rd:DesignerState'  ) oa1(qd)
ORDER BY
     r.[Path]
    ,DataSet
;

-- dataset parameters
;WITH XMLNAMESPACES (
    DEFAULT 'http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition'
           ,'http://schemas.microsoft.com/SQLServer/reporting/reportdesigner' AS rd
)
SELECT
     r.[Name]
    ,r.[Path]
    ,DataSet       = oa0.ds.value('@Name'                                           , 'nvarchar(260)')
    ,Parameter     = oa1.qp.value('@Name'                                           , 'sysname'      )
    ,[Value]       = oa1.qp.value('(Value/text())[1]'                               , 'nvarchar(max)')
    ,SharedDataSet = oa0.ds.value('(SharedDataSet/SharedDataSetReference/text())[1]', 'nvarchar(260)')
    ,CommandType   =  
        ISNULL(
             oa2.qd.value('
                declare default element namespace "http://schemas.microsoft.com/AnalysisServices/QueryDefinition";
                declare namespace xsi           = "http://www.w3.org/2001/XMLSchema-instance"                    ;
                declare namespace xsd           = "http://www.w3.org/2001/XMLSchema"                             ;

                (QueryDefinition/CommandType/text())[1]', 'varchar(20)'
             )
            ,'T-SQL'
        )
FROM #Reports r
OUTER APPLY r.ReportXML.nodes('/Report/DataSets/DataSet'            ) oa0(ds)
OUTER APPLY      oa0.ds.nodes('Query/QueryParameters/QueryParameter') oa1(qp)
OUTER APPLY      oa0.ds.nodes('Query/rd:DesignerState'              ) oa2(qd)
ORDER BY
     r.[Path]
    ,DataSet
    ,Parameter
;
