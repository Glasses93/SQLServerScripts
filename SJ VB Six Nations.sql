/*
Six Nations 2020:
ROUND ONE:
- Wales v Italy, Principality Stadium, Cardiff, Saturday 01/02/2020 14:15:00
- Ireland v Scotland, Aviva Stadium, Dublin, Saturday 01/02/2020 16:45:00
- France v England, Stade de France, Paris, Sunday 02/02/2020 15:00:00 (UK)
ROUND TWO:
- Ireland v Wales, Aviva Stadium, Dublin, Saturday 08/02/2020 14:15:00
- Scotland v England, BT Murrayfield Stadium, Edinburgh, Saturday 08/02/2020 16:45:00
- France v Italy, Stade de France, Paris, Sunday 09/02/2020 15:00:00 (UK)
ROUND THREE:
- Italy v Scotland, Stadio Olimpico, Rome, Saturday 22/02/2020 14:15:00 (UK)
- Wales v France, Principality Stadium, Cardiff, Saturday 22/02/2020 16:45:00
- England v Ireland, Twickenham Stadium, London, Sunday 23/02/2020 15:00:00
ROUND FOUR:
- England v Wales, Twickenham Stadium, London, Saturday 07/03/2020 16:45:00
- Scotland v France, BT Murrayfield Stadium, Edinburgh, Sunday 08/03/2020 15:00:00

Six Nations 2019:

ROUND ONE
Friday 1 February
France v Wales, KO 8.00pm, Paris
Saturday 2 February
Scotland v Italy, KO 2.15pm, Edinburgh
Ireland v England, KO 4.45pm, Dublin
ROUND TWO
Saturday 9 February
Scotland v Ireland, KO 2.15pm, Edinburgh
Italy v Wales, KO 4.45pm, Rome
Sunday 10 February
England v France, KO, 3.00pm, Twickenham
ROUND THREE
Saturday 23 February
France v Scotland, KO 2.15pm, Paris
Wales v England, KO 4.45pm, Cardiff
Sunday 24 February
Italy v Ireland, KO 3.00pm, Rome
ROUND FOUR
Saturday 9 March
Scotland v Wales, KO 2.15pm, Edinburgh
England v Italy, KO 4.45pm, Twickenham
Sunday 10 March
Ireland v France, KO 3.00pm, Dublin
ROUND FIVE
Saturday 16 March
Italy v France, KO 12.30pm, Rome
Wales v Ireland, KO 2.45pm, Cardiff
England v Scotland, KO 5.00pm, Twickenham

Six Nations 2018:

3/4 February
Wales v Scotland, Saturday 2.15pm
France v Ireland, Saturday 4.45pm
Italy v England, Sunday 3.00pm

10/11 February
Ireland v Italy, Saturday 2.15pm
England v Wales, Saturday 4.45pm
Scotland v France, Sunday 3.00pm

23/24 February
France v Italy, Friday 8.00pm*
Ireland v Wales, Saturday 2.15pm
Scotland v England, Saturday 4.45pm

10/11 March
Ireland v Scotland, Saturday 2.15pm
France v England, Saturday 4.45pm
Wales v Italy, Sunday 3.00pm

17 March
Italy v Scotland, Saturday 12.30pm
England v Ireland, Saturday 2.45pm
Wales v France, Saturday 5.00pm
*/

/*
CREATE TABLE Sandbox.dbo.SJ_VB_Events (
	 ID															TINYINT			NOT NULL	IDENTITY(1, 1)
	,EventDescription											VARCHAR(200)	NOT NULL
	,EventStart 												DATETIME		NOT NULL
	,EventEnd													DATETIME		NOT NULL
	,OneHourBefore AS DATEADD(HOUR, -1, EventStart) PERSISTED
	,OneHourAfter  AS DATEADD(HOUR,  1, EventEnd  ) PERSISTED
	,BST														BIT				NOT NULL			
)
;
*/

-- Vodafone ETL:

IF NOT EXISTS (
	SELECT 1
	FROM Staging.dbo.DWJobStatus
	WHERE Supplier = 'Vodafone'
		AND CAST(EndTime AS DATE) = CAST(GETDATE() AS DATE)
)
BEGIN

	SELECT 1
	FROM Ble.Mae.Vodafone
	;

END
;

-- Vodafone Risks:

;WITH RenewalDates AS (
	SELECT
		 PolicyNumber
		,NumTerm
		,PeriodEndDate
		,RN = ROW_NUMBER() OVER (PARTITION BY PolicyNumber, NumTerm ORDER BY GWTermNo DESC, ModelNo DESC)
	FROM Sandbox.dbo.PolCVPTrav
)
SELECT
	 PolicyNumber = CAST(p.PolicyNumber AS VARCHAR(20))
	,NumTerm      = CAST(p.NumTerm      AS TINYINT    )
	,p.PolIncDate
	,rd.PeriodEndDate
	,p.EffectFromDate
	,p.EffectToDate
	,VehMiles     = CAST(p.VehMiles AS INT)
	,TeleDevRem   = CAST(LTRIM(p.TeleDevRem) AS CHAR(1))
	,p.VehABICode
	,VehReg = CAST(UPPER(REPLACE(p.VehReg, ' ', '')) AS VARCHAR(20))
	,Postcode = UPPER(REPLACE(p.RiskPostcode, ' ', ''))
INTO Sandbox.dbo.SJ_VB_Guidewire
FROM Sandbox.dbo.PolCVPTrav p
INNER JOIN (
	SELECT
		 PolicyNumber
		,NumTerm
		,PeriodEndDate
	FROM RenewalDates
	WHERE RN = 1
) rd
	ON  p.PolicyNumber = rd.PolicyNumber
	AND p.NumTerm	   = rd.NumTerm
WHERE p.TraversedFlag = '1'
	AND p.EffectFromDate <= CAST(GETDATE() AS DATE)
	AND p.TeleDevSuppl = 'vodafone'
;

CREATE CLUSTERED INDEX IX_SJ_VB_Guidewire_PolicyNumber ON Sandbox.dbo.SJ_VB_Guidewire (PolicyNumber ASC);

SELECT DISTINCT PolicyNumber
INTO Sandbox.dbo.SJ_VB_PolicyNumbers
FROM Sandbox.dbo.SJ_VB_Guidewire
;

CREATE UNIQUE CLUSTERED INDEX IX_SJ_VB_PolicyNumbers_PolicyNumber ON Sandbox.dbo.SJ_VB_PolicyNumbers (PolicyNumber ASC);

-- First Trip:

SELECT
	 ExternalContractNumber
	,FirstTrip = MIN(EventTimeStamp)
INTO Sandbox.dbo.SJ_VB_FirstTrip
FROM Vodafone.dbo.Trip t
WHERE EXISTS (
	SELECT 1
	FROM Sandbox.dbo.SJ_VB_PolicyNumbers p
	WHERE t.ExternalContractNumber = p.PolicyNumber
)
GROUP BY ExternalContractNumber
;

CREATE CLUSTERED INDEX IS_SJ_VB_FirstTrip_ExternalContractNumber ON Sandbox.dbo.SJ_VB_FirstTrip (ExternalContractNumber ASC);

/*
Daylight saving time 2019 in United Kingdom began at 1:00 AM on
Sunday, March 31
and ended at 2:00 AM on
Sunday, October 27
All times are in United Kingdom Time.

Daylight saving time 2018 in United Kingdom began at 1:00 AM on
Sunday, March 25
and ended at 2:00 AM on
Sunday, October 28
All times are in United Kingdom Time.

Daylight saving time 2017 in United Kingdom began at 1:00 AM on
Sunday, March 26
and ended at 2:00 AM on
Sunday, October 29
All times are in United Kingdom Time.
*/

/*
UPDATE Sandbox.dbo.SJ_VB_FirstTrip
	SET FirstTrip = DATEADD(HOUR, 1, FirstTrip)
WHERE (
		FirstTrip BETWEEN '26/03/2017 01:00:00' AND '29/10/2017 02:00:00'
	OR	FirstTrip BETWEEN '25/03/2018 01:00:00' AND '28/10/2018 02:00:00'
	OR 	FirstTrip BETWEEN '26/03/2019 01:00:00' AND '29/10/2019 02:00:00'
)
*/

-- Installations

;WITH Vouchers AS (
	SELECT DISTINCT
		 p.PolicyNumber
		,vr.VoucherID
	FROM Sandbox.dbo.SJ_VB_PolicyNumbers p
	INNER JOIN Vodafone.dbo.VoucherResponse vr
		ON p.PolicyNumber = vr.PolicyNumber
)
SELECT
	 v.PolicyNumber
	,g.PlateNumber
	,InstallationDate = MIN(g.EquipmentActivationDateTime)
INTO Sandbox.dbo.SJ_VB_Installations
FROM Vouchers v
INNER JOIN Vodafone.dbo.GeneralMI g
	ON v.VoucherID = g.VoucherID
WHERE g.EquipmentActivationDateTime IS NOT NULL
GROUP BY
	 v.PolicyNumber
	,g.PlateNumber
;

SELECT
	 p.*
	,InstallationDate = COALESCE(id.InstallationDate, f.FirstTrip)
INTO Sandbox.dbo.SJ_VB_InstallationsFT
FROM Sandbox.dbo.SJ_VB_Guidewire p
LEFT JOIN Sandbox.dbo.SJ_VB_Installations id
	ON  p.PolicyNumber = id.PolicyNumber
	AND p.VehReg = REPLACE(UPPER(id.PlateNumber), ' ', '')
LEFT JOIN Sandbox.dbo.SJ_VB_FirstTrip f
	ON p.PolicyNumber = f.ExternalContractNumber
;

;WITH Installations AS (
	SELECT
		 PolicyNumber
		,VehABICode
		,EndDate = MAX(EffectToDate)
	FROM Sandbox.dbo.SJ_VB_InstallationsFT
	WHERE TeleDevRem = '0'
	GROUP BY
		 PolicyNumber
		,VehABICode
)
SELECT
	 a.*
	,b.EndDate
INTO Sandbox.dbo.SJ_VB_EndDate
FROM Sandbox.dbo.SJ_VB_InstallationsFT a
INNER JOIN Installations b
	ON  a.PolicyNumber = b.PolicyNumber
	AND a.VehABICode = b.VehABICode
;

SELECT
	 *
	,RN = RANK() OVER (PARTITION BY PolicyNumber ORDER BY InstallationDate ASC)
INTO #Temp
FROM Sandbox.dbo.SJ_VB_EndDate
;

UPDATE a
	SET a.InstallationDate = CASE WHEN b.FirstTrip < a.InstallationDate THEN b.FirstTrip ELSE a.InstallationDate END
FROM #Temp a
LEFT JOIN Sandbox.dbo.SJ_VB_FirstTrip b
	ON a.PolicyNumber = b.ExternalContractNumber
WHERE a.RN = 1
;

SELECT DISTINCT
	 PolicyNumber
	,InstallationDate
	,EndDate
INTO Sandbox.dbo.SJ_VB_ValidRanges
FROM #Temp
;

CREATE CLUSTERED INDEX IX_SJ_VB_ValidRanges_PolicyNumber ON Sandbox.dbo.SJ_VB_ValidRanges (PolicyNumber ASC);

DECLARE @i TINYINT = ;

WHILE @i < 
BEGIN

	DECLARE @EventDesc     VARCHAR(200) = ( SELECT EventDescription FROM Sandbox.dbo.SJ_VB_Events WHERE ID = @i );
	DECLARE @EventStart    DATETIME 	= ( SELECT EventStart 		FROM Sandbox.dbo.SJ_VB_Events WHERE ID = @i );
	DECLARE @EventEnd 	   DATETIME 	= ( SELECT EventEnd 		FROM Sandbox.dbo.SJ_VB_Events WHERE ID = @i );
	DECLARE @OneHourBefore DATETIME 	= ( SELECT OneHourBefore 	FROM Sandbox.dbo.SJ_VB_Events WHERE ID = @i );
	DECLARE @OneHourAfter  DATETIME 	= ( SELECT OneHourAfter 	FROM Sandbox.dbo.SJ_VB_Events WHERE ID = @i );

	INSERT Sandbox.dbo.SJ_VB_EventDriving (
		EventDescription, PolicyNumber, InstallationDate, EndDate, Eligible, OneHourBefore, During, OneHourAfter, RelevantRAPostcode
	)
	SELECT
		 @EventDesc
		,PolicyNumber
		,InstallationDate
		,EndDate
		,CAST(CASE WHEN @EventEnd BETWEEN InstallationDate AND EndDate THEN 1 ELSE 0 END AS BIT)
		,CAST(
			CASE WHEN EXISTS (
				SELECT 1
				FROM Vodafone.dbo.Trip t
				WHERE vr.PolicyNumber = t.ExternalContractNumber
					AND t.EventTimeStamp >= @OneHourBefore
					AND t.EventTimeStamp <  @EventStart
					AND t.EventTimeStamp >= vr.InstallationDate
					AND t.EventTimeStamp < vr.EndDate
			) THEN 1 ELSE 0 END
		 AS BIT)
		,CAST(CASE WHEN EXISTS (
			SELECT 1
			FROM Vodafone.dbo.Trip t
			WHERE vr.PolicyNumber = t.ExternalContractNumber
				AND t.EventTimeStamp >= @EventStart
				AND t.EventTimeStamp <  @EventEnd
				AND t.EventTimeStamp >= vr.InstallationDate
				AND t.EventTimeStamp < vr.EndDate
		 ) THEN 1 ELSE 0 END AS BIT)
		,CAST(CASE WHEN EXISTS (
			SELECT 1
			FROM Vodafone.dbo.Trip t
			WHERE vr.PolicyNumber = t.ExternalContractNumber
				AND t.EventTimeStamp >= @EventEnd
				AND t.EventTimeStamp <  @OneHourAfter
				AND t.EventTimeStamp >= vr.InstallationDate
				AND t.EventTimeStamp < vr.EndDate
		 ) THEN 1 ELSE 0 END AS BIT)
	FROM Sandbox.dbo.SJ_VB_ValidRanges vr
	;

	IF CAST(GETDATE() AS TIME) BETWEEN '01:00:00' AND '02:00:00' BREAK;

	SET @i += 1;

END
;

--DROP INDEX IX_SJ_VB_EventDriving_PolicyNumber ON Sandbox.dbo.SJ_VB_EventDriving;
--CREATE CLUSTERED INDEX IX_SJ_VB_EventDriving_PolicyNumber ON Sandbox.dbo.SJ_VB_EventDriving (PolicyNumber ASC);

SELECT
	 PolicyNumber
	,EffectFromDate
	,EffectToDate
	,Postcode
	.Postcode4 = LEFT(Postcode, 4)
	,Postcode3 = LEFT(Postcode, 3)
	,Postcode2 = LEFT(Postcode, 2)
INTO Sandbox.dbo.SJ_VB_PostMalone
FROM Sandbox.dbo.SJ_VB_Guidewire
;

--CREATE CLUSTERED INDEX IX_SJ_VB_PostMalone_PolicyNumber ON SANDBOX.DBO.SJ_VB_PostMalone (PolicyNumber ASC);

/*
UPDATE a
	SET a.RelevantRAPostcode = 1
OUTPUT INSERTED.PolicyNumber
INTO #Temp
FROM Sandbox.dbo.SJ_VB_EventDriving a
INNER JOIN Sandbox.dbo.SJ_VB_PostMalone b
	ON a.PolicyNumber = b.PolicyNumber
INNER JOIN Sandbox.dbo.SJ_VB_Events c
	ON a.EventDescription = c.EventDescription
WHERE c.EventStart BETWEEN b.EffectFromDate AND b.EffectToDate
	AND a.Eligible = 1
	AND a.RelevantRAPostcode IS NULL
	AND a.EventDescription LIKE '%Scotland%'
	AND b.Postcode2 IN (SELECT p.Postcode FROM Sandbox.dbo.SJ_VB_Postcodes p WHERE p.Country LIKE '%Scotland%')
	AND a.PolicyNumber NOT IN (SELECT PolicyNumber FROM #Temp)
;
*/

SELECT DISTINCT PolicyNumber
INTO #Temp
FROM Sandbox.dbo.SJ_VB_EventDriving
WHERE RelevantRAPostcode = 1
;

CREATE CLUSTERED INDEX IX_Temp_PolicyNumber ON #Temp (PolicyNumber ASC);

SELECT PolicyNumber, COUNT(DISTINCT EventDescription)
FROM Sandbox.dbo.SJ_VB_EventDriving
WHERE RelevantRAPostcode = 1
GROUP BY PolicyNumber
ORDER BY 2 DESC
;

SELECT *
FROM Sandbox.dbo.SJ_VB_EventDriving
WHERE PolicyNumber = 'P61386990-1'

SELECT *
FROM Sandbox.dbo.SJ_VB_Guidewire
WHERE PolicyNumber = 'P61386990-1'

