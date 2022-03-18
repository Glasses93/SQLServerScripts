;WITH avb AS (
	SELECT
		 PolicyNumber
		,CoverStartDate = MIN(EffectFromDate)
	FROM dbo.PolCVPTrav
	WHERE TraversedFlag = '1'
		AND EffectFromDate <= CONVERT(date, CURRENT_TIMESTAMP)
		AND TelematicsFlag = '1'
		AND TeleDevSuppl = 'vodafone'
		AND TeleDevRem = '0'
	GROUP BY PolicyNumber
),
d AS (
	SELECT
		 d.d
		,d.wd
		,avb.*
	FROM dbo.Dates d
	INNER JOIN avb
		ON d.d >= avb.CoverStartDate
	WHERE d.d < CONVERT(date, CURRENT_TIMESTAMP)
),
m AS (
	SELECT
		 ExternalContractNumber
		,d = CONVERT(date, EventTimeStamp)
		,Mileage = (SUM(DeltaTripDistance) * 100) / 1609.344 
	FROM Vodafone.dbo.Trip t
	WHERE EXISTS (
		SELECT 1
		FROM avb
		WHERE t.ExternalContractNumber = CONVERT(nvarchar(20), avb.PolicyNumber)
	)
	GROUP BY
		 ExternalContractNumber
		,CONVERT(date, EventTimeStamp)
)
SELECT
	 d.*
	,m.Mileage
FROM d
LEFT JOIN m
	ON  d.d = m.d
	AND d.PolicyNumber = m.ExternalContractNumber
ORDER BY
	 d.d
	,d.PolicyNumber
;

;WITH avb AS (
	SELECT
		 PolicyNumber   = CONVERT(nvarchar(20), PolicyNumber)
		,CoverStartDate = MIN(EffectFromDate)
	FROM dbo.PolCVPTrav
	WHERE TraversedFlag = '1'
		AND EffectFromDate <= CONVERT(date, CURRENT_TIMESTAMP)
		AND TelematicsFlag = '1'
		AND TeleDevSuppl = 'vodafone'
		AND TeleDevRem = '0'
	GROUP BY CONVERT(nvarchar(20), PolicyNumber)
),
d AS (
	SELECT
		 d.d
		,d.wd
		,avb.*
	FROM dbo.Dates d
	INNER JOIN avb
		ON d.d >= avb.CoverStartDate
	WHERE d.d < CONVERT(date, CURRENT_TIMESTAMP)
),
m AS (
	SELECT
		 ExternalContractNumber
		,d = CONVERT(date, EventTimeStamp)
		,Mileage = (SUM(DeltaTripDistance) * 100) / 1609.344 
	FROM Vodafone.dbo.Trip t
	WHERE EXISTS (
		SELECT 1
		FROM avb
		WHERE t.ExternalContractNumber = avb.PolicyNumber
	)
	GROUP BY
		 ExternalContractNumber
		,CONVERT(date, EventTimeStamp)
)
SELECT
	 d.*
	,m.Mileage
FROM d
LEFT JOIN m
	ON  d.d = m.d
	AND d.PolicyNumber = m.ExternalContractNumber
ORDER BY
	 d.d
	,d.PolicyNumber
;