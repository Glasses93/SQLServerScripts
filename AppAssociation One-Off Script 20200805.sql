
/*------------------------------------------------------- Service App Association ------------------------------------------------
	Purpose: Create and update a user-level summary for Service App customers.

	Method:
		1.	Insert new Service App registrations into CMTSERV.dbo.AppAssociation.
			These are identified as a unique combination of PolicyNumber and RiskID from Endava's REGS, LOGS, and LOCP files.
		2. 	Update columns for all users based on new data.
		3. 	Insert new Emails and DeviceIDs for previously inserted registrations.

	Notes:
		-	See Sandbox.dbo.Association_Log for query run-times and row counts affected.
		-	The clustered index is re-built once every middle-of-the-month Monday in order to reduce fragmentation.
  -------------------------------------------------------------------------------------------------------------------------------*/

-- Session settings:
SET NOCOUNT ON;
SET DATEFIRST 1;
SET XACT_ABORT ON;

-- BST table:
CREATE TABLE #BST (
	 Year		smallint	NOT NULL
	,StartTime	datetime	NOT NULL
	,EndTime	datetime	NOT NULL
)
;

DECLARE @Year smallint = 2018;

WHILE @Year <= YEAR(GETDATE())
BEGIN

	WITH LastWeekOfMarch (Date) AS (
		SELECT DATETIMEFROMPARTS(@Year, 03, 25, 01, 00, 00, 000)
		
		UNION ALL
		
		SELECT DATEADD(DAY, 1, Date)
		FROM LastWeekOfMarch
		WHERE MONTH(DATEADD(DAY, 1, Date)) < 4
	),
	LastWeekOfOctober (Date) AS (
		SELECT DATETIMEFROMPARTS(@Year, 10, 25, 01, 00, 00, 000)
		
		UNION ALL
		
		SELECT DATEADD(DAY, 1, Date)
		FROM LastWeekOfOctober
		WHERE MONTH(DATEADD(DAY, 1, Date)) < 11
	)
	INSERT #BST (Year, StartTime, EndTime)
	SELECT
		 @Year
		,lsm.Date
		,lso.Date
	FROM LastWeekOfMarch lsm
	CROSS JOIN (
		SELECT Date
		FROM LastWeekOfOctober
		WHERE DATENAME(WEEKDAY, Date) = 'Sunday'
	) lso
	WHERE DATENAME(WEEKDAY, lsm.Date) = 'Sunday'
	OPTION (MAXRECURSION 6)
	;
	
	SET @Year += 1;

END
;

-- Insert new registrations:
;WITH Registrations AS (
	SELECT DISTINCT
		 Account_ID = CONCAT(a.PolicyNumber, '.', a.RiskID)
		,a.PolicyNumber
		,a.RiskID
		,a.Brand
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
		FROM CMTSERV.dbo.SuccessfulLoginHistory

		UNION ALL

		SELECT
			 PolicyNumber
			,RiskID
			,Brand
			,Email
			,Platform
			,DeviceID
		FROM CMTSERV.dbo.SuccessfulLoginHistory_EL

		UNION ALL

		SELECT
			 PolicyNumber
			,RiskID
			,Brand
			,Email
			,Platform
			,DeviceID
		FROM CMTSERV.dbo.LocationPermissionChange

		UNION ALL

		SELECT
			 PolicyNumber
			,RiskID
			,Brand
			,Email
			,Platform
			,DeviceID
		FROM CMTSERV.dbo.LocationPermissionChange_EL

	) a
	WHERE a.PolicyNumber LIKE 'P%'
		AND ( a.RiskID LIKE 'M%' OR a.RiskID LIKE 'H%' )
		AND a.Brand    IN ('EL', 'AD')
		AND a.Email    LIKE '%@%'
		AND a.Platform != 'null'
		AND a.DeviceID != 'null'
)
INSERT CMTSERV.dbo.AppAssociation WITH (TABLOCK) (Account_ID, PolicyNumber, RiskID, Brand, Email, Platform, DeviceID, DeviceIDShort, CoverType)
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
	FROM CMTSERV.dbo.AppAssociation a
	WHERE r.Account_ID = a.Account_ID
)
;

-- Update RegistrationDate:
;WITH RegistrationDate AS (
	SELECT
		 Account_ID 	  = CONCAT(a.PolicyNumber, '.', a.RiskID)
		,RegistrationDate = MIN(a.LoginDate)
	FROM (
		SELECT
			 PolicyNumber
			,RiskID
			,LoginDate
			,InsertedDate
		FROM CMTSERV.dbo.SuccessfulLoginHistory

		UNION ALL

		SELECT
			 PolicyNumber
			,RiskID
			,LoginDate
			,InsertedDate
		FROM CMTSERV.dbo.SuccessfulLoginHistory_EL

		UNION ALL

		SELECT
			 PolicyNumber
			,RiskID
			,LoginDate = ChangeDate
			,InsertedDate
		FROM CMTSERV.dbo.LocationPermissionChange

		UNION ALL

		SELECT
			 PolicyNumber
			,RiskID
			,LoginDate = ChangeDate
			,InsertedDate
		FROM CMTSERV.dbo.LocationPermissionChange_EL
	) a
	WHERE a.LoginDate >= '2018-02-20T00:00:00.000'
		AND a.LoginDate < GETDATE()
		AND a.LoginDate < a.InsertedDate
	GROUP BY
		 a.PolicyNumber
		,a.RiskID
)
UPDATE a
	SET a.RegistrationDate = rd.RegistrationDate
FROM CMTSERV.dbo.AppAssociation a
INNER JOIN RegistrationDate rd
	ON a.Account_ID = rd.Account_ID
WHERE ( rd.RegistrationDate < a.RegistrationDate OR a.RegistrationDate IS NULL )
;

;WITH CMTsRegistrationDate AS (
	SELECT
		 a.Account_ID
		,RegistrationDate = MIN(a.Creation_Date)
	FROM (
		SELECT
			 Account_ID
			,Creation_Date
			,InsertedDate
		FROM CMTSERV.dbo.CMTDriverProfile
		
		UNION ALL
		
		SELECT
			 Account_ID
			,Creation_Date
			,InsertedDate
		FROM CMTSERV.dbo.CMTDriverProfile_EL
	) a
	WHERE a.Creation_Date >= '2018-02-20T00:00:00.000'
		AND a.Creation_Date < GETDATE()
		AND a.Creation_Date < a.InsertedDate
	GROUP BY a.Account_ID
)
UPDATE a
	SET a.RegistrationDate = CASE WHEN bst.StartTime IS NOT NULL THEN DATEADD(HOUR, 1, cmt.RegistrationDate) ELSE cmt.RegistrationDate END
FROM CMTSERV.dbo.AppAssociation a
INNER JOIN CMTsRegistrationDate cmt
		ON a.Account_ID = cmt.Account_ID
LEFT JOIN #BST bst
	ON  cmt.RegistrationDate >= bst.StartTime
	AND cmt.RegistrationDate <  bst.EndTime
WHERE (
		a.RegistrationDate > ( CASE WHEN bst.StartTime IS NOT NULL THEN DATEADD(HOUR, 1, cmt.RegistrationDate) ELSE cmt.RegistrationDate END )
	OR	a.RegistrationDate IS NULL
)
;

-- Update MostRecentLoginDate:
UPDATE CMTSERV.dbo.AppAssociation
	SET MostRecentLoginDate = RegistrationDate
WHERE MostRecentLoginDate IS NULL
;

;WITH MostRecentLoginDate AS (
	SELECT
		 Account_ID 		 = CONCAT(a.PolicyNumber, '.', a.RiskID)
		,MostRecentLoginDate = MAX(a.LoginDate)
	FROM (
		SELECT
			 PolicyNumber
			,RiskID
			,LoginDate
			,InsertedDate
		FROM CMTSERV.dbo.SuccessfulLoginHistory

		UNION ALL

		SELECT
			 PolicyNumber
			,RiskID
			,LoginDate
			,InsertedDate
		FROM CMTSERV.dbo.SuccessfulLoginHistory_EL
	) a
	WHERE a.LoginDate >= '2018-02-20T00:00:00.000'
		AND a.LoginDate < GETDATE()
		AND a.LoginDate < a.InsertedDate
	GROUP BY
		 a.PolicyNumber
		,a.RiskID
)
UPDATE a
	SET a.MostRecentLoginDate = mrld.MostRecentLoginDate
FROM CMTSERV.dbo.AppAssociation a
INNER JOIN MostRecentLoginDate mrld
	ON a.Account_ID = mrld.Account_ID
WHERE ( mrld.MostRecentLoginDate > a.MostRecentLoginDate OR a.MostRecentLoginDate IS NULL )
;

-- Update LoginCount:
;WITH LoginCount AS (
	SELECT
		 Account_ID = CONCAT(a.PolicyNumber, '.', a.RiskID)
		,LoginCount = COUNT(DISTINCT a.LoginDate)
	FROM (
		SELECT
			 PolicyNumber
			,RiskID
			,LoginDate
			,InsertedDate
		FROM CMTSERV.dbo.SuccessfulLoginHistory

		UNION ALL

		SELECT
			 PolicyNumber
			,RiskID
			,LoginDate
			,InsertedDate
		FROM CMTSERV.dbo.SuccessfulLoginHistory_EL
	) a
	GROUP BY
		 a.PolicyNumber
		,a.RiskID
)
UPDATE a
	SET a.LoginCount = CASE WHEN a.RegistrationDate < '2019-04-03T15:25:14.000' THEN lc.LoginCount ELSE ( lc.LoginCount + 1 ) END
FROM CMTSERV.dbo.AppAssociation a
INNER JOIN LoginCount lc
	ON a.Account_ID = lc.Account_ID
;

-- Update FirstLOCP and FirstLOCPDate:
;WITH LOCP AS (
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
		FROM CMTSERV.dbo.LocationPermissionChange

		UNION ALL

		SELECT
			 PolicyNumber
			,RiskID
			,Status
			,StatusCode
			,ChangeDate
			,InsertedDate
		FROM CMTSERV.dbo.LocationPermissionChange_EL
	) a
	WHERE a.ChangeDate >= '2018-02-20T00:00:00.000'
		AND a.ChangeDate < GETDATE()
		AND a.ChangeDate < a.InsertedDate
)
UPDATE a
SET
	 a.FirstLOCP     = l.LOCP
	,a.FirstLOCPDate = l.ChangeDate
FROM CMTSERV.dbo.AppAssociation a
INNER JOIN LOCP l
	ON a.Account_ID = l.Account_ID
WHERE l.RowNumber = 1
	AND ( l.ChangeDate < a.FirstLOCPDate OR a.FirstLOCPDate IS NULL )
;

-- Update MostRecentLOCP and MostRecentLOCPDate:
;WITH LOCP AS (
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
		FROM CMTSERV.dbo.LocationPermissionChange

		UNION ALL

		SELECT
			 PolicyNumber
			,RiskID
			,Status
			,StatusCode
			,ChangeDate
			,InsertedDate
		FROM CMTSERV.dbo.LocationPermissionChange_EL
	) a
	WHERE a.ChangeDate >= '2018-02-20T00:00:00.000'
		AND a.ChangeDate < GETDATE()
		AND a.ChangeDate < a.InsertedDate
)
UPDATE a
SET
	 a.MostRecentLOCP     = l.LOCP
	,a.MostRecentLOCPDate = l.ChangeDate
FROM CMTSERV.dbo.AppAssociation a
INNER JOIN LOCP l
	ON a.Account_ID = l.Account_ID
WHERE l.RowNumber = 1
	AND ( l.ChangeDate > a.MostRecentLOCPDate OR a.MostRecentLOCPDate IS NULL )
;

-- Update FirstTripDate, MostRecentTripDate, and Mileage:
;WITH FirstTrips AS (
	SELECT
		 Account_ID         = AccountID
		,FirstTripDate      = MIN(DateAchieved)
		,MostRecentTripDate = MAX(DateAchieved)
	FROM CMTSERV.dbo.Achievement
	WHERE AchievementID = 'first_trip'
		AND DateAchieved >= '2018-02-20T00:00:00.000'
		AND DateAchieved <  GETDATE()
		AND DateAchieved < InsertedDate
	GROUP BY AccountID
)
UPDATE a
SET
	 a.FirstTripDate      =
		CASE WHEN ( ft.FirstTripDate      < a.FirstTripDate      OR a.FirstTripDate      IS NULL ) THEN ft.FirstTripDate      ELSE a.FirstTripDate      END
	,a.MostRecentTripDate =
		CASE WHEN ( ft.MostRecentTripDate > a.MostRecentTripDate OR a.MostRecentTripDate IS NULL ) THEN ft.MostRecentTripDate ELSE a.MostRecentTripDate END
FROM CMTSERV.dbo.AppAssociation a
INNER JOIN FirstTrips ft
	ON a.Account_ID = ft.Account_ID
;

;WITH MyTrips AS (
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
			,InsertedDate
		FROM CMTSERV.dbo.CMTTripSummary

		UNION ALL

		SELECT
			 Account_ID
			,Trip_Start_Local
			,Distance_Mapmatched_KM
			,InsertedDate
		FROM CMTSERV.dbo.CMTTripSummary_EL
	) a
	WHERE a.Trip_Start_Local >= '2018-02-20T00:00:00.000'
		AND a.Trip_Start_Local < GETDATE()
		AND a.Trip_Start_Local < a.InsertedDate
	GROUP BY a.Account_ID
)
UPDATE a
SET
	 a.FirstTripDate 	  	 = mt.FirstTripDate
	,a.MostRecentTripDate 	 = mt.MostRecentTripDate
	,a.Mileage 				 = mt.Mileage
FROM CMTSERV.dbo.AppAssociation a
INNER JOIN MyTrips mt
	ON a.Account_ID = mt.Account_ID
;

-- Update MostRecentAchievement and MostRecentAchievementDate:
;WITH Medals AS (
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
			,InsertedDate
		FROM CMTSERV.dbo.Achievement

		/*
		UNION ALL

		SELECT
			 AccountID
			,AchievementID
			,AchievementMiles
			,DateAchieved
			,ImportFileID
			,InsertedDate
		FROM CMTSERV.dbo.Achievement_EL
		*/
	) a
	WHERE a.AchievementMiles IN (50, 250, 500, 750, 1000)
		AND a.DateAchieved >= '2018-02-20T00:00:00.000'
		AND a.DateAchieved < GETDATE()
		AND a.DateAchieved < a.InsertedDate
)
UPDATE a
SET
	 a.MostRecentAchievement     = m.AchievementMiles
	,a.MostRecentAchievementDate = m.DateAchieved
FROM CMTSERV.dbo.AppAssociation a
INNER JOIN Medals m
	ON a.Account_ID = m.Account_ID
WHERE m.RowNumber = 1
	AND ( m.DateAchieved > a.MostRecentAchievementDate OR a.MostRecentAchievementDate IS NULL )
;

-- Update Notifications and NotificationsDate:
;WITH Notifications AS (
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
			,InsertedDate
		FROM CMTSERV.dbo.Notifications

		UNION ALL

		SELECT
			 PolicyNumber
			,RiskID
			,Status
			,StatusCode
			,ChangeDate
			,ImportFileID
			,InsertedDate
		FROM CMTSERV.dbo.Notifications_EL
	) a
	WHERE a.StatusCode IN (
		 'null'               , '/trip/'        , '/achievement/'        , '/rating/'                   , 
		 '/trip//achievement/', '/trip//rating/', '/achievement//rating/', '/trip//achievement//rating/'
		 
	)
		AND a.ChangeDate >= '2018-02-20T00:00:00.000'
		AND a.ChangeDate < GETDATE()
		AND a.ChangeDate < a.InsertedDate
)
UPDATE a
SET
	 a.Notifications     = n.Notifications
	,a.NotificationsDate = n.ChangeDate
FROM CMTSERV.dbo.AppAssociation a
INNER JOIN Notifications n
	ON a.Account_ID = n.Account_ID
WHERE n.RowNumber = 1
	AND ( n.ChangeDate > a.NotificationsDate OR a.NotificationsDate IS NULL )
;

-- Update PushNotified and PushNotifiedDate:
;WITH PushNotified AS (
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
			,InsertedDate
		FROM CMTSERV.dbo.WeeklyNotify

		/*
		UNION ALL

		SELECT
			 PolicyNumber
			,RiskID
			,NotificationType
			,NotificationCounter
			,LastNotificationDate
			,ImportFileID
			,InsertedDate
		FROM CMTSERV.dbo.WeeklyNotify_EL
		*/
	) a
	WHERE a.NotificationType IN ('two days', 'seven days')
		AND a.NotificationCounter IN (1, 2, 3)
		AND a.LastNotificationDate >= '2018-02-20T00:00:00.000'
		AND a.LastNotificationDate < GETDATE()
		AND a.LastNotificationDate < a.InsertedDate
)
UPDATE a
SET
	 a.PushNotified     = pn.NotificationType
	,a.PushNotifiedDate = pn.LastNotificationDate
FROM CMTSERV.dbo.AppAssociation a
INNER JOIN PushNotified pn
	ON a.Account_ID = pn.Account_ID
WHERE pn.RowNumber = 1
	AND ( pn.LastNotificationDate > a.PushNotifiedDate OR a.PushNotifiedDate IS NULL )
;

;WITH Versions AS (
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
			,InsertedDate
		FROM CMTSERV.dbo.SuccessfulLoginHistory

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
			,InsertedDate
		FROM CMTSERV.dbo.SuccessfulLoginHistory_EL

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
			,InsertedDate
		FROM CMTSERV.dbo.LocationPermissionChange

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
			,InsertedDate
		FROM CMTSERV.dbo.LocationPermissionChange_EL
	) a
	WHERE a.LoginDate >= '2018-02-20T00:00:00.000'
		AND a.LoginDate < GETDATE()
		AND a.Brand IN ('EL', 'AD')
		AND a.LoginDate < a.InsertedDate
)
UPDATE a
SET
	 a.Brand       = v.Brand
	,a.OSVersion   = v.OSVersion
	,a.AppVersion  = v.AppVersion
	,a.Environment = v.Environment
FROM CMTSERV.dbo.AppAssociation a
INNER JOIN Versions v
	ON a.Account_ID = v.Account_ID
WHERE v.RowNumber = 1
;

-- Update StaffTester:
WITH StaffTesters AS (
	SELECT DISTINCT Account_ID = CONCAT(PolicyNumber, '.', RiskID)
	FROM Sandbox.dbo.ServiceApp_StaffTesters
)
UPDATE a
	SET a.StaffTester = CASE WHEN st.Account_ID IS NOT NULL THEN 1 ELSE 0 END
FROM CMTSERV.dbo.AppAssociation a
LEFT JOIN StaffTesters st
	ON a.Account_ID = st.Account_ID
;

-- Update EndDate, CXXSentDate, CXXSSuccessDate, and CXXSReturnDate:
;WITH Cancellations AS (
	SELECT
		 Account_ID      = CONCAT(PolicyNumber, '.', RiskID)
		,EndDate         = MIN(CAST(CancellationDate AS DATE))
		,CXXSentDate     = MIN(CAST(CXXS_Date AS DATE))
		,CXXSSuccessDate = MIN(CASE WHEN Success = 1 THEN CAST(UpdateDate AS DATE) ELSE NULL END)
		,CXXSReturnDate  = MIN(CAST(UpdateDate AS DATE))
	FROM CMTSERV.dbo.Cancellation
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
FROM CMTSERV.dbo.AppAssociation a
INNER JOIN Cancellations c
	ON a.Account_ID = c.Account_ID
;

-- De-duplicate associations:
;WITH RowNumbered AS (
	SELECT
		 RN =
			ROW_NUMBER() OVER (
				PARTITION BY Account_ID, Email, DeviceID
				ORDER BY ( SELECT NULL )
			)
		,*
	FROM CMTSERV.dbo.AppAssociation
)
DELETE RowNumbered
WHERE RN > 1
;