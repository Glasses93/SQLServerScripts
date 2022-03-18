
USE Staging;

-- Session settings:
SET NOCOUNT ON;
SET DATEFIRST 1;
SET XACT_ABORT ON;

BEGIN TRY
	BEGIN TRANSACTION;

		-- Log table:
		DECLARE @Association_Log TABLE (
			 ScriptStartTime	datetime2(7)	NOT NULL
			,StepName			varchar(100)	NOT NULL
			,StepFinishTime		datetime2(7)	NOT NULL
			,RowsAffected		int				NOT NULL
		)
		;

		DECLARE @ScriptStartTime datetime2(7) = SYSDATETIME();

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
				FROM staging.dbo.EndavaSuccessfulLoginHistory

				UNION ALL

				SELECT
					 PolicyNumber
					,RiskID
					,Brand
					,Email
					,Platform
					,DeviceID
				FROM staging.dbo.EndavaSuccessfulLoginHistory_EL

				UNION ALL

				SELECT
					 PolicyNumber
					,RiskID
					,Brand
					,Email
					,Platform
					,DeviceID
				FROM staging.dbo.EndavaLocationPermissionChange

				UNION ALL

				SELECT
					 PolicyNumber
					,RiskID
					,Brand
					,Email
					,Platform
					,DeviceID
				FROM staging.dbo.EndavaLocationPermissionChange_EL
			) a
			WHERE a.PolicyNumber LIKE 'P%'
				AND ( a.RiskID LIKE 'M%' OR a.RiskID LIKE 'H%' )
				AND a.Brand IN ('EL', 'AD')
				AND a.Email LIKE '%@%'
				AND a.Platform != 'null'
				AND a.DeviceID != 'null'
		)
		INSERT CMTSERV.dbo.AppAssociation (Account_ID, PolicyNumber, RiskID, Brand, Email, Platform, DeviceID, DeviceIDShort, CoverType)
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

		INSERT @Association_Log (ScriptStartTime, StepName, StepFinishTime, RowsAffected)
			VALUES (@ScriptStartTime, 'New Registrations (Endava)', SYSDATETIME(), @@ROWCOUNT)
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
				FROM staging.dbo.EndavaSuccessfulLoginHistory

				UNION ALL

				SELECT
					 PolicyNumber
					,RiskID
					,LoginDate
				FROM staging.dbo.EndavaSuccessfulLoginHistory_EL

				UNION ALL

				SELECT
					 PolicyNumber
					,RiskID
					,LoginDate = ChangeDate
				FROM staging.dbo.EndavaLocationPermissionChange

				UNION ALL

				SELECT
					 PolicyNumber
					,RiskID
					,LoginDate = ChangeDate
				FROM staging.dbo.EndavaLocationPermissionChange_EL
			) a
			WHERE a.LoginDate >= '2018-02-20T00:00:00.000'
				AND a.LoginDate < GETDATE()		
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

		INSERT @Association_Log (ScriptStartTime, StepName, StepFinishTime, RowsAffected)
			VALUES (@ScriptStartTime, 'RegistrationDate (Endava)', SYSDATETIME(), @@ROWCOUNT)
		;

		;WITH CMTsRegistrationDate AS (
			SELECT
				 a.Account_ID
				,RegistrationDate = MIN(CASE WHEN bst.StartTime IS NOT NULL THEN DATEADD(HOUR, 1, a.Creation_Date) ELSE a.Creation_Date END)
			FROM (
				SELECT
					 Account_ID
					,Creation_Date = TRY_CONVERT(DATETIME, LEFT(Creation_Date, 19), 121)
				FROM staging.dbo.CMTDriverProfile_Staging
				
				UNION ALL
				
				SELECT
					 Account_ID
					,Creation_Date = TRY_CONVERT(DATETIME, LEFT(Creation_Date, 19), 121)
				FROM staging.dbo.CMTDriverProfile_Staging_EL
			) a
			LEFT JOIN #BST bst
				ON  a.Creation_Date >= bst.StartTime
				AND a.Creation_Date <  bst.EndTime
			WHERE a.Creation_Date >= '2018-02-20T00:00:00.000'
				AND ( CASE WHEN bst.StartTime IS NOT NULL THEN DATEADD(HOUR, 1, a.Creation_Date) ELSE a.Creation_Date END < GETDATE() )
			GROUP BY a.Account_ID
		)
		UPDATE a
			SET a.RegistrationDate = cmt.RegistrationDate
		FROM CMTSERV.dbo.AppAssociation a
		INNER JOIN CMTsRegistrationDate cmt
			ON a.Account_ID = cmt.Account_ID
		WHERE ( cmt.RegistrationDate < a.RegistrationDate OR a.RegistrationDate IS NULL )
		;

		INSERT @Association_Log (ScriptStartTime, StepName, StepFinishTime, RowsAffected)
			VALUES (@ScriptStartTime, 'RegistrationDate (CMT)', SYSDATETIME(), @@ROWCOUNT)
		;

		-- Update MostRecentLoginDate:
		UPDATE CMTSERV.dbo.AppAssociation
			SET MostRecentLoginDate = RegistrationDate
		WHERE MostRecentLoginDate IS NULL
		;

		INSERT @Association_Log (ScriptStartTime, StepName, StepFinishTime, RowsAffected)
			VALUES (@ScriptStartTime, 'MostRecentLoginDate #1', SYSDATETIME(), @@ROWCOUNT)
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
				FROM staging.dbo.EndavaSuccessfulLoginHistory

				UNION ALL

				SELECT
					 PolicyNumber
					,RiskID
					,LoginDate
				FROM staging.dbo.EndavaSuccessfulLoginHistory_EL
			) a
			WHERE a.LoginDate >= '2018-02-20T00:00:00.000'
				AND a.LoginDate < GETDATE()
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

		INSERT @Association_Log (ScriptStartTime, StepName, StepFinishTime, RowsAffected)
			VALUES (@ScriptStartTime, 'MostRecentLoginDate #2', SYSDATETIME(), @@ROWCOUNT)
		;

		-- Update LoginCount (comment this query when re-running the script over the same data to avoid doubling-up login counts):
		;WITH LoginCount AS (
			SELECT
				 Account_ID = CONCAT(a.PolicyNumber, '.', a.RiskID)
				,LoginCount = COUNT(DISTINCT a.LoginDate)
			FROM (
				SELECT
					 PolicyNumber
					,RiskID
					,LoginDate
				FROM staging.dbo.EndavaSuccessfulLoginHistory

				UNION ALL

				SELECT
					 PolicyNumber
					,RiskID
					,LoginDate
				FROM staging.dbo.EndavaSuccessfulLoginHistory_EL
			) a
			WHERE a.LoginDate >= '2018-02-20T00:00:00.000'
				AND a.LoginDate < GETDATE()
			GROUP BY
				 a.PolicyNumber
				,a.RiskID
		)
		UPDATE a
			SET a.LoginCount += lc.LoginCount
		FROM CMTSERV.dbo.AppAssociation a
		INNER JOIN LoginCount lc
			ON a.Account_ID = lc.Account_ID
		;

		INSERT @Association_Log (ScriptStartTime, StepName, StepFinishTime, RowsAffected)
			VALUES (@ScriptStartTime, 'LoginCount', SYSDATETIME(), @@ROWCOUNT)
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
				FROM staging.dbo.EndavaLocationPermissionChange

				UNION ALL

				SELECT
					 PolicyNumber
					,RiskID
					,Status
					,StatusCode
					,ChangeDate
					,InsertedDate
				FROM staging.dbo.EndavaLocationPermissionChange_EL
			) a
			WHERE a.ChangeDate >= '2018-02-20T00:00:00.000'
				AND a.ChangeDate < GETDATE()
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

		INSERT @Association_Log (ScriptStartTime, StepName, StepFinishTime, RowsAffected)
			VALUES (@ScriptStartTime, 'FirstLOCP & FirstLOCPDate', SYSDATETIME(), @@ROWCOUNT)
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
				FROM staging.dbo.EndavaLocationPermissionChange

				UNION ALL

				SELECT
					 PolicyNumber
					,RiskID
					,Status
					,StatusCode
					,ChangeDate
					,InsertedDate
				FROM staging.dbo.EndavaLocationPermissionChange_EL
			) a
			WHERE a.ChangeDate >= '2018-02-20T00:00:00.000'
				AND a.ChangeDate < GETDATE()
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

		INSERT @Association_Log (ScriptStartTime, StepName, StepFinishTime, RowsAffected)
			VALUES (@ScriptStartTime, 'MostRecentLOCP & MostRecentLOCPDate', SYSDATETIME(), @@ROWCOUNT)
		;

		-- Update FirstTripDate and MostRecentTripDate, and Mileage:
		;WITH FirstTrips AS (
			SELECT
				 Account_ID         = AccountID
				,FirstTripDate      = MIN(DateAchieved)
				,MostRecentTripDate = MAX(DateAchieved)
			FROM staging.dbo.EndavaAchievement
			WHERE AchievementID = 'first_trip'
				AND DateAchieved >= '2018-02-20T00:00:00.000'
				AND DateAchieved <  GETDATE()
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

		INSERT @Association_Log (ScriptStartTime, StepName, StepFinishTime, RowsAffected)
			VALUES (@ScriptStartTime, 'FirstTripDate & MostRecentTripDate (Endava)', SYSDATETIME(), @@ROWCOUNT)
		;

		;WITH MyTrips AS (
			SELECT
				 a.Account_ID
				,FirstTripDate      = MIN(a.Trip_Start_Local)
				,MostRecentTripDate = MAX(a.Trip_Start_Local)
				,Mileage            = SUM(a.Distance_Mapmatched_KM) * 0.621371
			FROM (
				SELECT
					 Account_ID
					,Trip_Start_Local       = TRY_CONVERT(DATETIME, LEFT(Trip_Start_Local, 19), 121)
					,Distance_Mapmatched_KM = CONVERT(NUMERIC(19, 10), Distance_Mapmatched_KM)
				FROM staging.dbo.CMTTripSummary_Staging

				UNION ALL

				SELECT
					 Account_ID
					,Trip_Start_Local       = TRY_CONVERT(DATETIME, LEFT(Trip_Start_Local, 19), 121)
					,Distance_Mapmatched_KM = CONVERT(NUMERIC(19, 10), Distance_Mapmatched_KM)
				FROM staging.dbo.CMTTripSummary_Staging_EL
			) a
			WHERE a.Trip_Start_Local >= '2018-02-20T00:00:00.000'
				AND a.Trip_Start_Local < GETDATE()
			GROUP BY a.Account_ID
		)
		UPDATE a
		SET
			 a.FirstTripDate      =
				CASE WHEN ( mt.FirstTripDate      < a.FirstTripDate      OR a.FirstTripDate      IS NULL ) THEN mt.FirstTripDate      ELSE a.FirstTripDate      END
			,a.MostRecentTripDate =
				CASE WHEN ( mt.MostRecentTripDate > a.MostRecentTripDate OR a.MostRecentTripDate IS NULL ) THEN mt.MostRecentTripDate ELSE a.MostRecentTripDate END
			-- Comment the below line when re-running the script over the same data to avoid doubling-up mileage:
			,a.Mileage            = CASE WHEN a.Mileage IS NULL THEN mt.Mileage ELSE ( a.Mileage + ISNULL(mt.Mileage, 0) ) END
		FROM CMTSERV.dbo.AppAssociation a
		INNER JOIN MyTrips mt
			ON a.Account_ID = mt.Account_ID
		;

		INSERT @Association_Log (ScriptStartTime, StepName, StepFinishTime, RowsAffected)
			VALUES (@ScriptStartTime, 'FirstTripDate, MostRecentTripDate, and Mileage (CMT)', SYSDATETIME(), @@ROWCOUNT)
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
				FROM staging.dbo.EndavaAchievement

				/*
				UNION ALL

				SELECT
					 AccountID
					,AchievementID
					,AchievementMiles
					,DateAchieved
					,ImportFileID
				FROM staging.dbo.EndavaAchievement_EL
				*/
			) a
			WHERE a.AchievementMiles IN (50, 250, 500, 750, 1000)
				AND a.DateAchieved >= '2018-02-20T00:00:00.000'
				AND a.DateAchieved < GETDATE()
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

		INSERT @Association_Log (ScriptStartTime, StepName, StepFinishTime, RowsAffected)
			VALUES (@ScriptStartTime, 'MostRecentAchievement & MostRecentAchievementDate', SYSDATETIME(), @@ROWCOUNT)
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
				FROM staging.dbo.EndavaNotifications

				UNION ALL

				SELECT
					 PolicyNumber
					,RiskID
					,Status
					,StatusCode
					,ChangeDate
					,ImportFileID
				FROM staging.dbo.EndavaNotifications_EL
			) a
			WHERE a.StatusCode IN (
				'null'               , '/trip/'        , '/achievement/'        , '/rating/'                   , 
				'/trip//achievement/', '/trip//rating/', '/achievement//rating/', '/trip//achievement//rating/'
			)
				AND a.ChangeDate >= '2018-02-20T00:00:00.000'
				AND a.ChangeDate < GETDATE()
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

		INSERT @Association_Log (ScriptStartTime, StepName, StepFinishTime, RowsAffected)
			VALUES (@ScriptStartTime, 'Notifications & NotificationsDate', SYSDATETIME(), @@ROWCOUNT)
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
				,LastNotificationDate = CONVERT(DATETIME, a.LastNotificationDate, 120)
				,RowNumber  =
					ROW_NUMBER() OVER (
						PARTITION BY a.PolicyNumber, a.RiskID
						ORDER BY CONVERT(DATETIME, a.LastNotificationDate, 120) DESC, a.ImportFileID DESC
					)
			FROM (
				SELECT
					 PolicyNumber
					,RiskID
					,NotificationType
					,NotificationCounter
					,LastNotificationDate
					,ImportFileID
				FROM staging.dbo.EndavaWeeklyNotify

				/*
				UNION ALL

				SELECT
					 PolicyNumber
					,RiskID
					,NotificationType
					,NotificationCounter
					,LastNotificationDate
					,ImportFileID
				FROM staging.dbo.EndavaWeeklyNotify_EL
				*/
			) a
			WHERE a.NotificationType IN ('two days', 'seven days')
				AND a.NotificationCounter IN (1, 2, 3)
				AND a.LastNotificationDate >= '2018-02-20T00:00:00.000'
				AND a.LastNotificationDate < GETDATE()
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

		INSERT @Association_Log (ScriptStartTime, StepName, StepFinishTime, RowsAffected)
			VALUES (@ScriptStartTime, 'PushNotified & PushNotifiedDate', SYSDATETIME(), @@ROWCOUNT)
		;

		-- Update Brand, OSVersion, AppVersion, and Environment:
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
				FROM staging.dbo.EndavaSuccessfulLoginHistory

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
				FROM staging.dbo.EndavaSuccessfulLoginHistory_EL

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
				FROM staging.dbo.EndavaLocationPermissionChange

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
				FROM staging.dbo.EndavaLocationPermissionChange_EL
			) a
			WHERE a.LoginDate >= '2018-02-20T00:00:00.000'
				AND a.LoginDate < GETDATE()
				AND a.Brand IN ('EL', 'AD')
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
			AND ( v.LoginDate = a.MostRecentLoginDate OR v.LoginDate = a.MostRecentLOCPDate )
		;

		INSERT @Association_Log (ScriptStartTime, StepName, StepFinishTime, RowsAffected)
			VALUES (@ScriptStartTime, 'Brand, OSVersion, AppVersion, and Environment', SYSDATETIME(), @@ROWCOUNT)
		;

		/*
		-- Update StaffTester:
		IF (
			SELECT ISNULL(SUM(rows), 0)
			FROM sandbox.sys.partitions
			WHERE object_id = OBJECT_ID('sandbox.dbo.ServiceApp_StaffTesters', 'U')
				AND index_id IN (0, 1)
		) > 0
		BEGIN

			WITH StaffTesters AS (
				SELECT DISTINCT Account_ID = CONCAT(PolicyNumber, '.', RiskID)
				FROM sandbox.dbo.ServiceApp_StaffTesters
			)
			UPDATE a
				SET a.StaffTester = CASE WHEN st.Account_ID IS NOT NULL THEN 1 ELSE 0 END
			FROM CMTSERV.dbo.AppAssociation a
			LEFT JOIN StaffTesters st
				ON a.Account_ID = st.Account_ID
			;

		END
		ELSE
		BEGIN

			UPDATE CMTSERV.dbo.AppAssociation
				SET StaffTester = NULL
			;

		END
		;

		INSERT @Association_Log (ScriptStartTime, StepName, StepFinishTime, RowsAffected)
			VALUES (@ScriptStartTime, 'StaffTester', SYSDATETIME(), @@ROWCOUNT)
		;
		*/

		-- Update EndDate, CXXSentDate, CXXSSuccessDate, and CXXSReturnDate:
		;WITH Cancellations AS (
			SELECT
				 Account_ID      = CONCAT(PolicyNumber, '.', RiskID)
				,EndDate         = MIN(CONVERT(DATE, CancellationDate))
				,CXXSentDate     = MIN(CONVERT(DATE, CXXS_Date))
				,CXXSSuccessDate = MIN(CASE WHEN Success = 1 THEN CONVERT(DATE, UpdateDate) ELSE NULL END)
				,CXXSReturnDate  = MIN(CONVERT(DATE, UpdateDate))
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

		INSERT @Association_Log (ScriptStartTime, StepName, StepFinishTime, RowsAffected)
			VALUES (@ScriptStartTime, 'EndDate, CXXSentDate, CXXSSuccessDate, and CXXSReturnDate', SYSDATETIME(), @@ROWCOUNT)
		;

		-- Insert new combinations of Email and DeviceID:
		;WITH NewAssociations AS (
			SELECT DISTINCT
				 Account_ID = CONCAT(a.PolicyNumber, '.', a.RiskID)
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
				FROM staging.dbo.EndavaSuccessfulLoginHistory

				UNION ALL

				SELECT
					 PolicyNumber
					,RiskID
					,Brand
					,Email
					,Platform
					,DeviceID
				FROM staging.dbo.EndavaSuccessfulLoginHistory_EL

				UNION ALL

				SELECT
					 PolicyNumber
					,RiskID
					,Brand
					,Email
					,Platform
					,DeviceID
				FROM staging.dbo.EndavaLocationPermissionChange

				UNION ALL

				SELECT
					 PolicyNumber
					,RiskID
					,Brand
					,Email
					,Platform
					,DeviceID
				FROM staging.dbo.EndavaLocationPermissionChange_EL
			) a
			WHERE NOT EXISTS (
				SELECT 1
				FROM CMTSERV.dbo.AppAssociation b
				WHERE a.Email = b.Email
					AND a.DeviceID = b.DeviceID
			)
				AND a.Brand    IN ('EL', 'AD')
				AND a.Email    LIKE '%@%'
				AND a.Platform != 'null'
				AND a.DeviceID != 'null'
		)
		INSERT CMTSERV.dbo.AppAssociation (
			Account_ID      , PolicyNumber       , RiskID            , Brand           , Email             , Platform       , DeviceID             , DeviceIDShort            ,
			RegistrationDate, MostRecentLoginDate, LoginCount        , EndDate         , CXXSentDate       , CXXSSuccessDate, CXXSReturnDate       , FirstLOCP                ,
			FirstLOCPDate   , MostRecentLOCP     , MostRecentLOCPDate, FirstTripDate   , MostRecentTripDate, Mileage        , MostRecentAchievement, MostRecentAchievementDate,
			Notifications   , NotificationsDate  , PushNotified      , PushNotifiedDate, OSVersion         , AppVersion     , Environment          , StaffTester              , CoverType
		)
		SELECT
			 na.Account_ID
			,a.PolicyNumber
			,a.RiskID
			,a.Brand
			,na.Email
			,na.Platform
			,na.DeviceID
			,na.DeviceIDShort
			,a.RegistrationDate
			,a.MostRecentLoginDate
			,a.LoginCount
			,a.EndDate
			,a.CXXSentDate
			,a.CXXSSuccessDate
			,a.CXXSReturnDate
			,a.FirstLOCP
			,a.FirstLOCPDate
			,a.MostRecentLOCP
			,a.MostRecentLOCPDate
			,a.FirstTripDate
			,a.MostRecentTripDate
			,a.Mileage
			,a.MostRecentAchievement
			,a.MostRecentAchievementDate
			,a.Notifications
			,a.NotificationsDate
			,a.PushNotified
			,a.PushNotifiedDate
			,a.OSVersion
			,a.AppVersion
			,a.Environment
			,a.StaffTester
			,a.CoverType
		FROM NewAssociations na
		INNER JOIN CMTSERV.dbo.AppAssociation a
			ON na.Account_ID = a.Account_ID
		;

		INSERT @Association_Log (ScriptStartTime, StepName, StepFinishTime, RowsAffected)
			VALUES (@ScriptStartTime, 'New Associations', SYSDATETIME(), @@ROWCOUNT)
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

		INSERT @Association_Log (ScriptStartTime, StepName, StepFinishTime, RowsAffected)
			VALUES (@ScriptStartTime, 'De-duplicate Associations', SYSDATETIME(), @@ROWCOUNT)
		;

		-- Rebuild index:
		IF DATENAME(WEEKDAY, GETDATE()) = 'Monday'
			AND DATEPART(DAY, GETDATE()) BETWEEN 12 AND 18
		BEGIN

			ALTER INDEX IX_AppAssociation_AccountID ON CMTSERV.dbo.AppAssociation REBUILD;

			INSERT @Association_Log (ScriptStartTime, StepName, StepFinishTime, RowsAffected)
				VALUES (@ScriptStartTime, 'Index Rebuild', SYSDATETIME(), @@ROWCOUNT)
			;

		END
		;

		-- Write log to Sandbox:
		IF OBJECT_ID('sandbox.dbo.AppAssociation_Log', 'U') IS NOT NULL
		BEGIN

			INSERT sandbox.dbo.AppAssociation_Log (ScriptStartTime, StepName, StepFinishTime, RowsAffected)
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
			INTO sandbox.dbo.AppAssociation_Log
			FROM @Association_Log
			;

		END
		;

	-- Commit all DML if no error
	-- is encountered thus far:
	COMMIT TRANSACTION;

END TRY
-- If an error occurs, rollback every DML
-- and re-raise the error:
BEGIN CATCH

	IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
	;THROW;

END CATCH
;