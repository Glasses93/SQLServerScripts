;WITH z AS (
	SELECT DISTINCT
		 Account_id
		,Driveid
		,LatestTripLabel =
			FIRST_VALUE(New_label) OVER (
				PARTITION BY Account_id, Driveid
				ORDER BY     Label_change_date DESC, ImportFileID DESC
			)
	FROM CMTSERV.dbo.CMTTripLabel
	WHERE Account_id LIKE 'P%M%'
),
x AS (
	SELECT
		 ts.Account_ID
		,ts.Trip_End
		,AccumulativeMileage =
			SUM(ts.Distance_Mapmatched_KM) OVER (
				PARTITION BY ts.Account_ID
				ORDER BY     ts.Trip_End ASC
				ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
			) / 1.609344 -- Convert from KM to miles.
		,FirstTripDate = MIN(ts.Trip_Start) OVER (PARTITION BY ts.Account_ID)
	FROM CMTSERV.dbo.CMTTripSummary ts
	LEFT JOIN z
		ON  ts.Account_ID = z.Account_id
		AND ts.DriveID    = z.Driveid
	-- Remove Admiral Rewards:
	WHERE NOT EXISTS (
		SELECT 1
		FROM CMTSERV.dbo.ADM_Rewards_Summary ar
		WHERE ts.Account_ID = ar.accountId
	)
		-- Admiral only:
		AND NOT EXISTS (
			SELECT 1
			FROM CMTSERV.dbo.AppAssociation aa
			WHERE ts.Account_ID = aa.Account_ID
				AND aa.Brand = 'Elephant'
		)
		-- Driver trips only (based on most recent assigned label):
		AND COALESCE(z.LatestTripLabel, ts.User_Label, ts.Trip_Mode) IN ('car', 'DRIVER')
),
y AS (
	SELECT
		 *
		,RN = ROW_NUMBER() OVER (PARTITION BY Account_ID ORDER BY Trip_End ASC)
	FROM x
	WHERE AccumulativeMileage >= 500
)
SELECT
	 FirstTripYear         = YEAR(FirstTripDate)
	,FirstTripMonth        = MONTH(FirstTripDate)
	,FirstTripMonthName    = DATENAME(MONTH, FirstTripDate)
	,AverageDaysTo500Miles = AVG(DATEDIFF(MINUTE, FirstTripDate, Trip_End) / 1440.0)
	,Risks                 = COUNT(*)
FROM y
-- The first journey that exceeds the accumulative mileage of 500:
WHERE RN = 1
GROUP BY GROUPING SETS (
	 (YEAR(FirstTripDate), MONTH(FirstTripDate), DATENAME(MONTH, FirstTripDate))
	,()
)
ORDER BY
	 CASE WHEN YEAR(FirstTripDate) IS NULL THEN 1 ELSE 2 END ASC
	,1 DESC
	,2 DESC
;

SELECT
	 FirstTripYear         = YEAR(ar1.dateRewarded)
	,FirstTripMonth        = MONTH(ar1.dateRewarded)
	,FirstTripMonthName    = DATENAME(MONTH, ar1.dateRewarded)
	,AverageDaysTo500Miles = AVG(DATEDIFF(MINUTE, ar1.dateRewarded, ar2.dateRewarded) / 1440.0)
	,Risks                 = COUNT(*)
FROM CMTSERV.dbo.ADM_Rewards ar1
INNER JOIN CMTSERV.dbo.ADM_Rewards ar2
	ON  ar1.account_ID = ar2.account_ID
	AND ar1.rewardId   = 'rewardFirstTrip'
	AND ar2.rewardId   = 'reward500miles'
	AND ar2.dateRewarded > ar1.dateRewarded
	AND ar1.account_ID LIKE 'P%M%'
GROUP BY GROUPING SETS (
	 (YEAR(ar1.dateRewarded), MONTH(ar1.dateRewarded), DATENAME(MONTH, ar1.dateRewarded))
	,()
)
ORDER BY
	 CASE WHEN YEAR(ar1.dateRewarded) IS NULL THEN 1 ELSE 2 END ASC
	,1 DESC
	,2 DESC
;
