SELECT *
INTO dbo.SJ_Testy
FROM DataSummary.dbo.RedTailPolygons
WHERE IMEI IN (
	SELECT TOP (1) IMEI
	FROM DataSummary.dbo.RedTailPolygons
)
;

SELECT *
FROM dbo.Dates d
INNER JOIN dbo.SJ_Testy t
	ON t.LastTimeStamp < d.d
WHERE d.d > '20201011'
	AND d.d <= CONVERT(date, CURRENT_TIMESTAMP)
ORDER BY d.d, t.FirstTimeStamp
;


SELECT
	 d.d
	,Mileage = 
		AVG(ISNULL(SUM(MilesDriven), 0)) OVER (
			ORDER BY d.d ASC
			ROWS BETWEEN 13 PRECEDING AND CURRENT ROW
		)
FROM dbo.Dates d
LEFT JOIN dbo.SJ_Testy t
	ON d.d = CONVERT(date, t.FirstTimeStamp)
WHERE d.d >= '20201001'
	AND d.d < '20210101'
	AND (
			t.PolygonName = 'Birmingham'
		OR	t.PolygonName IS NULL
	)
GROUP BY d.d
ORDER BY d.d ASC
;

SELECT
	 d.d
	,Mileage = ISNULL(SUM(MilesDriven), 0)
FROM dbo.Dates d
LEFT JOIN dbo.SJ_Testy t
	ON d.d = CONVERT(date, t.FirstTimeStamp)
WHERE d.d >= '20201001'
	AND d.d < '20210101'
	AND (
			t.PolygonName = 'Birmingham'
		OR	t.PolygonName IS NULL
	)
GROUP BY d.d
ORDER BY d.d ASC
;

;WITH n(n) AS (
	SELECT ROW_NUMBER() OVER (ORDER BY [object_id] ASC)
	FROM staging.sys.all_columns
	ORDER BY [object_id] ASC
	OFFSET 0 ROWS
	FETCH FIRST 52 ROWS ONLY
)
SELECT
	 n.n
	,Mileage = ISNULL(SUM(t.MilesDriven), 0)
	,RollingAverage =
		AVG(ISNULL(SUM(t.MilesDriven), 0)) OVER (
			
			ORDER BY n.n ASC
			ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
		)
FROM n
LEFT JOIN dbo.SJ_Testy t
	ON n.n = DATEPART(WEEK, t.FirstTimeStamp)
WHERE n.n % 2 = 0
GROUP BY n.n
ORDER BY 1 ASC
;

