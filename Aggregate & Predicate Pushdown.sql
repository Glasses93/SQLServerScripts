;WITH d AS (
	SELECT
		 d.d
		,d.wd
		,p.PolygonName
	FROM dbo.Dates d
	CROSS JOIN staging.dbo.Polygons p
	WHERE d.d >= '20201201'
		AND d.d < '20210101'
		AND p.PolygonName != 'British Isles'
)
SELECT
	 d.d
	,d.wd
	,d.PolygonName
	,Mileage = SUM(rp.MilesDriven)
--INTO #YEET
FROM d
LEFT OUTER JOIN DataSummary.dbo.RedTailPolygons rp
	ON  d.d           = CONVERT(date, rp.FirstTimeStamp)
	AND d.PolygonName = rp.PolygonName
GROUP BY
	 d.d
	,d.wd
	,d.PolygonName
;

;WITH d AS (
	SELECT
		 d.d
		,d.wd
		,p.PolygonName
	FROM dbo.Dates d
	CROSS JOIN staging.dbo.Polygons p
	WHERE d.d >= '20201201'
		AND d.d < '20210101'
		AND p.PolygonName != 'British Isles'
)
SELECT
	 d.d
	,d.wd
	,d.PolygonName
	,Mileage = SUM(rp.MilesDriven)
--INTO #YEET
FROM d
LEFT OUTER JOIN DataSummary.dbo.RedTailPolygons rp
	ON  d.d                = CONVERT(date, rp.FirstTimeStamp)
	AND d.PolygonName      = rp.PolygonName
	AND rp.FirstTimeStamp >= '20201201'
	AND rp.FirstTimeStamp <  '20210101'
GROUP BY
	 d.d
	,d.wd
	,d.PolygonName
;

;WITH d AS (
	SELECT
		 d.d
		,d.wd
		,p.PolygonName
	FROM dbo.Dates d
	CROSS JOIN staging.dbo.Polygons p
	WHERE d.d >= '20201201'
		AND d.d < '20210101'
		AND p.PolygonName != 'British Isles'
)
SELECT
	 d.d
	,d.wd
	,d.PolygonName
	,Mileage = SUM(rp.MilesDriven)
--INTO #YEET
FROM d
LEFT OUTER JOIN DataSummary.dbo.RedTailPolygons rp
	ON  d.d                = CONVERT(date, rp.FirstTimeStamp)
	AND d.PolygonName      = rp.PolygonName
	AND rp.FirstTimeStamp >= '20201201'
	AND rp.FirstTimeStamp <  '20210101'
LEFT OUTER JOIN dbo.SJ_BatchModeEnabler bme
	ON 1 = 0
GROUP BY
	 d.d
	,d.wd
	,d.PolygonName
;

;WITH d AS (
	SELECT
		 d.d
		,d.wd
		,p.PolygonName
	FROM dbo.Dates d
	CROSS JOIN staging.dbo.Polygons p
	WHERE d.d >= '20201201'
		AND d.d < '20210101'
		AND p.PolygonName != 'British Isles'
)
SELECT
	 d.d
	,d.wd
	,d.PolygonName
	,Mileage = ISNULL(SUM(rp.MilesDriven), 0)
--INTO #YEET
FROM d
LEFT OUTER JOIN DataSummary.dbo.RedTailPolygons rp
	ON  d.d                = CONVERT(date, rp.FirstTimeStamp)
	AND d.PolygonName      = rp.PolygonName
	AND rp.FirstTimeStamp >= CONVERT(datetime2(2), '20201201')
	AND rp.FirstTimeStamp <  CONVERT(datetime2(2), '20210101')
LEFT OUTER JOIN dbo.SJ_BatchModeEnabler bme
	ON 1 = 0
GROUP BY
	 d.d
	,d.wd
	,d.PolygonName
;







SET STATISTICS IO, TIME ON;


;WITH d AS (
	SELECT
		 d.d
		,d.wd
		,p.PolygonName
	FROM dbo.Dates d
	CROSS JOIN staging.dbo.Polygons p
	WHERE d.d >= '20201201'
		AND d.d < '20210101'
		AND p.PolygonName != 'British Isles'
)
SELECT
	 d.d
	,d.wd
	,d.PolygonName
	,Mileage = ISNULL(SUM(rp.MilesDriven), 0)
--INTO #YEET
FROM d
LEFT OUTER JOIN DataSummary.dbo.RedTailPolygons rp
	ON  d.d                = CONVERT(date, rp.FirstTimeStamp)
	AND d.PolygonName      = rp.PolygonName
	AND rp.FirstTimeStamp >= CONVERT(datetime2(2), '20201201')
	AND rp.FirstTimeStamp <  CONVERT(datetime2(2), '20210101')
GROUP BY
	 d.d
	,d.wd
	,d.PolygonName
;

-- Ran this one:
;WITH d AS (
	SELECT
		 d.d
		,d.wd
		,p.PolygonName
	FROM dbo.Dates d
	CROSS JOIN staging.dbo.Polygons p
	WHERE d.d >= CONVERT(date, '20201201')
		AND d.d < CONVERT(date, '20210101')
		AND p.PolygonName != 'British Isles'
)
SELECT
	 d.d
	,d.wd
	,d.PolygonName
	,Mileage = ISNULL(rp.Mileage, 0)
--INTO dbo.SJ_Testings
FROM d
LEFT OUTER JOIN (
	SELECT
		 d       = CONVERT(date, FirstTimeStamp)
		,PolygonName
		,Mileage = SUM(MilesDriven)
	FROM DataSummary.dbo.RedTailPolygons
	WHERE FirstTimeStamp >=  CONVERT(datetime2(2), '20201201')
		AND FirstTimeStamp < CONVERT(datetime2(2), '20210101')
	GROUP BY
		 PolygonName
		,CONVERT(date, FirstTimeStamp)
) rp
	ON  d.d           = rp.d
	AND d.PolygonName = rp.PolygonName
;

;WITH d AS (
	SELECT
		 d.d
		,d.wd
		,p.PolygonName
	FROM dbo.Dates d
	CROSS JOIN staging.dbo.Polygons p
	WHERE d.d >= '20201201'
		AND d.d < '20210101'
		AND p.PolygonName != 'British Isles'
),
y AS (
	SELECT
		 PolygonName
		,d       = CONVERT(date, FirstTimeStamp)
		,Mileage = SUM(MilesDriven)
	FROM DataSummary.dbo.RedTailPolygons
	WHERE FirstTimeStamp >=  '20201201'
		AND FirstTimeStamp < '20210101'
	GROUP BY
		 PolygonName
		,CONVERT(date, FirstTimeStamp)
)
SELECT
	 d.d
	,d.wd
	,d.PolygonName
	,Mileage = ISNULL(rp.Mileage, 0)
--INTO dbo.SJ_Testings
FROM d
LEFT OUTER JOIN y rp
	ON  d.d           = rp.d
	AND d.PolygonName = rp.PolygonName
;

;WITH d AS (
	SELECT
		 d.d
		,d.wd
		,p.PolygonName
	FROM dbo.Dates d
	CROSS JOIN staging.dbo.Polygons p
	WHERE d.d >= CONVERT(date, '20201201')
		AND d.d < CONVERT(date, '20210101')
		AND p.PolygonName != 'British Isles'
)
SELECT
	 d.d
	,d.wd
	,d.PolygonName
	,Mileage = ISNULL(rp.Mileage, 0)
--INTO dbo.SJ_Testings
FROM d
LEFT OUTER JOIN (
	SELECT
		 PolygonName
		,d       = CONVERT(date, FirstTimeStamp)
		,Mileage = SUM(MilesDriven)
	FROM DataSummary.dbo.RedTailPolygons
	WHERE CONVERT(date, FirstTimeStamp) >=  CONVERT(date, '20201201')
		AND CONVERT(date, FirstTimeStamp) < CONVERT(date, '20210101')
	GROUP BY
		 PolygonName
		,CONVERT(date, FirstTimeStamp)
) rp
	ON  d.d           = rp.d
	AND d.PolygonName = rp.PolygonName
LEFT OUTER JOIN dbo.SJ_BatchModeEnabler bme
	ON 1 = 0
;


SELECT *
FROM dbo.SJ_Testings
ORDER BY PolygonName, d
;

;WITH x AS (
	SELECT
		 *
		,SevenDaysPrior =
				Mileage
			/	NULLIF(LAG(Mileage, 7, NULL) OVER (
					PARTITION BY PolygonName
					ORDER BY	 d ASC
				), 0)
	FROM dbo.SJ_Testings
)
SELECT *
FROM x
WHERE d = '20201225'
ORDER BY 5 ASC
;



