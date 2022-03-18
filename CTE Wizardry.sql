;WITH x AS (
	SELECT TOP (100) *
	FROM dbo.SJ_IndexSpool
)
SELECT *
FROM x
UNION ALL
SELECT *
FROM x
;

;WITH x AS (
	SELECT TOP (100) *
	FROM dbo.SJ_IndexSpool
)
SELECT ca.*
FROM x
CROSS APPLY (
	SELECT x.*
	UNION ALL
	SELECT x.*
) ca
;
