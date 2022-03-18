
--SET STATISTICS IO, TIME ON;

--DROP TABLE #T1, #T2;

SELECT
	 d.[Date]
	,KM = ISNULL(SUM(ts.Distance_Mapmatched_KM), 0)
INTO #T1
FROM dbo.Dates d
LEFT OUTER JOIN (
	SELECT Trip_Start, Trip_End, Distance_Mapmatched_KM
	FROM CMTSERV.dbo.CMTTripSummary_EL
	WHERE Trip_End >= '20210101'
		AND Trip_Start < '20210201'
) ts
	ON (
			d.[Date] = CONVERT(date, ts.Trip_Start)
		OR	d.[Date] = CONVERT(date, ts.Trip_End)
	)
WHERE d.[Date] >= '20210101'
	AND d.[Date] < '20210201'
GROUP BY d.[Date]
ORDER BY d.[Date]
;

;WITH d AS (
	SELECT [Date]
	FROM dbo.Dates
	WHERE [Date] >= '20210101'
		AND [Date] < '20210201'
),
y AS (
	SELECT
		 TripDate = CONVERT(date, ca.TripDate)
		,Dist	  = SUM(COALESCE(ca.Distance_Mapmatched_KM, ca.Distance_Mapmatched_KM_2))
	FROM CMTSERV.dbo.CMTTripSummary_EL ts
	CROSS APPLY (
		SELECT
			 v.TripDate
			,v.Distance_Mapmatched_KM
			,v.Distance_Mapmatched_KM_2
		FROM (
			VALUES
				 (ts.Trip_Start, CASE WHEN CONVERT(date, ts.Trip_Start) != CONVERT(date, ts.Trip_End) THEN ts.Distance_Mapmatched_KM END, ts.Distance_Mapmatched_KM)
				,(ts.Trip_End  , CASE WHEN CONVERT(date, ts.Trip_Start) != CONVERT(date, ts.Trip_End) THEN ts.Distance_Mapmatched_KM END, NULL)
		) v(TripDate, Distance_Mapmatched_KM, Distance_Mapmatched_KM_2)
	) ca
	WHERE ca.TripDate >= '20210101'
		AND ca.TripDate < '20210201'
		AND ts.Trip_End >= '20210101'
		AND ts.Trip_Start < '20210201'
	GROUP BY CONVERT(date, ca.TripDate)
)
SELECT
	 d.[Date]
	,KM = ISNULL(y.Dist, 0)
INTO #T2
FROM d
LEFT OUTER JOIN y
	ON d.[Date] = y.TripDate
ORDER BY d.[Date]
;

--SELECT *
--FROM #T1
--;

--SELECT *
--FROM #T2
--;

SELECT *
FROM #T2
EXCEPT
SELECT *
FROM #T1
;
