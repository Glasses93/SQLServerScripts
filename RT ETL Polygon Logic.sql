
USE RedTailStaging;

-- Reduce network traffic to client:
SET NOCOUNT ON;
-- In case we implement DATEPART WEEK functions:
SET DATEFIRST 1;
SET XACT_ABORT ON;

BEGIN TRY
	BEGIN TRANSACTION;

		-- Note start time of script for logging purposes:
		DECLARE @ScriptStartTime datetime2(7) = SYSDATETIME();

		-- Build table for logging purposes:
		DECLARE @Log TABLE (
			 ScriptStartTime	datetime2(7)	NOT NULL
			,Query				varchar(70)		NOT NULL
			,RowsAffected		int				NOT NULL
			,QueryFinishTime	datetime2(7)	NOT NULL
		)
		;

		-- BST table:
		DROP TABLE IF EXISTS #BST;

		CREATE TABLE #BST (
			 [Year]		smallint		NOT NULL
			,StartTime	datetime2(2)	NOT NULL
			,EndTime	datetime2(2)	NOT NULL
		)
		;

		DECLARE @Year smallint = 2015;

		WHILE @Year <= YEAR(CURRENT_TIMESTAMP)
		BEGIN

			;WITH LastWeekOfMarch ([Date]) AS (
				SELECT DATETIMEFROMPARTS(@Year, 03, 25, 01, 00, 00, 00)
				
				UNION ALL
				
				SELECT DATEADD(DAY, 1, [Date])
				FROM LastWeekOfMarch
				WHERE MONTH(DATEADD(DAY, 1, [Date])) < 4
			),
			LastWeekOfOctober ([Date]) AS (
				SELECT DATETIMEFROMPARTS(@Year, 10, 25, 01, 00, 00, 00)
				
				UNION ALL
				
				SELECT DATEADD(DAY, 1, [Date])
				FROM LastWeekOfOctober
				WHERE MONTH(DATEADD(DAY, 1, [Date])) < 11
			)
			INSERT #BST ([Year], StartTime, EndTime)
			SELECT
				 @Year
				,lsm.[Date]
				,lso.[Date]
			FROM LastWeekOfMarch lsm
			CROSS JOIN (
				SELECT [Date]
				FROM LastWeekOfOctober
				WHERE DATENAME(WEEKDAY, [Date]) = 'Sunday'
			) lso
			WHERE DATENAME(WEEKDAY, lsm.[Date]) = 'Sunday'
			OPTION (MAXRECURSION 6)
			;
			
			SET @Year += 1;

		END
		;

		-- Clean up tables:
		--DROP TABLE IF EXISTS staging.dbo.PolygonRTJE1;
		DROP TABLE IF EXISTS sandbox.dbo.SJ_PolygonRTJE1;
		--DROP TABLE IF EXISTS staging.dbo.PolygonRTJE2;
		DROP TABLE IF EXISTS sandbox.dbo.SJ_PolygonRTJE2;
		--DROP TABLE IF EXISTS staging.dbo.PolygonRTJE3;
		DROP TABLE IF EXISTS sandbox.dbo.SJ_PolygonRTJE3;

		--CREATE TABLE staging.dbo.PolygonRTJE1 (
		CREATE TABLE sandbox.dbo.SJ_PolygonRTJE1 (
			 IMEI						bigint			NOT NULL
			,Journey_ID					integer			NOT NULL
			,JourneyEvent_RawID			bigint			NOT NULL
			,EventOrder					tinyint				NULL
			,EventTimeStamp				datetime2(2)		NULL
			,TimeElapsed				integer				NULL
			,Latitude					float(53)		NOT	NULL
			,Longitude					float(53)		NOT	NULL
			,Coordinate					geography			NULL
			,DistanceFromPrevPosition	smallint	    	NULL
			,TravelSpeedMPH				tinyint				NULL
			,HaversineMetresDriven		integer				NULL
		)
		;

		;WITH JourneyEvent AS (
			SELECT
				 IMEI
				,Journey_ID    
				,JourneyEvent_RawID
				-- To better identify journey start/end should EventTimeStamp be duplicated:
				,EventOrder =
					CASE EventTypeID
						WHEN 1 THEN 1
						WHEN 2 THEN 3
							   ELSE 2
					END
				,EventTimeStamp
				-- A different attempt at TimeElapsed:
				,TimeElapsed =
					CASE WHEN
						DATEDIFF(
							 SECOND
							,LAG(EventTimeStamp, 1, NULL) OVER (PARTITION BY IMEI, Journey_ID ORDER BY EventTimeStamp ASC)
							,EventTimeStamp
						) > 3600 THEN 3600
					ELSE
						DATEDIFF(
							 SECOND
							,LAG(EventTimeStamp, 1, NULL) OVER (PARTITION BY IMEI, Journey_ID ORDER BY EventTimeStamp ASC)
							,EventTimeStamp
						)
					END
				,Latitude
				,Longitude
				-- For polygon-related steps:
				,Coordinate = CASE WHEN Latitude IS NOT NULL AND Longitude IS NOT NULL THEN geography::Point(Latitude, Longitude, 4326) END
				-- Cap anomalous data similar to RT Score:
				,DistanceFromPrevPosition = CASE WHEN DistanceFromPrevPosition > 2000 THEN 2000 ELSE DistanceFromPrevPosition END
				-- Cap anomalous data similar to RT Score:
				,TravelSpeedMPH = CASE WHEN TravelSpeedMPH BETWEEN 0 AND 156 THEN TravelSpeedMPH END
			FROM RedTailstaging.dbo.JourneyEvent je
			-- Remove previously inserted journeys:
			WHERE NOT EXISTS (
				SELECT 1
				FROM DataSummary.dbo.RedTailPolygons p
				--FROM sandbox.dbo.SJ_RedTailPolygons p
				WHERE je.IMEI = p.IMEI
					AND je.Journey_ID = p.Journey_ID
			)
				-- Because there are nullability constraints on these fields:
				AND IMEI 	   IS NOT NULL
				AND Journey_ID IS NOT NULL
				AND Latitude   IS NOT NULL
				AND Longitude  IS NOT NULL
		)
		-- The TABLOCK table hint is used to achieve Parallelism:
		--INSERT staging.dbo.PolygonRTJE1 WITH (TABLOCK) (
		INSERT sandbox.dbo.SJ_PolygonRTJE1 WITH ( TABLOCK ) (
			IMEI    , Journey_ID, JourneyEvent_RawID, EventTimeStamp          , EventOrder    , TimeElapsed          ,
			Latitude, Longitude , Coordinate        , DistanceFromPrevPosition, TravelSpeedMPH, HaversineMetresDriven
		)
		SELECT
			 IMEI
			,Journey_ID
			,JourneyEvent_RawID
			,EventTimeStamp
			,EventOrder
			,TimeElapsed
			,Latitude
			,Longitude
			,Coordinate		
			,DistanceFromPrevPosition
			,TravelSpeedMPH
			-- A different attempt at DistanceFromPrevPosition:
			,HaversineMetresDriven =
				Coordinate.STDistance(
					LAG(Coordinate, 1, NULL) OVER (
						PARTITION BY IMEI, Journey_ID
						ORDER BY	 EventTimeStamp ASC, EventOrder ASC
					)
				)
		FROM JourneyEvent
		;

		INSERT @Log (ScriptStartTime, Query, RowsAffected, QueryFinishTime)
		SELECT
			 @ScriptStartTime
			,'Insert into staging.dbo.PolygonRTJE1'
			,@@ROWCOUNT
			,SYSDATETIME()
		;

		-- Primary Key required for building spatial index:
		--ALTER TABLE staging.dbo.PolygonRTJE1
		ALTER TABLE sandbox.dbo.SJ_PolygonRTJE1
		ADD CONSTRAINT PK_PolygonRTJE1_IMEIJourneyIDJourneyEventRawID PRIMARY KEY CLUSTERED (
			 IMEI               ASC
			,Journey_ID         ASC
			,JourneyEvent_RawID ASC
		)
		;

		INSERT @Log (ScriptStartTime, Query, RowsAffected, QueryFinishTime)
		SELECT
			 @ScriptStartTime
			,'Add Primary Key to staging.dbo.PolygonRTJE1'
			,@@ROWCOUNT
			,SYSDATETIME()
		;

		-- To improve performance of polygon-related steps:
		CREATE SPATIAL INDEX IX_PolygonRTJE1_Coordinate
		--ON staging.dbo.PolygonRTJE1 (Coordinate)
		ON sandbox.dbo.SJ_PolygonRTJE1 (Coordinate)
		USING GEOGRAPHY_GRID WITH (
			 GRIDS            = ( LEVEL_1 = HIGH, LEVEL_2 = HIGH, LEVEL_3 = HIGH, LEVEL_4 = HIGH )
			,CELLS_PER_OBJECT = 1
		)
		;

		INSERT @Log (ScriptStartTime, Query, RowsAffected, QueryFinishTime)
		SELECT
			 @ScriptStartTime
			,'Create Spatial Index on staging.dbo.PolygonRTJE1'
			,@@ROWCOUNT
			,SYSDATETIME()
		;

		--CREATE TABLE staging.dbo.PolygonRTJE2 (
		CREATE TABLE sandbox.dbo.SJ_PolygonRTJE2 (
			 IMEI						bigint			NOT NULL
			,Journey_ID					integer			NOT NULL
			,EventOrder					tinyint				NULL
			,EventTimeStamp				datetime2(2)		NULL
			,TimeElapsed				integer				NULL
			,Latitude					float(53)		NOT	NULL
			,Longitude					float(53)		NOT	NULL
			,DistanceFromPrevPosition	smallint	    	NULL
			,TravelSpeedMPH				tinyint				NULL
			,HaversineMetresDriven		integer				NULL
			,PolygonName				varchar(30)		NOT NULL
		)
		;

		;WITH Polygons AS (
			SELECT
				 PolygonName
				,Polygon
			--FROM staging.dbo.Polygons
			FROM sandbox.dbo.SJ_Polygons
			-- Filters required to ensure valid polygons.
			-- Take care when modifying this table:
			WHERE Valid = 1
				AND SRID = 4326
				AND ETL = 1
		)
		--INSERT staging.dbo.PolygonRTJE2 WITH (TABLOCK) (
		INSERT sandbox.dbo.SJ_PolygonRTJE2 WITH (TABLOCK) (
			IMEI     , Journey_ID			   , EventTimeStamp, EventOrder           , TimeElapsed, Latitude,
			Longitude, DistanceFromPrevPosition, TravelSpeedMPH, HaversineMetresDriven, PolygonName
		)
		SELECT
			 je.IMEI
			,je.Journey_ID
			,je.EventTimeStamp
			,je.EventOrder
			,je.TimeElapsed
			,je.Latitude
			,je.Longitude
			,je.DistanceFromPrevPosition
			,je.TravelSpeedMPH
			,je.HaversineMetresDriven
			,p.PolygonName
		--FROM staging.dbo.PolygonRTJE1 je
		FROM sandbox.dbo.SJ_PolygonRTJE1 je
		INNER JOIN Polygons p
			-- Identify British Isles driving:
			ON p.Polygon.STIntersects(je.Coordinate) = 1
		;

		INSERT @Log (ScriptStartTime, Query, RowsAffected, QueryFinishTime)
		SELECT
			 @ScriptStartTime
			,'Insert UK Driving into staging.dbo.PolygonRTJE2'
			,@@ROWCOUNT
			,SYSDATETIME()
		;

		;WITH BritishIsles AS (
			SELECT Polygon
			--FROM staging.dbo.Polygons
			FROM sandbox.dbo.SJ_Polygons
			WHERE Valid = 1
				AND SRID = 4326
				AND PolygonName = 'British Isles'
				AND Artist = 'SJ'
		)
		--INSERT staging.dbo.PolygonRTJE2 WITH (TABLOCK) (
		INSERT sandbox.dbo.SJ_PolygonRTJE2 WITH (TABLOCK) (
			IMEI     , Journey_ID              , EventTimeStamp, EventOrder           , TimeElapsed, Latitude,
			Longitude, DistanceFromPrevPosition, TravelSpeedMPH, HaversineMetresDriven, PolygonName
		)
		SELECT
			 je.IMEI
			,je.Journey_ID
			,je.EventTimeStamp
			,je.EventOrder
			,je.TimeElapsed
			,je.Latitude
			,je.Longitude
			,je.DistanceFromPrevPosition
			,je.TravelSpeedMPH
			,je.HaversineMetresDriven
			,'Outside British Isles'
		--FROM staging.dbo.PolygonRTJE1 je
		FROM sandbox.dbo.SJ_PolygonRTJE1 je
		INNER JOIN BritishIsles p
			-- Identify foreign driving:
			ON p.Polygon.STIntersects(je.Coordinate) = 0
		;

		INSERT @Log (ScriptStartTime, Query, RowsAffected, QueryFinishTime)
		SELECT
			 @ScriptStartTime
			,'Insert Foreign Driving into staging.dbo.PolygonRTJE2'
			,@@ROWCOUNT
			,SYSDATETIME()
		;

		--CREATE TABLE staging.dbo.PolygonRTJE3 (
		CREATE TABLE sandbox.dbo.SJ_PolygonRTJE3 (
			 IMEI					bigint			NOT NULL
			,Journey_ID				int				NOT NULL
			,PolygonName			varchar(30)		NOT NULL
			,FirstTimeStamp			datetime2(2)		NULL
			,LastTimeStamp			datetime2(2)		NULL
			,FirstLatitude			float(53)		NOT	NULL
			,FirstLongitude			float(53)		NOT	NULL
			,LastLatitude			float(53)		NOT	NULL
			,LastLongitude			float(53)		NOT	NULL
			,HaversineMetres		integer				NULL
			,MetresDriven 			integer				NULL
			,MilesDriven			numeric(9, 5)		NULL
			,SecondsDriven 			integer				NULL
			,MinutesDriven			numeric(9, 4)		NULL
			,MaxSpeedMPH			tinyint				NULL
			,MilesOver70MPH			numeric(9, 5)		NULL
			,SecondsOver70MPH		integer				NULL
			,EventCount				smallint			NULL
			,NightMiles				numeric(9, 5) 		NULL
			,NightMinutes			numeric(9, 5) 		NULL
			,HaversineMetresDriven	integer				NULL
			,AverageSpeedMPH		numeric(9, 4)		NULL
			,DistancePctOfJourney	numeric(9, 8)		NULL
			,TimePctOfJourney		numeric(9, 8)		NULL
			,EventsPctOfJourney		numeric(9, 8)		NULL
		)
		;

		;WITH RowNumbers AS (
			SELECT
				 je.IMEI
				,je.Journey_ID
				-- Alter timestamps during British Summer Time:
				,EventTimeStamp = CASE WHEN bst.StartTime IS NOT NULL THEN DATEADD(HOUR, 1, je.EventTimeStamp) ELSE je.EventTimeStamp END
				,je.EventOrder
				,je.TimeElapsed
				,je.Latitude
				,je.Longitude
				,je.DistanceFromPrevPosition
				,je.TravelSpeedMPH
				,je.HaversineMetresDriven
				,je.PolygonName
				-- To identify journey/polygon start:
				,RowNumAsc 	=
					ROW_NUMBER() OVER (
						PARTITION BY je.IMEI, je.Journey_ID, je.PolygonName
						ORDER BY	 je.EventTimeStamp ASC , je.EventOrder ASC
					)
				-- To identify journey/polygon end:
				,RowNumDesc =
					ROW_NUMBER() OVER (
						PARTITION BY je.IMEI, je.Journey_ID, je.PolygonName
						ORDER BY	 je.EventTimeStamp DESC, je.EventOrder DESC
					)
			--FROM staging.dbo.PolygonRTJE2
			FROM sandbox.dbo.SJ_PolygonRTJE2 je
			LEFT JOIN #BST bst
				ON  je.EventTimeStamp >= bst.StartTime
				AND je.EventTimeStamp <  bst.EndTime
		)
		--INSERT staging.dbo.PolygonRTJE3 (
		INSERT sandbox.dbo.SJ_PolygonRTJE3 WITH (TABLOCK) (
			PolygonName , IMEI         , Journey_ID  , FirstTimeStamp       , LastTimeStamp, FirstLatitude , FirstLongitude  , 
			LastLatitude, LastLongitude, MetresDriven, SecondsDriven        , MaxSpeedMPH  , MilesOver70MPH, SecondsOver70MPH, 
			NightMiles  , NightMinutes , EventCount  , HaversineMetresDriven, MilesDriven  , MinutesDriven , AverageSpeedMPH
		)
		SELECT
			 PolygonName
			,IMEI
			,Journey_ID
			,FirstTimeStamp   	   = MIN(EventTimeStamp)
			,LastTimeStamp    	   = MAX(EventTimeStamp)
			-- Use SUM as dummy aggregate to identify first lat/longs:
			,FirstLatitude    	   = SUM(CASE RowNumAsc  WHEN 1 THEN Latitude  ELSE NULL END)
			,FirstLongitude   	   = SUM(CASE RowNumAsc  WHEN 1 THEN Longitude ELSE NULL END)
			,LastLatitude     	   = SUM(CASE RowNumDesc WHEN 1 THEN Latitude  ELSE NULL END)
			,LastLongitude    	   = SUM(CASE RowNumDesc WHEN 1 THEN Longitude ELSE NULL END)
			,MetresDriven     	   = SUM(DistanceFromPrevPosition)
			,SecondsDriven    	   = SUM(TimeElapsed)
			,MaxSpeedMPH	  	   = MAX(TravelSpeedMPH)
			,MilesOver70MPH   	   = SUM(CASE WHEN TravelSpeedMPH > 70 THEN DistanceFromPrevPosition ELSE 0 END) / 1609.344
			,SecondsOver70MPH 	   = SUM(CASE WHEN TravelSpeedMPH > 70 THEN TimeElapsed              ELSE 0 END)
			-- Night-time driving is considered between 10pm and 4am:
			,NightMiles		  	   = SUM(CASE WHEN ( DATEPART(HOUR, EventTimeStamp) >= 22 OR DATEPART(HOUR, EventTimeStamp) < 4 ) THEN DistanceFromPrevPosition ELSE 0 END) / 1609.344
			,NightMinutes          = SUM(CASE WHEN ( DATEPART(HOUR, EventTimeStamp) >= 22 OR DATEPART(HOUR, EventTimeStamp) < 4 ) THEN TimeElapsed              ELSE 0 END) / 60.0
			,EventCount       	   = COUNT(*)
			,HaversineMetresDriven = SUM(HaversineMetresDriven)
			,MilesDriven 		   = SUM(DistanceFromPrevPosition) / 1609.344
			,MinutesDriven 		   = SUM(TimeElapsed) / 60.0
			-- A different attempt at AverageSpeedMPH:
			,AverageSpeedMPH 	   = ( SUM(DistanceFromPrevPosition) / NULLIF(SUM(TimeElapsed), 0) ) * 2.23694
		FROM RowNumbers
		GROUP BY
			 PolygonName
			,IMEI
			,Journey_ID
		;

		INSERT @Log (ScriptStartTime, Query, RowsAffected, QueryFinishTime)
		SELECT
			 @ScriptStartTime
			,'Insert into staging.dbo.PolygonRTJE3'
			,@@ROWCOUNT
			,SYSDATETIME()
		;

		-- Calculate percentage of journeys in each polygon
		-- should a journey intersect more than one:
		;WITH Journeys AS (
			SELECT
				 IMEI
				,Journey_ID
				,MetresDriven  = SUM(DistanceFromPrevPosition)
				,SecondsDriven = SUM(TimeElapsed)
				,EventCount	   = COUNT(*)
			--FROM staging.dbo.PolygonRTJE1
			FROM sandbox.dbo.SJ_PolygonRTJE1
			GROUP BY
				 IMEI
				,Journey_ID
		)
		UPDATE js
		SET
			 js.DistancePctOfJourney = ( js.MetresDriven  * 1.0 ) / NULLIF(j.MetresDriven , 0)
			,js.TimePctOfJourney     = ( js.SecondsDriven * 1.0 ) / NULLIF(j.SecondsDriven, 0)
			,js.EventsPctOfJourney   = ( js.EventCount    * 1.0 ) / NULLIF(j.EventCount   , 0)
		--FROM staging.dbo.PolygonRTJE3 js
		FROM sandbox.dbo.SJ_PolygonRTJE3 js
		INNER JOIN Journeys j
			ON  js.IMEI       = j.IMEI
			AND js.Journey_ID = j.Journey_ID
		;

		INSERT @Log (ScriptStartTime, Query, RowsAffected, QueryFinishTime)
		SELECT
			 @ScriptStartTime
			,'Update %s in staging.dbo.PolygonRTJE3'
			,@@ROWCOUNT
			,SYSDATETIME()
		;

		-- Haversine distance between first and last point
		-- in each polygon for each journey:
		--UPDATE staging.dbo.PolygonRTJE3
		UPDATE sandbox.dbo.SJ_PolygonRTJE3
			SET HaversineMetres = geography::Point(FirstLatitude, FirstLongitude, 4326).STDistance(geography::Point(LastLatitude, LastLongitude, 4326))
		;

		INSERT @Log (ScriptStartTime, Query, RowsAffected, QueryFinishTime)
		SELECT
			 @ScriptStartTime
			,'Update HaversineMetres in staging.dbo.PolygonRTJE3'
			,@@ROWCOUNT
			,SYSDATETIME()
		;

		INSERT sandbox.dbo.SJ_RedTailPolygonSummary (
			IMEI                 , Journey_ID      , PolygonName         , FirstTimeStamp  , LastTimeStamp     ,
			FirstLatitude        , FirstLongitude  , LastLatitude        , LastLongitude   , HaversineMetres   ,
			MetresDriven         , MilesDriven     , SecondsDriven       , MinutesDriven   , MaxSpeedMPH       ,
			MilesOver70MPH       , SecondsOver70MPH, EventCount          , NightMiles      , NightMinutes      ,
			HaversineMetresDriven, AverageSpeedMPH , DistancePctOfJourney, TimePctOfJourney, EventsPctOfJourney
		)
		SELECT
			 IMEI
			,Journey_ID
			,PolygonName
			,FirstTimeStamp
			,LastTimeStamp
			,FirstLatitude
			,FirstLongitude
			,LastLatitude
			,LastLongitude
			,HaversineMetres
			,MetresDriven
			,MilesDriven
			,SecondsDriven
			,MinutesDriven
			,MaxSpeedMPH
			,MilesOver70MPH
			,SecondsOver70MPH
			,EventCount
			,NightMiles
			,NightMinutes
			,HaversineMetresDriven
			,AverageSpeedMPH
			,DistancePctOfJourney
			,TimePctOfJourney
			,EventsPctOfJourney
		FROM sandbox.dbo.SJ_PolygonRTJE3
		;

		INSERT @Log (ScriptStartTime, Query, RowsAffected, QueryFinishTime)
		SELECT
			 @ScriptStartTime
			,'Insert into DataSummary.dbo.RedTailPolygonSummary'
			,@@ROWCOUNT
			,SYSDATETIME()
		;
		
		-- Persist log results to sandbox
		-- for trouble-shooting purposes:
		IF OBJECT_ID('sandbox.dbo.RedTailPolygonSummary_Log', 'U') IS NULL
		BEGIN

			SELECT
				 ScriptStartTime
				,Query
				,RowsAffected
				,QueryFinishTime
			INTO sandbox.dbo.RedTailPolygonSummary_Log
			FROM @Log
			;

		END
		ELSE
		BEGIN

			INSERT sandbox.dbo.RedTailPolygonSummary_Log (ScriptStartTime, Query, RowsAffected, QueryFinishTime)
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











/*
--CREATE TABLE DataSummary.dbo.RedTailPolygonSummary (
CREATE TABLE sandbox.dbo.SJ_RedTailPolygonSummary (
	 IMEI					bigint			NOT NULL
	,Journey_ID				int				NOT NULL
	,PolygonName			varchar(30)		NOT NULL
	,FirstTimeStamp			datetime2(2)		NULL
	,LastTimeStamp			datetime2(2)		NULL
	,FirstLatitude			float(53)		NOT	NULL
	,FirstLongitude			float(53)		NOT	NULL
	,LastLatitude			float(53)		NOT	NULL
	,LastLongitude			float(53)		NOT	NULL
	,HaversineMetres		int					NULL
	,MetresDriven 			int					NULL
	,MilesDriven			numeric(9, 5)		NULL
	,SecondsDriven 			int					NULL
	,MinutesDriven			numeric(9, 4)		NULL
	,MaxSpeedMPH			tinyint				NULL
	,MilesOver70MPH			numeric(9, 5)		NULL
	,SecondsOver70MPH		int					NULL
	,EventCount				smallint			NULL
	,NightMiles				numeric(9, 5) 		NULL
	,NightMinutes			numeric(9, 5) 		NULL
	,HaversineMetresDriven	int 				NULL
	,AverageSpeedMPH		numeric(9, 4)		NULL
	,DistancePctOfJourney	numeric(9, 8)		NULL
	,TimePctOfJourney		numeric(9, 8)		NULL
	,EventsPctOfJourney		numeric(9, 8)		NULL
	,InsertedDate			date			NOT NULL	CONSTRAINT DF_RedTailPolygonSummary_InsertedDate CURRENT_TIMESTAMP
)
;

CREATE CLUSTERED INDEX IX_RedTailPolygonSummary_IMEIFirstTimeStamp
ON sandbox.dbo.SJ_RedTailPolygonSummary (
	 IMEI 		    ASC
	,FirstTimeStamp ASC
)
;

CREATE NONCLUSTERED INDEX IX_RedTailPolygonSummary_PolygonName 
ON sandbox.dbo.SJ_RedTailPolygonSummary (PolygonName ASC)
;

SELECT *
FROM sandbox.dbo.RedTailPolygonSummary_Log
ORDER BY
	 1 DESC
	,4 ASC
;

SELECT *
FROM sandbox.dbo.SJ_PolygonRTJE3
WHERE PolygonName IN ('Outside British Isles', 'Guernsey', 'Jersey', 'Isle of Man', 'Isle of Wight')
;

SELECT Latitude, Longitude
FROM RedTail.dbo.JourneyEvent
WHERE IMEI = 356917057086626
AND Journey_ID = 92035427
;

SELECT RC = SUM(Rows)
FROM sandbox.sys.partitions
WHERE Object_ID = OBJECT_ID('sandbox.dbo.SJ_RedTailPolygonSummary', 'U')
AND Index_ID = 1
;
*/