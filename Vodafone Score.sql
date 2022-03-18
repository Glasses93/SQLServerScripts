
-- VODAFONE SCORE.

-- SET CONFIGURATIONS.

SET DATEFIRST         1 ;
SET NOCOUNT           ON;
SET ANSI_NULLS        ON;
SET QUOTED_IDENTIFIER ON;

-- CHECKS FOR DAYS.

IF ( OBJECT_ID('Sandbox.dbo.PolCVPTrav', 'U') IS NULL OR OBJECT_ID('Sandbox.dbo.TEL0012_Postcodes3', 'U') IS NULL )
BEGIN
	PRINT 'Sandbox.dbo.PolCVPTrav OR Sandbox.dbo.TEL0012_Postcodes3 does not exist. This script will syntax error on purpose.';
	SELECT *
	FROM Ble.Mae.PolCVPTrav
	;
END
ELSE
BEGIN
	IF NOT EXISTS (
		SELECT 1
		FROM Sandbox.dbo.PolCVPTrav
	) OR NOT EXISTS (
		SELECT 1
		FROM Sandbox.dbo.TEL0012_Postcodes3
	) OR (
		SELECT TOP (1) CreatedDate
		FROM Sandbox.dbo.PolCVPTrav 
	) < CAST(GETDATE() - 1 AS DATE)
	BEGIN
		PRINT 'Sandbox.dbo.PolCVPTrav OR Sandbox.dbo.TEL0012_Postcodes3 are empty. PolCVPTrav may be out-of-date. This script will syntax error on purpose.';
		SELECT *
		FROM Ble.Mae.PolCVPTrav
		;
	END
END

-- VODAFONE ACTIVE RISKS AND THEIR DECLARED RISK ADDRESS POSTCODES.

;WITH AVB (PolicyNumber) AS (
	SELECT PolicyNumber
	FROM Sandbox.dbo.PolCVPTrav
	WHERE TraversedFlag = '1'
		AND EffectFromDate <= CAST(GETDATE() AS DATE)
		AND EffectToDate > CAST(GETDATE() AS DATE)
		AND TelematicsFlag = '1'
		AND TeleDevSuppl = 'vodafone'
)

SELECT DISTINCT
	 PolicyNumber
	,NumTerm
	,EffectFromDate
	,EffectToDate
	,RiskPostcode = CAST(UPPER(REPLACE(RiskPostcode, ' ', '')) AS VARCHAR(20))
INTO Sandbox.dbo.VFS_AVBPostcodes -- DROP TABLE IF EXISTS Sandbox.dbo.VFS_AVBPostcodes;
FROM Sandbox.dbo.PolCVPTrav p
WHERE EXISTS (
	SELECT 1
	FROM AVB
	WHERE p.PolicyNumber = AVB.PolicyNumber
)
	AND TraversedFlag = '1'
	AND EffectFromDate <= CAST(GETDATE() AS DATE)
	AND TelematicsFlag = '1'
	AND TeleDevSuppl = 'vodafone'
ORDER BY
	 PolicyNumber	ASC
	,EffectFromDate	ASC
;

-- VODAFONE ACTIVE RISKS AND THEIR FIRST DECLARED ANNUAL MILEAGE PER TERM + INCEPTION & TERM EXPIRY DATES.

;WITH DeclaredMileage (PolicyNumber, NumTerm, PolIncDate, OrigDecMiles) AS (
	SELECT
		 a.PolicyNumber
		,a.NumTerm
		,a.PolIncDate
		,OrigDecMiles = a.VehMiles
	FROM (
		SELECT
			 PolicyNumber
			,PolIncDate
			,EffectFromDate
			,VehMiles
			,FirstSliceDate = MIN(EffectFromDate) OVER (PARTITION BY PolicyNumber, NumTerm)
		FROM Sandbox.dbo.PolCVPTrav
		WHERE TraversedFlag = '1'
			AND EffectFromDate <= CAST(GETDATE() AS DATE)
	) a
	WHERE a.EffectFromDate = a.FirstSliceDate
),

RenewalDates (PolicyNumber, NumTerm, PeriodEndDate) AS (
	SELECT
		 a.PolicyNumber
		,a.NumTerm
		,a.PeriodEndDate
	FROM (
		SELECT
			 PolicyNumber
			,NumTerm
			,PolIncDate
			,EffectFromDate
			,LastSliceDate = MAX(EffectFromDate) OVER (PARTITION BY PolicyNumber, NumTerm)
		FROM Sandbox.dbo.PolCVPTrav
		WHERE TraversedFlag = '1'
			AND EffectFromDate <= CAST(GETDATE() AS DATE)
	) a
	WHERE a.EffectFromDate = a.LastSliceDate
)

SELECT DISTINCT
	 pc.PolicyNumber
	,pc.NumTerm
	,dm.PolIncDate
	,rd.PeriodEndDate
	,dm.OrigDecMiles
INTO Sandbox.dbo.VFS_TermInfomation -- DROP TABLE IF EXISTS Sandbox.dbo.VFS_TermInfomation;
FROM Sandbox.dbo.VFS_AVBPostcodes p
INNER JOIN DeclaredMileage dm
	ON  p.PolicyNumber = dm.PolicyNumber
	AND p.NumTerm      = dm.NumTerm
INNER JOIN RenewalDates rd
	ON  p.PolicyNumber = rd.PolicyNumber
	AND p.NumTerm      = rd.NumTerm
ORDER BY
	 p.PolicyNumber	ASC
	,p.NumTerm		ASC
;

-- RENEWAL / INCEPTION DATES CHECK.

IF EXISTS (
	SELECT 1
	FROM Sandbox.dbo.VFS_TermInfomation a
	INNER JOIN Sandbox.dbo.VFS_TermInfomation b
		ON  a.PolicyNumber = b.PolicyNumber
		AND a.NumTerm = b.NumTerm - 1
	WHERE a.PeriodEndDate != b.PolIncDate
)
BEGIN
	PRINT
		'One or more risks have renewal dates differing to the previous term''s expiry date. This can attribute journeys and their score to the wrong terms. ' +
		'This script will syntax error on purpose.'
	;
	SELECT *
	FROM Ble.Mae.PolCVPTrav
	;
END
;

-- THE LATEST INFORMATION PER ANOMALY PER VOUCHER.

;WITH AnomaliesMI AS (
	SELECT
		 vr.PolicyNumber
		,a.*
		,RowNumber =
			ROW_NUMBER() OVER (
				PARTITION BY a.VoucherID, a.AnomalyID
				ORDER BY CASE WHEN imf.FileName LIKE '%VODA%ANOM%' AND imf.FileDate >= '2017....' THEN CONVERT(DATE, imf.FileDate, 112) ELSE a.InsertedDate END DESC, a.ImportFileID DESC
			 ) 
	FROM Vodafone.dbo.VoucherResponse vr
	INNER JOIN Vodafone.dbo.AnomaliesMI a
		ON vr.VoucherID = a.VoucherID
	LEFT JOIN Staging.dbo.ImportFile imf
		ON a.ImportFileID = imf.ImportFileID -- ASK EK ABOUT DUPLICATING IDS.
)

SELECT *
INTO Sandbox.dbo.VFS_Anomalies -- DROP TABLE IF EXISTS Sandbox.dbo.VFS_Anomalies;
FROM AnomaliesMI
WHERE RowNumber = 1
ORDER BY 
	 PolicyNumber			ASC
	,AnomalyCreationDate	ASC
;

-- THE LATEST INFORMATION PER OPERATION PER VOUCHER.

;WITH GeneralMI AS (
	SELECT
		 a.PolicyNumber
		,b.*
		,RowNumber = ROW_NUMBER() OVER (
			PARTITION BY b.VoucherID, b.OperationID
			ORDER BY b.FileDateTime DESC, b.ImportFileID DESC
		 )
	FROM Vodafone.dbo.VoucherResponse a
	INNER JOIN Vodafone.dbo.GeneralMI b
		ON a.VoucherID = b.VoucherID
)

SELECT *
INTO Sandbox.dbo.VFS_Operations -- DROP TABLE IF EXISTS Sandbox.VFS_Operations;
FROM GeneralMI
WHERE RowNumber = 1
ORDER BY 
	 PolicyNumber		ASC
	,CreationDateTime	ASC
;










