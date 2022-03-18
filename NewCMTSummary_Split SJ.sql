USE [CMTSERV]
GO

/****** Object:  StoredProcedure [dbo].[InsertCMTSummary]    Script Date: 07/02/2020 11:42:08 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- ===================================================================
-- Author: Emmanuel Kanagala
-- Create date: 2019-11-12
-- Description: Populate CMTJourneys table in DataSummary db
-- ===================================================================
CREATE PROCEDURE [dbo].[InsertCMTSummary]
AS

/* COMBINE BOTH TRIP STAGING TABLES - SINCE IT'S STAGING IT SHOULDN'T TAKE LONG. */

INSERT INTO Staging.dbo.CMTTripCombined -- OR Staging...? REMEMBER TO DROP TABLE OR TRUNCATE / INSERT IF USING STAGING. ALSO CAN WE USE 'SELECT INTO' IN A PROCEDURE - I CAN'T GET THAT TO WORK.
SELECT * FROM
(
	SELECT
	[Latitude],[Longitude],[Altitude],[email],[short_user_id],[Device_ID],[Tag_MAC_Address],[DriveID],[Tag_Trip_Number],[IntervalType]
	,[EventTimeStamp],[LocalEventTimeStamp],[IntervalDuration],[TotalDuration],[Heading],[MM_Latitude],[MM_Longitude],[DistanceTravelled]
	,[MM_DistanceTravelled],[CumulativeDistanceTravelled],[MM_CumulativeDistanceTravelled],[PointSpeed],[MaxSpeed],[MaxSpeedGPSValid]
	,[CumulativeIdleTime],[IntervalIdleTime],[HorizontalAccuracy],[GPSValidCount],[Accelerations1],[Accelerations2],[Accelerations3]
	,[Accelerations4],[Accelerations5],[Accelerations6],[Accelerations7],[Accelerations8],[Accelerations9],[Accelerations10],[Decelerations1]
	,[Decelerations2],[Decelerations3],[Decelerations4],[Decelerations5],[Decelerations6],[Decelerations7],[Decelerations8],[Decelerations9]
	,[Decelerations10],[DistractionEvents],[DuskDawnNightFlag],[ImportFileID],[FileDate],[Account_ID],[Cornering1],[Cornering2],[Cornering3]
	,[Cornering4],[Cornering5],[Cornering6],[Cornering7],[Cornering8],[Cornering9],[Cornering10]
	FROM Staging.dbo.CMTTrip_Staging
	
	UNION ALL -- OR UNION? UNION ALL IS QUICKER BUT I'M ASSUMING CMT DON'T LOAD THE SAME JOURNEY INTO BOTH FILES...
	
	SELECT 
	[Latitude],[Longitude],[Altitude],[email],[short_user_id],[Device_ID],[Tag_MAC_Address],[DriveID],[Tag_Trip_Number],[IntervalType]
	,[EventTimeStamp],[LocalEventTimeStamp],[IntervalDuration],[TotalDuration],[Heading],[MM_Latitude],[MM_Longitude],[DistanceTravelled]
	,[MM_DistanceTravelled],[CumulativeDistanceTravelled],[MM_CumulativeDistanceTravelled],[PointSpeed],[MaxSpeed],[MaxSpeedGPSValid]
	,[CumulativeIdleTime],[IntervalIdleTime],[HorizontalAccuracy],[GPSValidCount],[Accelerations1],[Accelerations2],[Accelerations3]
	,[Accelerations4],[Accelerations5],[Accelerations6],[Accelerations7],[Accelerations8],[Accelerations9],[Accelerations10],[Decelerations1]
	,[Decelerations2],[Decelerations3],[Decelerations4],[Decelerations5],[Decelerations6],[Decelerations7],[Decelerations8],[Decelerations9]
	,[Decelerations10],[DistractionEvents],[DuskDawnNightFlag],[ImportFileID],[FileDate],[Account_ID],[Cornering1],[Cornering2],[Cornering3]
	,[Cornering4],[Cornering5],[Cornering6],[Cornering7],[Cornering8],[Cornering9],[Cornering10]
	FROM Staging.dbo.CMTTrip_Staging_EL
)a
;

/*
	COMBINE BOTH TRIP SUMMARY TABLES FOR TRIPS IN TODAY'S STAGING - LONGEST STEP. IF WE INDEX BOTH CMTServ.dbo.CMTTripSummary AND CMTServ.dbo.CMTTripSummary_EL WHICH WOULD BE THE PRIMARY KEY AND DO TWO
	STATEMENTS JOINING TO #TRIPCOMBINED THEN THE INDEX CAN BE USED I THINK.*/

;WITH BothTables AS (
	SELECT 
		Account_ID, DriveID, Trip_Mode, Overall_Points, Accel_Points,
		Cornering_Points, Speeding_Points, Phone_Motion_Points, Star_Rating_Overall,
		Star_Rating_Accel, Star_Rating_Braking, Star_Rating_Cornering, Star_Rating_Speeding,
		Star_Rating_Phone_Motion, NightTime_Driving_Minutes, Classification_Confidence, InsertedDate
	FROM CMTServ.dbo.CMTTripSummary

	UNION ALL -- OR UNION? UNION ALL IS QUICKER BUT I'M ASSUMING CMT DON'T LOAD THE SAME JOURNEY INTO BOTH FILES...

	SELECT 
		Account_ID, DriveID, Trip_Mode, Overall_Points, Accel_Points,
		Cornering_Points, Speeding_Points, Phone_Motion_Points, Star_Rating_Overall,
		Star_Rating_Accel, Star_Rating_Braking, Star_Rating_Cornering, Star_Rating_Speeding,
		Star_Rating_Phone_Motion, NightTime_Driving_Minutes, Classification_Confidence, InsertedDate
	FROM CMTServ.dbo.CMTTripSummary_EL
)
INSERT INTO Staging.dbo.CMTTripSummaryCombined
(Account_ID, DriveID, Trip_Mode, Overall_Points, Accel_Points,
Cornering_Points, Speeding_Points, Phone_Motion_Points, Star_Rating_Overall,
Star_Rating_Accel, Star_Rating_Braking, Star_Rating_Cornering, Star_Rating_Speeding,
Star_Rating_Phone_Motion, NightTime_Driving_Minutes, Classification_Confidence, InsertedDate)
SELECT 
		a.Account_ID, a.DriveID, Trip_Mode, Overall_Points, Accel_Points,
		Cornering_Points, Speeding_Points, Phone_Motion_Points, Star_Rating_Overall,
		Star_Rating_Accel, Star_Rating_Braking, Star_Rating_Cornering, Star_Rating_Speeding,
		Star_Rating_Phone_Motion, NightTime_Driving_Minutes, Classification_Confidence, InsertedDate
FROM BothTables a
INNER JOIN ( -- ONLY INTERESTED IN TRIP SUMMARY FOR TRIPS FROM TODAY'S STAGING.
	SELECT DISTINCT
		 Account_ID
		,DriveID
	FROM Staging.dbo.CMTTripCombined
) b
	ON a.Account_ID = b.Account_ID
	AND a.DriveID = b.DriveID
;

/* THIS NOW READS FROM #TripCombined INSTEAD OF Staging.dbo.CMTTrip_Staging. */

;WITH Trip_Vars AS (
	SELECT	Account_ID,
		Device_ID,
		DriveID,
		IntervalType,
		EventTimeStamp,
		LocalEventTimeStamp,
		IntervalDuration,
		TotalDuration,
		Latitude,
		Longitude,
		Heading,
		Altitude,
		MM_Longitude,
		DistanceTravelled,
		MM_DistanceTravelled,
		CumulativeDistanceTravelled,
		MM_CumulativeDistanceTravelled,
		PointSpeed,
		MaxSpeed,
		MaxSpeedGPSValid,
		CumulativeIdleTime,
		IntervalIdleTime,
		HorizontalAccuracy,
		GPSValidCount,
		Accelerations1,
		Accelerations2,
		Accelerations3,
		Accelerations4,
		Accelerations5,
		Accelerations6,
		Accelerations7,
		Accelerations8,
		Accelerations9,
		Accelerations10,
		Decelerations1,
		Decelerations2,
		Decelerations3,
		Decelerations4,
		Decelerations5,
		Decelerations6,
		Decelerations7,
		Decelerations8,
		Decelerations9,
		Decelerations10,
		DistractionEvents,
		DuskDawnNightFlag,
		CASE WHEN (DATEPART(HOUR, LocalEventTimeStamp) > 21 OR DATEPART(HOUR, LocalEventTimeStamp) < 4) THEN 1 ELSE 0 END [NightMarker],
		MaxSpeedGPSValid * 2.23694 [Max_Speed_MPH],
		CASE WHEN (MaxSpeedGPSValid * 2.23694) > 50 THEN 1 ELSE 0 END [SpGT50],
		CASE WHEN (MaxSpeedGPSValid * 2.23694) > 60 THEN 1 ELSE 0 END [SpGT60],
		CASE WHEN (MaxSpeedGPSValid * 2.23694) > 75 THEN 1 ELSE 0 END [SpGT75],
		CASE WHEN (MaxSpeedGPSValid * 2.23694) > 85 THEN 1 ELSE 0 END [SpGT85],
		CASE WHEN (MaxSpeedGPSValid * 2.23694) > 100 THEN 1 ELSE 0 END [SpGT100],
		CASE WHEN (MaxSpeedGPSValid * 2.23694) > 110 THEN 1 ELSE 0 END [SpGT110],
		CASE WHEN (MaxSpeedGPSValid * 2.23694) > 120 THEN 1 ELSE 0 END [SpGT120],
		CASE WHEN (MaxSpeedGPSValid * 2.23694) > 130 THEN 1 ELSE 0 END [SpGT130],
		GETDATE() [InsertedDate]

From [staging].[dbo].[CMTTripCombined]
)
INSERT INTO [sandbox].[dbo].[CMTTripVars]
SELECT	Account_ID
	,Device_ID
	,DriveID
	,MIN(LocalEventTimeStamp) [JStartTimeLocal]
	,MAX(LocalEventTimeStamp) [JEndTimeLocal]
	,MIN(CAST(LocalEventTimeStamp as Date)) [JStartDateLocal]
	,MAX(CAST(LocalEventTimeStamp as Date)) [JEndDateLocal]
	,MIN(EventTimeStamp) [JStartTime]
	,MAX(EventTimeStamp) [JEndTime]
	,MIN(CAST(EventTimeStamp as Date)) [JStartDate]
	,MAX(CAST(EventTimeStamp as Date)) [JEndDate]
	,SUM(IntervalDuration / 60) [Duration_Mins]
	,SUM((IntervalDuration / 3600) * NightMarker) [Night_Hours]
	,SUM(DistanceTravelled) * 0.621371 [Distance_Miles]
	,SUM(DistanceTravelled) [Distance_KM]
	,SUM(MM_DistanceTravelled) * 0.621371 [Distance_Miles_MM]
	,SUM(MM_DistanceTravelled) [Distance_KM_MM]
	,SUM(CAST(Accelerations1 as INT)+CAST(Accelerations2 as INT)+CAST(Accelerations3 as INT)+CAST(Accelerations4 as INT)+CAST(Accelerations5 as INT)+CAST(Accelerations6 as INT)+CAST(Accelerations7 as INT)+CAST(Accelerations8 as INT)+CAST(Accelerations9 as INT)+CAST(Accelerations10 as INT)) [Acc_Over3MsS]
	,SUM(CAST(Decelerations1 as INT)+CAST(Decelerations2 as INT)+CAST(Decelerations3 as INT)+CAST(Decelerations4 as INT)+CAST(Decelerations5 as INT)+CAST(Decelerations6 as INT)+CAST(Decelerations7 as INT)+CAST(Decelerations8 as INT)+CAST(Decelerations9 as INT)+CAST(Decelerations10 as INT)) [Dec_Over2MsS]
	,SUM(CAST(Decelerations4 as INT)+CAST(Decelerations5 as INT)+CAST(Decelerations6 as INT)+CAST(Decelerations7 as INT)+CAST(Decelerations8 as INT)+CAST(Decelerations9 as INT)+CAST(Decelerations10 as INT)) [Dec_Over5MsS]
	,MAX(Max_Speed_MPH) [Max_Speed_MPH]				
	,SUM(SpGT50)  [SpGT50]
	,SUM(SpGT60)  [SpGT60]
	,SUM(SpGT75)  [SpGT75]
	,SUM(SpGT85)  [SpGT85]
	,SUM(SpGT100) [SpGT100]
	,SUM(SpGT110) [SpGT110]
	,SUM(SpGT120) [SpGT120]
	,SUM(SpGT130) [SpGT130]
	,SUM(CAST(DistractionEvents as INT)) AS [SumDistraction]
	,InsertedDate
FROM Trip_Vars
GROUP BY Account_ID, DriveID, Device_ID, InsertedDate;
  
/* THIS NOW READS FROM #TripCombined AND #TripSummaryCombined INSTEAD OF Staging.dbo.CMTTrip_Staging AND CMTServ.dbo.CMTTripSummary */

INSERT INTO [DataSummary].[dbo].[CMTCalc]  -- Truncate the table later
SELECT	a.Account_ID,
	LEFT(a.Account_ID, CHARINDEX('.', a.Account_ID)-1) [PolicyNumber],
	RIGHT(a.Account_ID, CHARINDEX('.', REVERSE(a.Account_ID))-1) [RiskID],
	a.Device_ID,
	a.DriveID,
	d.Trip_Mode [Original_Trip_Mode],
	--d.Trip_Mode [Trip_Mode], SJ CHANGE 17/02/2020
	-- REASON FOR CHANGE: CMT PROVIDE TWO DISTINCT LABELS FOR CAR JOURNEYS - WE WANT THESE JOURNEYS ASSIGNED UNDER ONE LABEL.
	CASE COALESCE(d.User_Label, d.Trip_Mode) WHEN 'DRIVER' THEN 'car' ELSE LOWER(COALESCE(d.User_Label, d.Trip_Mode)) END [Trip_Mode], -- SJ CHANGE 17/02/2020
	d.Classification_Confidence,
	b.StartLatitude,
	b.StartLongitude,
	b.EndLatitude,
	b.EndLongitude,
	a.JStartTimeLocal,
	a.JEndTimeLocal,
	a.JStartDateLocal,
	a.JEndDateLocal,
	a.JStartTime,
	a.JEndTime,
	a.JStartDate,
	a.JEndDate,
	a.Duration_Mins,
	a.Night_Hours,
	a.Distance_Miles,
	a.Distance_Miles_MM,
	a.Distance_KM,
	a.Distance_KM_MM,
	a.Acc_Over3MsS,
	a.Dec_Over2MsS,
	a.Dec_Over5MsS,
	a.Max_Speed_MPH,
	a.SpGT50,
	a.SpGT60,
	a.SpGT75,
	a.SpGT85,
	a.SpGT100,
	a.SpGT110,
	a.SpGT120,
	a.SpGT130,
	d.Overall_Points,
	d.Accel_Points,
	d.Cornering_Points,
	d.Speeding_Points,
	d.Phone_Motion_Points,
	d.Star_Rating_Overall,
	d.Star_Rating_Accel,
	d.Star_Rating_Braking,
	d.Star_Rating_Cornering,
	d.Star_Rating_Speeding,
	d.Star_Rating_Phone_Motion,
	d.NightTime_Driving_Minutes,
	a.SumDistraction,
	a.InsertedDate
FROM sandbox.[dbo].[CMTTripVars] a
INNER JOIN (
	SELECT DISTINCT
		 Account_ID
		,Device_ID
		,DriveID
		,FIRST_VALUE(MM_Latitude) OVER (
			PARTITION BY Account_ID, Device_ID, DriveID
			ORDER BY LocalEventTimeStamp ASC, CASE IntervalType WHEN '1.0' THEN 1 WHEN '2.0' THEN 3 ELSE 2 END ASC
			ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
		 ) [StartLatitude]
		,FIRST_VALUE(MM_Longitude) OVER (
			PARTITION BY Account_ID, Device_ID, DriveID
			ORDER BY LocalEventTimeStamp ASC, CASE IntervalType WHEN '1.0' THEN 1 WHEN '2.0' THEN 3 ELSE 2 END ASC
			ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
		 ) [StartLongitude]
		,LAST_VALUE(MM_Latitude) OVER (
			PARTITION BY Account_ID, Device_ID, DriveID
			ORDER BY LocalEventTimeStamp ASC, CASE IntervalType WHEN '1.0' THEN 1 WHEN '2.0' THEN 3 ELSE 2 END ASC
			ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
		 ) [EndLatitude]
		,LAST_VALUE(MM_Longitude) OVER (
			PARTITION BY Account_ID, Device_ID, DriveID
			ORDER BY LocalEventTimeStamp ASC, CASE IntervalType WHEN '1.0' THEN 1 WHEN '2.0' THEN 3 ELSE 2 END ASC
			ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
		 ) [EndLongitude]
FROM [staging].[dbo].[CMTTripCombined]
) b
	ON  a.Account_ID = b.Account_ID
	and a.DriveID = b.DriveID

INNER JOIN (
	SELECT	ROW_NUMBER() OVER (PARTITION BY Account_ID, DriveID
					ORDER BY InsertedDate ASC) AS RN,
		Account_ID, DriveID, Trip_Mode, User_Label, Overall_Points, Accel_Points,
		Cornering_Points, Speeding_Points, Phone_Motion_Points, Star_Rating_Overall,
		Star_Rating_Accel, Star_Rating_Braking, Star_Rating_Cornering, Star_Rating_Speeding,
		Star_Rating_Phone_Motion, NightTime_Driving_Minutes, Classification_Confidence
	FROM [Staging].[dbo].[CMTTripSummaryCombined]
) d
	ON  a.Account_ID = d.Account_ID
	AND a.DriveID = d.DriveID
WHERE d.RN = 1;


/* Insert into DATA SUMMARY TABLE */
INSERT INTO sandbox.[dbo].[EKCMTJourneys]
SELECT *
FROM [DataSummary].[dbo].[CMTCalc];


/* Remove Trips from the Master Table which have Joined */

DELETE a
FROM sandbox.[dbo].[CMTTripVars] a
INNER JOIN [CMTServ].[dbo].[CMTTripSummary] b
	ON  a.Account_ID = b.Account_ID
	AND a.DriveID = b.DriveID;

DELETE a
FROM sandbox.[dbo].[CMTTripVars] a
INNER JOIN [CMTServ].[dbo].[CMTTripSummary_EL] b
	ON  a.Account_ID = b.Account_ID
	AND a.DriveID = b.DriveID;


/* Update Summary With New Trip Labels */

/* UPDATE TRIP LABELS FROM UNION OF BOTH TABLES. */

;WITH BothTables AS (
	SELECT
		 Account_ID
		,DriveID
		,New_Label
		,Label_Change_Date
	FROM CMTServ.dbo.CMTTripLabel
	
	UNION ALL
	
	SELECT
		 Account_ID
		,DriveID
		,New_Label
		,Label_Change_Date
	FROM CMTServ.dbo.CMTTripLabel_EL
),

LatestTripLabel AS (
SELECT	DISTINCT 
	Account_ID
	,DriveID
	,Last_Value(New_Label) OVER (PARTITION BY Account_ID, DriveID
					ORDER BY Label_Change_Date
					ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) New_Trip_Mode
FROM BothTables
)
UPDATE sandbox.[dbo].[EKCMTJourneys] 
	-- SET Trip_Mode = lower(b.New_Trip_Mode) SJ CHANGE 17/02/2020
	-- REASON FOR CHANGE: CMT PROVIDE TWO DISTINCT LABELS FOR CAR JOURNEYS - WE WANT THESE JOURNEYS ASSIGNED UNDER ONE LABEL.
	SET Trip_Mode = lower(CASE b.New_Trip_Mode WHEN 'DRIVER' THEN 'car' ELSE b.New_Trip_Mode END) -- SJ CHANGE 17/02/2020
	FROM sandbox.[dbo].[EKCMTJourneys] a
	INNER JOIN LatestTripLabel b
		ON  a.Account_ID = b.Account_ID
		AND a.DriveID = b.DriveID
;

TRUNCATE TABLE [DataSummary].[dbo].[CMTCalc]
TRUNCATE TABLE [staging].[dbo].[CMTTripCombined]
TRUNCATE TABLE [Staging].[dbo].[CMTTripSummaryCombined]

GO


