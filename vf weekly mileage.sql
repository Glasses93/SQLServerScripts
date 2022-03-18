
DROP TABLE IF EXISTS #YEET;

;WITH x AS (
	SELECT
		 PolicyNumber
		,NumTerm
		,FirstDayOfTerm	= MIN(EffectFromDate)
		,LastDayOfTerm  = MAX(EffectToDate)
	FROM dbo.PolCVPTrav
	WHERE PolicyNumber IS NOT NULL
		AND NumTerm IS NOT NULL
		AND EffectFromDate IS NOT NULL
		AND EffectToDate IS NOT NULL
		AND TraversedFlag = '1'
		AND EffectFromDate <= CONVERT(date, CURRENT_TIMESTAMP)
		AND TelematicsFlag = '1'
		AND TeleDevSuppl = 'vodafone'
		AND TeleDevRem = '0'
	GROUP BY
		 PolicyNumber
		,NumTerm
),
y AS (
	SELECT
		 vr.PolicyNumber
		,InstallationDate = CONVERT(date, MIN(gmi.EquipmentActivationDatetime))
	FROM Vodafone.dbo.VoucherResponse vr
	INNER JOIN Vodafone.dbo.GeneralMI gmi
		ON vr.voucherID = gmi.VoucherID
	WHERE vr.PolicyNumber IS NOT NULL
		AND gmi.EquipmentActivationDatetime IS NOT NULL
	GROUP BY vr.PolicyNumber
)
SELECT
	 PolicyNumber		= ISNULL(CONVERT(varchar(22), x.PolicyNumber), 'blah')
	,NumTerm			= ISNULL(CONVERT(tinyint, x.NumTerm), 255)
	,FirstDayOfTerm		= ISNULL(x.FirstDayOfTerm, '19000101')
	,LastDayOfTerm		= ISNULL(x.LastDayOfTerm, '19000101')
	,InstallationDate	= ISNULL(y.InstallationDate, '19000101')
	,ca.Minimom
INTO #YEET
FROM x
INNER JOIN y
	ON x.PolicyNumber = y.PolicyNumber
CROSS APPLY (
	SELECT Minimom = MIN(v.d)
	FROM (
		VALUES
			 (x.LastDayOfTerm)
			,(CONVERT(date, CURRENT_TIMESTAMP))
	) v(d)
) ca
;

SELECT
	 wc = d.d
	,y.*
INTO #YEET2
FROM dbo.Dates d
INNER JOIN #YEET y
	ON  d.d >= DATEADD(DAY, 1 - DATEPART(WEEKDAY, y.InstallationDate), CONVERT(date, y.InstallationDate))
	AND d.d >= y.FirstDayOfTerm
	AND d.d <  y.LastDayOfTerm
WHERE d.wd = 'Monday'
;

;WITH c AS (
	SELECT
		 vj.PolicyNumber
		,y.NumTerm
		,wc				= DATEADD(DAY, 1 - DATEPART(WEEKDAY, vj.starttime), CONVERT(date, vj.starttime))
		,MilesDriven	= SUM(vj.miles_driven)
	FROM DataSummary.dbo.VodaJourneys vj
	INNER JOIN #YEET y
		ON  vj.PolicyNumber = y.PolicyNumber
		AND vj.starttime   >= y.FirstDayOfTerm
		AND vj.starttime   <  y.LastDayOfTerm
	WHERE vj.miles_driven IS NOT NULL
	GROUP BY
		 vj.PolicyNumber
		,y.NumTerm
		,DATEADD(DAY, 1 - DATEPART(WEEKDAY, vj.starttime), CONVERT(date, vj.starttime))
)
SELECT
	 y.*
	,MilesDriven = ISNULL(c.MilesDriven, 0)
INTO dbo.SJ_VFTESTINGS
FROM #YEET2 y
LEFT OUTER JOIN c
	ON  y.PolicyNumber	= c.PolicyNumber
	AND y.NumTerm		= c.NumTerm
	AND y.wc			= c.wc
LEFT OUTER JOIN dbo.SJ_BatchModeEnabler bme
	ON 1 = 0
;

ALTER TABLE dbo.SJ_VFTESTINGS ADD CONSTRAINT YEET PRIMARY KEY CLUSTERED (PolicyNumber ASC, NumTerm ASC, wc ASC);

SELECT TOP (100) *
FROM dbo.SJ_VFTESTINGS
;
