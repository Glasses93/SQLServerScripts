
USE Staging;

-- Reduce network traffic to client:
SET NOCOUNT ON;
-- In case we implement DATEPART WEEK functions:
SET DATEFIRST 1;
SET XACT_ABORT ON;

BEGIN TRY
	BEGIN TRANSACTION;
	
		DECLARE @ScriptStartTime DATETIME2(7) = SYSDATETIME();

		DECLARE @Log TABLE (
			 ScriptStartTime	DATETIME2(7)	NOT NULL
			,Query				VARCHAR(70)		NOT NULL
			,RowsAffected		INT				NOT NULL
			,QueryFinishTime	DATETIME2(7)	NOT NULL
		)
		;

		DROP TABLE IF EXISTS staging.dbo.PolygonVFJE1;
		DROP TABLE IF EXISTS staging.dbo.PolygonVFJE2;

		CREATE TABLE staging.dbo.PolygonVFJE1 (
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
			FROM staging.dbo.VodaTrip_RAW je
			WHERE NOT EXISTS (
				SELECT 1
				FROM DataSummary.dbo.VodafonePolygons vp
				WHERE je.ExternalContractNumber = vp.ExternalContractNumber
					AND je.TripID = vp.TripID
				)
					AND Latitude  IS NOT NULL
					AND Longitude IS NOT NULL
		)
		INSERT staging.dbo.PolygonVFJE1 WITH (TABLOCK) (
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
		WHERE (
				TimeElapsed < 1200
			OR 	TimeElapsed IS NULL
		)
		;

		INSERT @Log (ScriptStartTime, Query, RowsAffected, QueryFinishTime)
		SELECT
			 @ScriptStartTime
			,'Insert into staging.dbo.PolygonVFJE1'
			,@@ROWCOUNT
			,SYSDATETIME()
		;

		ALTER TABLE staging.dbo.PolygonVFJE1
		ADD CONSTRAINT PK_PolygonVFJE1_ExternalContractNumberTripIDTripRawID PRIMARY KEY CLUSTERED (ExternalContractNumber ASC, TripID ASC, TripRawID ASC)
		;

		INSERT @Log (ScriptStartTime, Query, RowsAffected, QueryFinishTime)
		SELECT
			 @ScriptStartTime
			,'Add Primary Key to staging.dbo.PolygonVFJE1'
			,@@ROWCOUNT
			,SYSDATETIME()
		;

		CREATE SPATIAL INDEX IX_PolygonVFJE1_Coordinate ON staging.dbo.PolygonVFJE1 (Coordinate);

		INSERT @Log (ScriptStartTime, Query, RowsAffected, QueryFinishTime)
		SELECT
			 @ScriptStartTime
			,'Create Spatial Index on staging.dbo.PolygonVFJE1'
			,@@ROWCOUNT
			,SYSDATETIME()
		;

		CREATE TABLE staging.dbo.PolygonVFJE2 (
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
			FROM staging.dbo.Polygons
			WHERE Valid = 1
				AND Artist = 'OSM - Original (Reduced)'
				AND ETL = 1
				AND SRID = 4326
		)
		INSERT staging.dbo.PolygonVFJE2 WITH (TABLOCK) (
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
		FROM staging.dbo.PolygonVFJE1 je
		INNER JOIN Polygons p
			ON p.Polygon.STIntersects(je.Coordinate) = 1
		;

		INSERT @Log (ScriptStartTime, Query, RowsAffected, QueryFinishTime)
		SELECT
			 @ScriptStartTime
			,'Insert UK Driving into staging.dbo.PolygonVFJE2'
			,@@ROWCOUNT
			,SYSDATETIME()
		;

		;WITH BritishIsles AS (
			SELECT Polygon
			FROM staging.dbo.Polygons
			WHERE Valid = 1
				AND SRID = 4326
				AND PolygonName = 'British Isles'
				AND Artist = 'SJ'
		)
		INSERT staging.dbo.PolygonVFJE2 WITH (TABLOCK) (
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
		FROM staging.dbo.PolygonVFJE1 je
		INNER JOIN BritishIsles p
			ON p.Polygon.STIntersects(je.Coordinate) = 0
		;

		DECLARE @ForeignDriving INT = @@ROWCOUNT;

		IF @ForeignDriving > 0
		BEGIN

			IF OBJECT_ID('sandbox.dbo.VodafonePolygons_FD', 'U') IS NULL
			BEGIN

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
				INTO sandbox.dbo.VodafonePolygons_FD
				FROM staging.dbo.PolygonVFJE2
				WHERE PolygonName = 'Outside British Isles'
				;

			END
			ELSE
			BEGIN

			INSERT sandbox.dbo.VodafonePolygons_FD (
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
			FROM staging.dbo.PolygonVFJE2
			WHERE PolygonName = 'Outside British Isles'
			;

			END
			;

		END
		;

		INSERT @Log (ScriptStartTime, Query, RowsAffected, QueryFinishTime)
		SELECT
			 @ScriptStartTime
			,'Insert Foreign Driving into staging.dbo.PolygonVFJE2'
			,@ForeignDriving
			,SYSDATETIME()
		;

		CREATE CLUSTERED INDEX IX_PolygonVFJE2_ExternalContractNumberTripIDEventTimeStamp ON staging.dbo.PolygonVFJE2 (ExternalContractNumber ASC, TripID ASC, EventTimeStamp ASC);

		INSERT @Log (ScriptStartTime, Query, RowsAffected, QueryFinishTime)
		SELECT
			 @ScriptStartTime
			,'Create Index on staging.dbo.PolygonRTJE2'
			,@@ROWCOUNT
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
			FROM staging.dbo.PolygonVFJE2 je
		)
		INSERT DataSummary.dbo.VodafonePolygons (
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
			,'Insert into DataSummary.dbo.VodafonePolygons'
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
			FROM staging.dbo.PolygonVFJE1
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
		FROM DataSummary.dbo.VodafonePolygons js
		INNER JOIN Journeys j
			ON  js.ExternalContractNumber = j.ExternalContractNumber
			AND js.TripID = j.TripID
		;

		INSERT @Log (ScriptStartTime, Query, RowsAffected, QueryFinishTime)
		SELECT
			 @ScriptStartTime
			,'Update %s in DataSummary.dbo.VodafonePolygons'
			,@@ROWCOUNT
			,SYSDATETIME()
		;

		UPDATE p
			SET HaversineMetres = GEOGRAPHY::Point(FirstLatitude, FirstLongitude, 4326).STDistance(GEOGRAPHY::Point(LastLatitude, LastLongitude, 4326))
		FROM DataSummary.dbo.VodafonePolygons p
		WHERE EXISTS (
			SELECT 1
			FROM staging.dbo.PolygonVFJE1 je
			WHERE p.ExternalContractNumber = je.ExternalContractNumber
				AND p.TripID = je.TripID
		)
		;

		INSERT @Log (ScriptStartTime, Query, RowsAffected, QueryFinishTime)
		SELECT
			 @ScriptStartTime
			,'Update HaversineMetres in DataSummary.dbo.VodafonePolygons'
			,@@ROWCOUNT
			,SYSDATETIME()
		;

		IF OBJECT_ID('sandbox.dbo.VodafonePolygons_Log', 'U') IS NULL
		BEGIN

			SELECT
				 ScriptStartTime
				,Query
				,RowsAffected
				,QueryFinishTime
			INTO sandbox.dbo.VodafonePolygons_Log
			FROM @Log
			;

		END
		ELSE
		BEGIN

			INSERT sandbox.dbo.VodafonePolygons_Log (ScriptStartTime, Query, RowsAffected, QueryFinishTime)
			SELECT
				 ScriptStartTime
				,Query
				,RowsAffected
				,QueryFinishTime
			FROM @Log
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
