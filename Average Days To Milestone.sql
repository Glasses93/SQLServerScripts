
--SET STATISTICS IO, TIME ON;

;WITH a AS (
	SELECT ALL TOP (100) PolicyNumber
	FROM RedTail.dbo.Association
	ORDER BY AssociationID ASC
),
x AS (
	SELECT ALL
		 PolicyNumber
		,JourneyEndTime
		,RollingMileage =
			SUM(MilesDriven) OVER (
				PARTITION BY PolicyNumber
				ORDER BY     JourneyEndTime ASC
				ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
			)
		,FirstTripTime = MIN(JourneyStartTime) OVER (PARTITION BY PolicyNumber)
	FROM DataSummary.dbo.RedTailScoreJourney
	WHERE PolicyNumber IN (
		SELECT PolicyNumber
		FROM a
	)
	--WHERE PolicyNumber = 'ADAPT5349767001001'
	--WHERE PolicyNumber LIKE 'BL%'
),
y(Milestone) AS (
	SELECT ALL TOP (4) ROW_NUMBER() OVER (ORDER BY [object_id] ASC) * 250
	FROM staging.sys.all_objects
	ORDER BY [object_id] ASC
),
z AS (
	SELECT ALL
		 *
		,RN = ROW_NUMBER() OVER (PARTITION BY x.PolicyNumber, y.Milestone ORDER BY x.JourneyEndTime ASC)
	FROM x
	INNER JOIN y
		ON x.RollingMileage >= y.Milestone
)
SELECT ALL
	 Milestone
	,AverageDaysToMilestone = AVG(DATEDIFF(MINUTE, FirstTripTime, JourneyEndTime) / 1440.0)
--INTO dbo.SJ_BellRedTailMilestones
FROM z
WHERE RN = 1
GROUP BY Milestone
ORDER BY Milestone ASC
;

;WITH a AS (
	SELECT ALL TOP (100) PolicyNumber
	FROM RedTail.dbo.Association
	ORDER BY AssociationID ASC
),
x AS (
	SELECT ALL
		 PolicyNumber
		,JourneyEndTime
		,RollingMileage =
			SUM(MilesDriven) OVER (
				PARTITION BY PolicyNumber
				ORDER BY     JourneyEndTime ASC
				ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
			)
		,FirstTripTime = MIN(JourneyStartTime) OVER (PARTITION BY PolicyNumber)
	FROM DataSummary.dbo.RedTailScoreJourney
	--WHERE PolicyNumber IN (
	--	SELECT PolicyNumber
	--	FROM a
	--)
	--WHERE PolicyNumber = 'ADAPT5349767001001'
	WHERE PolicyNumber LIKE 'BL%'
),
y(Milestone, Limit) AS (
	SELECT ALL TOP (4)
		  ROW_NUMBER() OVER (ORDER BY [object_id] ASC) * 250
		,(ROW_NUMBER() OVER (ORDER BY [object_id] ASC) * 250) + 250
	FROM staging.sys.all_objects
	ORDER BY [object_id] ASC
),
z AS (
	SELECT ALL
		 *
		,RN = ROW_NUMBER() OVER (PARTITION BY x.PolicyNumber, y.Milestone ORDER BY x.JourneyEndTime ASC)
	FROM x
	INNER JOIN y
		ON  x.RollingMileage >= y.Milestone
		AND x.RollingMileage <  y.Limit
)
SELECT ALL
	 Milestone
	,AverageDaysToMilestone = AVG(DATEDIFF(MINUTE, FirstTripTime, JourneyEndTime) / 1440.0)
--INTO dbo.SJ_BellRedTailMilestones
FROM z
WHERE RN = 1
GROUP BY Milestone
ORDER BY Milestone ASC
;
