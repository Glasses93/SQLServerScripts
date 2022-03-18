
/*------------------------------------------------------- CMT Association -------------------------------------------------------
	Purpose: Create and update a user-level summary on Service App customers.

	Method:
		1.	Insert new Service App registrations into CMTServ.dbo.Association.
			These are identified as a unique combination of PolicyNumber and RiskID from Endava's REGS, LOGS, and LOCP files.
		2. 	Update columns for all users based on new data.
		3. 	Insert new Emails and DeviceIDs for previously inserted registrations.

	Table Constraints:
		-	CLUSTERED INDEX: Account_ID.
		-	DEFAULT        : LoginCount = 1.
		-	DEFAULT        : Mileage    = 0.

	Notes:
		-	See Sandbox.dbo.Association_Log for query run-times and row counts affected.
		-	The clustered index is re-built once every middle-of-the-month Monday in order to reduce fragmentation.
		-	In order to recount the Mileage and LoginCount fields from scratch (due to data deletions or other issues), create
			the following table: Sandbox.dbo.SJ_Association_RFRSH.
			Drop the table after recounting to avoid unnecessarily slowing down the script.
  -------------------------------------------------------------------------------------------------------------------------------*/

-- Session settings:

SET ANSI_NULLS        ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT           ON;

-- Log table:

DECLARE @Association_Log TABLE (
	 ScriptStartTime	DATETIME2(7)	NOT NULL
	,StepName			VARCHAR(100)	NOT NULL
	,StepFinishTime		DATETIME2(7)	NOT NULL
	,RowsAffected		INT				NOT NULL
)
;

DECLARE @ScriptStartTime DATETIME2(7) = SYSDATETIME();

IF OBJECT_ID('Sandbox.dbo.SJ_Association', 'U') IS NULL
BEGIN

-- Table definition:

	CREATE TABLE Sandbox.dbo.SJ_Association ( -- DROP TABLE IF EXISTS Sandbox.dbo.SJ_Association;
		 Account_ID					VARCHAR(30)		NOT NULL
		,PolicyNumber				VARCHAR(20)		NOT NULL
		,RiskID					    CHAR(4)			NOT NULL
		,Brand					 	VARCHAR(15)		NOT	NULL
		,Email						VARCHAR(128)	NOT	NULL
		,Platform					VARCHAR(15)		NOT	NULL
		,DeviceID				    CHAR(36)		NOT	NULL
		,DeviceIDShort			    CHAR(16)		NOT	NULL
		,RegistrationDate			DATETIME2(0)		NULL
		,MostRecentLoginDate		DATETIME2(0)		NULL
		,LoginCount					SMALLINT			NULL	CONSTRAINT DF_SJ_Association_LoginCount DEFAULT 1
		,EndDate					DATE				NULL
		,CXXSentDate				DATE				NULL
		,CXXSSuccessDate			DATE				NULL
		,CXXSReturnDate				DATE				NULL
		,FirstLOCP					VARCHAR(25)			NULL
		,FirstLOCPDate				DATETIME2(0)		NULL
		,MostRecentLOCP				VARCHAR(25)			NULL
		,MostRecentLOCPDate			DATETIME2(0)		NULL
		,FirstTripDate				DATETIME2(0)		NULL
		,MostRecentTripDate			DATETIME2(0)		NULL
		,Mileage					NUMERIC(9, 2)		NULL	CONSTRAINT DF_SJ_Association_Mileage    DEFAULT 0
		,MostRecentAchievement		VARCHAR(25)			NULL
		,MostRecentAchievementDate	DATETIME2(0)		NULL
		,Notifications				VARCHAR(40)			NULL
		,NotificationsDate			DATETIME2(0)		NULL
		,PushNotified			  	VARCHAR(40)			NULL
		,PushNotifiedDate			SMALLDATETIME		NULL
		,OSVersion				    VARCHAR(20)			NULL
		,AppVersion				    VARCHAR(20)			NULL
		,Environment				VARCHAR(15)			NULL
		,StaffTester				CHAR(3)				NULL
		,CoverType				    CHAR(5)				NULL
	)
	;

	-- Index:

	CREATE CLUSTERED INDEX IX_SJ_Association_Account_ID ON Sandbox.dbo.SJ_Association (Account_ID ASC);

END
;

TRUNCATE TABLE Sandbox.dbo.SJ_Association;

-- Insert new registrations:

;WITH Registrations (Account_ID, PolicyNumber, RiskID, Brand, Email, Platform, DeviceID, DeviceIDShort, CoverType) AS (
	SELECT DISTINCT
		 Account_ID = CONCAT(a.PolicyNumber, '.', a.RiskID)
		,a.PolicyNumber
		,a.RiskID
		,Brand =
			CASE a.Brand
				WHEN 'EL' THEN 'Elephant'
				WHEN 'AD' THEN 'Admiral'
			END	
		,a.Email
		,a.Platform
		,a.DeviceID
		,DeviceIDShort = LEFT(a.DeviceID, 16)
		,CoverType =
			CASE
				WHEN a.RiskID LIKE 'M%' THEN 'Motor'
				WHEN a.RiskID LIKE 'H%' THEN 'Home'
			END
	FROM (
		SELECT
			 PolicyNumber
			,RiskID
			,Brand
			,Email
			,Platform
			,DeviceID
		FROM CMTServ.dbo.SuccessfulLoginHistory

		UNION ALL

		SELECT
			 PolicyNumber
			,RiskID
			,Brand
			,Email
			,Platform
			,DeviceID
		FROM CMTServ.dbo.SuccessfulLoginHistory_EL

		UNION ALL

		SELECT
			 PolicyNumber
			,RiskID
			,Brand
			,Email
			,Platform
			,DeviceID
		FROM CMTServ.dbo.LocationPermissionChange

		UNION ALL

		SELECT
			 PolicyNumber
			,RiskID
			,Brand
			,Email
			,Platform
			,DeviceID
		FROM CMTServ.dbo.LocationPermissionChange_EL

	) a
	WHERE a.PolicyNumber LIKE 'P%'
		AND ( a.RiskID LIKE 'M%' OR a.RiskID LIKE 'H%' )
		AND a.Brand    IN ('EL', 'AD')
		AND a.Email    LIKE '%@%'
		AND a.Platform != 'null'
		AND a.DeviceID != 'null'
)

INSERT Sandbox.dbo.SJ_Association (Account_ID, PolicyNumber, RiskID, Brand, Email, Platform, DeviceID, DeviceIDShort, CoverType)
SELECT
	 r.Account_ID
	,r.PolicyNumber
	,r.RiskID
	,r.Brand
	,r.Email
	,r.Platform
	,r.DeviceID
	,r.DeviceIDShort
	,r.CoverType
FROM Registrations r
WHERE NOT EXISTS (
	SELECT 1
	FROM Sandbox.dbo.SJ_Association a
	WHERE r.Account_ID = a.Account_ID
)
;

INSERT @Association_Log (ScriptStartTime, StepName, StepFinishTime, RowsAffected)
	VALUES (@ScriptStartTime, 'New Registrations', SYSDATETIME(), @@ROWCOUNT)
;

-- Update RegistrationDate:

;WITH RegistrationDate (Account_ID, RegistrationDate) AS (
	SELECT
		 Account_ID 	  = CONCAT(a.PolicyNumber, '.', a.RiskID)
		,RegistrationDate = MIN(a.LoginDate)
	FROM (
		SELECT
			 PolicyNumber
			,RiskID
			,LoginDate
		FROM CMTServ.dbo.SuccessfulLoginHistory

		UNION ALL

		SELECT
			 PolicyNumber
			,RiskID
			,LoginDate
		FROM CMTServ.dbo.SuccessfulLoginHistory_EL

		UNION ALL

		SELECT
			 PolicyNumber
			,RiskID
			,LoginDate = ChangeDate
		FROM CMTServ.dbo.LocationPermissionChange

		UNION ALL

		SELECT
			 PolicyNumber
			,RiskID
			,LoginDate = ChangeDate
		FROM CMTServ.dbo.LocationPermissionChange_EL
	) a
	WHERE a.LoginDate >= '20/02/2018 00:00:00'
		AND a.LoginDate < GETDATE()		
	GROUP BY
		 a.PolicyNumber
		,a.RiskID
)

UPDATE a
	SET a.RegistrationDate = rd.RegistrationDate
FROM Sandbox.dbo.SJ_Association a
INNER JOIN RegistrationDate rd
	ON a.Account_ID = rd.Account_ID
WHERE ( rd.RegistrationDate < a.RegistrationDate OR a.RegistrationDate IS NULL )
;

INSERT @Association_Log (ScriptStartTime, StepName, StepFinishTime, RowsAffected)
	VALUES (@ScriptStartTime, 'RegistrationDate', SYSDATETIME(), @@ROWCOUNT)
;

-- Update MostRecentLoginDate:

UPDATE Sandbox.dbo.SJ_Association
	SET MostRecentLoginDate = RegistrationDate
WHERE MostRecentLoginDate IS NULL
;

INSERT @Association_Log (ScriptStartTime, StepName, StepFinishTime, RowsAffected)
	VALUES (@ScriptStartTime, 'MostRecentLoginDate #1', SYSDATETIME(), @@ROWCOUNT)
;

;WITH MostRecentLoginDate (Account_ID, MostRecentLoginDate) AS (
	SELECT
		 Account_ID 		 = CONCAT(a.PolicyNumber, '.', a.RiskID)
		,MostRecentLoginDate = MAX(a.LoginDate)
	FROM (
		SELECT
			 PolicyNumber
			,RiskID
			,LoginDate
		FROM CMTServ.dbo.SuccessfulLoginHistory

		UNION ALL

		SELECT
			 PolicyNumber
			,RiskID
			,LoginDate
		FROM CMTServ.dbo.SuccessfulLoginHistory_EL
	) a
	WHERE a.LoginDate >= '20/02/2018 00:00:00'
		AND a.LoginDate < GETDATE()
	GROUP BY
		 a.PolicyNumber
		,a.RiskID
)

UPDATE a
	SET a.MostRecentLoginDate = mrld.MostRecentLoginDate
FROM Sandbox.dbo.SJ_Association a
INNER JOIN MostRecentLoginDate mrld
	ON a.Account_ID = mrld.Account_ID
WHERE ( mrld.MostRecentLoginDate > a.MostRecentLoginDate OR a.MostRecentLoginDate IS NULL )
;

INSERT @Association_Log (ScriptStartTime, StepName, StepFinishTime, RowsAffected)
	VALUES (@ScriptStartTime, 'MostRecentLoginDate #2', SYSDATETIME(), @@ROWCOUNT)
;

;WITH LoginCount (Account_ID, LoginCount) AS (
	SELECT
		 Account_ID = CONCAT(a.PolicyNumber, '.', a.RiskID)
		,LoginCount = COUNT(DISTINCT a.LoginDate)
	FROM (
		SELECT
			 PolicyNumber
			,RiskID
			,LoginDate
		FROM CMTServ.dbo.SuccessfulLoginHistory

		UNION ALL

		SELECT
			 PolicyNumber
			,RiskID
			,LoginDate
		FROM CMTServ.dbo.SuccessfulLoginHistory_EL
	) a
	WHERE a.LoginDate >= '20/02/2018 00:00:00'
		AND a.LoginDate < GETDATE()
	GROUP BY
		 a.PolicyNumber
		,a.RiskID
)

UPDATE a
	SET a.LoginCount = CASE WHEN a.RegistrationDate < '03/04/2019 15:25:14' THEN lc.LoginCount ELSE ( lc.LoginCount + 1 ) END
FROM Sandbox.dbo.SJ_Association a
INNER JOIN LoginCount lc
	ON a.Account_ID = lc.Account_ID
;

INSERT @Association_Log (ScriptStartTime, StepName, StepFinishTime, RowsAffected)
	VALUES (@ScriptStartTime, 'LoginCount Refresh', SYSDATETIME(), @@ROWCOUNT)
;


-- Update FirstLOCP and FirstLOCPDate:

;WITH LOCP (Account_ID, LOCP, ChangeDate, RowNumber) AS (
	SELECT
		 Account_ID = CONCAT(a.PolicyNumber, '.'  , a.RiskID)
		,LOCP 		= CONCAT(a.Status      , ' - ', a.StatusCode)
		,a.ChangeDate
		,RowNumber  =
			ROW_NUMBER() OVER (
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
		FROM CMTServ.dbo.LocationPermissionChange

		UNION ALL

		SELECT
			 PolicyNumber
			,RiskID
			,Status
			,StatusCode
			,ChangeDate
			,InsertedDate
		FROM CMTServ.dbo.LocationPermissionChange_EL
	) a
	WHERE a.ChangeDate >= '20/02/2018 00:00:00'
		AND a.ChangeDate < GETDATE()
)

UPDATE a
SET
	 a.FirstLOCP     = l.LOCP
	,a.FirstLOCPDate = l.ChangeDate
FROM Sandbox.dbo.SJ_Association a
INNER JOIN LOCP l
	ON a.Account_ID = l.Account_ID
WHERE l.RowNumber = 1
	AND ( l.ChangeDate < a.FirstLOCPDate OR a.FirstLOCPDate IS NULL )
;

INSERT @Association_Log (ScriptStartTime, StepName, StepFinishTime, RowsAffected)
	VALUES (@ScriptStartTime, 'FirstLOCP & FirstLOCPDate', SYSDATETIME(), @@ROWCOUNT)
;

-- Update MostRecentLOCP and MostRecentLOCPDate:

;WITH LOCP (Account_ID, LOCP, ChangeDate, RowNumber) AS (
	SELECT
		 Account_ID = CONCAT(a.PolicyNumber, '.'  , a.RiskID)
		,LOCP 		= CONCAT(a.Status      , ' - ', a.StatusCode)
		,a.ChangeDate
		,RowNumber  =
			ROW_NUMBER() OVER (
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
		FROM CMTServ.dbo.LocationPermissionChange

		UNION ALL

		SELECT
			 PolicyNumber
			,RiskID
			,Status
			,StatusCode
			,ChangeDate
			,InsertedDate
		FROM CMTServ.dbo.LocationPermissionChange_EL
	) a
	WHERE a.ChangeDate >= '20/02/2018 00:00:00'
		AND a.ChangeDate < GETDATE()
)

UPDATE a
SET
	 a.MostRecentLOCP     = l.LOCP
	,a.MostRecentLOCPDate = l.ChangeDate
FROM Sandbox.dbo.SJ_Association a
INNER JOIN LOCP l
	ON a.Account_ID = l.Account_ID
WHERE l.RowNumber = 1
	AND ( l.ChangeDate > a.MostRecentLOCPDate OR a.MostRecentLOCPDate IS NULL )
;

INSERT @Association_Log (ScriptStartTime, StepName, StepFinishTime, RowsAffected)
	VALUES (@ScriptStartTime, 'MostRecentLOCP & MostRecentLOCPDate', SYSDATETIME(), @@ROWCOUNT)
;

-- Update FirstTripDate, MostRecentTripDate, and Mileage:

;WITH MyTrips (Account_ID, FirstTripDate, MostRecentTripDate, Mileage) AS (
	SELECT
		 a.Account_ID
		,FirstTripDate 		= MIN(a.Trip_Start_Local)
		,MostRecentTripDate = MAX(a.Trip_Start_Local)
		,Mileage            = SUM(a.Distance_Mapmatched_KM) * 0.621371
	FROM (
		SELECT
			 Account_ID
			,Trip_Start_Local
			,Distance_Mapmatched_KM
		FROM CMTServ.dbo.CMTTripSummary

		UNION ALL

		SELECT
			 Account_ID
			,Trip_Start_Local
			,Distance_Mapmatched_KM
		FROM CMTServ.dbo.CMTTripSummary_EL
	) a
	WHERE a.Trip_Start_Local >= '20/02/2018 00:00:00'
		AND a.Trip_Start_Local < GETDATE()
	GROUP BY a.Account_ID
)

UPDATE a
SET
	 a.FirstTripDate 	  	 = mt.FirstTripDate
	,a.MostRecentTripDate 	 = mt.MostRecentTripDate
	,a.Mileage 				 = mt.Mileage
FROM Sandbox.dbo.SJ_Association a
INNER JOIN MyTrips mt
	ON a.Account_ID = mt.Account_ID
;

INSERT @Association_Log (ScriptStartTime, StepName, StepFinishTime, RowsAffected)
	VALUES (@ScriptStartTime, 'FirstTripDate, MostRecentTripDate, and Mileage Refresh', SYSDATETIME(), @@ROWCOUNT)
;

-- Update MostRecentAchievement and MostRecentAchievementDate:

;WITH Medals (Account_ID, AchievementMiles, DateAchieved, RowNumber) AS (
	SELECT
		 Account_ID       = a.AccountID
		,AchievementMiles =
			CASE a.AchievementMiles
				WHEN 50   THEN '50 Miles'
				WHEN 250  THEN '250 Miles'
				WHEN 500  THEN '500 Miles'
				WHEN 750  THEN '750 Miles'
				WHEN 1000 THEN '1,000 Miles & 3 Months'
			END
		,a.DateAchieved
		,RowNumber =
			ROW_NUMBER() OVER (
				PARTITION BY a.AccountID
				ORDER BY a.DateAchieved DESC, a.ImportFileID DESC
			)
	FROM (
		SELECT
			 AccountID
			,AchievementID
			,AchievementMiles
			,DateAchieved
			,ImportFileID
		FROM CMTServ.dbo.Achievement

		/*
		UNION ALL

		SELECT
			 AccountID
			,AchievementID
			,AchievementMiles
			,DateAchieved
			,ImportFileID
		FROM CMTServ.dbo.Achievement_EL
		*/
	) a
	WHERE a.AchievementMiles IN (50, 250, 500, 750, 1000)
		AND a.DateAchieved >= '20/02/2018 00:00:00'
		AND a.DateAchieved < GETDATE()
)

UPDATE a
SET
	 a.MostRecentAchievement     = m.AchievementMiles
	,a.MostRecentAchievementDate = m.DateAchieved
FROM Sandbox.dbo.SJ_Association a
INNER JOIN Medals m
	ON a.Account_ID = m.Account_ID
WHERE m.RowNumber = 1
	AND ( m.DateAchieved > a.MostRecentAchievementDate OR a.MostRecentAchievementDate IS NULL )
;

INSERT @Association_Log (ScriptStartTime, StepName, StepFinishTime, RowsAffected)
	VALUES (@ScriptStartTime, 'MostRecentAchievement & MostRecentAchievementDate', SYSDATETIME(), @@ROWCOUNT)
;

-- Update Notifications and NotificationsDate:

;WITH Notifications (Account_ID, Notifications, ChangeDate, RowNumber) AS (
	SELECT
		 Account_ID = CONCAT(a.PolicyNumber, '.', a.RiskID)
		,Notifications =
			CASE
				WHEN a.Status     = 'Disabled' 					  THEN 'Turned Off'
				WHEN a.StatusCode = '/trip/' 					  THEN 'Trips'
				WHEN a.StatusCode = '/trip//achievement/' 		  THEN 'Trips & Achievements'
				WHEN a.StatusCode = '/trip//rating/' 			  THEN 'Trips & Rating'
				WHEN a.StatusCode = '/trip//achievement//rating/' THEN 'Trips, Achievements, and Rating'
				WHEN a.StatusCode = '/achievement/' 			  THEN 'Achievements'
				WHEN a.StatusCode = '/achievement//rating/' 	  THEN 'Achievements & Rating'
				WHEN a.StatusCode = '/rating/' 					  THEN 'Rating'
			 END
		,a.ChangeDate
		,RowNumber  =
			ROW_NUMBER() OVER (
				PARTITION BY a.PolicyNumber, a.RiskID
				ORDER BY a.ChangeDate DESC, a.ImportFileID DESC
			)
	FROM (
		SELECT
			 PolicyNumber
			,RiskID
			,Status
			,StatusCode
			,ChangeDate
			,ImportFileID
		FROM CMTServ.dbo.Notifications

		UNION ALL

		SELECT
			 PolicyNumber
			,RiskID
			,Status
			,StatusCode
			,ChangeDate
			,ImportFileID
		FROM CMTServ.dbo.Notifications_EL
	) a
	WHERE a.StatusCode IN ('null', '/trip/', '/achievement/', '/rating/', '/trip//achievement/', '/trip//rating/', '/achievement//rating/', '/trip//achievement//rating/')
		AND a.ChangeDate >= '20/02/2018 00:00:00'
		AND a.ChangeDate < GETDATE()
)

UPDATE a
SET
	 a.Notifications     = n.Notifications
	,a.NotificationsDate = n.ChangeDate
FROM Sandbox.dbo.SJ_Association a
INNER JOIN Notifications n
	ON a.Account_ID = n.Account_ID
WHERE n.RowNumber = 1
	AND ( n.ChangeDate > a.NotificationsDate OR a.NotificationsDate IS NULL )
;

INSERT @Association_Log (ScriptStartTime, StepName, StepFinishTime, RowsAffected)
	VALUES (@ScriptStartTime, 'Notifications & NotificationsDate', SYSDATETIME(), @@ROWCOUNT)
;

-- Update PushNotified and PushNotifiedDate:

;WITH PushNotified (Account_ID, NotificationType, LastNotificationDate, RowNumber) AS (
	SELECT
		 Account_ID = CONCAT(a.PolicyNumber, '.', a.RiskID)
		,NotificationType = 
			CASE 
				WHEN a.NotificationType = 'two days'   AND a.NotificationCounter = 1 THEN 'Two Days No Trip - 1st Push'
				WHEN a.NotificationType = 'two days'   AND a.NotificationCounter = 2 THEN 'Two Days No Trip - 2nd Push'
				WHEN a.NotificationType = 'two days'   AND a.NotificationCounter = 3 THEN 'Two Days No Trip - 3rd Push'
				WHEN a.NotificationType = 'seven days' AND a.NotificationCounter = 1 THEN 'Seven Days No Trip - 1st Push'
				WHEN a.NotificationType = 'seven days' AND a.NotificationCounter = 2 THEN 'Seven Days No Trip - 2nd Push'
				WHEN a.NotificationType = 'seven days' AND a.NotificationCounter = 3 THEN 'Seven Days No Trip - 3rd Push'
		 	END
		,a.LastNotificationDate
		,RowNumber  =
			ROW_NUMBER() OVER (
				PARTITION BY a.PolicyNumber, a.RiskID
				ORDER BY a.LastNotificationDate DESC, a.ImportFileID DESC
			)
	FROM (
		SELECT
			 PolicyNumber
			,RiskID
			,NotificationType
			,NotificationCounter
			,LastNotificationDate
			,ImportFileID
		FROM CMTServ.dbo.WeeklyNotify

		/*
		UNION ALL

		SELECT
			 PolicyNumber
			,RiskID
			,NotificationType
			,NotificationCounter
			,LastNotificationDate
			,ImportFileID
		FROM CMTServ.dbo.WeeklyNotify_EL
		*/
	) a
	WHERE a.NotificationType IN ('two days', 'seven days')
		AND a.NotificationCounter IN (1, 2, 3)
		AND a.LastNotificationDate >= '20/02/2018 00:00:00'
		AND a.LastNotificationDate < GETDATE()
)

UPDATE a
SET
	 a.PushNotified     = pn.NotificationType
	,a.PushNotifiedDate = pn.LastNotificationDate
FROM Sandbox.dbo.SJ_Association a
INNER JOIN PushNotified pn
	ON a.Account_ID = pn.Account_ID
WHERE pn.RowNumber = 1
	AND ( pn.LastNotificationDate > a.PushNotifiedDate OR a.PushNotifiedDate IS NULL )
;

INSERT @Association_Log (ScriptStartTime, StepName, StepFinishTime, RowsAffected)
	VALUES (@ScriptStartTime, 'PushNotified & PushNotifiedDate', SYSDATETIME(), @@ROWCOUNT)
;

;WITH Versions (Account_ID, Brand, LoginDate, OSVersion, AppVersion, Environment, RowNumber) AS (
	SELECT
		 Account_ID = CONCAT(a.PolicyNumber, '.', a.RiskID)
		,Brand =
			CASE a.Brand
				WHEN 'EL' THEN 'Elephant'
				WHEN 'AD' THEN 'Admiral'
			END
		,a.LoginDate
		,OSVersion  = CASE WHEN a.OSVersion  = 'null' THEN NULL ELSE a.OSVersion  END
		,AppVersion = CASE WHEN a.AppVersion = 'null' THEN NULL ELSE a.AppVersion END
		,a.Environment
		,RowNumber  =
			ROW_NUMBER() OVER (
				PARTITION BY a.PolicyNumber, a.RiskID
				ORDER BY a.LoginDate DESC, a.ImportFileID DESC
			)
	FROM (
		SELECT
			 PolicyNumber
			,RiskID
			,Brand
			,LoginDate
			,OSVersion
			,AppVersion
			,Environment = 'Admiral'
			,ImportFileID
		FROM CMTServ.dbo.SuccessfulLoginHistory

		UNION ALL

		SELECT
			 PolicyNumber
			,RiskID
			,Brand
			,LoginDate
			,OSVersion
			,AppVersion
			,Environment = 'Elephant'
			,ImportFileID
		FROM CMTServ.dbo.SuccessfulLoginHistory_EL

		UNION ALL

		SELECT
			 PolicyNumber
			,RiskID
			,Brand
			,LoginDate = ChangeDate
			,OSVersion
			,AppVersion
			,Environment = 'Admiral'
			,ImportFileID
		FROM CMTServ.dbo.LocationPermissionChange

		UNION ALL

		SELECT
			 PolicyNumber
			,RiskID
			,Brand
			,LoginDate = ChangeDate
			,OSVersion
			,AppVersion
			,Environment = 'Elephant'
			,ImportFileID
		FROM CMTServ.dbo.LocationPermissionChange_EL
	) a
	WHERE a.LoginDate >= '20/02/2018 00:00:00'
		AND a.LoginDate < GETDATE()
		AND a.Brand IN ('EL', 'AD')
)

UPDATE a
SET
	 a.Brand       = v.Brand
	,a.OSVersion   = v.OSVersion
	,a.AppVersion  = v.AppVersion
	,a.Environment = v.Environment
FROM Sandbox.dbo.SJ_Association a
INNER JOIN Versions v
	ON a.Account_ID = v.Account_ID
WHERE v.RowNumber = 1
;

INSERT @Association_Log (ScriptStartTime, StepName, StepFinishTime, RowsAffected)
	VALUES (@ScriptStartTime, 'Brand, OSVersion, AppVersion, and Environment', SYSDATETIME(), @@ROWCOUNT)
;

-- Update StaffTester:

IF (
	SELECT COALESCE(SUM(Rows), 0)
	FROM Sandbox.sys.Partitions
	WHERE Object_ID = OBJECT_ID('Sandbox.dbo.ServiceApp_StaffTesters', 'U')
		AND Index_ID IN (0, 1)
) > 0
BEGIN

	WITH StaffTesters (Account_ID) AS (
		SELECT DISTINCT Account_ID = CONCAT(PolicyNumber, '.', RiskID)
		FROM Sandbox.dbo.ServiceApp_StaffTesters
	)

	UPDATE a
		SET a.StaffTester = CASE WHEN st.Account_ID IS NOT NULL THEN 'Yes' ELSE 'No' END
	FROM Sandbox.dbo.SJ_Association a
	LEFT JOIN StaffTesters st
		ON a.Account_ID = st.Account_ID
	;

END
ELSE
BEGIN

	UPDATE Sandbox.dbo.SJ_Association
		SET StaffTester = NULL
	;

END
;

INSERT @Association_Log (ScriptStartTime, StepName, StepFinishTime, RowsAffected)
	VALUES (@ScriptStartTime, 'StaffTester', SYSDATETIME(), @@ROWCOUNT)
;

-- Update EndDate, CXXSentDate, CXXSSuccessDate, and CXXSReturnDate:

;WITH Cancellations (Account_ID, EndDate, CXXSentDate, CXXSSuccessDate, CXXSReturnDate) AS (
	SELECT
		 Account_ID      = CONCAT(PolicyNumber, '.', RiskID)
		,EndDate         = MIN(CAST(CancellationDate AS DATE))
		,CXXSentDate     = MIN(CAST(CXXS_Date AS DATE))
		,CXXSSuccessDate = MIN(CASE WHEN Success = 1 THEN CAST(UpdateDate AS DATE) ELSE NULL END)
		,CXXSReturnDate  = MIN(CAST(UpdateDate AS DATE))
	FROM CMTServ.dbo.Cancellation
	GROUP BY
		 PolicyNumber
		,RiskID
)

UPDATE a
SET
	 a.EndDate         = c.EndDate
	,a.CXXSentDate     = c.CXXSentDate
	,a.CXXSSuccessDate = c.CXXSSuccessDate
	,a.CXXSReturnDate  = c.CXXSReturnDate
FROM Sandbox.dbo.SJ_Association a
INNER JOIN Cancellations c
	ON a.Account_ID = c.Account_ID
;

INSERT @Association_Log (ScriptStartTime, StepName, StepFinishTime, RowsAffected)
	VALUES (@ScriptStartTime, 'EndDate, CXXSentDate, CXXSSuccessDate, and CXXSReturnDate', SYSDATETIME(), @@ROWCOUNT)
;

-- Rebuild index:

IF DATENAME(WEEKDAY, GETDATE()) = 'Monday'
	AND DATEPART(DAY, GETDATE()) BETWEEN 12 AND 18
BEGIN

	ALTER INDEX IX_SJ_Association_Account_ID ON Sandbox.dbo.SJ_Association REBUILD;

	INSERT @Association_Log (ScriptStartTime, StepName, StepFinishTime, RowsAffected)
		VALUES (@ScriptStartTime, 'Index Rebuild', SYSDATETIME(), @@ROWCOUNT)
	;

END
;

-- Write log to Sandbox:

IF OBJECT_ID('Sandbox.dbo.SJ_Association_Log', 'U') IS NOT NULL
BEGIN

	INSERT Sandbox.dbo.SJ_Association_Log (ScriptStartTime, StepName, StepFinishTime, RowsAffected)
	SELECT
		 ScriptStartTime
		,StepName
		,StepFinishTime
		,RowsAffected
	FROM @Association_Log
	;

END
ELSE
BEGIN

	SELECT
		 ScriptStartTime
		,StepName
		,StepFinishTime
		,RowsAffected
	INTO Sandbox.dbo.SJ_Association_Log
	FROM @Association_Log
	;

END

--GO
