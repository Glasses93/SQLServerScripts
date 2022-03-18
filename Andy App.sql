/*
PROC SQL;
	CREATE TABLE ServiceAppRisks AS
		SELECT DISTINCT
			 PolicyNumber
			,COMPRESS(PolicyNo || '.' || RatabaseID) AS Account_ID
			,MAX(EffectToDate) FORMAT DDMMYY10. AS RiskCXXDate
		FROM Telema.PolCVPTrav_ServiceApp_DontDelete
		WHERE PolicyNumber IN (
			SELECT x.PolicyNumber
			FROM Telema.PolCVPTrav_ServiceApp_DontDelete x
			WHERE x.ServiceAppFlag = '1'
				AND x.PolicyNumber IS NOT NULL 
		)
			AND TraversedFlag = '1'
			AND EffectFromDate <= TODAY()
			AND EffectFromDate IS NOT NULL
		GROUP BY PolicyNumber
		;
QUIT;

PROC SQL;
	CONNECT TO ODBC AS DDP (DSN = "Telematics_DDP_Sandbox" AuthDomain = "SPYDDPAuth");
		EXEC(

			DROP TABLE IF EXISTS sandbox.dbo.SJ_ServiceAppRisks;

			CREATE TABLE sandbox.dbo.SJ_ServiceAppRisks (
				 PolicyNumber	varchar(20)	NOT NULL
				,Account_ID		varchar(30)	NOT NULL
				,RiskCXXDate	date		NOT NULL

				CONSTRAINT PK_SJServiceAppRisks_PolicyNumberAccountID PRIMARY KEY CLUSTERED (PolicyNumber ASC, Account_ID ASC)
			)
			;

		) BY DDP;
	DISCONNECT FROM DDP;
QUIT;

PROC APPEND
	BASE = Sand_DDP.SJ_ServiceAppRisks
	DATA = ServiceAppRisks
	FORCE;
RUN;

/**/
*/

ALTER TABLE sandbox.dbo.SJ_ServiceAppRisks ADD InstallationDate date NULL;

;WITH InstallationDate AS (
	SELECT sar.PolicyNumber, InstallationDate = MIN(tpd.Day)
	FROM sandbox.dbo.SJ_ServiceAppRisks sar
	INNER JOIN sandbox.dbo.TEL1516_TripsPerDay tpd
		ON sar.Account_ID = tpd.Account_ID
	GROUP BY sar.PolicyNumber
)
UPDATE sar
	SET sar.InstallationDate = id.InstallationDate 
FROM sandbox.dbo.SJ_ServiceAppRisks sar
INNER JOIN InstallationDate id
	ON sar.PolicyNumber = id.PolicyNumber
;

--DROP TABLE IF EXISTS sandbox.dbo.SJ_ServiceAppDailyLogins;
CREATE TABLE sandbox.dbo.SJ_ServiceAppDailyLogins (
	 Account_ID	varchar(30)	NOT NULL
	,LoginDay	date		NOT NULL

	CONSTRAINT PK_SJServiceAppDailyLogins_AccountIDLoginDay PRIMARY KEY CLUSTERED (Account_ID ASC, LoginDay ASC)
)
;

;WITH Logins AS (
	SELECT PolicyNumber, RiskID, LoginDate
	FROM CMTSERV.dbo.SuccessfulLoginHistory

	UNION ALL

	SELECT PolicyNumber, RiskID, LoginDate
	FROM CMTSERV.dbo.SuccessfulLoginHistory_EL
)
INSERT sandbox.dbo.SJ_ServiceAppDailyLogins WITH (TABLOCK) (Account_ID, LoginDay)
SELECT DISTINCT
	 Account_ID = CONCAT(PolicyNumber, '.', RiskID)
	,LoginDay   = CONVERT(date, LoginDate)
FROM Logins
WHERE PolicyNumber LIKE 'P%'
	AND RiskID LIKE 'M%'
	AND LoginDate IS NOT NULL
;

INSERT sandbox.dbo.SJ_ServiceAppDailyLogins (Account_ID, LoginDay)
SELECT
	 Account_ID
	,RegistrationDate
FROM sandbox.dbo.TEL1300_3_MI t
WHERE NOT EXISTS (
	SELECT 1
	FROM sandbox.dbo.SJ_ServiceAppDailyLogins dl
	WHERE t.Account_ID = dl.Account_ID
		AND t.RegistrationDate = dl.LoginDay
)
;

--DROP TABLE IF EXISTS sandbox.dbo.SJ_ServiceAppTrips;
CREATE TABLE sandbox.dbo.SJ_ServiceAppTrips (
	 Account_ID			varchar(30)		NOT NULL
	,DriveID			char(36)		NOT NULL
	,Trip_Start_Local	datetime 		NOT NULL
	,Mileage			numeric(9, 5)	NOT NULL
	,Trip_Mode			varchar(20)			NULL
	,User_Label			varchar(20)			NULL

	CONSTRAINT PK_SJServiceAppTrips_AccountIDDriveID PRIMARY KEY CLUSTERED (Account_ID ASC, DriveID ASC)
)
;

;WITH TripSummary AS (
	SELECT
		 Account_ID
		,DriveID
		,Trip_Start_Local
		,Distance_Mapmatched_KM
		,Trip_Mode
		,User_Label
	FROM CMTSERV.dbo.CMTTripSummary

	UNION ALL

	SELECT
		 Account_ID
		,DriveID
		,Trip_Start_Local
		,Distance_Mapmatched_KM
		,Trip_Mode
		,User_Label
	FROM CMTSERV.dbo.CMTTripSummary_EL
)
INSERT sandbox.dbo.SJ_ServiceAppTrips WITH (TABLOCK) (Account_ID, DriveID, Trip_Start_Local, Mileage, Trip_Mode, User_Label)
SELECT
	 Account_ID
	,DriveID
	,Trip_Start_Local
	,Mileage = ISNULL(Distance_Mapmatched_KM, 0) * 0.62137119
	,Trip_Mode
	,User_Label
FROM TripSummary
WHERE Account_ID LIKE 'P%M%'
	AND Trip_Start_Local >= '2020-03-23T00:00:00.000'
	AND Trip_Start_Local <  CONVERT(date, CURRENT_TIMESTAMP)
	AND DriveID IS NOT NULL
;

;WITH TripLabel AS (
	SELECT
		 Account_ID
		,DriveID
		,New_Label
		,Label_Change_Date
		,FileDate
	FROM CMTSERV.dbo.CMTTripLabel

	UNION ALL

	SELECT
		 Account_ID
		,DriveID
		,New_Label
		,Label_Change_Date
		,FileDate
	FROM CMTSERV.dbo.CMTTripLabel_EL
)
SELECT DISTINCT
	 Account_ID
	,DriveID = CONVERT(CHAR(36), DriveID)
	,LastLabel =
		LAST_VALUE(New_Label) OVER (
			PARTITION BY Account_ID, DriveID
			ORDER BY Label_Change_Date ASC, FileDate ASC
			ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
		 )
INTO #LatestLabels
FROM TripLabel tl
WHERE EXISTS (
	SELECT 1
	FROM sandbox.dbo.SJ_ServiceAppTrips sat
	WHERE tl.Account_ID = sat.Account_ID 
		AND tl.DriveID  = sat.DriveID
)
;

DROP TABLE IF EXISTS #Mondays;

;WITH Dates (Date) AS (
	SELECT CONVERT(date, '20200323')

	UNION ALL

	SELECT DATEADD(DAY, 7, Date)
	FROM Dates
	WHERE Date < '20200803'
)
SELECT Date
INTO #Mondays
FROM Dates
;

--DROP TABLE sandbox.dbo.SJ_SAWeeklyMileage 
CREATE TABLE sandbox.dbo.SJ_SAWeeklyMileage (
	 WeekCommencing 		date			NOT NULL
	,PolicyNumber			varchar(20)		NOT NULL
	,Account_ID				varchar(30)		NOT NULL
	,InstallationDate		date			NOT NULL
	,RiskCXXDate			date			NOT NULL
	,OriginalLabelMileage	numeric(9, 5)		NULL
	,LatestLabelMileage		numeric(9, 5)		NULL
	,LatestLoginDay			date				NULL
)
;

INSERT sandbox.dbo.SJ_SAWeeklyMileage WITH (TABLOCK) (WeekCommencing, PolicyNumber, Account_ID, InstallationDate, RiskCXXDate)
SELECT
	 WeekCommencing = m.Date
	,sar.PolicyNumber
	,sar.Account_ID
	,sar.InstallationDate
	,sar.RiskCXXDate
FROM #Mondays m
INNER JOIN sandbox.dbo.SJ_ServiceAppRisks sar
	ON  m.Date >= sar.InstallationDate
	AND m.Date <  sar.RiskCXXDate
;

;WITH LatestLogins AS (
	SELECT w.WeekCommencing, w.PolicyNumber, LatestLoginDay = MAX(dl.LoginDay)
	FROM sandbox.dbo.SJ_SAWeeklyMileage w
	INNER JOIN sandbox.dbo.SJ_ServiceAppDailyLogins dl
		ON  w.Account_ID = dl.Account_ID
		AND dl.LoginDay < DATEADD(DAY, 7, w.WeekCommencing)
	GROUP BY w.WeekCommencing, w.PolicyNumber
)
UPDATE w
	SET w.LatestLoginDay = ll.LatestLoginDay 
FROM sandbox.dbo.SJ_SAWeeklyMileage w
INNER JOIN LatestLogins ll
	ON  w.PolicyNumber   = ll.PolicyNumber
	AND w.WeekCommencing = ll.WeekCommencing
;

;WITH OriginalMode AS (
	SELECT 
		 WeekCommencing = DATEADD(WEEK, DATEDIFF(WEEK, '19000101', DATEADD(DAY, -1, t.Trip_Start_Local)), '19000101')
		,w.PolicyNumber
		,Mileage = SUM(t.Mileage)
	FROM sandbox.dbo.SJ_SAWeeklyMileage w
	INNER JOIN sandbox.dbo.SJ_ServiceAppTrips t
		ON  w.Account_ID = t.Account_ID
		AND t.Trip_Mode  = 'car'
		AND w.WeekCommencing = DATEADD(WEEK, DATEDIFF(WEEK, '19000101', DATEADD(DAY, -1, t.Trip_Start_Local)), '19000101')
	GROUP BY
		 DATEADD(WEEK, DATEDIFF(WEEK, '19000101', DATEADD(DAY, -1, t.Trip_Start_Local)), '19000101')
		,w.PolicyNumber
)
UPDATE w
	SET w.OriginalLabelMileage = om.Mileage
FROM sandbox.dbo.SJ_SAWeeklyMileage w
INNER JOIN OriginalMode om
	ON  w.PolicyNumber   = om.PolicyNumber
	AND w.WeekCommencing = om.WeekCommencing
;

;WITH LatestMode AS (
	SELECT
		 WeekCommencing = DATEADD(WEEK, DATEDIFF(WEEK, '19000101', DATEADD(DAY, -1, t.Trip_Start_Local)), '19000101')
		,w.PolicyNumber
		,Mileage = SUM(t.Mileage)
	FROM sandbox.dbo.SJ_SAWeeklyMileage w
	INNER JOIN sandbox.dbo.SJ_ServiceAppTrips t
		ON  w.Account_ID     = t.Account_ID
		AND w.WeekCommencing = DATEADD(WEEK, DATEDIFF(WEEK, '19000101', DATEADD(DAY, -1, t.Trip_Start_Local)), '19000101')
	LEFT JOIN #LatestLabels ll
		ON  t.Account_ID = ll.Account_ID
		AND t.DriveID    = ll.DriveID
	WHERE COALESCE(ll.LastLabel, t.User_Label, t.Trip_Mode) IN ('car', 'DRIVER')
	GROUP BY
		 DATEADD(WEEK, DATEDIFF(WEEK, '19000101', DATEADD(DAY, -1, t.Trip_Start_Local)), '19000101')
		,w.PolicyNumber
)
UPDATE w
	SET w.LatestLabelMileage = lm.Mileage
FROM sandbox.dbo.SJ_SAWeeklyMileage w
INNER JOIN LatestMode lm
	ON  w.PolicyNumber   = lm.PolicyNumber
	AND w.WeekCommencing = lm.WeekCommencing
;

;WITH LEL AS (
	SELECT
		 *
		,RN = ROW_NUMBER() OVER (PARTITION BY PolicyNumber, WeekCommencing ORDER BY ( SELECT NULL ))
	FROM sandbox.dbo.SJ_SAWeeklyMileage 
)
DELETE LEL
WHERE RN > 1
;

ALTER TABLE sandbox.dbo.SJ_SAWeeklyMileage ADD CONSTRAINT PK_SJSAWeeklyMileage_WeekCommencingPolicyNumber
PRIMARY KEY NONCLUSTERED (WeekCommencing ASC, PolicyNumber ASC)
;

CREATE CLUSTERED INDEX IX_SJSAWeeklyMileage_LatestLabelMileage ON sandbox.dbo.SJ_SAWeeklyMileage (LatestLabelMileage ASC);