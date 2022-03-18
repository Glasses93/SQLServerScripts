SELECT TOP (100) *
FROM dbo.TEL1516_TraversedSlices
;

SELECT TOP (100) *
FROM dbo.TEL1516_TripsPerDay
;

SET STATISTICS IO, TIME ON;

;WITH d AS (
	SELECT
		 d.d
		--,d.wd
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
	WHERE d.d >= '20201201'
		AND d.d < DATEADD(DAY, -1, CONVERT(date, CURRENT_TIMESTAMP))
)
SELECT
	 d.d
	--,d.wd
	,Brand      = COALESCE(d.Brand, 'Both Brands')
	,Telematics = COUNT(DISTINCT ts.PolicyNumber)
FROM d
LEFT OUTER JOIN dbo.TEL1516_TraversedSlices ts
	ON  d.d     < ts.RiskCXXDate
	AND d.Brand = ts.Brand
	AND ts.RiskCXXDate >= '20201202'
	AND EXISTS (
		SELECT 1
		FROM dbo.TEL1516_TripsPerDay tpd
		WHERE ts.Account_ID = tpd.Account_ID
			AND tpd.[Day] >= DATEADD(DAY, -6, d.d)
			AND tpd.[Day] <= d.d
			AND tpd.[Day] >= DATEADD(DAY, -6, '20201201') 
	)
LEFT JOIN dbo.SJ_BatchModeEnabler bme
	ON 1 = 0
GROUP BY
	 d.d
	--,d.wd
	,GROUPING SETS (
		 (d.Brand)
		,()
	 )
--ORDER BY
--	 x.d DESC
--	,Brand
;

DROP INDEX CIX ON dbo.TEL1516_TraversedSlices;
DROP INDEX CIX ON dbo.TEL1516_TripsPerDay;

CREATE CLUSTERED INDEX CIX ON dbo.TEL1516_TraversedSlices (RiskCXXDate, Account_ID);
CREATE UNIQUE CLUSTERED INDEX CIX ON dbo.TEL1516_TripsPerDay ([Day], Account_ID);
