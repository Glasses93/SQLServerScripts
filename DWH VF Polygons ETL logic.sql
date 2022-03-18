
USE Staging;

SET NOCOUNT ON;

DECLARE @ScriptStartTime DATETIME2(7) = SYSDATETIME();

DECLARE @Log TABLE (
	 ScriptStartTime	DATETIME2(7)	NOT NULL
	,Query				VARCHAR(70)		NOT NULL
	,RowsAffected		INT				NOT NULL
	,QueryFinishTime	DATETIME2(7)	NOT NULL
)
;

DROP TABLE IF EXISTS Staging.dbo.PolygonVFJE1;
DROP TABLE IF EXISTS Staging.dbo.PolygonVFJE2;

CREATE TABLE Staging.dbo.PolygonVFJE1 (
	 ExternalContractNumber	VARCHAR(20)		NOT NULL
	,PlateNumber			VARCHAR(50)		NOT NULL
	,TripID					VARCHAR(50)		NOT NULL
	,TripRawID				BIGINT			NOT NULL
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
	,NightFlag				BIT					NULL
)
;

;WITH JourneyEvent AS (
	SELECT
		 ExternalContractNumber
		,PlateNumber
		,TripID    
		,TripRawID
		,EventOrder =
			CASE EventTypeID
				WHEN 1 THEN 1
				WHEN 2 THEN 3
					   ELSE 2
			END
		,EventTimeStamp =
			CASE
				WHEN BSTFlag = 1 THEN DATEADD(HOUR, 1, EventTimeStamp)
				ELSE EventTimeStamp
			END
		,Latitude
		,Longitude
		,Coordinate = GEOGRAPHY::Point(Latitude, Longitude, 4326)
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
		,NightFlag
	FROM Staging.dbo.VodaTrip_RAW je
	WHERE NOT EXISTS (
		SELECT 1
		FROM DataSummary.dbo.VodafonePolygonSummary p
		WHERE je.ExternalContractNumber = p.ExternalContractNumber
			AND je.TripID = p.TripID
	)
)
INSERT Staging.dbo.PolygonVFJE1 WITH (TABLOCK) (
	 ExternalContractNumber
	,PlateNumber
	,TripID
	,TripRawID
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
	,NightFlag
)
SELECT
	 ExternalContractNumber
	,PlateNumber
	,TripID
	,TripRawID
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
	,NightFlag
FROM JourneyEvent
WHERE TimeElapsed < 1200
;

INSERT @Log (ScriptStartTime, Query, RowsAffected, QueryFinishTime)
SELECT
	 @ScriptStartTime
	,'Insert into Staging.dbo.PolygonVFJE1'
	,@@ROWCOUNT
	,SYSDATETIME()
;

ALTER TABLE Staging.dbo.PolygonVFJE1
ADD CONSTRAINT PK_PolygonVFJE1_TripRawID PRIMARY KEY CLUSTERED (TripRawID ASC)
;

INSERT @Log (ScriptStartTime, Query, RowsAffected, QueryFinishTime)
SELECT
	 @ScriptStartTime
	,'Add Primary Key to Staging.dbo.PolygonVFJE1'
	,@@ROWCOUNT
	,SYSDATETIME()
;

CREATE SPATIAL INDEX IX_PolygonVFJE1_Coordinate ON Staging.dbo.PolygonVFJE1 (Coordinate);

INSERT @Log (ScriptStartTime, Query, RowsAffected, QueryFinishTime)
SELECT
	 @ScriptStartTime
	,'Create Spatial Index on Staging.dbo.PolygonVFJE1'
	,@@ROWCOUNT
	,SYSDATETIME()
;

CREATE TABLE Staging.dbo.PolygonVFJE2 (
	 ExternalContractNumber	VARCHAR(20)		NOT NULL
	,PlateNumber			VARCHAR(50)		NOT NULL
	,TripID					VARCHAR(50)		NOT NULL
	,TripRawID				BIGINT			NOT NULL
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
	,NightFlag				BIT					NULL
	,PolygonName			VARCHAR(30)		NOT NULL
)
;

;WITH Polygons AS (
	SELECT
		 PolygonName
		,Polygon
	FROM Staging.dbo.Polygons
	WHERE Valid = 1
		AND SRID = 4326
		AND ETL = 1
)
INSERT Staging.dbo.PolygonVFJE2 WITH (TABLOCK) (
	 ExternalContractNumber
	,PlateNumber
	,TripID
	,TripRawID
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
	,NightFlag
	,PolygonName
)
SELECT
	 je.ExternalContractNumber
	,je.PlateNumber
	,je.TripID
	,je.TripRawID
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
	,je.NightFlag
	,p.PolygonName
FROM Staging.dbo.PolygonVFJE1 je
INNER JOIN Polygons p
	ON p.Polygon.STIntersects(je.Coordinate) = 1
;

INSERT @Log (ScriptStartTime, Query, RowsAffected, QueryFinishTime)
SELECT
	 @ScriptStartTime
	,'Insert UK Driving into Staging.dbo.PolygonVFJE2'
	,@@ROWCOUNT
	,SYSDATETIME()
;

;WITH BritishIsles AS (
	SELECT
		 PolygonName
		,Polygon
	FROM Staging.dbo.Polygons
	WHERE Valid = 1
		AND SRID = 4326
		AND PolygonName = 'British Isles'
		AND Artist = 'SJ'
)
INSERT Staging.dbo.PolygonVFJE2 WITH (TABLOCK) (
	 ExternalContractNumber
	,PlateNumber
	,TripID
	,TripRawID
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
	,NightFlag
	,PolygonName
)
SELECT
	 je.ExternalContractNumber
	,je.PlateNumber
	,je.TripID
	,je.TripRawID
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
	,je.NightFlag
	,'Outside British Isles'
FROM Staging.dbo.PolygonVFJE1 je
INNER JOIN BritishIsles p
	ON p.Polygon.STIntersects(je.Coordinate) = 0
;

DECLARE @ForeignDriving INT = @@ROWCOUNT;

IF @ForeignDriving > 0
BEGIN

	IF OBJECT_ID('Sandbox.dbo.VodaPolygonSummary_FD', 'U') IS NULL
	BEGIN

		SELECT
			 i.ExternalContractNumber
			,i.PlateNumber
			,i.TripID
			,i.TripRawID
			,i.EventOrder
			,i.EventTimeStamp
			,i.TimeElapsed
			,i.Latitude
			,i.Longitude
			,i.DeltaDistanceMetres
			,i.HaversineMetresDriven
			,i.DeltaMaxSpeedMPH
			,i.DeltaTripIdleTime
			,i.Country
			,i.County
			,i.City
			,i.GPSAccuracy
			,i.NightFlag
			,i.PolygonName
		INTO Sandbox.dbo.VodaPolygonSummary_FD
		FROM Staging.dbo.PolygonVFJE2 i
		WHERE i.PolygonName = 'Outside British Isles'
		;

	END
	ELSE
	BEGIN

	INSERT Sandbox.dbo.VodaPolygonSummary_FD (
		 ExternalContractNumber
		,PlateNumber
		,TripID
		,TripRawID
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
		,NightFlag
		,PolygonName
	)
	SELECT
		 i.ExternalContractNumber
		,i.PlateNumber
		,i.TripID
		,i.TripRawID
		,i.EventOrder
		,i.EventTimeStamp
		,i.TimeElapsed
		,i.Latitude
		,i.Longitude
		,i.DeltaDistanceMetres
		,i.HaversineMetresDriven
		,i.DeltaMaxSpeedMPH
		,i.DeltaTripIdleTime
		,i.Country
		,i.County
		,i.City
		,i.GPSAccuracy
		,i.NightFlag
		,i.PolygonName
	FROM Staging.dbo.PolygonVFJE2 i
	WHERE i.PolygonName = 'Outside British Isles'
	;

	END
	;

END
;

INSERT @Log (ScriptStartTime, Query, RowsAffected, QueryFinishTime)
SELECT
	 @ScriptStartTime
	,'Insert Foreign Driving into Staging.dbo.PolygonVFJE2'
	,@ForeignDriving
	,SYSDATETIME()
;

;WITH RowNumbers AS (
	SELECT
		 ExternalContractNumber
		,PlateNumber
		,TripID
		,TripRawID
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
		,NightFlag
		,PolygonName
		,RowNumAsc =
			ROW_NUMBER() OVER (
				PARTITION BY ExternalContractNumber, TripID, PolygonName
				ORDER BY EventTimeStamp ASC , EventOrder ASC
			)
		,RowNumDesc =
			ROW_NUMBER() OVER (
				PARTITION BY ExternalContractNumber, TripID, PolygonName
				ORDER BY EventTimeStamp DESC, EventOrder DESC
			)
	FROM Staging.dbo.PolygonVFJE2
)
INSERT DataSummary.dbo.VodafonePolygonSummary (
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
		(SUM(DeltaDistanceMetres) / 1609.344) / (SUM(TimeElapsed) / 3600.0)
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
	,NightSeconds =
		SUM(
			CASE
				WHEN NightFlag = 1 THEN TimeElapsed
				ELSE 0
			END)
	,NightMetres =
		SUM(
			CASE
				WHEN NightFlag = 1 THEN DeltaDistanceMetres
				ELSE 0
			END)
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

INSERT @Log (ScriptStartTime, Query, RowsAffected, QueryFinishTime)
SELECT
	 @ScriptStartTime
	,'Insert into DataSummary.dbo.VodafonePolygonSummary'
	,@@ROWCOUNT
	,SYSDATETIME()
;

;WITH Journeys AS (
	SELECT
		 ExternalContractNumber
		,PlateNumber	
		,TripID
		,MetresDriven  = SUM(DeltaDistanceMetres)
		,SecondsDriven = SUM(TimeElapsed)
	FROM Staging.dbo.PolygonVFJE1
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
FROM DataSummary.dbo.VodafonePolygonSummary js
INNER JOIN Journeys j
	ON  js.ExternalContractNumber = j.ExternalContractNumber
	AND js.TripID = j.TripID
;

INSERT @Log (ScriptStartTime, Query, RowsAffected, QueryFinishTime)
SELECT
	 @ScriptStartTime
	,'Update %''s in DataSummary.dbo.VodafonePolygonSummary'
	,@@ROWCOUNT
	,SYSDATETIME()
;

UPDATE p
	SET HaversineMetres = GEOGRAPHY::Point(FirstLatitude, FirstLongitude, 4326).STDistance(GEOGRAPHY::Point(LastLatitude, LastLongitude, 4326))
FROM DataSummary.dbo.VodafonePolygonSummary p
WHERE EXISTS (
	SELECT 1
	FROM Staging.dbo.PolygonVFJE1 je
	WHERE p.ExternalContractNumber = je.ExternalContractNumber
		AND p.TripID = je.TripID
)
;

INSERT @Log (ScriptStartTime, Query, RowsAffected, QueryFinishTime)
SELECT
	 @ScriptStartTime
	,'Update HaversineMetres in DataSummary.dbo.VodafonePolygonSummary'
	,@@ROWCOUNT
	,SYSDATETIME()
;

IF OBJECT_ID('Sandbox.dbo.VodafonePolygonSummary_Log', 'U') IS NULL
BEGIN

	SELECT
		 ScriptStartTime
		,Query
		,RowsAffected
		,QueryFinishTime
	INTO Sandbox.dbo.VodafonePolygonSummary_Log
	FROM @Log
	;

END
ELSE
BEGIN

	INSERT Sandbox.dbo.VodafonePolygonSummary_Log (ScriptStartTime, Query, RowsAffected, QueryFinishTime)
	SELECT
		 ScriptStartTime
		,Query
		,RowsAffected
		,QueryFinishTime
	FROM @Log
	;

END
;

