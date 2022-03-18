USE CMTSERV;

DECLARE @PolicyNumber varchar(20) = 'P65042770%';

SELECT *
FROM dbo.AppAssociation
WHERE Account_ID LIKE @PolicyNumber
OPTION (OPTIMIZE FOR (@PolicyNumber = 'P65042770'))
;

;WITH x AS (
SELECT
  Email, PolicyNumber, RiskID, DoB, Brand, LoginDate, DeviceID
, [Platform], AppVersion, OSVersion, ImportFileID, InsertedDate
, Environment = 'Admiral'
FROM dbo.SuccessfulLoginHistory
UNION ALL
SELECT
  Email, PolicyNumber, RiskID, DoB, Brand, LoginDate, DeviceID
, [Platform], AppVersion, OSVersion, ImportFileID, InsertedDate
, Environment = 'Elephant'
FROM dbo.SuccessfulLoginHistory_EL
)
SELECT *
FROM x
WHERE PolicyNumber LIKE @PolicyNumber
ORDER BY LoginDate ASC
;

;WITH y AS (
SELECT
  Email, PolicyNumber, RiskID, DoB, [Status], StatusCode
, Brand, ChangeDate, DeviceID, [Platform], AppVersion
, OSVersion, ImportFileID, InsertedDate
, Environment = 'Admiral'
FROM dbo.LocationPermissionChange
UNION ALL
SELECT
  Email, PolicyNumber, RiskID, DoB, [Status], StatusCode
, Brand, ChangeDate, DeviceID, [Platform], AppVersion
, OSVersion, ImportFileID, InsertedDate
, Environment = 'Elephant'
FROM dbo.LocationPermissionChange_EL
)
SELECT *
FROM y
WHERE PolicyNumber LIKE @PolicyNumber
ORDER BY ChangeDate ASC
;

;WITH z AS (
SELECT
  Account_ID, email, short_user_id, Device_ID, Tag_MAC_Address
, DriveID, Tag_Trip_Number, Trip_Start, Trip_End, Trip_Start_Local
, Trip_End_Local, UTC_Offset_With_dst, Startlat, Startlon
, Endlat, Endlon, Distance_Mapmatched_KM, Duration_Minutes
, Recorded_Duration_Minutes, Mean_Speed_kph, Trip_Mode
, Classification_Confidence, Hardware_Manufacturer, Hardware_Model
, User_Label, Overall_Points, accel_Points, Braking_Points
, Cornering_Points, Speeding_Points, Phone_Motion_Points
, Star_Rating_Overall, Star_Rating_Accel, Star_Rating_Braking
, Star_Rating_Cornering, Star_Rating_Speeding, Star_Rating_Phone_Motion
, Nighttime_Driving_Minutes, ImportFileID, InsertedDate
, FileDate
, Environment = 'Admiral'
FROM dbo.CMTTripSummary
UNION ALL
SELECT
  Account_ID, email, short_user_id, Device_ID, Tag_MAC_Address
, DriveID, Tag_Trip_Number, Trip_Start, Trip_End, Trip_Start_Local
, Trip_End_Local, UTC_Offset_With_dst, Startlat, Startlon
, Endlat, Endlon, Distance_Mapmatched_KM, Duration_Minutes
, Recorded_Duration_Minutes, Mean_Speed_kph, Trip_Mode
, Classification_Confidence, Hardware_Manufacturer, Hardware_Model
, User_Label, Overall_Points, accel_Points, Braking_Points
, Cornering_Points, Speeding_Points, Phone_Motion_Points
, Star_Rating_Overall, Star_Rating_Accel, Star_Rating_Braking
, Star_Rating_Cornering, Star_Rating_Speeding, Star_Rating_Phone_Motion
, Nighttime_Driving_Minutes, ImportFileID, InsertedDate
, FileDate
, Environment = 'Elephant'
FROM dbo.CMTTripSummary_EL
)
SELECT *
FROM z
WHERE Account_ID LIKE @PolicyNumber
ORDER BY Trip_Start_Local ASC
;

SELECT AccountID, CMTID, AchievementID, AchievementMiles, AchievementOrder, DateAchieved
FROM CMTSERV.dbo.Achievement
WHERE AccountID LIKE @PolicyNumber
ORDER BY AchievementOrder ASC
;

;WITH xxyyxx AS (
SELECT
  email, short_user_id, Account_ID, Device_ID, Anomaly_Type
, Anomaly_Device_Time, Anomaly_Server_Time, ImportFileID
, InsertedDate, FileDate
, Environment = 'Admiral'
FROM dbo.CMTAnomaly
UNION ALL
SELECT
  email, short_user_id, Account_ID, Device_ID, Anomaly_Type
, Anomaly_Device_Time, Anomaly_Server_Time, ImportFileID
, InsertedDate, FileDate
, Environment = 'Elephant'
FROM dbo.CMTAnomaly_EL
)
SELECT *
FROM xxyyxx
WHERE Account_ID LIKE @PolicyNumber
ORDER BY Anomaly_Device_Time ASC
;