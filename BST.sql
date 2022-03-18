SELECT BOMonth = DATEFROMPARTS(n2.n, n1.n, 01)
FROM dbo.Numbers n1
CROSS JOIN (
	SELECT n
	FROM dbo.Numbers
	WHERE n BETWEEN 2015 AND 2020
) n2
WHERE n1.n BETWEEN 1 AND 12
;

SET STATISTICS IO ON;

CREATE TABLE #BST (
	 --y	smallint	NOT NULL
	 s	datetime	NOT NULL
	,e	datetime	NOT NULL

	,CONSTRAINT PK_BST_se PRIMARY KEY CLUSTERED (
		 s ASC
		,e ASC
	 )
)
;

SELECT CONVERT(datetime2, '99991231');
GO

CREATE OR ALTER VIEW dbo.vw_SJ_BST
WITH SCHEMABINDING
AS
	WITH x AS (
		SELECT BST = DATEADD(HOUR, 1, CONVERT(datetime, d))
		FROM dbo.Dates
		WHERE wd = 'Sunday'
			AND d >= '20150325'
			AND d <  DATEFROMPARTS(YEAR(CURRENT_TIMESTAMP), 11, 01)
			AND MONTH(d) IN (3, 10)
			AND DAY(d) >= 25
	)
	SELECT
		 s = x1.BST
		,e = x2.BST
	FROM x x1
	INNER JOIN x x2
		ON  YEAR(x1.BST) = YEAR(x2.BST)
		AND x1.BST       < x2.BST
	;
GO

SELECT t.*, CASE WHEN bst.s IS NOT NULL THEN DATEADD(HOUR, 1, t.EventTimeStamp) ELSE t.EventTimeStamp END
FROM Vodafone.dbo.Trip t
LEFT JOIN dbo.vw_SJ_BST bst
	ON  t.EventTimeStamp >= bst.s
	AND t.EventTimeStamp <  bst.e
	AND bst.e >= '20200101'
WHERE t.EventTimeStamp >= '20200101'
;

SELECT t.*, CASE WHEN bst.s IS NOT NULL THEN DATEADD(HOUR, 1, t.EventTimeStamp) ELSE t.EventTimeStamp END
FROM Vodafone.dbo.Trip t
LEFT JOIN #LEL bst
	ON  t.EventTimeStamp >= bst.s
	AND t.EventTimeStamp <  bst.e
	AND bst.e >= '20200101'
WHERE t.EventTimeStamp >= '20200101'
;

SELECT t.*, CASE WHEN bst.s IS NOT NULL THEN DATEADD(HOUR, 1, t.EventTimeStamp) ELSE t.EventTimeStamp END
FROM Vodafone.dbo.Trip t
LEFT JOIN #LEL2 bst
	ON  t.EventTimeStamp >= bst.s
	AND t.EventTimeStamp <  bst.e
	AND bst.e >= '20200101'
WHERE t.EventTimeStamp >= '20200101'
;


SELECT *
FROM Vodafone.dbo.Trip
WHERE EventTimeStamp >= '20200101'
;

CREATE TABLE #LEL2 (s date NOT NULL, e date NOT NULL, CONSTRAINT PK_LEL2_se PRIMARY KEY CLUSTERED (s ASC));
INSERT #LEL2
SELECT *
FROM dbo.vw_SJ_BST

;WITH lw AS (
	SELECT
		 s = DATEADD(DAY, v1.d, DATETIMEFROMPARTS(v2.y, 03, 25, 01, 00, 00, 000))
		,e = DATEADD(DAY, v1.d, DATETIMEFROMPARTS(v2.y, 10, 25, 01, 00, 00, 000))
	FROM (
		VALUES
			 (0)
			,(1)
			,(2)
			,(3)
			,(4)
			,(5)
			,(6)
	) v1(d)
	CROSS APPLY (
		VALUES
			 (2015)
			,(2016)
			,(2017)
			,(2018)
			,(2019)
			,(2020)
	) v2(y)
	--ORDER BY s, e
)
SELECT lw1.s, lw2.e
FROM lw lw1
INNER JOIN lw lw2
	ON YEAR(lw1.s) = YEAR(lw2.e)
WHERE DATENAME(WEEKDAY, lw1.s) = N'Sunday'
	AND DATENAME(WEEKDAY, lw2.e) = N'Sunday'
;

