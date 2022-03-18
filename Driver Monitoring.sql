

INSERT Sandbox.dbo.TEL1386_Terms (Supplier, PolicyNumber, NumTerm, PolIncDate)
SELECT DISTINCT
	 Supplier     = CAST(CASE TeleDevSuppl WHEN 'vodafone' THEN 'Vodafone' ELSE 'RedTail' END AS VARCHAR(15))
	,PolicyNumber = CAST(PolicyNumber AS VARCHAR(20))
	,NumTerm      = CAST(NumTerm AS TINYINT)
	,PolIncDate
	--,PeriodEndDate = CAST(NULL AS DATE)
	--,InstallationDate = CAST(NULL AS DATE)
	--,RiskCXXDate      = CAST(NULL AS DATE)
FROM Sandbox.dbo.PolCVPTrav p
WHERE TraversedFlag = '1'
	AND EffectFromDate <= CAST(GETDATE() AS DATE)
	AND TelematicsFlag = '1'
	AND TeleDevSuppl IN ('redtail', 'vodafone')
	AND TeleDevRem = '0'
	AND NOT EXISTS (
		SELECT 1
		FROM Sandbox.dbo.TEL1386_Terms t
		WHERE p.PolicyNumber = t.PolicyNumber
			AND p.NumTerm = t.NumTerm
	)
;

/*
CREATE CLUSTERED INDEX IX_TEL1386Terms_PolicyNumber
ON Sandbox.dbo.TEL1386_Terms (
	 PolicyNumber ASC
	,NumTerm      ASC
)
;
*/

;WITH RenewalDate AS (
	SELECT
		 PolicyNumber
		,NumTerm
		,PeriodEndDate
		,RN = ROW_NUMBER() OVER (PARTITION BY PolicyNumber, NumTerm ORDER BY EffectFromDate DESC)
	FROM Sandbox.dbo.PolCVPTrav
	WHERE TraversedFlag = '1'
		AND EffectFromDate <= CAST(GETDATE() AS DATE)
)
UPDATE t
	SET t.PeriodEndDate = rd.PeriodEndDate
FROM Sandbox.dbo.TEL1386_Terms t
INNER JOIN RenewalDate rd
	ON t.PolicyNumber = rd.PolicyNumber
	AND t.NumTerm = rd.NumTerm
	AND rd.RN = 1
;

;WITH CXX AS (
	SELECT
		 PolicyNumber
		,RiskCXXDate
	FROM Sandbox.dbo.TEL1386_VFCXX

	UNION ALL

	SELECT
		 PolicyNumber
		,RiskCXXDate = MIN(EndDate)
	FROM RedTail.dbo.Association
	WHERE EndDate IS NOT NULL --ReviewDate / CXXDate?
	GROUP BY PolicyNumber
)
UPDATE t
	SET t.RiskCXXDate = COALESCE(cxx.RiskCXXDate, CAST(GETDATE() - 1 AS DATE))
FROM Sandbox.dbo.TEL1386_Terms t
LEFT JOIN CXX
	ON t.PolicyNumber = cxx.PolicyNumber
;

INSERT Sandbox.dbo.TEL1386_StatsPerDay (PolicyNumber, NumTerm, Date, Journeys, Mileage, Supplier)
SELECT
	 t.PolicyNumber
	,t.NumTerm
	,Date     = CAST(vj.StartTime AS DATE)
	,Journeys = COUNT(vj.Journey_ID)
	,Mileage  = SUM(vj.Miles_Driven)
	,Supplier = 'Vodafone'
FROM DataSummary.dbo.VodaJourneys vj
INNER JOIN Sandbox.dbo.TEL1386_Terms t
	ON  vj.PolicyNumber = t.PolicyNumber
	AND vj.StartTime   >= t.PolIncDate
	AND vj.StartTime   <  t.PeriodEndDate
	AND vj.StartTime   <  t.RiskCXXDate
	AND vj.StartTime   >= '2020-01-01T00:00:00.000'
	AND vj.StartTime   <  CAST(GETDATE() - 3 AS DATE)
WHERE NOT EXISTS (
	SELECT 1
	FROM Sandbox.dbo.TEL1386_StatsPerDay spd
	WHERE t.PolicyNumber = spd.PolicyNumber
		AND CAST(vj.StartTime AS DATE) = spd.Date
)
GROUP BY
	 t.PolicyNumber
	,t.NumTerm
	,CAST(vj.StartTime AS DATE)
;

INSERT Sandbox.dbo.TEL1386_StatsPerDay (PolicyNumber, NumTerm, Date, Journeys, Mileage, Supplier)
SELECT
	 t.PolicyNumber
	,t.NumTerm
	,Date     = CAST(vj.StartTime AS DATE)
	,Journeys = COUNT(vj.Journey_ID)
	,Mileage  = SUM(vj.Miles_Driven)
	,Supplier = 'Vodafone'
FROM DataSummary.dbo.VodaJourneys_COVID vj
INNER JOIN Sandbox.dbo.TEL1386_Terms t
	ON  vj.PolicyNumber = t.PolicyNumber
	AND vj.StartTime   >= t.PolIncDate
	AND vj.StartTime   <  t.PeriodEndDate
	AND vj.StartTime   <  t.RiskCXXDate
	AND vj.StartTime   >= '2020-01-01T00:00:00.000'
	AND vj.StartTime   <  CAST(GETDATE() - 3 AS DATE)
WHERE NOT EXISTS (
	SELECT 1
	FROM Sandbox.dbo.TEL1386_StatsPerDay spd
	WHERE t.PolicyNumber = spd.PolicyNumber
		AND CAST(vj.StartTime AS DATE) = spd.Date
)
GROUP BY
	 t.PolicyNumber
	,t.NumTerm
	,CAST(vj.StartTime AS DATE)
;

PRINT @@ROWCOUNT;

INSERT Sandbox.dbo.TEL1386_StatsPerDay (PolicyNumber, NumTerm, Date, Journeys, Mileage, Supplier)
SELECT
	 t.PolicyNumber
	,t.NumTerm
	,Date     = rsj.JourneyStartDate
	,Journeys = COUNT(rsj.Journey_ID)
	,Mileage  = SUM(rsj.MilesDriven)
	,Supplier = 'RedTail'
FROM DataSummary.dbo.RedTailScoreJourney rsj
INNER JOIN Sandbox.dbo.TEL1386_Terms t
	ON  rsj.PolicyNumber      = t.PolicyNumber
	AND rsj.JourneyStartDate >= t.PolIncDate
	AND rsj.JourneyStartDate <  t.PeriodEndDate
	AND rsj.JourneyStartDate <  t.RiskCXXDate
	AND rsj.JourneyStartDate >= '20200101'
	AND rsj.JourneyStartDate <  CAST(GETDATE() - 3  AS DATE)
	AND rsj.InsertedDate     >=  CAST(GETDATE() - 16 AS DATE)
WHERE NOT EXISTS (
	SELECT 1
	FROM Sandbox.dbo.TEL1386_StatsPerDay spd
	WHERE t.PolicyNumber = spd.PolicyNumber
		AND rsj.JourneyStartDate = spd.Date
)
GROUP BY
	 t.PolicyNumber
	,t.NumTerm
	,rsj.JourneyStartDate
;

INSERT Sandbox.dbo.TEL1386_StatsPerDay (PolicyNumber, NumTerm, Date, Journeys, Mileage, Supplier)
SELECT
	 t.PolicyNumber
	,t.NumTerm
	,Date     = rsj.JourneyStartDate
	,Journeys = COUNT(rsj.Journey_ID)
	,Mileage  = SUM(rsj.MilesDriven)
	,Supplier = 'RedTail'
FROM DataSummary.dbo.RedTailScoreJourney_COVID rsj
INNER JOIN Sandbox.dbo.TEL1386_Terms t
	ON  rsj.PolicyNumber      = t.PolicyNumber
	AND rsj.JourneyStartDate >= t.PolIncDate
	AND rsj.JourneyStartDate <  t.PeriodEndDate
	AND rsj.JourneyStartDate <  t.RiskCXXDate
	AND rsj.JourneyStartDate >= '20200101'
	AND rsj.JourneyStartDate <  CAST(GETDATE() - 3  AS DATE)
WHERE NOT EXISTS (
	SELECT 1
	FROM Sandbox.dbo.TEL1386_StatsPerDay spd
	WHERE t.PolicyNumber = spd.PolicyNumber
		AND rsj.JourneyStartDate = spd.Date
)
GROUP BY
	 t.PolicyNumber
	,t.NumTerm
	,rsj.JourneyStartDate
;


;WITH InstallationDates AS (
	SELECT
		 vr.PolicyNumber
		,InstallationDate = CAST(MIN(g.EquipmentActivationDateTime) AS DATE)
	FROM Vodafone.dbo.VoucherResponse vr
	INNER JOIN Vodafone.dbo.GeneralMI g
		ON  vr.VoucherID = g.VoucherID
		AND g.EquipmentActivationDateTime IS NOT NULL
	GROUP BY vr.PolicyNumber

	UNION ALL

	SELECT
		 PolicyNumber
		,InstallationDate = MIN(StartDate) --+7?
	FROM RedTail.dbo.Association
	WHERE StartDate IS NOT NULL
	GROUP BY PolicyNumber
)
UPDATE t
	SET t.InstallationDate = id.InstallationDate
FROM Sandbox.dbo.TEL1386_Terms t
INNER JOIN InstallationDates id
	ON  t.PolicyNumber = id.PolicyNumber
	AND t.InstallationDate IS NULL
;

;WITH MissingInstallVF AS (
	SELECT *
	FROM Sandbox.dbo.TEL1386_Terms
	WHERE Supplier = 'Vodafone' --RT too?
		--AND InstallationDate IS NULL
)
UPDATE mi
	SET mi.InstallationDate = ft.FirstTrip
FROM MissingInstallVF mi
INNER JOIN (
	SELECT
		 PolicyNumber
		,FirstTrip = MIN(Date)
	FROM Sandbox.dbo.TEL1386_StatsPerDay
	GROUP BY PolicyNumber
) ft
	ON mi.PolicyNumber = ft.PolicyNumber
	AND ( ft.FirstTrip < mi.InstallationDate OR mi.InstallationDate IS NULL )
;

DROP TABLE IF EXISTS #Dates;

;WITH Rec (Date) AS (
	SELECT CAST('01/01/2020' AS DATE)

	UNION ALL

	SELECT DATEADD(DAY, 1, Date)
	FROM Rec
	WHERE DATEADD(DAY, 1, Date) < CAST(GETDATE() - 2 AS DATE)
)
SELECT Date
INTO #Dates
FROM Rec
OPTION (MAXRECURSION 32767)
;

DECLARE @SixMondaysAgo DATE;
DECLARE @OneMondayAgo  DATE;

SELECT
	 @SixMondaysAgo = MIN(Date)
	,@OneMondayAgo  = MAX(Date)
FROM #Dates
WHERE DATENAME(WEEKDAY, Date) = 'Monday'
	AND Date >= CAST(GETDATE() - 49 AS DATE)
;

DROP TABLE IF EXISTS ##ForSAS;

SELECT
	 t.Supplier
	,t.PolicyNumber
	,t.PolIncDate
	,d.Date
	,Year = YEAR(d.Date)
	,WeekOfYear = DATEPART(WEEK, d.Date)
	,WeekCommencing  = CAST(NULL AS DATE)
	,Journeys = ISNULL(spd.Journeys, 0)
	,spd.Mileage
INTO ##ForSAS
FROM Sandbox.dbo.TEL1386_Terms t
INNER JOIN #Dates d
	ON  d.Date >= t.InstallationDate
	AND d.Date <  t.RiskCXXDate
	AND d.Date >= t.PolIncDate
	AND d.Date <  t.PeriodEndDate
	AND d.Date >= @SixMondaysAgo
	AND d.Date <  @OneMondayAgo
LEFT JOIN Sandbox.dbo.TEL1386_StatsPerDay spd
	ON  t.PolicyNumber = spd.PolicyNumber
	AND d.Date         = spd.Date
;

UPDATE fs
SET fs.WeekCommencing = d.Date
FROM ##ForSAS fs
INNER JOIN #Dates d
	ON fs.Year = YEAR(d.Date)
	AND fs.WeekOfYear = DATEPART(WEEK, d.Date)
	AND DATENAME(WEEKDAY, d.Date) = 'Monday'
;

select weekcommencing, avg(journeys)
from ##forsas
group by weekcommencing


select *
from Sandbox.dbo.TEL1386_StatsPerDay 
where date >= '20200629'

use datasummary
----------------------




SELECT
	 t.Supplier
	,t.PolicyNumber
	,t.PolIncDate
	,d.Date
	,Journeys = ISNULL(spd.Journeys, 0)
	,spd.Mileage
INTO ##Lockdown
FROM Sandbox.dbo.TEL1386_Terms t
INNER JOIN #Dates d
	ON  d.Date >= t.InstallationDate
	AND d.Date <  t.RiskCXXDate
	AND d.Date >= t.PolIncDate
	AND d.Date <  t.PeriodEndDate
	AND d.Date >= '20200322'
	AND d.Date <  '20200511'
LEFT JOIN Sandbox.dbo.TEL1386_StatsPerDay spd
	ON  t.PolicyNumber = spd.PolicyNumber
	AND d.Date         = spd.Date
;

select top 1000 * from ##lockdown where journeys = 0

select * from VodaJourneys_COVID

select * from RedTailScoreJourney_COVID