
SET STATISTICS IO, TIME ON;

-- Overlapping intervals and hours parked at night:
;WITH x AS (
	SELECT NightStartTime = DATEADD(HOUR, -2, CONVERT(datetime, d)), NightEndTime = DATEADD(HOUR, +4, CONVERT(datetime, d))
	FROM dbo.Dates
	WHERE d >= '20210101'
		AND d < '20210107'
),
y AS (
	SELECT ID = 1, ParkedTime = CONVERT(datetime, '2021-01-01T13:00:00'), NextJourneyStartTime = CONVERT(datetime, '2021-01-03T23:00:00')
	UNION ALL
	SELECT ID = 2, ParkedTime = CONVERT(datetime, '2021-01-01T13:00:00'), NextJourneyStartTime = CONVERT(datetime, '2021-01-01T23:00:00')
	UNION ALL
	SELECT ID = 3, ParkedTime = CONVERT(datetime, '2021-01-03T23:00:00'), NextJourneyStartTime = CONVERT(datetime, '2021-01-04T01:00:00')
	UNION ALL
	SELECT ID = 4, ParkedTime = CONVERT(datetime, '2021-01-05T03:00:00'), NextJourneyStartTime = CONVERT(datetime, '2021-01-05T21:00:00')
)
SELECT
	 ID
	,NightHoursParked = SUM(CONVERT(bigint, DATEDIFF(SECOND, ca.ParkedNightStartTime, ca.ParkedNightEndTime))) / 3600.0
FROM y
INNER JOIN x
	ON  y.NextJourneyStartTime >= x.NightStartTime
	AND y.ParkedTime           <  x.NightEndTime
CROSS APPLY (
	SELECT
		 ParkedNightStartTime = MAX(v.ParkedAndNightStartTime        )
		,ParkedNightEndTime   = MIN(v.NextJourneyStartAndNightEndTime)
	FROM (
		VALUES
			 (y.ParkedTime    , y.NextJourneyStartTime)
			,(x.NightStartTime, x.NightEndTime        )
	) v(ParkedAndNightStartTime, NextJourneyStartAndNightEndTime)
) ca
GROUP BY y.ID
ORDER BY y.ID
;


-- Overlapping intervals and hours parked at night:
;WITH x AS (
	SELECT NightStartTime = DATEADD(HOUR, -2, CONVERT(datetime, d)), NightEndTime = DATEADD(HOUR, +4, CONVERT(datetime, d))
	FROM dbo.Dates
	WHERE d >= '20210101'
		AND d < '20210107'
),
y AS (
	SELECT ID = 1, ParkedTime = CONVERT(datetime, '2021-01-01T13:00:00'), NextJourneyStartTime = CONVERT(datetime, '2021-01-03T23:00:00')
	UNION ALL
	SELECT ID = 2, ParkedTime = CONVERT(datetime, '2021-01-01T13:00:00'), NextJourneyStartTime = CONVERT(datetime, '2021-01-01T23:00:00')
	UNION ALL
	SELECT ID = 3, ParkedTime = CONVERT(datetime, '2021-01-03T23:00:00'), NextJourneyStartTime = CONVERT(datetime, '2021-01-04T01:00:00')
	UNION ALL
	SELECT ID = 4, ParkedTime = CONVERT(datetime, '2021-01-05T03:00:00'), NextJourneyStartTime = CONVERT(datetime, '2021-01-05T21:00:00')
)
SELECT
	 ID
	,NightHoursParked =
		SUM(CONVERT(bigint, DATEDIFF(
			 SECOND
			,CASE WHEN y.ParkedTime           > x.NightStartTime THEN y.ParkedTime           ELSE x.NightStartTime END
			,CASE WHEN y.NextJourneyStartTime < x.NightEndTime   THEN y.NextJourneyStartTime ELSE x.NightEndTime   END
		))) / 3600.0
FROM y
INNER JOIN x
	ON  y.NextJourneyStartTime >= x.NightStartTime
	AND y.ParkedTime           <  x.NightEndTime
GROUP BY y.ID
ORDER BY y.ID
;
