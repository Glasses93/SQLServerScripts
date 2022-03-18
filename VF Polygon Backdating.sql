/*
CREATE TABLE Sandbox.dbo.SJ_VFPolicies (
PolicyNumber NVARCHAR(20) NOT NULL
,RN INT NOT NULL IDENTITY(1, 1)
)

INSERT Sandbox.dbo.SJ_VFPolicies WITH (TABLOCK) (PolicyNumber)
SELECT DISTINCT PolicyNumber
FROM Sandbox.dbo.PolCVPTrav
WHERE TeleDevSuppl = 'vodafone'
AND TeleDevRem = '0'
AND TraversedFlag = '1'
AND EffectFromDate < GETDATE()
;

CREATE UNIQUE CLUSTERED INDEX IX_SJVFPolicies_RN
ON Sandbox.dbo.SJ_VFPolicies (RN ASC)
;

SELECT 1
FROM Vodafone.dbo.Trip t
WHERE EXISTS (
SELECT 1
FROM Sandbox.dbo.SJ_VFPolicies p
WHERE t.ExternalContractNumber = p.PolicyNumber
AND p.RN BETWEEN 1 AND 100
)
;
*/

USE Sandbox;

SET NOCOUNT ON;

IF NOT EXISTS (
SELECT 1
FROM Staging.dbo.DWJobStatus
WHERE Supplier = 'vodafone'
AND CAST(EndTime AS DATE) = CAST(GETDATE() AS DATE)
)
SELECT 1
FROM Ble.Mae.[ETLVodafone?]
;

DECLARE @ScriptStartTime DATETIME2(7) = SYSDATETIME();

DECLARE @Log TABLE (
	 ScriptStartTime	DATETIME2(7)	NOT NULL
	,Query				VARCHAR(70)		NOT NULL
	,RowsAffected		INT				NOT NULL
	,QueryFinishTime	DATETIME2(7)	NOT NULL
)
;

DROP TABLE IF EXISTS #BST;

CREATE TABLE #BST (
	 Year		SMALLINT		NOT NULL
	,StartTime	DATETIME2(2)	NOT NULL
	,EndTime	DATETIME2(2)	NOT NULL
)
;

DECLARE @Year SMALLINT = 2017;

WHILE @Year <= YEAR(GETDATE())
BEGIN

	WITH LastWeekOfMarch (Date) AS (
		SELECT DATETIMEFROMPARTS(@Year, 03, 25, 01, 00, 00, 00)
		
		UNION ALL
		
		SELECT DATEADD(DAY, 1, Date)
		FROM LastWeekOfMarch
		WHERE MONTH(DATEADD(DAY, 1, Date)) < 4
	),
	LastWeekOfOctober (Date) AS (
		SELECT DATETIMEFROMPARTS(@Year, 10, 25, 01, 00, 00, 00)
		
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
	OPTION (MAXRECURSION 32767)
	;
	
	SET @Year += 1;

END
;

/*
SET SHOWPLAN_ALL ON;
SET SHOWPLAN_ALL OFF;
*/

DECLARE @Min INT = 4101;
DECLARE @Max INT = @Min + 99;

--WHILE @Min <= 167318
--BEGIN

DROP TABLE IF EXISTS Sandbox.dbo.SJ_PolygonVFJE1;
TRUNCATE TABLE Sandbox.dbo.SJ_PolygonVFJE2;
TRUNCATE TABLE Sandbox.dbo.SJ_PolygonVFJE3;

CREATE TABLE Sandbox.dbo.SJ_PolygonVFJE1 (
	 ID 			INT			NOT NULL	 IDENTITY(1, 1)
	,ExternalContractNumber	VARCHAR(20)		NOT NULL
	,PlateNumber			VARCHAR(50)		NOT NULL
	,TripID					VARCHAR(50)		NOT NULL
	,EventOrder				TINYINT				NULL
	,EventTimeStamp			DATETIME2(2)		NULL
	,TimeElapsed			INT					NULL
	,Latitude				FLOAT(53)			NULL
	,Longitude				FLOAT(53)			NULL
	,Coordinate				GEOGRAPHY			NULL
	,HaversineMetresDriven	INT					NULL
	,DeltaDistanceMetres	INT	  			  	NULL
	,DeltaMaxSpeedMPH		NUMERIC(9, 1)		NULL
	,DeltaTripIdleTime		INT					NULL
	,Country				NVARCHAR(5)			NULL
	,County					NVARCHAR(50)		NULL
	,City					NVARCHAR(50)		NULL
	,GPSAccuracy			TINYINT				NULL
)
;

;WITH JourneyEvent AS (
	SELECT
		 ExternalContractNumber
		,PlateNumber
		,TripID    
		,EventOrder =
			CASE EventTypeID
				WHEN 1 THEN 1
				WHEN 2 THEN 3
					   ELSE 2
			END
		,EventTimeStamp
		,Latitude
		,Longitude
		,Coordinate =
			GEOGRAPHY::Point(Latitude, Longitude, 4326)
		,DeltaDistanceMetres =
			NULLIF(CONVERT(INT, DeltaTripDistance) * 100, 0)
		,TimeElapsed =
			NULLIF(TimeElapsed, 0)
		,DeltaMaxSpeedMPH =
			CONVERT(INT, DeltaMaxSpeed) / 1.609344
		,DeltaTripIdleTime =
			CONVERT(INT, DeltaTripIdleTime)
		,Country
		,County
		,City
		,GPSAccuracy =
			CONVERT(INT, GPSAccuracy)
	FROM Vodafone.dbo.Trip t
	WHERE EXISTS (
		SELECT 1
		FROM Sandbox.dbo.SJ_VFPolicies p
		WHERE t.ExternalContractNumber = p.PolicyNumber
			AND p.RN BETWEEN @Min AND @Max
	)
		AND Latitude IS NOT NULL
		AND Longitude IS NOT NULL
)
INSERT Sandbox.dbo.SJ_PolygonVFJE1 WITH (TABLOCK) (
	 ExternalContractNumber
	,PlateNumber
	,TripID
	,EventOrder
	,EventTimeStamp
	,TimeElapsed
	,Latitude
	,Longitude
	,Coordinate
	,DeltaDistanceMetres
	,HaversineMetresDriven
	,DeltaMaxSpeedMPH
	,DeltaTripIdleTime
	,Country
	,County
	,City
	,GPSAccuracy
)
SELECT
	 ExternalContractNumber
	,PlateNumber
	,TripID
	,EventOrder
	,EventTimeStamp
	,TimeElapsed
	,Latitude
	,Longitude
	,Coordinate
	,DeltaDistanceMetres
	,HaversineMetresDriven = 
		Coordinate.STDistance(
			LAG(Coordinate, 1, NULL) OVER (
				PARTITION BY ExternalContractNumber, TripID
				ORDER BY EventTimeStamp ASC, EventOrder ASC
			)
		)
	,DeltaMaxSpeedMPH =
		CONVERT(NUMERIC(6, 1), DeltaMaxSpeedMPH)
	,DeltaTripIdleTime
	,Country
	,County
	,City
	,GPSAccuracy
FROM JourneyEvent
WHERE TimeElapsed < 1200
OPTION (OPTIMIZE FOR (@Min = 1, @Max = 100))
;

/*
PRINT @@ROWCOUNT;

SELECT TOP (10000)
ID, ExternalContractNumber, PlateNumber, TripID, EventOrder
, EventTimeStamp, TimeElapsed, Latitude, Longitude
, HaversineMetresDriven, DeltaDistanceMetres, DeltaMaxSpeedMPH
, DeltaTripIdleTime, Country, County, City, GPSAccuracy
FROM Sandbox.dbo.SJ_PolygonVFJE1
;
*/

ALTER TABLE Sandbox.dbo.SJ_PolygonVFJE1
ADD CONSTRAINT PK_PolygonVFJE1_ID PRIMARY KEY CLUSTERED (ID ASC)
;

CREATE SPATIAL INDEX IX_PolygonVFJE1_Coordinate
ON Sandbox.dbo.SJ_PolygonVFJE1 (Coordinate)
;

/*
CREATE TABLE Sandbox.dbo.SJ_PolygonVFJE2 (
	 ExternalContractNumber	VARCHAR(20)		NOT NULL
	,PlateNumber			VARCHAR(50)		NOT NULL
	,TripID					VARCHAR(50)		NOT NULL
	,EventOrder				TINYINT				NULL
	,EventTimeStamp			DATETIME2(2)		NULL
	,TimeElapsed			INT					NULL
	,Latitude				FLOAT(53)			NULL
	,Longitude				FLOAT(53)			NULL			
	,DeltaDistanceMetres	INT	    			NULL
	,HaversineMetresDriven	INT					NULL
	,DeltaMaxSpeedMPH		NUMERIC(9, 1)		NULL
	,DeltaTripIdleTime		INT					NULL
	,Country				NVARCHAR(5)			NULL
	,County					NVARCHAR(50)		NULL
	,City					NVARCHAR(50)		NULL
	,GPSAccuracy			TINYINT				NULL
	,PolygonName			VARCHAR(30)		NOT NULL
)
;
*/

;WITH Polygons AS (
	SELECT
		 PolygonName
		,Polygon
	FROM Sandbox.dbo.SJ_Polygons
	WHERE Valid = 1
		AND SRID = 4326
		AND ETL = 1
)
INSERT Sandbox.dbo.SJ_PolygonVFJE2 WITH (TABLOCK) (
	 ExternalContractNumber
	,PlateNumber
	,TripID
	,EventOrder
	,EventTimeStamp
	,TimeElapsed
	,Latitude
	,Longitude
	,DeltaDistanceMetres
	,HaversineMetresDriven
	,DeltaMaxSpeedMPH
	,DeltaTripIdleTime
	,Country
	,County
	,City
	,GPSAccuracy
	,PolygonName
)
SELECT
	 je.ExternalContractNumber
	,je.PlateNumber
	,je.TripID
	,je.EventOrder
	,je.EventTimeStamp
	,je.TimeElapsed
	,je.Latitude
	,je.Longitude
	,je.DeltaDistanceMetres
	,je.HaversineMetresDriven
	,je.DeltaMaxSpeedMPH
	,je.DeltaTripIdleTime
	,je.Country
	,je.County
	,je.City
	,je.GPSAccuracy
	,p.PolygonName
FROM Sandbox.dbo.SJ_PolygonVFJE1 je
INNER JOIN Polygons p
	ON p.Polygon.STIntersects(je.Coordinate) = 1
;

/*
PRINT @@ROWCOUNT;

SELECT TOP (10000) *
FROM Sandbox.dbo.SJ_PolygonVFJE2
WHERE PolygonName = 'West Midlands'
;
*/

;WITH BritishIsles AS (
	SELECT Polygon
	FROM Sandbox.dbo.SJ_Polygons
	WHERE Valid = 1
		AND SRID = 4326
		AND PolygonName = 'British Isles'
		AND Artist = 'SJ'
)
INSERT Sandbox.dbo.SJ_PolygonVFJE2 WITH (TABLOCK) (
	 ExternalContractNumber
	,PlateNumber
	,TripID
	,EventOrder
	,EventTimeStamp
	,TimeElapsed
	,Latitude
	,Longitude
	,DeltaDistanceMetres
	,HaversineMetresDriven
	,DeltaMaxSpeedMPH
	,DeltaTripIdleTime
	,Country
	,County
	,City
	,GPSAccuracy
	,PolygonName
)
SELECT
	 je.ExternalContractNumber
	,je.PlateNumber
	,je.TripID
	,je.EventOrder
	,je.EventTimeStamp
	,je.TimeElapsed
	,je.Latitude
	,je.Longitude
	,je.DeltaDistanceMetres
	,je.HaversineMetresDriven
	,je.DeltaMaxSpeedMPH
	,je.DeltaTripIdleTime
	,je.Country
	,je.County
	,je.City
	,je.GPSAccuracy
	,'Outside British Isles'
FROM Sandbox.dbo.SJ_PolygonVFJE1 je
INNER JOIN BritishIsles p
	ON p.Polygon.STIntersects(je.Coordinate) = 0
;

/*
PRINT @@ROWCOUNT;

SELECT TOP (10000) *
FROM Sandbox.dbo.SJ_PolygonVFJE2
WHERE PolygonName = 'Outside British Isles'
;
*/

;WITH RowNumbers AS (
	SELECT
		 je.ExternalContractNumber
		,je.PlateNumber
		,je.TripID
		,je.EventOrder
		,EventTimeStamp = CASE WHEN bst.StartTime IS NOT NULL THEN DATEADD(HOUR, 1, je.EventTimeStamp) ELSE je.EventTimeStamp END
		,je.TimeElapsed
		,je.Latitude
		,je.Longitude
		,je.DeltaDistanceMetres
		,je.HaversineMetresDriven
		,je.DeltaMaxSpeedMPH
		,je.DeltaTripIdleTime
		,je.Country
		,je.County
		,je.City
		,je.GPSAccuracy
		,je.PolygonName
		,RowNumAsc =
			ROW_NUMBER() OVER (
				PARTITION BY je.ExternalContractNumber, je.TripID, je.PolygonName
				ORDER BY je.EventTimeStamp ASC , je.EventOrder ASC
			)
		,RowNumDesc =
			ROW_NUMBER() OVER (
				PARTITION BY je.ExternalContractNumber, je.TripID, je.PolygonName
				ORDER BY je.EventTimeStamp DESC, je.EventOrder DESC
			)
	FROM Sandbox.dbo.SJ_PolygonVFJE2 je
	LEFT JOIN #BST bst
		ON  je.EventTimeStamp >= bst.StartTime
		AND je.EventTimeStamp <  bst.EndTime
)
INSERT Sandbox.dbo.SJ_PolygonVFJE3 with (Tablock) (
	 PolygonName  
	,ExternalContractNumber
	,PlateNumber
	,TripID
	,FirstTimeStamp
	,LastTimeStamp
	,FirstLatitude
	,FirstLongitude
	,LastLatitude
	,LastLongitude
	,MetresDriven
	,MilesDriven
	,HaversineMetresDriven
	,SecondsDriven
	,AverageSpeedMPH
	,MaxSpeedMPH
	,CountMaxGT75MPH
	,CountMaxGT85MPH
	,CountMaxGT100MPH
	,IdleTime
	,NightSeconds
	,NightMetres
	,City
	,County
	,Country
)
SELECT
	 PolygonName
	,ExternalContractNumber
	,PlateNumber	
	,TripID
	,FirstTimeStamp =
		MIN(EventTimeStamp)
	,LastTimeStamp =
		MAX(EventTimeStamp)
	,FirstLatitude =
		SUM(
			CASE
				WHEN RowNumAsc  = 1 THEN Latitude
				ELSE NULL
			END)
	,FirstLongitude =
		SUM(
			CASE
				WHEN RowNumAsc  = 1 THEN Longitude
				ELSE NULL
			END)
	,LastLatitude =	
		SUM(
			CASE
				WHEN RowNumDesc = 1 THEN Latitude
				ELSE NULL
			END)
	,LastLongitude = 		
		SUM(
			CASE
				WHEN RowNumDesc = 1 THEN Longitude
				ELSE NULL
			END)
	,MetresDriven =
		SUM(DeltaDistanceMetres)
	,MilesDriven = 
		SUM(DeltaDistanceMetres) / 1609.344
	,HaversineMetresDriven =
		SUM(HaversineMetresDriven)
	,SecondsDriven =
		SUM(TimeElapsed)
	,AverageSpeedMPH =	
		(SUM(DeltaDistanceMetres) / 1609.344) / ( NULLIF(SUM(TimeElapsed), 0) / 3600.0 )
	,MaxSpeedMPH =
		MAX(DeltaMaxSpeedMPH)
	,CountMaxGT75MPH =
		SUM(
			CASE
				WHEN GPSAccuracy = 100 AND DeltaMaxSpeedMPH > 75 THEN 1
				ELSE 0
			END)
	,CountMaxGT85MPH =
		SUM(
			CASE
				WHEN GPSAccuracy = 100 AND DeltaMaxSpeedMPH > 85 THEN 1
				ELSE 0
			END)
	,CountMaxGT100MPH =
		SUM(
			CASE
				WHEN GPSAccuracy = 100 AND DeltaMaxSpeedMPH > 100 THEN 1
				ELSE 0
			END)
	,IdleTime =
		SUM(DeltaTripIdleTime)
	,NightSeconds = SUM(CASE WHEN ( DATEPART(HOUR, EventTimeStamp) >= 22 OR DATEPART(HOUR, EventTimeStamp) < 4 ) THEN TimeElapsed              ELSE 0 END)
	,NightMetres  = SUM(CASE WHEN ( DATEPART(HOUR, EventTimeStamp) >= 22 OR DATEPART(HOUR, EventTimeStamp) < 4 ) THEN DeltaDistanceMetres ELSE 0 END)
	,MAX(City)
	,MAX(County)
	,MAX(Country)
FROM RowNumbers
GROUP BY
	 PolygonName
	,ExternalContractNumber
	,PlateNumber	
	,TripID
;
SELECT * FROM SANDBOX.DBO.SJ_POLYGONVFJE2 WHERE EXTERNALCONTRACTNUMBER = 'P61960338-1'
/*
PRINT @@ROWCOUNT;

SELECT TOP (10000) *
FROM Sandbox.dbo.SJ_PolygonVFJE3
;
*/

;WITH Journeys AS (
	SELECT
		 ExternalContractNumber
		,PlateNumber	
		,TripID
		,MetresDriven  = SUM(DeltaDistanceMetres)
		,SecondsDriven = SUM(TimeElapsed)
	FROM Sandbox.dbo.SJ_PolygonVFJE1
	GROUP BY
		 ExternalContractNumber
		,PlateNumber	
		,TripID
)
UPDATE js
SET
	 js.DistancePctOfJourney =
		(js.MetresDriven  * 1.0) / NULLIF(j.MetresDriven , 0)
	,js.TimePctOfJourney =
		(js.SecondsDriven * 1.0) / NULLIF(j.SecondsDriven, 0)
FROM Sandbox.dbo.SJ_PolygonVFJE3 js
INNER JOIN Journeys j
	ON  js.ExternalContractNumber = j.ExternalContractNumber
	AND js.TripID = j.TripID
;

UPDATE Sandbox.dbo.SJ_PolygonVFJE3
	SET HaversineMetres = GEOGRAPHY::Point(FirstLatitude, FirstLongitude, 4326).STDistance(GEOGRAPHY::Point(LastLatitude, LastLongitude, 4326))
;

INSERT Sandbox.dbo.SJ_VodafonePolygonSummary WITH (TABLOCK) (
ExternalContractNumber, PlateNumber, TripID, PolygonName
, FirstTimeStamp, LastTimeStamp, FirstLatitude, FirstLongitude
, LastLatitude, LastLongitude, HaversineMetres, MetresDriven
, MilesDriven, HaversineMetresDriven, SecondsDriven
, AverageSpeedMPH, MaxSpeedMPH, CountMaxGT75MPH, CountMaxGT85MPH
, CountMaxGT100MPH, IdleTime, NightSeconds, NightMetres
, Country, County, City, DistancePctOfJourney, TimePctOfJourney
)
SELECT
ExternalContractNumber, PlateNumber, TripID, PolygonName
, FirstTimeStamp, LastTimeStamp, FirstLatitude, FirstLongitude
, LastLatitude, LastLongitude, HaversineMetres, MetresDriven
, MilesDriven, HaversineMetresDriven, SecondsDriven
, AverageSpeedMPH, MaxSpeedMPH, CountMaxGT75MPH, CountMaxGT85MPH
, CountMaxGT100MPH, IdleTime, NightSeconds, NightMetres
, Country, County, City, DistancePctOfJourney, TimePctOfJourney
FROM Sandbox.dbo.SJ_PolygonVFJE3
;

INSERT Sandbox.dbo.SJ_VFPLog
SELECT GETDATE(), @Min, @Max, @@ROWCOUNT
;

IF CAST(GETDATE() AS TIME) BETWEEN '01:00:00' AND '06:00:00'
BREAK
;

SET @Min += 100;
SET @Max = @Min + 99;

END
;











/*
PRINT @@ROWCOUNT;

SELECT *
FROM Sandbox.dbo.SJ_PolygonVFJE3
;

select * from Sandbox.dbo.SJ_VFPLog
*/
