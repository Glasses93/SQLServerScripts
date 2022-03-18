
USE sandbox;

SET NOCOUNT    ON;
SET XACT_ABORT ON;
SET DATEFIRST   1;

-- SET STATISTICS IO, TIME ON ;
-- SET STATISTICS IO, TIME OFF;

BEGIN TRY
	IF EXISTS (
		SELECT 1
		FROM staging.dbo.DWJobStatus
		WHERE Supplier = 'RedTail'
			AND CONVERT(date, EndTime) < CONVERT(date, CURRENT_TIMESTAMP)
	)
	BEGIN
		RETURN;
	END
	;

	DECLARE @ScriptStartTime datetime2(7) = SYSDATETIME();

	INSERT sandbox.dbo.SJ_PolyLogs ( ScriptStartTime, Query, RowsAffected, LowerVar, UpperVar )
		VALUES (@ScriptStartTime, 'Start of script', 0, 0, 0)
	;

	DROP TABLE IF EXISTS #BST;

	CREATE TABLE #BST (
		 [Year]		smallint		NOT NULL
		,StartTime	datetime2(0)	NOT NULL
		,EndTime	datetime2(0)	NOT NULL
	)
	;

	DECLARE @Year smallint = 2015;

	WHILE @Year <= YEAR(CURRENT_TIMESTAMP)
	BEGIN

		;WITH LastWeekOfMarch ([Date]) AS (
			SELECT DATETIME2FROMPARTS(@Year, 03, 25, 01, 00, 00, 0, 0)
		
			UNION ALL
		
			SELECT DATEADD(DAY, 1, [Date])
			FROM LastWeekOfMarch
			WHERE MONTH(DATEADD(DAY, 1, [Date])) < 4
		),
		LastWeekOfOctober ([Date]) AS (
			SELECT DATETIME2FROMPARTS(@Year, 10, 25, 01, 00, 00, 0, 0)
		
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
		OPTION ( MAXRECURSION 6 )
		;
	
		SET @Year += 1;

	END
	;

	DECLARE @MaxUpper integer;
	SELECT  @MaxUpper = MAX(ID)
	FROM	sandbox.dbo.SJ_RedTailIMEIs
	;

	DECLARE @Lower integer;
	SELECT	@Lower = MAX(UpperVar) + 1
	FROM	sandbox.dbo.SJ_PolyLogs
	WHERE	Query = 'Final insert'
		AND RowsAffected > 0
	;

	DECLARE @Upper integer = @Lower + 99;

	WHILE @Lower <= @MaxUpper
	BEGIN

		DROP TABLE IF EXISTS sandbox.dbo.SJ_PolygonRTJE1;
		DROP TABLE IF EXISTS sandbox.dbo.SJ_PolygonRTJE2;
		TRUNCATE TABLE       sandbox.dbo.SJ_PolygonRTJE3;

		CREATE TABLE sandbox.dbo.SJ_PolygonRTJE1 (
			 IMEI						bigint			NOT NULL
			,Journey_ID					integer			NOT NULL
			,JourneyEventID				integer			NOT NULL
			,EventOrder					tinyint				NULL
			,EventTimeStamp				datetime2(0)		NULL
			,TimeElapsed				integer				NULL
			,Latitude					float(53)		NOT	NULL
			,Longitude					float(53)		NOT	NULL
			,Coordinate					geography		NOT	NULL
			,DistanceFromPrevPosition	smallint	    	NULL
			,TravelSpeedMPH				tinyint				NULL
			,HaversineMetresDriven		integer				NULL
		)
		;

		;WITH JourneyEvent AS (
			SELECT
				 IMEI
				,Journey_ID
				,EventOrder =
					CASE EventTypeID
						WHEN 1 THEN 1
						WHEN 2 THEN 3
							   ELSE 2
					END
				,EventTimeStamp
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
				,Coordinate               = CASE WHEN Latitude IS NOT NULL AND Longitude IS NOT NULL THEN geography::Point(Latitude, Longitude, 4326) END
				,DistanceFromPrevPosition =	CASE WHEN DistanceFromPrevPosition > 2000 THEN 2000 ELSE DistanceFromPrevPosition END
				,TravelSpeedMPH           = CASE WHEN TravelSpeedMph BETWEEN 0 AND 156 THEN TravelSpeedMph END
			FROM RedTail.dbo.JourneyEvent je
			WHERE EXISTS (
				SELECT 1
				FROM sandbox.dbo.SJ_RedTailIMEIs ri
				WHERE je.IMEI = ri.IMEI
					AND ri.ID BETWEEN @Lower AND @Upper
					--AND ri.RN BETWEEN 1 AND 100
			)
				AND Latitude  IS NOT NULL
				AND Longitude IS NOT NULL
			--WHERE IMEI IS NOT NULL
			--	AND Journey_ID IS NOT NULL
			--	AND Latitude   IS NOT NULL
			--	AND Longitude  IS NOT NULL
			--	AND InsertedOn > '20201101'
		)
		INSERT sandbox.dbo.SJ_PolygonRTJE1 WITH ( TABLOCK ) (
			 IMEI
			,Journey_ID
			,JourneyEventID
			,EventTimeStamp
			,EventOrder
			,TimeElapsed
			,Latitude
			,Longitude
			,Coordinate		
			,DistanceFromPrevPosition
			,TravelSpeedMPH
			,HaversineMetresDriven
		)
		SELECT
			 IMEI
			,Journey_ID
			,JourneyEventID = ROW_NUMBER() OVER (ORDER BY (SELECT NULL))
			,EventTimeStamp
			,EventOrder
			,TimeElapsed
			,Latitude
			,Longitude
			,Coordinate		
			,DistanceFromPrevPosition
			,TravelSpeedMPH
			,HaversineMetresDriven =
				Coordinate.STDistance(
					LAG(Coordinate, 1, NULL) OVER (
						PARTITION BY IMEI, Journey_ID
						ORDER BY	 EventTimeStamp ASC, EventOrder ASC
					)
				)
		FROM JourneyEvent
		OPTION (
			OPTIMIZE FOR (
				 @Lower = 1
				,@Upper = 100
			)
		)
		;
		
		INSERT sandbox.dbo.SJ_PolyLogs ( ScriptStartTime, Query, RowsAffected, LowerVar, UpperVar )
			VALUES (@ScriptStartTime, 'Journey event', @@ROWCOUNT, @Lower, @Upper)
		;

		ALTER TABLE sandbox.dbo.SJ_PolygonRTJE1
		ADD CONSTRAINT PK__SJ_PolygonRTJE1__JourneyEventID PRIMARY KEY CLUSTERED ( JourneyEventID ASC )
		;

		INSERT sandbox.dbo.SJ_PolyLogs ( ScriptStartTime, Query, RowsAffected, LowerVar, UpperVar )
			VALUES (@ScriptStartTime, 'Primary key', @@ROWCOUNT, @Lower, @Upper)
		;

		CREATE SPATIAL INDEX SIX__SJ_PolygonRTJE1__Coordinate
		ON sandbox.dbo.SJ_PolygonRTJE1 ( Coordinate )
		USING GEOGRAPHY_GRID WITH (
			 GRIDS			  = ( LEVEL_1 = HIGH, LEVEL_2 = HIGH, LEVEL_3 = HIGH, LEVEL_4 = HIGH )
			,CELLS_PER_OBJECT = 8192
		)
		;

		INSERT sandbox.dbo.SJ_PolyLogs ( ScriptStartTime, Query, RowsAffected, LowerVar, UpperVar )
			VALUES (@ScriptStartTime, 'Spatial index', @@ROWCOUNT, @Lower, @Upper)
		;

		CREATE TABLE sandbox.dbo.SJ_PolygonRTJE2 (
			 IMEI						bigint			NOT NULL
			,Journey_ID					integer			NOT NULL
			,EventOrder					tinyint				NULL
			,EventTimeStamp				datetime2(0)		NULL
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
			FROM sandbox.dbo.SJ_Polygons
			WHERE Artist = 'ONS - Local Authority Districts (May 2020 Boundaries UK BFE)'
				AND DetailID = 2
				AND PolygonName NOT IN (
					 'Birmingham'
					,'Bristol, City of'
					,'Cardiff'
					,'City of Edinburgh'
					,'Glasgow City'
					,'Isle of Wight'
					,'Leeds'
					,'Leicester'
					,'Liverpool'
					,'Manchester'
					,'Nottingham'
					,'Sheffield'
				)
		)
		INSERT sandbox.dbo.SJ_PolygonRTJE2 WITH ( TABLOCK ) (
			 IMEI
			,Journey_ID
			,EventTimeStamp
			,EventOrder
			,TimeElapsed
			,Latitude
			,Longitude
			,DistanceFromPrevPosition
			,TravelSpeedMPH
			,HaversineMetresDriven
			,PolygonName
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
		FROM sandbox.dbo.SJ_PolygonRTJE1 je
		INNER JOIN Polygons p
			ON p.Polygon.STIntersects(je.Coordinate) = 1
		;

		INSERT sandbox.dbo.SJ_PolyLogs ( ScriptStartTime, Query, RowsAffected, LowerVar, UpperVar )
			VALUES (@ScriptStartTime, 'Polygons', @@ROWCOUNT, @Lower, @Upper)
		;

		;WITH x AS (
			SELECT
				 je.IMEI
				,je.Journey_ID
				,EventTimeStamp = CASE WHEN bst.StartTime IS NOT NULL THEN DATEADD(HOUR, 1, je.EventTimeStamp) ELSE je.EventTimeStamp END
				,je.EventOrder
				,je.TimeElapsed
				,je.Latitude
				,je.Longitude
				,je.DistanceFromPrevPosition
				,je.TravelSpeedMPH
				,je.HaversineMetresDriven
				,je.PolygonName
				,RowNumAsc 	=
					ROW_NUMBER() OVER (
						PARTITION BY je.IMEI, je.Journey_ID, je.PolygonName
						ORDER BY	 je.EventTimeStamp ASC , je.EventOrder ASC
					)
				,RowNumDesc =
					ROW_NUMBER() OVER (
						PARTITION BY je.IMEI, je.Journey_ID, je.PolygonName
						ORDER BY	 je.EventTimeStamp DESC, je.EventOrder DESC
					)
			FROM sandbox.dbo.SJ_PolygonRTJE2 je
			LEFT JOIN #BST bst
				ON  je.EventTimeStamp >= bst.StartTime
				AND je.EventTimeStamp <  bst.EndTime
		),
		y AS (
			SELECT
				 PolygonName
				,IMEI
				,Journey_ID
				,FirstTimeStamp   	   = MIN(EventTimeStamp)
				,LastTimeStamp    	   = MAX(EventTimeStamp)
				,FirstLatitude    	   = SUM(CASE RowNumAsc  WHEN 1 THEN Latitude  END)
				,FirstLongitude   	   = SUM(CASE RowNumAsc  WHEN 1 THEN Longitude END)
				,LastLatitude     	   = SUM(CASE RowNumDesc WHEN 1 THEN Latitude  END)
				,LastLongitude    	   = SUM(CASE RowNumDesc WHEN 1 THEN Longitude END)
				,MetresDriven     	   = SUM(DistanceFromPrevPosition)
				,SecondsDriven    	   = SUM(TimeElapsed)
				,MaxSpeedMPH	  	   = MAX(TravelSpeedMPH)
				,MilesOver70MPH   	   = SUM(CASE WHEN TravelSpeedMPH > 70 THEN DistanceFromPrevPosition ELSE 0 END) / 1609.344
				,SecondsOver70MPH 	   = SUM(CASE WHEN TravelSpeedMPH > 70 THEN TimeElapsed              ELSE 0 END)
				,NightMiles		  	   = SUM(CASE WHEN ( DATEPART(HOUR, EventTimeStamp) >= 22 OR DATEPART(HOUR, EventTimeStamp) < 4 ) THEN DistanceFromPrevPosition ELSE 0 END) / 1609.344
				,NightMinutes          = SUM(CASE WHEN ( DATEPART(HOUR, EventTimeStamp) >= 22 OR DATEPART(HOUR, EventTimeStamp) < 4 ) THEN TimeElapsed              ELSE 0 END) / 60.0
				,EventCount       	   = COUNT(*)
				,HaversineMetresDriven = SUM(HaversineMetresDriven)
				,MilesDriven 		   = SUM(DistanceFromPrevPosition) / 1609.344
				,MinutesDriven 		   = SUM(TimeElapsed) / 60.0
				,AverageSpeedMPH 	   = ( SUM(DistanceFromPrevPosition) / NULLIF(SUM(TimeElapsed), 0) ) / 0.44704
			FROM x
			GROUP BY
				 PolygonName
				,IMEI
				,Journey_ID
		)
		INSERT sandbox.dbo.SJ_PolygonRTJE3 WITH ( TABLOCK ) (
			 PolygonName
			,IMEI
			,Journey_ID
			,FirstTimeStamp
			,LastTimeStamp
			,FirstLatitude
			,FirstLongitude
			,LastLatitude
			,LastLongitude
			,MetresDriven
			,SecondsDriven
			,MaxSpeedMPH
			,MilesOver70MPH
			,SecondsOver70MPH
			,NightMiles
			,NightMinutes
			,EventCount
			,HaversineMetresDriven
			,MilesDriven
			,MinutesDriven
			,AverageSpeedMPH
			,HaversineMetres
		)
		SELECT
			 PolygonName
			,IMEI
			,Journey_ID
			,FirstTimeStamp
			,LastTimeStamp
			,FirstLatitude
			,FirstLongitude
			,LastLatitude
			,LastLongitude
			,MetresDriven
			,SecondsDriven
			,MaxSpeedMPH
			,MilesOver70MPH
			,SecondsOver70MPH
			,NightMiles
			,NightMinutes
			,EventCount
			,HaversineMetresDriven
			,MilesDriven
			,MinutesDriven
			,AverageSpeedMPH
			,HaversineMetres = geography::Point(FirstLatitude, FirstLongitude, 4326).STDistance(geography::Point(LastLatitude, LastLongitude, 4326))
		FROM y
		;

		INSERT sandbox.dbo.SJ_PolyLogs ( ScriptStartTime, Query, RowsAffected, LowerVar, UpperVar )
			VALUES (@ScriptStartTime, 'Aggregate', @@ROWCOUNT, @Lower, @Upper)
		;

		INSERT sandbox.dbo.SJ_RedTailPolygons WITH ( TABLOCK ) (
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
		FROM sandbox.dbo.SJ_PolygonRTJE3
		;

		INSERT sandbox.dbo.SJ_PolyLogs ( ScriptStartTime, Query, RowsAffected, LowerVar, UpperVar )
			VALUES (@ScriptStartTime, 'Final insert', @@ROWCOUNT, @Lower, @Upper)
		;

		IF CONVERT(time, CURRENT_TIMESTAMP) BETWEEN '03:00:00' AND '08:00:00'
		BEGIN
			PRINT 'Timeout at Lower: ' + RTRIM(@Lower) + ' and Upper: ' + RTRIM(@Upper) + '.';
			BREAK;
		END
		;

		SET @Lower += 100;
		SET @Upper  = @Lower + 99;

	END
	;
END TRY
BEGIN CATCH
	;THROW;
END CATCH
;

/*
--DROP TABLE sandbox.dbo.SJ_PolygonRTJE3;
CREATE TABLE sandbox.dbo.SJ_PolygonRTJE3 (
	 IMEI					bigint			NOT NULL
	,Journey_ID				integer			NOT NULL
	,PolygonName			varchar(30)		NOT NULL
	,FirstTimeStamp			datetime2(0)		NULL
	,LastTimeStamp			datetime2(0)		NULL
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
)
;

CREATE TABLE sandbox.dbo.SJ_RedTailPolygons (
	 IMEI					bigint			NOT NULL
	,Journey_ID				integer			NOT NULL
	,PolygonName			varchar(30)		NOT NULL
	,FirstTimeStamp			datetime2(0)		NULL
	,LastTimeStamp			datetime2(0)		NULL
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
)
;

--DROP TABLE sandbox.dbo.SJ_RedTailIMEIs;
--CREATE TABLE sandbox.dbo.SJ_RedTailIMEIs (
--	 ID		integer		NOT NULL IDENTITY(1, 1)
--	,IMEI	bigint		NOT NULL

--	,CONSTRAINT PK__SJ_RedTailIMEIs__IDIMEI PRIMARY KEY CLUSTERED (
--		 ID   ASC
--		,IMEI ASC
--	 )
--	)
--;

--INSERT sandbox.dbo.SJ_RedTailIMEIs ( IMEI )
--SELECT DISTINCT IMEI
--FROM RedTail.dbo.Association
--WHERE IMEI IS NOT NULL
--;

--CREATE TABLE sandbox.dbo.SJ_PolyLogs (
--	 ScriptStartTime	datetime2(7)	NOT NULL
--	,Query				varchar(40)		NOT NULL
--	,QueryEndTime		datetime2(7)	NOT NULL CONSTRAINT DF__SJ_PolyLogs__QueryEndTime DEFAULT SYSDATETIME()
--	,RowsAffected		integer			NOT NULL
--	,LowerVar			integer			NOT NULL
--	,UpperVar			integer			NOT NULL
--)
--;

--CREATE TRIGGER dbo.TR__DML__SJ_RedTailPolygons
--ON dbo.SJ_RedTailPolygons
--INSTEAD OF INSERT, UPDATE, DELETE
--AS

--PRINT 'No can do.';

*/