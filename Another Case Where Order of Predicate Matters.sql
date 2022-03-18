SET STATISTICS IO, TIME ON;

;WITH d AS (
	SELECT
			d.d
		,b.Brand
	FROM dbo.Dates d
	INNER JOIN (
		SELECT *
		FROM (
			VALUES
					('Elephant', CONVERT(date, '20180424'))
				,('Admiral' , CONVERT(date, '20190605'))
		) v(Brand, LaunchDate)
	) b
		ON  d.d >= b.LaunchDate
	WHERE d.d >= DATEADD(DAY, -32, CONVERT(date, CURRENT_TIMESTAMP))
		AND d.d < DATEADD(DAY, -1, CONVERT(date, CURRENT_TIMESTAMP))
)
SELECT
		d.d
	,d.Brand
	,Risks = COUNT(DISTINCT ts.PolicyNumber)
FROM d
LEFT OUTER JOIN dbo.TEL1516_TraversedSlices ts
	ON  d.d     < ts.RiskCXXDate
	AND d.Brand = ts.Brand
	AND ts.RiskCXXDate >= DATEADD(DAY, -31, CONVERT(date, CURRENT_TIMESTAMP))
	AND EXISTS (
		SELECT 1
		FROM dbo.TEL1516_TripsPerDay tpd
		WHERE tpd.[Day] >= DATEADD(DAY, -38, CONVERT(date, CURRENT_TIMESTAMP))
			AND tpd.[Day] >= DATEADD(DAY, -6, d.d)
			AND tpd.[Day] <= d.d
			AND ts.Account_ID = tpd.Account_ID
	)
LEFT JOIN dbo.SJ_BatchModeEnabler bme
	ON 1 = 0
GROUP BY
		d.d
	,GROUPING SETS (
			(d.Brand)
		,()
		)
;

					

;WITH d AS (
	SELECT
			d.d
		,b.Brand
	FROM dbo.Dates d
	INNER JOIN (
		SELECT *
		FROM (
			VALUES
					('Elephant', CONVERT(date, '20180424'))
				,('Admiral' , CONVERT(date, '20190605'))
		) v(Brand, LaunchDate)
	) b
		ON  d.d >= b.LaunchDate
	WHERE d.d >= DATEADD(DAY, -32, CONVERT(date, CURRENT_TIMESTAMP))
		AND d.d < DATEADD(DAY, -1, CONVERT(date, CURRENT_TIMESTAMP))
)
SELECT
		d.d
	,d.Brand
	,Risks = COUNT(DISTINCT ts.PolicyNumber)
FROM d
LEFT OUTER JOIN dbo.TEL1516_TraversedSlices ts
	ON  d.d     < ts.RiskCXXDate
	AND d.Brand = ts.Brand
	AND ts.RiskCXXDate >= DATEADD(DAY, -31, CONVERT(date, CURRENT_TIMESTAMP))
	AND EXISTS (
		SELECT 1
		FROM dbo.TEL1516_TripsPerDay tpd
		WHERE ts.Account_ID = tpd.Account_ID
			AND tpd.[Day] >= DATEADD(DAY, -6, d.d)
			AND tpd.[Day] <= d.d
			AND tpd.[Day] >= DATEADD(DAY, -38, CONVERT(date, CURRENT_TIMESTAMP))
	)
LEFT JOIN dbo.SJ_BatchModeEnabler bme
	ON 1 = 0
GROUP BY
		d.d
	,GROUPING SETS (
			(d.Brand)
		,()
		)
;