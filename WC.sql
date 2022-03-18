
;WITH x AS (
	SELECT
		 rp.PolygonName
		,wc = DATEADD(DAY, 1 - DATEPART(WEEKDAY, rp.FirstTimeStamp), CONVERT(date, rp.FirstTimeStamp))
		,m  = SUM(rp.MilesDriven)
		,nm = SUM(rp.NightMiles)
	FROM DataSummary.dbo.RedTailPolygons rp
	LEFT JOIN dbo.SJ_BatchModeEnabler bme
		ON 1 = 0
	GROUP BY
		 rp.PolygonName
		,DATEADD(DAY, 1 - DATEPART(WEEKDAY, rp.FirstTimeStamp), CONVERT(date, rp.FirstTimeStamp))
)
SELECT
	 p.PolygonName
	,d.d
	,Mileage     = ISNULL(x.m , 0)
	,NiteMileage = ISNULL(x.nm, 0)
INTO #Temp
FROM dbo.Dates d
CROSS JOIN staging.dbo.Polygons p
LEFT JOIN x
	ON  d.d = x.wc
	AND p.PolygonName = x.PolygonName
WHERE d.wd = 'Monday'
	AND d.d >= '20200101'
	AND d.d <  '20201218'
	--AND 1 = 0
ORDER BY
	 p.PolygonName
	,d.d
;

SELECT *
FROM #Temp
ORDER BY
	 PolygonName
	,d
;

SELECT
	 *
	,RollingAverage =
		AVG(Mileage) OVER (
			PARTITION BY PolygonName
			ORDER BY d
			ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
		)
FROM #Temp
ORDER BY
	 PolygonName
	,d
;


