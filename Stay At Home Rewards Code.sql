
/*
-- SAS:

PROC SQL;
	CREATE TABLE ServiceApp AS
		SELECT DISTINCT
			 a.BrandName AS Brand
			,a.PolicyNumber
			,a.PolicyNo
			,a.SubPolicyID
			,COMPRESS(a.PolicyNo || '.' || a.RatabaseID) AS Account_ID
			,a.RatabaseID
			,b.GWCXXDate
		FROM Telema.PolCVPTrav_ServiceApp_DontDelete a
		INNER JOIN (
			SELECT
				 PolicyNumber
				,MAX(EffectToDate) FORMAT DDMMYY10. AS GWCXXDate
			FROM Telema.PolCVPTrav_ServiceApp_DontDelete
			WHERE TraversedFlag = '1'
		) b
			ON a.PolicyNumber = b.PolicyNumber
		WHERE a.BrandName IN ('Elephant', 'Admiral')
			AND a.ServiceAppFlag = '1'
		;
QUIT;

-- DDP:

CREATE TABLE Sandbox.dbo.SJ_SAHR_GW ( -- DROP TABLE IF EXISTS Sandbox.dbo.SJ_SAHR_GW;
	 Brand			VARCHAR(15)	NOT NULL
	,PolicyNumber	VARCHAR(20)	NOT NULL
	,PolicyNo		VARCHAR(20)	NOT NULL
	,SubPolicyID	TINYINT		NOT NULL
	,Account_ID		VARCHAR(30)	NOT NULL
	,RatabaseID		VARCHAR(8)	NOT NULL
	,GWCXXDate		DATE		NOT NULL
)
;

-- SAS:

PROC APPEND
	BASE = Sand_DDP.SJ_SAHR_GW
	DATA = ServiceApp
	FORCE;
RUN;

-- DDP:

CREATE CLUSTERED INDEX IX_SJ_SAHR_GW_Account_ID ON Sandbox.dbo.SJ_SAHR_GW (Account_ID ASC);
ALTER TABLE Sandbox.dbo.SJ_SAHR_GW ALTER COLUMN GWCXXDate DATETIME NOT NULL;
ALTER TABLE Sandbox.dbo.SJ_SAHR_GW ADD RegistrationDate DATETIME NULL;

;WITH RiskRegistrationDate (PolicyNumber, RegistrationDate) AS (
	SELECT
		 a.PolicyNumber
		,MIN(b.RegistrationDate)
	FROM Sandbox.dbo.SJ_SAHR_GW a
	INNER JOIN Sandbox.dbo.SJ_Association b
		ON a.Account_ID = b.Account_ID
	GROUP BY a.PolicyNumber
)

UPDATE a
	SET a.RegistrationDate = b.RegistrationDate
FROM Sandbox.dbo.SJ_SAHR_GW a
INNER JOIN RiskRegistrationDate b
	ON a.PolicyNumber = b.PolicyNumber
;

;WITH TripLabels AS (
	SELECT
		 Account_ID = CAST(Account_ID AS VARCHAR(30))
		,DriveID
		,New_Label = CAST(New_Label AS VARCHAR(20))
		,Label_Change_Date = DATEADD(HOUR, 1, Label_Change_Date)
		,FileDate
	FROM CMTServ.dbo.CMTTripLabel

	UNION ALL

	SELECT
		 Account_ID = CAST(Account_ID AS VARCHAR(30))
		,DriveID
		,New_Label = CAST(New_Label AS VARCHAR(20))
		,Label_Change_Date = DATEADD(HOUR, 1, Label_Change_Date)
		,FileDate
	FROM CMTServ.dbo.CMTTripLabel
)

SELECT *
INTO Sandbox.dbo.SJ_SAHR_TripLabelChanges
FROM TripLabels
WHERE Account_ID IS NOT NULL
;

CREATE CLUSTERED INDEX IX_SJ_SAHR_TripLabelChanges_Account_IDLabel_Change_Date ON Sandbox.dbo.SJ_SAHR_TripLabelChanges (Account_ID ASC, Label_Change_Date ASC);

;WITH Trips AS (
	SELECT
		 Account_ID = CAST(Account_ID AS VARCHAR(30))
		,DriveID
		,Trip_Mode
		,Trip_Start_Local
		,Trip_End_Local
		,User_Label
		,ID
	FROM CMTServ.dbo.CMTTripSummary

	UNION ALL
	
	SELECT
		 Account_ID = CAST(Account_ID AS VARCHAR(30))
		,DriveID
		,Trip_Mode
		,Trip_Start_Local
		,Trip_End_Local
		,User_Label
		,ID
	FROM CMTServ.dbo.CMTTripSummary_EL
)

SELECT *
INTO Sandbox.dbo.SJ_SAHR_Trips
FROM Trips
WHERE ( Trip_Start_Local >= '01/01/2020' OR Trip_End_Local >= '01/01/2020' )
;

CREATE CLUSTERED INDEX IX_SJ_SAHR_Trips_Account_IDTrip_Start_Local ON Sandbox.dbo.SJ_SAHR_Trips (Account_ID ASC, Trip_Start_Local ASC);

;WITH Anomalies AS (
	SELECT
		 Account_ID = CAST(Account_ID AS VARCHAR(30))
		,Anomaly_Type
		,Anomaly_Device_Time
		,Anomaly_Server_Time
	FROM CMTServ.dbo.CMTAnomaly
	
	UNION ALL
	
	SELECT
		 Account_ID = CAST(Account_ID AS VARCHAR(30))
		,Anomaly_Type
		,Anomaly_Device_Time
		,Anomaly_Server_Time	
	FROM CMTServ.dbo.CMTAnomaly_EL
)

SELECT
		 Account_ID
		,Anomaly_Type
		,Anomaly_Device_Time = DATEADD(HOUR, 1, Anomaly_Device_Time)
		,Anomaly_Server_Time = DATEADD(HOUR, 1, Anomaly_Server_Time)
INTO Sandbox.dbo.SJ_SAHR_Anomalies
FROM Anomalies
;

CREATE CLUSTERED INDEX IX_SJ_SAHR_Anomalies_Account_ID ON Sandbox.dbo.SJ_SAHR_Anomalies (Account_ID ASC);

;WITH LocationServices (Account_ID, Status, ChangeDate) AS (
	SELECT
		 CONCAT(PolicyNumber, '.', RiskID)
		,Status
		,ChangeDate
	FROM CMTServ.dbo.LocationPermissionChange
	
	UNION ALL
	
	SELECT
		 CONCAT(PolicyNumber, '.', RiskID)
		,Status
		,ChangeDate
	FROM CMTServ.dbo.LocationPermissionChange_EL
	
	UNION ALL
	
	SELECT
		 Account_ID
		,CASE Anomaly_Type
			WHEN 'LOCATION_SERVICES_ON'  THEN 'Enabled'
			WHEN 'LOCATION_SERVICES_OFF' THEN 'Disabled'
		 END
		,Anomaly_Device_Time
	FROM Sandbox.dbo.SJ_SAHR_Anomalies
	WHERE Anomaly_Type IN ('LOCATION_SERVICES_ON', 'LOCATION_SERVICES_OFF')
)

SELECT
	 Account_ID = CAST(Account_ID AS VARCHAR(30))
	,Status
	,ChangeDate
INTO Sandbox.dbo.SJ_SAHR_LocationServices
FROM LocationServices
WHERE ChangeDate >= DATEADD(DAY, -7, '01/01/2020')
	AND Account_ID != 'null.null'
;

CREATE CLUSTERED INDEX IX_SJ_SAHR_LocationServices_Account_IDChangeDate ON Sandbox.dbo.SJ_SAHR_LocationServices (Account_ID ASC, ChangeDate ASC);

SELECT
	 Account_ID
	,Day = CAST(ChangeDate AS DATE)
INTO Sandbox.dbo.SJ_SAHR_DisabledDays
FROM Sandbox.dbo.SJ_SAHR_LocationServices
WHERE Status = 'Disabled'
;

CREATE CLUSTERED INDEX IX_SJ_SAHR_DisabledDays_Account_IDDay ON Sandbox.dbo.SJ_SAHR_DisabledDays (Account_ID ASC, Day ASC);


SELECT *
FROM Sandbox.dbo.SJ_SAHR_GW
;

SELECT *
FROM Sandbox.dbo.SJ_SAHR_TripLabelChanges
;

SELECT TOP 1000 *
FROM Sandbox.dbo.SJ_SAHR_Trips
;

SELECT TOP 1000 *
FROM Sandbox.dbo.SJ_SAHR_Anomalies
;

SELECT TOP 1000 *
FROM Sandbox.dbo.SJ_SAHR_LocationServices
;


*/

DECLARE @EffectiveDate DATE = '01/01/2020';
DECLARE @EffectiveDatePlusOne DATE = DATEADD(DAY, 1, @EffectiveDate);

WHILE @EffectiveDate < '01/05/2020'
BEGIN

	DROP TABLE IF EXISTS Sandbox.dbo.SJ_SAHR_Active;

	SELECT
		 EffectiveDate = @EffectiveDate
		,Brand
		,PolicyNumber
		,Account_ID
	INTO Sandbox.dbo.SJ_SAHR_Active
	FROM Sandbox.dbo.SJ_SAHR_GW
	WHERE RegistrationDate < @EffectiveDatePlusOne
		AND GWCXXDate > @EffectiveDate
	;

	DROP TABLE IF EXISTS Sandbox.dbo.SJ_SAHR_TripsOnDay;

	;WITH LatestTripLabel AS (
		SELECT DISTINCT
			 Account_ID
			,DriveID
			,LatestTripLabel =
				LAST_VALUE(New_Label) OVER (
					PARTITION BY Account_ID, DriveID
					ORDER BY Label_Change_Date ASC, FileDate ASC
					ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
				)
		FROM Sandbox.dbo.SJ_SAHR_TripLabelChanges
	)

	SELECT
		 a.Account_ID
		,a.DriveID
		,a.Trip_Mode
		,LatestTripLabel = COALESCE(b.LatestTripLabel, a.User_Label, a.Trip_Mode)
	INTO Sandbox.dbo.SJ_SAHR_TripsOnDay
	FROM Sandbox.dbo.SJ_SAHR_Trips a
	LEFT JOIN LatestTripLabel b
		ON  a.Account_ID = b.Account_ID
		AND a.DriveID    = b.DriveID
	WHERE EXISTS ( SELECT 1 FROM Sandbox.dbo.SJ_SAHR_Active c WHERE a.Account_ID = c.Account_ID )
		AND a.Trip_Start_Local >= DATEADD(DAY, DATEDIFF(DAY, 0, @EffectiveDate       ), 0)
		AND a.Trip_Start_Local <  DATEADD(DAY, DATEDIFF(DAY, 0, @EffectiveDatePlusOne), 0)
	;

	DROP TABLE IF EXISTS Sandbox.dbo.SJ_SAHR_Drove;

	SELECT
		 a.Account_ID
		,StartedTrip     = CAST(1 AS BIT)
		,CarTripCMTLabel =
			CAST(CASE WHEN EXISTS ( 
				SELECT 1
				FROM Sandbox.dbo.SJ_SAHR_TripsOnDay b
				WHERE a.Account_ID = b.Account_ID
					AND b.Trip_Mode IN ('car', 'driver') 
			) THEN 1 ELSE 0 END AS BIT)
		,CarTripLastLabel =
			CAST(CASE WHEN EXISTS ( 
				SELECT 1
				FROM Sandbox.dbo.SJ_SAHR_TripsOnDay c
				WHERE a.Account_ID = c.Account_ID
					AND c.LatestTripLabel IN ('car', 'driver') 
			) THEN 1 ELSE 0 END AS BIT)
	INTO Sandbox.dbo.SJ_SAHR_Drove
	FROM Sandbox.dbo.SJ_SAHR_Active a
	WHERE EXISTS ( SELECT 1 FROM Sandbox.dbo.SJ_SAHR_TripsOnDay t WHERE a.Account_ID = t.Account_ID )
	;

	DROP TABLE IF EXISTS Sandbox.dbo.SJ_SAHR_LastLOCP;

	;WITH RollingLOCP AS (
		SELECT
			 Account_ID
			,Status
			,ChangeDate
			,RN = ROW_NUMBER() OVER (PARTITION BY Account_ID ORDER BY ChangeDate DESC)
		FROM Sandbox.dbo.SJ_SAHR_LocationServices
		WHERE ChangeDate >= DATEADD(DAY, -8, @EffectiveDate)
			AND ChangeDate < @EffectiveDatePlusOne
	)

	SELECT
		 Account_ID
		,Status
		,ChangeDate
	INTO Sandbox.dbo.SJ_SAHR_LastLOCP
	FROM RollingLOCP
	WHERE RN = 1
	;

	DROP TABLE IF EXISTS Sandbox.dbo.SJ_SAHR_NoDriveButEligible;

	;WITH AnomaliesAfter AS (
		SELECT a.Account_ID	
		FROM Sandbox.dbo.SJ_SAHR_LastLOCP a
		INNER JOIN Sandbox.dbo.SJ_SAHR_Anomalies b
			ON a.Account_ID = b.Account_ID
		WHERE b.Anomaly_Device_Time > a.ChangeDate
			AND b.Anomaly_Device_Time < @EffectiveDatePlusOne
			AND b.Anomaly_Type IN ('LOGOUT', 'FORCE_QUIT')
	)

	SELECT
		 a.Account_ID
		,StartedTrip      = CAST(0 AS BIT)
		,CarTripCMTLabel  = CAST(0 AS BIT)
		,CarTripLastLabel = CAST(0 AS BIT)
	INTO Sandbox.dbo.SJ_SAHR_NoDriveButEligible
	FROM Sandbox.dbo.SJ_SAHR_Active a
	WHERE NOT EXISTS (
		SELECT 1
		FROM Sandbox.dbo.SJ_SAHR_Drove b
		WHERE a.Account_ID = b.Account_ID
	)
		AND NOT EXISTS (
			SELECT 1
			FROM Sandbox.dbo.SJ_SAHR_DisabledDays c
			WHERE a.Account_ID = c.Account_ID
				AND c.Day = @EffectiveDate
		)
		AND EXISTS (
			SELECT 1
			FROM Sandbox.dbo.SJ_SAHR_LastLOCP d
			WHERE a.Account_ID = d.Account_ID
				AND d.Status = 'Enabled'
		)
		AND NOT EXISTS (
			SELECT 1
			FROM AnomaliesAfter e
			WHERE a.Account_ID = e.Account_ID
		)
	;

	;WITH Eligible AS (
		SELECT *
		FROM Sandbox.dbo.SJ_SAHR_Drove

		UNION ALL

		SELECT *
		FROM Sandbox.dbo.SJ_SAHR_NoDriveButEligible
	)

	INSERT Sandbox.dbo.SJ_SAHR_Eligible
	SELECT
		 a.*
		,b.StartedTrip
		,b.CarTripCMTLabel
		,b.CarTripLastLabel
		,'Started trip on day OR (last LOCP within last 8 days is enabled + no disabled LOCP on day + no logout/FQ after last LOCP)'
	FROM Sandbox.dbo.SJ_SAHR_Active a
	INNER JOIN Eligible b
		ON a.Account_ID = b.Account_ID
	;

	SET @EffectiveDate        = DATEADD(DAY, 1, @EffectiveDate);
	SET @EffectiveDatePlusOne = DATEADD(DAY, 1, @EffectiveDate);

END
;


/*
CREATE CLUSTERED INDEX IX_SJ_SAHR_Eligible_EffectiveDateMethod ON Sandbox.dbo.SJ_SAHR_Eligible (EffectiveDate ASC, Method ASC);

INSERT Sandbox.dbo.SJ_SAHR_Finale
SELECT
	 EffectiveDate
	,Method
	,Installed            = COUNT(DISTINCT PolicyNumber)
	,StartedTrip          = COUNT(DISTINCT CASE WHEN StartedTrip      = 1 THEN PolicyNumber END)
	,CarTripCMT           = COUNT(DISTINCT CASE WHEN CarTripCMTLabel  = 1 THEN PolicyNumber END)
	,CarTripLastLabel     = COUNT(DISTINCT CASE WHEN CarTripLastLabel = 1 THEN PolicyNumber END)
	,[StartedTrip %]      = COUNT(DISTINCT CASE WHEN StartedTrip      = 1 THEN PolicyNumber END) * 1.0 / COUNT(DISTINCT PolicyNumber)
	,[CarTripCMT %]       = COUNT(DISTINCT CASE WHEN CarTripCMTLabel  = 1 THEN PolicyNumber END) * 1.0 / COUNT(DISTINCT PolicyNumber)
	,[CarTripLastLabel %] = COUNT(DISTINCT CASE WHEN CarTripLastLabel = 1 THEN PolicyNumber END) * 1.0 / COUNT(DISTINCT PolicyNumber)
FROM Sandbox.dbo.SJ_SAHR_Eligible
WHERE Method = 'Started trip on day OR (last LOCP within last 10 days is enabled + no disabled LOCP on day + no logout/FQ after last LOCP)'
GROUP BY 
	 EffectiveDate
	,Method
;

SELECT
	 Method
	,AVG([StartedTrip %])
	,AVG([CarTripCMT %])
	,AVG([CarTripLastLabel %])
FROM Sandbox.dbo.SJ_SAHR_Finale
GROUP BY Method
ORDER BY 1 ASC
;

SELECT
	 Method
	,AVG([StartedTrip %])
	,AVG([CarTripCMT %])
	,AVG([CarTripLastLabel %])
FROM Sandbox.dbo.SJ_SAHR_Finale
WHERE EffectiveDate < '01/03/2020'
GROUP BY Method
ORDER BY 1 ASC
;

SELECT
	 Method
	,AVG([StartedTrip %])
	,AVG([CarTripCMT %])
	,AVG([CarTripLastLabel %])
FROM Sandbox.dbo.SJ_SAHR_Finale
WHERE EffectiveDate >= '01/03/2020'
GROUP BY Method
ORDER BY 1 ASC
;
	
SELECT
	 AVG(b.Drivers * 1.0 / a.Count)
FROM Sandbox.dbo.SJ_VF_AVB a
INNER JOIN Sandbox.dbo.TEL1386_VFDailySummary b
	ON a.Day = b.Date
ORDER BY 1 ASC
;

SELECT
	 AVG(b.Drivers * 1.0 / a.Count)
FROM Sandbox.dbo.SJ_VF_AVB a
INNER JOIN Sandbox.dbo.TEL1386_VFDailySummary b
	ON a.Day = b.Date
	AND a.Day < '01/03/2020'
ORDER BY 1 ASC
;

SELECT
	 AVG(b.Drivers * 1.0 / a.Count)
FROM Sandbox.dbo.SJ_VF_AVB a
INNER JOIN Sandbox.dbo.TEL1386_VFDailySummary b
	ON a.Day = b.Date
	AND a.Day >= '01/03/2020'
ORDER BY 1 ASC
;


SELECT
	 AVG(b.Drivers * 1.0 / a.Count)
FROM Sandbox.dbo.SJ_RT_AVB a
INNER JOIN Sandbox.dbo.TEL1386_RTDailySummary b
	ON a.Day = b.Date
ORDER BY 1 ASC
;

SELECT
	 AVG(b.Drivers * 1.0 / a.Count)
FROM Sandbox.dbo.SJ_RT_AVB a
INNER JOIN Sandbox.dbo.TEL1386_RTDailySummary b
	ON a.Day = b.Date
	AND a.Day < '01/03/2020'
ORDER BY 1 ASC
;

SELECT
	 AVG(b.Drivers * 1.0 / a.Count)
FROM Sandbox.dbo.SJ_RT_AVB a
INNER JOIN Sandbox.dbo.TEL1386_RTDailySummary b
	ON a.Day = b.Date
	AND a.Day >= '01/03/2020'
ORDER BY 1 ASC
;

AJ 20:20, 20:30 WIFI ON
9PM ON

USE CMTSERV;

-- DROP TABLE SANDBOX.DBO.SJ_SAHR_Heartbeat;

;WITH HMM AS (
SELECT POLICYNUMBER, RISKID, DEVICEID, STATUS, STATUSCODE, CHANGEDATE, PLATFORM, APPVERSION, OSVERSION, IMPORTFILEID
FROM DBO.LOCATIONPERMISSIONCHANGE

UNION ALL

SELECT POLICYNUMBER, RISKID, DEVICEID, STATUS, STATUSCODE, CHANGEDATE, PLATFORM, APPVERSION, OSVERSION, IMPORTFILEID
FROM DBO.LOCATIONPERMISSIONCHANGE_EL
)

SELECT *, PreviousStatus = LAG(STATUS, 1, NULL) OVER (PARTITION BY POLICYNUMBER, RISKID, DEVICEID ORDER BY CHANGEDATE ASC, IMPORTFILEID ASC),
PreviousStatusCode = LAG(STATUSCODE, 1, NULL) OVER (PARTITION BY POLICYNUMBER, RISKID, DEVICEID ORDER BY CHANGEDATE ASC, IMPORTFILEID ASC)
INTO SANDBOX.DBO.SJ_SAHR_Heartbeat
FROM HMM
WHERE CHANGEDATE >= '01/01/2020' AND CHANGEDATE < '01/05/2020'
;

PRINT @@ROWCOUNT;

CREATE CLUSTERED INDEX IX_SJ_SAHR_Heartbeat ON SANDBOX.DBO.SJ_SAHR_Heartbeat (POLICYNUMBER, CHANGEDATE);

SELECT COUNT(DISTINCT CONCAT(POLICYNUMBER, RISKID, DEVICEID))
FROM SANDBOX.DBO.SJ_SAHR_Heartbeat A
WHERE STATUS = PREVIOUSSTATUS
AND STATUSCODE = PREVIOUSSTATUSCODE
AND PLATFORM = 'ANDROID'
AND EXISTS ( SELECT 1 FROM SANDBOX.DBO.TEL1300_3_MI B WHERE A.POLICYNUMBER = B.POLICYNUMBER AND A.RISKID = B.RISKID AND B.REGISTRATIONDATE < '01/03/2020'
)
AND EXISTS ( SELECT 1 FROM SANDBOX.DBO.SJ_SAHR_Heartbeat C WHERE A.POLICYNUMBER = C.POLICYNUMBER AND A.RISKID = C.RISKID AND A.DEVICEID = C.DEVICEID AND C.CHANGEDATE >= '01/04/2020' )
GROUP BY CUBE (APPVERSION, OSVERSION )
;

SET SHOWPLAN_ALL OFF


EVENTS: 2,756,971
EVENTS EQ TO PRIOR EVENT: 2,213,403 (80%)
EVENTS EQ TO PRIOR EVENT ANDROID: 357,781 (13%)
EVENTS EQ TO PRIOR EVENT IOS: 1,855,622 (87%)
ANDROID IS 1/3 OF OUR USER BASE MEANING WE WOULD EXPECT 33%.
THIS MEANS HEARTBEATS PERFORM BETTER ON IOS CUSTOMERS WHICH WE'D WANT, IF WE HAD TO CHOOSE.

DISTINCT POLICYNUMBER RISKID DEVICEID: 139,313
EQ TO PRIOR EQ: 87,899
EQ TO PRIOR EVENT ANDROID: 2,550
IOS: 85,447
MEANING =========== IOS USERS HEARTS BEAT FAR MORE OFTEN.




















*/

























/*
CREATE TABLE Sandbox.dbo.SJ_BST (
	 StartDate DATETIME NOT NULL
	,EndDate   DATETIME NOT NULL 

	CONSTRAINT PK__SJ_BST__StartDateEndDate PRIMARY KEY CLUSTERED (StartDate ASC, EndDate ASC)
)
;

TRUNCATE TABLE Sandbox.dbo.SJ_BST;

DECLARE @StartYear SMALLINT = 2018;
DECLARE @EndYear SMALLINT = 2020;

WHILE @StartYear <= @EndYear
BEGIN

	;WITH FinalWeekOfMarch (StartDate) AS (
		SELECT DATETIMEFROMPARTS(@StartYear, 03, 25, 01, 00, 00, 000)

		UNION ALL

		SELECT DATEADD(DAY, 1, StartDate)
		FROM FinalWeekOfMarch 
		WHERE DATENAME(MONTH, DATEADD(DAY, 1, StartDate)) = 'March'
	),

	FinalWeekOfOctober (EndDate) AS (
		SELECT DATETIMEFROMPARTS(@StartYear, 10, 25, 01, 00, 00, 000)

		UNION ALL

		SELECT DATEADD(DAY, 1, EndDate)
		FROM FinalWeekOfOctober 
		WHERE DATENAME(MONTH, DATEADD(DAY, 1, EndDate)) = 'October'
	)

	INSERT Sandbox.dbo.SJ_BST (StartDate, EndDate)
	SELECT *
	FROM FinalWeekOfMarch a
	CROSS JOIN (
		SELECT EndDate
		FROM FinalWeekOfOctober
		WHERE DATENAME(WEEKDAY, EndDate) = 'Sunday'
	) b
	WHERE DATENAME(WEEKDAY, a.StartDate) = 'Sunday'
	OPTION (MAXRECURSION 6)
	;

	SET @StartYear += 1;

END
;

SELECT *
FROM Sandbox.dbo.SJ_BST
;
*/












