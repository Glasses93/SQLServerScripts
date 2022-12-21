
SELECT *
FROM sys.fn_helpcollations()
;

SELECT
     [name]
    ,collation_name
FROM sys.databases
;

;WITH rec(n) AS (
    SELECT -1
    UNION ALL
    SELECT n + 1
    FROM rec
    WHERE n < 65536
)
SELECT
     n
    ,[ASCII]   =  char(n)
    ,[Unicode] = nchar(n)
    ,[ASCII]   =  char(n) COLLATE Greek_CS_AS_KS_WS
    ,[Unicode] = nchar(n) COLLATE Greek_CS_AS_KS_WS
    ,[ASCII]   =  char(n) COLLATE Greek_100_CS_AS_KS_WS
    ,[Unicode] = nchar(n) COLLATE Greek_100_CS_AS_KS_WS
FROM rec
ORDER BY n
OPTION (MAXRECURSION 0)
;

