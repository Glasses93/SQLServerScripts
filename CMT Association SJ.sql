
-- CMT ASSOCIATION SJ.

-- TABLE DEFINITION.

CREATE TABLE Sandbox.dbo.CMTAssociation_SJ ( -- DROP TABLE IF EXISTS Sandbox.dbo.CMTAssociation_SJ;
	 Account_ID				VARCHAR(15 )	NOT NULL
	,PolicyNumber			VARCHAR(10 )	NOT NULL
	,RiskID					VARCHAR(4  )	NOT NULL
	,Brand					VARCHAR(4  )		NULL
	,Email					VARCHAR(256)	 	NULL
	,Platform				VARCHAR(15 )	 	NULL
	,DeviceID				VARCHAR(40 )	 	NULL
	,DeviceIDShort			VARCHAR(16 )	 	NULL
	,RegistrationDate		DATETIME		 	NULL
	,MostRecentLoginDate	DATETIME		 	NULL
	,TeleOptInDate			DATETIME			NULL
	,FirstLOCP				VARCHAR(15)			NULL
	,FirstLOCPDate			DATETIME			NULL
	,MostRecentLOCP			VARCHAR(15)			NULL
	,MostRecentLOCPDate		DATETIME			NULL
	,FirstTripDate			DATETIME			NULL
	,MostRecentTripDate		DATETIME			NULL	
	,FirstDrivingDate		DATETIME			NULL
	,MostRecentDrivingDate	DATETIME			NULL
	,Mileage				NUMERIC(18, 6)		NULL
	,DriverMileage			NUMERIC(18, 6)		NULL
	,RegistrationAppVersion
	,RegistrationOSVersion
	,LatestAppVersion
	,LatestOSVersion
	--, CXXS Dates ...
);

CREATE CLUSTERED INDEX IX_CMTAssociationSJ_AccountID ON Sandbox.dbo.CMTAssociation_SJ (Account_ID ASC);

-- UPDATE REGISTRATION DATES.

;WITH RegistrationDate (Account_ID, RegistrationDate) AS (
	SELECT
		 Account_ID 	  = CONCAT(a.PolicyNumber, '.', a.RiskID)
		,RegistrationDate = MIN(a.LoginDate)
	FROM (
		SELECT
			 PolicyNumber
			,RiskID
			,LoginDate
		--FROM Staging.dbo.EndavaSuccessfulLoginHistory
		FROM CMTServ.dbo.SuccessfulLoginHistory
		
		UNION ALL
		
		SELECT
			 PolicyNumber
			,RiskID
			,LoginDate
		--FROM Staging.dbo.EndavaSuccessfulLoginHistory_EL
		FROM CMTServ.dbo.SuccessfulLoginHistory_EL
		
		UNION ALL
		
		SELECT
			 PolicyNumber
			,RiskID
			,LoginDate = ChangeDate
		--FROM Staging.dbo.EndavaLocationPermissionChange
		FROM CMTServ.dbo.LocationPermissionChange
		
		UNION ALL
		
		SELECT
			 PolicyNumber
			,RiskID
			,LoginDate = ChangeDate
		--FROM Staging.dbo.EndavaLocationPermissionChange_EL
		FROM CMTServ.dbo.LocationPermissionChange_EL
	) a
	GROUP BY
		 a.PolicyNumber
		,a.RiskID
)

UPDATE a
SET a.RegistrationDate = b.RegistrationDate
OUTPUT
	 INSERTED.Account_ID
	,DELETED.RegistrationDate  AS OldRegistrationDate
	,INSERTED.RegistrationDate AS NewRegistrationDate
FROM Sandbox.dbo.CMTAssociation_SJ a
INNER JOIN RegistrationDate b
	ON a.Account_ID = b.Account_ID
WHERE (b.RegistrationDate < a.RegistrationDate OR a.RegistrationDate IS NULL)
;

-- UPDATE MOST RECENT SUCCESSFUL LOGIN DATE.

;WITH MostRecentLoginDate (Account_ID, MostRecentLoginDate) AS (
	SELECT
		 Account_ID 		 = CONCAT(a.PolicyNumber, '.', a.RiskID)
		,MostRecentLoginDate = MAX(a.LoginDate)
	FROM (
		SELECT
			 PolicyNumber
			,RiskID
			,LoginDate
		--FROM Staging.dbo.EndavaSuccessfulLoginHistory
		FROM CMTServ.dbo.SuccessfulLoginHistory
		
		UNION ALL
		
		SELECT
			 PolicyNumber
			,RiskID
			,LoginDate
		--FROM Staging.dbo.EndavaSuccessfulLoginHistory_EL
		FROM CMTServ.dbo.SuccessfulLoginHistory_EL
	) a
	GROUP BY
		 a.PolicyNumber
		,a.RiskID
)

UPDATE a
SET a.MostRecentLoginDate = b.MostRecentLoginDate
OUTPUT
	 INSERTED.Account_ID
	,DELETED.MostRecentLoginDate  AS OldMostRecentLoginDate
	,INSERTED.MostRecentLoginDate AS NewMostRecentLoginDate
FROM Sandbox.dbo.CMTAssociation_SJ a
INNER JOIN MostRecentLoginDate b
	ON a.Account_ID = b.Account_ID
WHERE (b.MostRecentLoginDate > a.MostRecentLoginDate OR a.MostRecentLoginDate IS NULL)
;

-- UPDATE TELEMATICS OPT-IN FLAG & DATE.

;WITH TelematicsOptIn (Account_ID, TeleOptInDate) AS (
	SELECT
		 Account_ID 		 = CONCAT(a.PolicyNumber, '.', a.RiskID)
		,TelematicsOptInDate = MIN(a.ChangeDate)
	FROM (
		SELECT
			 PolicyNumber
			,RiskID
			,Status
			,ChangeDate
		--FROM Staging.dbo.EndavaSuccessfulLoginHistory
		FROM CMTServ.dbo.SuccessfulLoginHistory
		
		UNION ALL
		
		SELECT
			 PolicyNumber
			,RiskID
			,Status
			,ChangeDate
		--FROM Staging.dbo.EndavaSuccessfulLoginHistory_EL
		FROM CMTServ.dbo.SuccessfulLoginHistory_EL
	) a
	WHERE a.Status = 'Enabled'
	GROUP BY
		 a.PolicyNumber
		,a.RiskID
)

UPDATE a
SET a.TeleOptInDate = b.TeleOptInDate
OUTPUT
	 INSERTED.Account_ID
	,DELETED.TeleOptInDate  AS OldTeleOptInDateDate
	,INSERTED.TeleOptInDate AS NewTeleOptInDateDate
FROM Sandbox.dbo.CMTAssociation_SJ a
INNER JOIN TelematicsOptIn b
	ON a.Account_ID = b.Account_ID
WHERE (b.TeleOptInDate < a.TeleOptInDate OR a.TeleOptInDate IS NULL)
;

-- UPDATE FIRST LOCATION PERMISSION.

;WITH LOCP (Account_ID, LOCP, ChangeDate, RowNumber) AS (
	SELECT
		 Account_ID = CONCAT(a.PolicyNumber, '.', a.RiskID)
		,LOCP 		= CONCAT(a.Status, ' - ', a.StatusCode)
		,a.ChangeDate
		,RowNumber  = ROW_NUMBER() OVER (
			PARTITION BY a.PolicyNumber, a.RiskID
			ORDER BY a.ChangeDate ASC, a.InsertedDate ASC
		 )
	FROM (
		SELECT
			 PolicyNumber
			,RiskID
			,Status
			,StatusCode
			,ChangeDate
			,InsertedDate
		--FROM Staging.dbo.EndavaLocationPermissionChange
		FROM CMTServ.dbo.LocationPermissionChange
		
		UNION ALL
		
		SELECT
			 PolicyNumber
			,RiskID
			,Status
			,StatusCode
			,ChangeDate
			,InsertedDate
		--FROM Staging.dbo.EndavaLocationPermissionChange_EL
		FROM CMTServ.dbo.LocationPermissionChange_EL
	) a
)

UPDATE a
SET
	 a.FirstLOCP     = b.LOCP
	,a.FirstLOCPDate = b.ChangeDate
OUTPUT
	 INSERTED.Account_ID
	,DELETED.FirstLOCP      AS OldFirstLOCP
	,INSERTED.FirstLOCP     AS NewFirstLOCP
	,DELETED.FirstLOCPDate  AS OldFirstLOCPDate
	,INSERTED.FirstLOCPDate AS NewFirstLOCPDate
FROM Sandbox.dbo.CMTAssociation_SJ a
INNER JOIN LOCP b
	ON a.Account_ID = b.Account_ID
WHERE b.RowNumber = 1
	AND (b.ChangeDate < a.FirstLOCPDate OR a.FirstLOCPDate IS NULL)
;

-- UPDATE MOST RECENT LOCATION PERMISSION.

;WITH LOCP (Account_ID, LOCP, ChangeDate, RowNumber) AS (
	SELECT
		 Account_ID = CONCAT(a.PolicyNumber, '.', a.RiskID)
		,LOCP 		= CONCAT(a.Status, ' - ', a.StatusCode)
		,a.ChangeDate
		,RowNumber  = ROW_NUMBER() OVER (
			PARTITION BY a.PolicyNumber, a.RiskID
			ORDER BY a.ChangeDate DESC, a.InsertedDate DESC
		 )
	FROM (
		SELECT
			 PolicyNumber
			,RiskID
			,Status
			,StatusCode
			,ChangeDate
			,InsertedDate
		--FROM Staging.dbo.EndavaLocationPermissionChange
		FROM CMTServ.dbo.LocationPermissionChange
		
		UNION ALL
		
		SELECT
			 PolicyNumber
			,RiskID
			,Status
			,StatusCode
			,ChangeDate
			,InsertedDate
		--FROM Staging.dbo.EndavaLocationPermissionChange_EL
		FROM CMTServ.dbo.LocationPermissionChange_EL
	) a
)

UPDATE a
SET
	 a.MostRecentLOCP     = b.LOCP
	,a.MostRecentLOCPDate = b.ChangeDate
OUTPUT
	 INSERTED.Account_ID
	,DELETED.MostRecentLOCP      AS OldMostRecentLOCP
	,INSERTED.MostRecentLOCP     AS NewMostRecentLOCP
	,DELETED.MostRecentLOCPDate  AS OldMostRecentLOCPDate
	,INSERTED.MostRecentLOCPDate AS NewMostRecentLOCPDate
FROM Sandbox.dbo.CMTAssociation_SJ a
INNER JOIN LOCP b
	ON a.Account_ID = b.Account_ID
WHERE b.RowNumber = 1
	AND (b.ChangeDate > a.MostRecentLOCPDate OR a.MostRecentLOCPDate IS NULL)
;

-- UPDATE TRIP DATES.

;WITH LatestTripLabel (Account_ID, DriveID, LatestTripLabel) AS (
	SELECT
		 a.Account_ID
		,a.DriveID
		,LatestTripLabel = LAST_VALUE(a.New_Label) OVER (
			PARTITION BY a.Account_ID, a.DriveID
			ORDER BY a.Label_Change_Date ASC, a.FileDate ASC
			ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
		 )
	FROM (
		SELECT
			 Account_ID
			,DriveID
			,New_Label
			,Label_Change_Date
			,FileDate
		FROM CMTServ.dbo.CMTTripLabel
		
		UNION ALL
		
		SELECT
			 Account_ID
			,DriveID
			,New_Label
			,Label_Change_Date
			,FileDate
		FROM CMTServ.dbo.CMTTripLabel_EL
	) a
),
TelematicsData (Account_ID, FirstTripDate, MostRecentTripDate, FirstDrivingDate, MostRecentDrivingDate, Mileage, DriverMileage) AS (
	SELECT
		 a.Account_ID
		,FirstTripDate 		   = MIN(a.Trip_Start_Local)
		,MostRecentTripDate    = MAX(a.Trip_End_Local)
		,FirstDrivingDate 	   = MIN(CASE WHEN COALESCE(b.LatestTripLabel, a.Trip_Mode) = 'Car' THEN a.Trip_Start_Local ELSE NULL END)
		,MostRecentDrivingDate = MAX(CASE WHEN COALESCE(b.LatestTripLabel, a.Trip_Mode) = 'Car' THEN a.Trip_End_Local   ELSE NULL END)
		,Mileage               = SUM(a.Distance_Mapmatched_KM * 0.621371)
		,DriverMileage         = SUM(CASE WHEN COALESCE(b.LatestTripLabel, a.Trip_Mode) = 'Car' THEN (a.Distance_Mapmatched_KM * 0.621371) ELSE 0 END)
	FROM (
		SELECT
			 Account_ID
			,DriveID
			,Trip_Start_Local
			,Trip_End_Local
			,Distance_Mapmatched_KM
			,Trip_Mode
		FROM CMTServ.dbo.CMTTripSummary
		
		UNION ALL
		
		SELECT
			 Account_ID
			,DriveID
			,Trip_Start_Local
			,Trip_End_Local
			,Distance_Mapmatched_KM
			,Trip_Mode
		FROM CMTServ.dbo.CMTTripSummary_EL
	) a
	LEFT JOIN LatestTripLabel b
		ON  a.Account_ID = b.Account_ID
		AND a.DriveID = b.DriveID
	GROUP BY a.Account_ID
)

UPDATE a
SET
	 a.FirstTripDate 	  	 = b.FirstTripDate
	,a.MostRecentTripDate 	 = b.MostRecentTripDate
	,a.FirstDrivingDate 	 = b.FirstDrivingDate
	,a.MostRecentDrivingDate = b.MostRecentDrivingDate
	,a.Mileage 				 = b.Mileage
	,a.DriverMileage 		 = b.DriverMileage
OUTPUT
	 INSERTED.Account_ID
	,DELETED.FirstTripDate      	AS OldFirstTripDate
	,INSERTED.FirstTripDate     	AS NewFirstTripDate
	,DELETED.MostRecentTripDate  	AS OldMostRecentTripDate
	,INSERTED.MostRecentTripDate 	AS NewMostRecentTripDate
	,DELETED.FirstDrivingDate      	AS OldFirstDrivingDate
	,INSERTED.FirstDrivingDate     	AS NewFirstDrivingDate
	,DELETED.MostRecentDrivingDate  AS OldMostRecentDrivingDate
	,INSERTED.MostRecentDrivingDate AS NewMostRecentDrivingDate
	,DELETED.Mileage      			AS OldMileage
	,INSERTED.Mileage     			AS NewMileage
	,DELETED.DriverMileage  		AS OldDriverMileage
	,INSERTED.DriverMileage 		AS NewDriverMileage
FROM Sandbox.dbo.CMTAssociation_SJ a
INNER JOIN TelematicsData b
	ON a.Account_ID = b.Account_ID
;

-- INSERT NEW ASSOCIATIONS (A UNIQUE COMBINATION OF POLICY NUMBER, RISK ID, EMAIL, AND DEVICEID) INTO CMTServ.dbo.Association.

;WITH Registrations (Account_ID, PolicyNumber, RiskID, Brand, Email, Platform, DeviceID, DeviceIDShort) AS (
	SELECT DISTINCT
		 Account_ID = CONCAT(a.PolicyNumber, '.', a.RiskID)
		,a.PolicyNumber
		,a.RiskID
		,a.Brand
		,a.Email
		,a.Platform
		,a.DeviceID
		,DeviceIDShort = LEFT(a.DeviceID, 16)
	FROM (
		SELECT
			 PolicyNumber
			,RiskID
			,Brand
			,Email
			,Platform
			,DeviceID
		--FROM Staging.dbo.EndavaSuccessfulLoginHistory
		FROM CMTServ.dbo.SuccessfulLoginHistory
		
		UNION ALL
		
		SELECT
			 PolicyNumber
			,RiskID
			,Brand
			,Email
			,Platform
			,DeviceID
		--FROM Staging.dbo.EndavaSuccessfulLoginHistory_EL
		FROM CMTServ.dbo.SuccessfulLoginHistory_EL
		
		UNION ALL
		
		SELECT
			 PolicyNumber
			,RiskID
			,Brand
			,Email
			,Platform
			,DeviceID
		--FROM Staging.dbo.EndavaLocationPermissionChange
		FROM CMTServ.dbo.LocationPermissionChange
		
		UNION ALL
		
		SELECT
			 PolicyNumber
			,RiskID
			,Brand
			,Email
			,Platform
			,DeviceID
		--FROM Staging.dbo.EndavaLocationPermissionChange_EL
		FROM CMTServ.dbo.LocationPermissionChange_EL
		
	) a
	WHERE a.PolicyNumber LIKE 'P%'
		AND a.RiskID NOT IN ('null', 'UNK')
)

INSERT Sandbox.dbo.CMTAssociation_SJ (Account_ID, PolicyNumber, RiskID, Brand, Email, Platform, DeviceID, DeviceIDShort)
OUTPUT
	 INSERTED.Account_ID
	,INSERTED.PolicyNumber
	,INSERTED.RiskID
	,INSERTED.Brand
	,INSERTED.Email
	,INSERTED.Platform
	,INSERTED.DeviceID
	,INSERTED.DeviceIDShort
SELECT a.*
FROM Registrations a
WHERE NOT EXISTS (
	SELECT 1
	FROM Sandbox.dbo.CMTAssociation_SJ b
	WHERE a.Account_ID = b.Account_ID
		AND a.Email = b.Email
		AND a.DeviceID = b.DeviceID
)
;
	