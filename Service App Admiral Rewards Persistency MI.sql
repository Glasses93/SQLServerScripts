
;WITH x AS (
	SELECT
		 Account_ID
		,Trip_Start
		,RN = ROW_NUMBER() OVER (PARTITION BY Account_ID ORDER BY Trip_Start ASC)
	FROM CMTSERV.dbo.CMTTripSummary
)
SELECT Account_ID
INTO #FirstTripBeforeRewards2
FROM x
WHERE RN = 1
	AND Trip_Start >= '20200902'
	AND Trip_Start <  '20200909'
	AND EXISTS (
		SELECT 1
		FROM CMTSERV.dbo.AppAssociation aa
		WHERE x.Account_ID = aa.Account_ID
			AND aa.Brand = 'Admiral'
	)
	AND NOT EXISTS (
		SELECT 1
		FROM CMTSERV.dbo.ADM_Rewards_Summary ar
		WHERE x.Account_ID = ar.accountId
	)
;

SELECT *
FROM #FirstTripBeforeRewards2
;

-- # of Admiral risks who sent a first in the week leading up to the second phase of the Admiral Rewards campaign: 2,337.

;WITH x AS (
	SELECT
		 Account_ID
		,Trip_Start
		,Distance_Mapmatched_KM
		,RN = ROW_NUMBER() OVER (PARTITION BY DriveID ORDER BY InsertedDate ASC)
	FROM CMTSERV.dbo.CMTTripSummary ts
	WHERE EXISTS (
		SELECT 1
		FROM #FirstTripBeforeRewards2 ft
		WHERE ts.Account_ID = ft.Account_ID
	)
)
,y AS (
	SELECT
		 Account_ID
		,Trip_Start
		,KM = SUM(Distance_Mapmatched_KM) OVER (PARTITION BY Account_ID ORDER BY Trip_Start ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
	FROM x
	WHERE RN = 1
		AND Trip_Start < DATEADD(DAY, 28, '20200909')
)
SELECT AVG(DaysTo), COUNT(CASE WHEN DaysTo IS NOT NULL THEN Account_ID END)
FROM (
	SELECT
		 Account_ID
		,DaysTo = DATEDIFF(DAY, MIN(Trip_Start), MIN(CASE WHEN KM / 1.609344 >= 250 THEN Trip_Start END)) * 1.0
	FROM y
	GROUP BY Account_ID
) dt
;

-- 994 people to 250 and on avg 10.787726 days
-- 3.362214 days to 50

-- # of Admiral risks who sent a first in the week leading up to the second phase of the Admiral Rewards campaign
-- and achieved 50 miles or more within 28 days: 1,662 (71.1%).

;WITH x AS (
	SELECT DISTINCT accountId, unlockDate
	FROM CMTSERV.dbo.ADM_Rewards_Summary
	WHERE rewardId = 'rewardFirstTrip'
		AND unlockDate >= '20200909'
		AND unlockDate <  '20200916'
		AND accountId LIKE 'P%M%'
)
SELECT 
AVG(DATEDIFF(DAY, x.unlockDate, ar.unlockDate) * 1.0), COUNT(DISTINCT ar.accountId)
--*
FROM CMTSERV.dbo.ADM_Rewards_Summary ar
INNER JOIN x
	ON ar.accountId = x.accountId
WHERE ar.rewardId = 'reward300Miles'
	AND ar.unlockDate < DATEADD(DAY, 28, '20200916')
;

SELECT 244/330.0

-- 330 first trip first week of ad rewards.
-- 244
-- 3.280545 days to 50
