CREATE OR ALTER PROCEDURE dbo.SJ_Parking
	 @TVP   dbo.SJ_ParkingType READONLY
	,@Debug bit = 0
AS
BEGIN

SET NOCOUNT    ON;
SET XACT_ABORT ON;

BEGIN TRY

IF (
		EXISTS (
			SELECT 1
			FROM staging.dbo.DWJobStatus
			WHERE CONVERT(date, EndTime) < CONVERT(date, CURRENT_TIMESTAMP)
		)
	OR	CONVERT(time, CURRENT_TIMESTAMP) BETWEEN '01:00:00' AND '08:00:00'		
)
BEGIN
	PRINT 'The ETL is not yet complete.';
	RETURN;
END
;

IF (
	SELECT COUNT(*)
	FROM @TVP
) > 25
BEGIN
	PRINT
		'This procedure will not process more than 25 entries in one run due to potential slow performance.' + CHAR(10) +
		'Consider breaking up the list into smaller batches.'
	;
	RETURN;
END
;

IF @Debug = 1
BEGIN
	CREATE TABLE #LogTbl (
		 StartTime			datetime2(7)	NOT NULL
		,Query				varchar(50)		NOT NULL
		,QueryFinishTime	datetime2(7)	NOT NULL
	)
	;
END
;

CREATE TABLE #Journeys (
	 [Telematics Supplier]					varchar(15)		NOT NULL
	,[Guidewire Policy Number] 				varchar(20)		NOT NULL
	,[From Date (inclusive)]				date		    NOT NULL
	,[To Date (exclusive)] 					date		    NOT NULL
	,[Miles Radius]							decimal(9, 7)	NOT NULL
	,[# Requested Parking Locations]		tinyint			NOT NULL
	,[Overnight Parking Only (10pm-4am)]	varchar(3)		NOT NULL 
	,StartTime								datetime2(0)	NOT NULL
	,EndTime								datetime2(0)	NOT NULL
	,[Parked Latitude]						decimal(9, 7)	NOT NULL
	,[Parked Longitude]						decimal(9, 6)	NOT NULL
	,NextStartTime							datetime2(2)	    NULL
	,SecondsParked							integer			NOT NULL
)
;

CREATE TABLE #ParkingBase (
	 [Telematics Supplier]					varchar(15)		NOT NULL
	,[Guidewire Policy Number] 				varchar(20)		NOT NULL
	,[From Date (inclusive)]				date		    NOT NULL
	,[To Date (exclusive)] 					date		    NOT NULL
	,[Miles Radius]							decimal(9, 7)	NOT NULL
	,[# Requested Parking Locations]		tinyint			NOT NULL
	,[Overnight Parking Only (10pm-4am)]	varchar(3)		NOT NULL
	,[Parked Latitude]						decimal(9, 7)	NOT NULL
	,[Parked Longitude]						decimal(9, 6)	NOT NULL
	,TimesParked							smallint		NOT NULL
	,SecondsParked							integer			NOT NULL
	,TotalSecondsParked						integer			NOT NULL
	,ParkedLocation							geography		NOT NULL
)
;

IF EXISTS (
	SELECT 1
	FROM @TVP
	WHERE [Overnight Parking Only (10pm-4am)] = 'Yes'
)
BEGIN
	DECLARE @Now      date    = CURRENT_TIMESTAMP;
	DECLARE @DaysDiff integer = DATEDIFF(DAY, '20100101', @Now) + 1;

	;WITH n(s, e) AS (
		SELECT TOP (@DaysDiff)
			 CONVERT(datetime2(0), DATEADD(
				 DAY
				,ROW_NUMBER() OVER (ORDER BY ac1.[object_id] ASC) - 1
				,'2014-01-01T22:00:00'
			 ))
			,CONVERT(datetime2(0), DATEADD(
				 DAY
				,ROW_NUMBER() OVER (ORDER BY ac1.[object_id] ASC) - 1
				,'2014-01-02T04:00:00'
			 ))
		FROM staging.sys.all_columns ac1
		CROSS JOIN staging.sys.all_columns ac2
		ORDER BY ac1.[object_id] ASC
	)
	SELECT *
	INTO #TenToFour
	FROM n
	;
END
;

DECLARE @SQL nvarchar(max) = N'
DECLARE @StartTime datetime2(7) = SYSDATETIME();

IF @Debug = 1
BEGIN
	INSERT #LogTbl (StartTime, Query, QueryFinishTime)
		VALUES (@StartTime, ''Into #TenToFour'', SYSDATETIME())
	;
END
;
'
;

IF EXISTS (
	SELECT 1
	FROM @TVP
	WHERE [Telematics Supplier] = 'Vodafone'
)
BEGIN

DECLARE @VodafoneCOVID nchar(1);
SELECT  @VodafoneCOVID =
	CASE WHEN EXISTS (
		SELECT 1
		FROM @TVP
		WHERE [Telematics Supplier]      = 'Vodafone'
			AND [From Date (inclusive)] <  '20200711'
			AND [To Date (exclusive)]   >= '20200316'
	)
	THEN N'1' ELSE N'2' END
;

SELECT @SQL += N'
;WITH t AS (
	SELECT TripID
	FROM Vodafone.dbo.Trip t
	WHERE EXISTS (
		SELECT 1
		FROM @TVP pt
		WHERE t.ExternalContractNumber = CONVERT(nvarchar(20), pt.[Guidewire Policy Number])
			AND pt.[Telematics Supplier] = ''Vodafone''
	)
),
j AS (
	SELECT
		 pt.*
		,StartTime		    = vj.starttime
		,EndTime            = vj.endtime
		,[Parked Latitude]  = CONVERT(decimal(9, 6), vj.end_lat )
		,[Parked Longitude] = CONVERT(decimal(9, 6), vj.end_long)
	FROM DataSummary.dbo.VodaJourneys vj
	INNER JOIN @TVP pt
		ON  vj.PolicyNumber          = pt.[Guidewire Policy Number]
		AND vj.startdate            >= pt.[From Date (inclusive)]
		AND vj.startdate            <  pt.[To Date (exclusive)]
		AND pt.[Telematics Supplier] = ''Vodafone''
	WHERE EXISTS (
		SELECT 1
		FROM t
		WHERE vj.Journey_ID = CONVERT(varchar(50), t.TripID)
	)

	UNION ALL

	SELECT 
		 pt.*
		,StartTime		    = vjc.starttime
		,EndTime            = vjc.endtime
		,[Parked Latitude]  = CONVERT(decimal(9, 6), vjc.end_lat )
		,[Parked Longitude] = CONVERT(decimal(9, 6), vjc.end_long)
	FROM DataSummary.dbo.VodaJourneys_COVID vjc
	INNER JOIN @TVP pt
		ON  vjc.PolicyNumber         = pt.[Guidewire Policy Number]
		AND vjc.startdate           >= pt.[From Date (inclusive)]
		AND vjc.startdate           <  pt.[To Date (exclusive)]
		AND pt.[Telematics Supplier] = ''Vodafone''
		AND 1                        = ' + @VodafoneCOVID + N'
)
INSERT #Journeys (
	[Telematics Supplier]		   , [Guidewire Policy Number]          , [From Date (inclusive)], [To Date (exclusive)], [Miles Radius]   ,
	[# Requested Parking Locations], [Overnight Parking Only (10pm-4am)], StartTime				 , EndTime              , [Parked Latitude],
	[Parked Longitude]			   , NextStartTime						, SecondsParked
)
SELECT
	 *
	,NextStartTime =
		LEAD(StartTime, 1, NULL) OVER (
			PARTITION BY
				[Guidewire Policy Number], [From Date (inclusive)]            , [To Date (exclusive)],
				[Miles Radius]           , [Overnight Parking Only (10pm-4am)]
			ORDER BY EndTime ASC
		)
	,SecondsParked =
		COALESCE(DATEDIFF(
			 SECOND
			,EndTime
			,LEAD(StartTime, 1, NULL) OVER (
				PARTITION BY
					[Guidewire Policy Number], [From Date (inclusive)]            , [To Date (exclusive)],
					[Miles Radius]           , [Overnight Parking Only (10pm-4am)]
				ORDER BY EndTime ASC
			 )
		), 0)
FROM j
WHERE [Parked Latitude] IS NOT NULL
	AND [Parked Longitude] IS NOT NULL
OPTION ( RECOMPILE )
;

IF @Debug = 1
BEGIN
	INSERT #LogTbl (StartTime, Query, QueryFinishTime)
		VALUES (@StartTime, ''Insert VF #Journeys'', SYSDATETIME())
	;
END
;
'
;

END
;

IF EXISTS (
	SELECT 1
	FROM @TVP
	WHERE [Telematics Supplier] = 'RedTail'
)
BEGIN

DECLARE @RedTailCOVID nchar(1);
SELECT  @RedTailCOVID =
	CASE WHEN EXISTS (
		SELECT 1
		FROM @TVP
		WHERE [Telematics Supplier]      = 'RedTail'
			AND [From Date (inclusive)] <  '20200612'
			AND [To Date (exclusive)]   >= '20200316'
	)
	THEN N'1' ELSE N'2' END
;

SELECT @SQL += N'
SELECT DISTINCT
	 PolicyNumber
	,IMEI      = CONVERT(bigint  , IMEI     )
	,StartDate = CONVERT(datetime, StartDate)
	,EndDate   = CONVERT(datetime, ISNULL(EndDate, DATEADD(DAY, 1, CURRENT_TIMESTAMP)))
INTO #Association
FROM RedTail.dbo.Association a
WHERE EXISTS (
	SELECT 1
	FROM @TVP pt
	WHERE a.PolicyNumber = pt.[Guidewire Policy Number]
		AND pt.[Telematics Supplier] = ''RedTail''
)
;

;WITH j AS (
	SELECT
		 pt.*
		,StartTime		    = rj.starttime
		,EndTime            = rj.endtime
		,[Parked Latitude]  = CONVERT(decimal(9, 6), rj.end_latitude )
		,[Parked Longitude] = CONVERT(decimal(9, 6), rj.end_longitude)
	FROM DataSummary.dbo.RedTailJourneys rj
	INNER JOIN #Association a
		ON  rj.IMEI = a.IMEI
		AND rj.starttime >= a.StartDate
		AND rj.starttime <  a.EndDate
	INNER JOIN @TVP pt
		ON  a.PolicyNumber           = pt.[Guidewire Policy Number]
		AND rj.starttime            >= pt.[From Date (inclusive)]
		AND rj.starttime            <  pt.[To Date (exclusive)]
		AND pt.[Telematics Supplier] = ''RedTail''

	UNION ALL

	SELECT 
		 pt.*
		,StartTime		    = rjc.starttime
		,EndTime            = rjc.endtime
		,[Parked Latitude]  = CONVERT(decimal(9, 6), rjc.end_latitude )
		,[Parked Longitude] = CONVERT(decimal(9, 6), rjc.end_longitude)
	FROM DataSummary.dbo.RedTailJourneys_COVID rjc
	INNER JOIN #Association a
		ON  rjc.IMEI       = a.IMEI
		AND rjc.starttime >= a.StartDate
		AND rjc.starttime <  a.EndDate
	INNER JOIN @TVP pt
		ON  a.PolicyNumber           = pt.[Guidewire Policy Number]
		AND rjc.starttime           >= pt.[From Date (inclusive)]
		AND rjc.starttime           <  pt.[To Date (exclusive)]
		AND pt.[Telematics Supplier] = ''RedTail''
		AND 1                        = ' + @RedTailCOVID + N'
)
INSERT #Journeys (
	[Telematics Supplier]		   , [Guidewire Policy Number]          , [From Date (inclusive)], [To Date (exclusive)], [Miles Radius]   ,
	[# Requested Parking Locations], [Overnight Parking Only (10pm-4am)], StartTime				 , EndTime              , [Parked Latitude],
	[Parked Longitude]			   , NextStartTime						, SecondsParked
)
SELECT
	 *
	,NextStartTime =
		LEAD(StartTime, 1, NULL) OVER (
			PARTITION BY
				[Guidewire Policy Number], [From Date (inclusive)]            , [To Date (exclusive)],
				[Miles Radius]           , [Overnight Parking Only (10pm-4am)]
			ORDER BY EndTime ASC
		)
	,SecondsParked =
		COALESCE(DATEDIFF(
			 SECOND
			,EndTime
			,LEAD(StartTime, 1, NULL) OVER (
				PARTITION BY
					[Guidewire Policy Number], [From Date (inclusive)]            , [To Date (exclusive)],
					[Miles Radius]           , [Overnight Parking Only (10pm-4am)]
				ORDER BY EndTime ASC
			 )
		), 0)
FROM j
WHERE [Parked Latitude] IS NOT NULL
	AND [Parked Longitude] IS NOT NULL
OPTION ( RECOMPILE )
;

IF @Debug = 1
BEGIN
	INSERT #LogTbl (StartTime, Query, QueryFinishTime)
		VALUES (@StartTime, ''Insert RT #Journeys'', SYSDATETIME())
	;
END
;
'
;

END
;

IF EXISTS (
	SELECT 1
	FROM @TVP
	WHERE [Overnight Parking Only (10pm-4am)] = 'No'
)
BEGIN

SELECT @SQL += N'
;WITH p AS (
	SELECT
		 [Telematics Supplier]
		,[Guidewire Policy Number]
		,[From Date (inclusive)]
		,[To Date (exclusive)]
		,[Miles Radius]
		,[# Requested Parking Locations]
		,[Overnight Parking Only (10pm-4am)]
		,[Parked Latitude]
		,[Parked Longitude]
		,TimesParked        = COUNT(*)
		,SecondsParked      = SUM(SecondsParked)
		,TotalSecondsParked =
			SUM(SUM(SecondsParked)) OVER (
				PARTITION BY [Guidewire Policy Number], [From Date (inclusive)], [To Date (exclusive)], [Miles Radius]
			)
	FROM #Journeys
	WHERE [Overnight Parking Only (10pm-4am)] = ''No''
	GROUP BY
		 [Telematics Supplier]
		,[Guidewire Policy Number]
		,[From Date (inclusive)]
		,[To Date (exclusive)]
		,[Miles Radius]
		,[# Requested Parking Locations]
		,[Overnight Parking Only (10pm-4am)]
		,[Parked Latitude]
		,[Parked Longitude]
)
INSERT #ParkingBase (
	[Telematics Supplier], [Guidewire Policy Number]      , [From Date (inclusive)]            , [To Date (exclusive)],
	[Miles Radius]       , [# Requested Parking Locations], [Overnight Parking Only (10pm-4am)], [Parked Latitude]    ,
	[Parked Longitude]   , TimesParked                    , SecondsParked                      , TotalSecondsParked   ,
	ParkedLocation
)
SELECT
	 *
	,ParkedLocation = geography::Point([Parked Latitude], [Parked Longitude], 4326)
FROM p
--OPTION ( RECOMPILE )
;

IF @Debug = 1
BEGIN
	INSERT #LogTbl (StartTime, Query, QueryFinishTime)
		VALUES (@StartTime, ''Insert All #ParkingBase'', SYSDATETIME())
	;
END
;
'
;

END
;

IF EXISTS (
	SELECT 1
	FROM @TVP
	WHERE [Overnight Parking Only (10pm-4am)] = 'Yes'
)
BEGIN

SELECT @SQL += N'
;WITH op AS (
	SELECT
		 j.[Telematics Supplier]
		,j.[Guidewire Policy Number]
		,j.[From Date (inclusive)]
		,j.[To Date (exclusive)]
		,j.[Miles Radius]
		,j.[# Requested Parking Locations]
		,j.[Overnight Parking Only (10pm-4am)]
		,j.[Parked Latitude]
		,j.[Parked Longitude]
		,TimesParked   = COUNT(DISTINCT j.EndTime)
		,SecondsParked =
			COALESCE(SUM(
				CASE
					WHEN j.EndTime >= ttf.s AND j.NextStartTime <  ttf.e
						THEN DATEDIFF(SECOND, j.EndTime, j.NextStartTime)
					WHEN j.EndTime <  ttf.s AND j.NextStartTime >= ttf.e
						THEN 21600
					WHEN j.EndTime <  ttf.s and j.NextStartTime >= ttf.s AND j.NextStartTime < ttf.e
						THEN
							DATEDIFF(
								 SECOND
								,DATETIME2FROMPARTS(
									 YEAR (ttf.s)
									,MONTH(ttf.s)
									,DAY  (ttf.s)
									,22
									,00
									,00
									,00
									,2
								 )
								,j.NextStartTime
							)
					WHEN j.EndTime >= ttf.s AND j.EndTime <  ttf.e AND j.NextStartTime >= ttf.e
						THEN
							DATEDIFF(
								 SECOND
								,j.EndTime 
								,DATETIME2FROMPARTS(
									 YEAR (ttf.e)
									,MONTH(ttf.e)
									,DAY  (ttf.e)
									,04
									,00
									,00
									,00
									,2
								 )
							)
				END
			), 0)
	FROM #Journeys j
	INNER JOIN #TenToFour ttf
		ON (
				( j.EndTime >= ttf.s AND j.NextStartTime <  ttf.e                             )
			OR	( j.EndTime <  ttf.s AND j.NextStartTime >= ttf.e                             )
			OR  ( j.EndTime <  ttf.s AND j.NextStartTime >= ttf.s AND j.NextStartTime < ttf.e )
			OR  ( j.EndTime >= ttf.s AND j.EndTime       <  ttf.e AND j.NextStartTime > ttf.e )
		)
		AND j.[Overnight Parking Only (10pm-4am)] = ''Yes''
	GROUP BY
		 j.[Telematics Supplier]
		,j.[Guidewire Policy Number]
		,j.[From Date (inclusive)]
		,j.[To Date (exclusive)]
		,j.[Miles Radius]
		,j.[# Requested Parking Locations]
		,j.[Overnight Parking Only (10pm-4am)]
		,j.[Parked Latitude]
		,j.[Parked Longitude]
)
INSERT #ParkingBase (
	[Telematics Supplier], [Guidewire Policy Number]      , [From Date (inclusive)]            , [To Date (exclusive)],
	[Miles Radius]       , [# Requested Parking Locations], [Overnight Parking Only (10pm-4am)], [Parked Latitude]    ,
	[Parked Longitude]   , TimesParked                    , SecondsParked                      , TotalSecondsParked   ,
	ParkedLocation
)
SELECT
	 *
	,TotalSecondsParked =
		SUM(SecondsParked) OVER (
			PARTITION BY [Guidewire Policy Number], [From Date (inclusive)], [To Date (exclusive)], [Miles Radius]
		)
	,ParkedLocation = geography::Point([Parked Latitude], [Parked Longitude], 4326)
FROM op
--OPTION ( RECOMPILE )
;

IF @Debug = 1
BEGIN
	INSERT #LogTbl (StartTime, Query, QueryFinishTime)
		VALUES (@StartTime, ''Insert Overnight #ParkingBase'', SYSDATETIME())
	;
END
;
'
;

END
;

SELECT @SQL += N'
ALTER TABLE #ParkingBase
ADD CONSTRAINT PK_ParkingBase_PolicyNumberFromDateToDateMilesRadiusOvernightLatitudeLongitude PRIMARY KEY CLUSTERED (
	 [Guidewire Policy Number]			 ASC
	,[From Date (inclusive)]			 ASC
	,[To Date (exclusive)]				 ASC
	,[Miles Radius]						 ASC
	,[Overnight Parking Only (10pm-4am)] ASC
	,[Parked Latitude]					 ASC
	,[Parked Longitude]					 ASC
)
;

CREATE SPATIAL INDEX IX_ParkingBase_ParkedLocation ON #ParkingBase ( ParkedLocation );

;WITH pr AS (
	SELECT
		 pb1.[Telematics Supplier]
		,pb1.[Guidewire Policy Number]
		,pb1.[From Date (inclusive)]
		,pb1.[To Date (exclusive)]
		,pb1.[Miles Radius]
		,pb1.[# Requested Parking Locations]
		,pb1.[Overnight Parking Only (10pm-4am)]
		,pb1.[Parked Latitude]
		,pb1.[Parked Longitude]
		,[Times Parked Within "Miles Radius"] = SUM(pb2.TimesParked)
		,SecondsParkedWithinMilesRadius       = SUM(pb2.SecondsParked)
		,[% Parked Within "Miles Radius"]     = ( SUM(pb2.SecondsParked * 100.0) / NULLIF(MAX(pb1.TotalSecondsParked), 0) )
		,TotalSecondsParked					  = MAX(pb1.TotalSecondsParked)
	FROM #ParkingBase pb1
	INNER JOIN #ParkingBase pb2
		ON  pb1.[Guidewire Policy Number]					   = pb2.[Guidewire Policy Number]
		AND pb1.[From Date (inclusive)]						   = pb2.[From Date (inclusive)]
		AND pb1.[To Date (exclusive)]				           = pb2.[To Date (exclusive)]
		AND pb1.[Miles Radius]								   = pb2.[Miles Radius]
		AND pb1.[Overnight Parking Only (10pm-4am)]            = pb2.[Overnight Parking Only (10pm-4am)]
		AND	pb1.ParkedLocation.STDistance(pb2.ParkedLocation) <= ( pb1.[Miles Radius] * 1609.344 )
	GROUP BY
		 pb1.[Telematics Supplier]
		,pb1.[Guidewire Policy Number]
		,pb1.[From Date (inclusive)]
		,pb1.[To Date (exclusive)]
		,pb1.[Miles Radius]
		,pb1.[# Requested Parking Locations]
		,pb1.[Overnight Parking Only (10pm-4am)]
		,pb1.[Parked Latitude]
		,pb1.[Parked Longitude]
)
SELECT
	 pr.*
	,pb.ParkedLocation
INTO #ParkingRadius
FROM pr
INNER JOIN #ParkingBase pb
	ON  pr.[Guidewire Policy Number]		   = pb.[Guidewire Policy Number]
	AND pr.[From Date (inclusive)]			   = pb.[From Date (inclusive)]
	AND pr.[To Date (exclusive)]			   = pb.[To Date (exclusive)]
	AND pr.[Miles Radius]					   = pb.[Miles Radius]
	AND pr.[Overnight Parking Only (10pm-4am)] = pb.[Overnight Parking Only (10pm-4am)]
	AND pr.[Parked Latitude]                   = pb.[Parked Latitude]
	AND pr.[Parked Longitude]                  = pb.[Parked Longitude]
OPTION ( RECOMPILE )
;

IF @Debug = 1
BEGIN
	INSERT #LogTbl (StartTime, Query, QueryFinishTime)
		VALUES (@StartTime, ''Into #ParkingRadius'', SYSDATETIME())
	;
END
;

;WITH cp AS (
	SELECT
		 pr1.[Telematics Supplier]
		,pr1.[Guidewire Policy Number]
		,pr1.[From Date (inclusive)]
		,pr1.[To Date (exclusive)]
		,pr1.[Miles Radius]
		,pr1.[# Requested Parking Locations]
		,pr1.[Overnight Parking Only (10pm-4am)]
		,pr1.[Parked Latitude]
		,pr1.[Parked Longitude]
		,pr1.[Times Parked Within "Miles Radius"]
		,pr1.SecondsParkedWithinMilesRadius
		,pr1.[% Parked Within "Miles Radius"]
		,pr1.TotalSecondsParked
		,ShortestDistanceRN =
			ROW_NUMBER() OVER (
				PARTITION BY
					pr1.[Guidewire Policy Number], pr1.[From Date (inclusive)]            , pr1.[To Date (exclusive)]         ,
					pr1.[Miles Radius]			 , pr1.[Overnight Parking Only (10pm-4am)], pr1.SecondsParkedWithinMilesRadius
				ORDER BY SUM(pr1.ParkedLocation.STDistance(pr2.ParkedLocation)) ASC
			)
	FROM #ParkingRadius pr1
	INNER JOIN #ParkingRadius pr2
		ON  pr1.[Guidewire Policy Number]			= pr2.[Guidewire Policy Number]
		AND pr1.[From Date (inclusive)]				= pr2.[From Date (inclusive)]
		AND pr1.[To Date (exclusive)]				= pr2.[To Date (exclusive)]
		AND pr1.[Miles Radius]						= pr2.[Miles Radius]
		AND pr1.[Overnight Parking Only (10pm-4am)] = pr2.[Overnight Parking Only (10pm-4am)]
		AND pr1.SecondsParkedWithinMilesRadius	    = pr2.SecondsParkedWithinMilesRadius
	GROUP BY
		 pr1.[Telematics Supplier]
		,pr1.[Guidewire Policy Number]
		,pr1.[From Date (inclusive)]
		,pr1.[To Date (exclusive)]
		,pr1.[Miles Radius]
		,pr1.[# Requested Parking Locations]
		,pr1.[Overnight Parking Only (10pm-4am)]
		,pr1.[Parked Latitude]
		,pr1.[Parked Longitude]
		,pr1.[Times Parked Within "Miles Radius"]
		,pr1.SecondsParkedWithinMilesRadius
		,pr1.[% Parked Within "Miles Radius"]
		,pr1.TotalSecondsParked
)
SELECT
	 cp.*
	,ParkingRank = 
		ROW_NUMBER() OVER (
			PARTITION BY
				cp.[Guidewire Policy Number], cp.[From Date (inclusive)]            , cp.[To Date (exclusive)],
				cp.[Miles Radius]			, cp.[Overnight Parking Only (10pm-4am)]
			ORDER BY cp.SecondsParkedWithinMilesRadius DESC
		)
	,pb.ParkedLocation
INTO #CentralPoint
FROM cp
INNER JOIN #ParkingBase pb
	ON  cp.[Guidewire Policy Number]		   = pb.[Guidewire Policy Number]
	AND cp.[From Date (inclusive)]			   = pb.[From Date (inclusive)]
	AND cp.[To Date (exclusive)]			   = pb.[To Date (exclusive)]
	AND cp.[Miles Radius]					   = pb.[Miles Radius]
	AND cp.[Overnight Parking Only (10pm-4am)] = pb.[Overnight Parking Only (10pm-4am)]
	AND cp.[Parked Latitude]                   = pb.[Parked Latitude]
	AND cp.[Parked Longitude]                  = pb.[Parked Longitude]
	AND cp.ShortestDistanceRN = 1
OPTION ( RECOMPILE )
;

IF @Debug = 1
BEGIN
	INSERT #LogTbl (StartTime, Query, QueryFinishTime)
		VALUES (@StartTime, ''Into #CentralPoint'', SYSDATETIME())
	;
END
;

CREATE CLUSTERED INDEX IX_CentralPoint_ParkingRankPolicyNumberOvernightParking ON #CentralPoint (
	 ParkingRank						 ASC
	,[Guidewire Policy Number]			 ASC
	,[Overnight Parking Only (10pm-4am)] ASC
)
;

;WITH rec AS (
	SELECT
		 [Telematics Supplier]
		,[Guidewire Policy Number]
		,[From Date (inclusive)]
		,[To Date (exclusive)]
		,[Miles Radius]
		,[# Requested Parking Locations]
		,[Overnight Parking Only (10pm-4am)]
		,[Parked Latitude]
		,[Parked Longitude]
		,ParkedLocation
		,ParkedLocations = ParkedLocation
		,ParkingRank
		,Disjoint = CONVERT(bit, 1)
		,[Times Parked Within "Miles Radius"]
		,SecondsParkedWithinMilesRadius
		,[% Parked Within "Miles Radius"]
		,TotalSecondsParked
	FROM #CentralPoint
	WHERE ParkingRank = 1

	UNION ALL

	SELECT
		 cp.[Telematics Supplier]
		,cp.[Guidewire Policy Number]
		,cp.[From Date (inclusive)]
		,cp.[To Date (exclusive)]
		,cp.[Miles Radius]
		,cp.[# Requested Parking Locations]
		,cp.[Overnight Parking Only (10pm-4am)]
		,cp.[Parked Latitude]
		,cp.[Parked Longitude]
		,cp.ParkedLocation
		,ParkedLocations =
			CASE WHEN rec.ParkedLocations.STDistance(cp.ParkedLocation) <= ( cp.[Miles Radius] * 2 * 1609.344 )
				THEN rec.ParkedLocations ELSE rec.ParkedLocations.STUnion(cp.ParkedLocation) END
		,cp.ParkingRank
		,Disjoint =
			CONVERT(bit, CASE WHEN rec.ParkedLocations.STDistance(cp.ParkedLocation) <= ( cp.[Miles Radius] * 2 * 1609.344 ) THEN 0 ELSE 1 END)
		,cp.[Times Parked Within "Miles Radius"]
		,cp.SecondsParkedWithinMilesRadius
		,cp.[% Parked Within "Miles Radius"]
		,cp.TotalSecondsParked
	FROM #CentralPoint cp
	INNER JOIN rec
		ON  cp.ParkingRank					       = rec.ParkingRank + 1
		AND cp.[Guidewire Policy Number]		   = rec.[Guidewire Policy Number]
		AND cp.[From Date (inclusive)]			   = rec.[From Date (inclusive)]
		AND cp.[To Date (exclusive)]               = rec.[To Date (exclusive)]
		AND cp.[Miles Radius]                      = rec.[Miles Radius]
		AND cp.[Overnight Parking Only (10pm-4am)] = rec.[Overnight Parking Only (10pm-4am)]
),
d AS (
	SELECT
		 [Telematics Supplier]
		,[Guidewire Policy Number]
		,[From Date (inclusive)]
		,[To Date (exclusive)]
		,[Miles Radius]
		,[# Requested Parking Locations]
		,[Overnight Parking Only (10pm-4am)]
		,[Parking Location Rank] =
			ROW_NUMBER() OVER (
				PARTITION BY
					[Guidewire Policy Number], [From Date (inclusive)]            , [To Date (exclusive)],
					[Miles Radius]           , [Overnight Parking Only (10pm-4am)]
				ORDER BY SecondsParkedWithinMilesRadius DESC
			)
		,[Parked Latitude]
		,[Parked Longitude]
		,ParkedLocation
		,[Times Parked Within "Miles Radius"]
		,SecondsParkedWithinMilesRadius
		,[Hours Parked Within "Miles Radius"] = ( SecondsParkedWithinMilesRadius / 3600.0 )
		,[% Parked Within "Miles Radius"]
		,[Total Hours Parked]                 = ( TotalSecondsParked / 3600.0 )
	FROM rec
	WHERE Disjoint = 1
)
SELECT *
INTO #DisjointParking
FROM d
WHERE [Parking Location Rank] <= [# Requested Parking Locations]
OPTION (
	 MAXRECURSION 32767
	,RECOMPILE
)
;

IF @Debug = 1
BEGIN
	INSERT #LogTbl (StartTime, Query, QueryFinishTime)
		VALUES (@StartTime, ''Into #DisjointParking'', SYSDATETIME())
	;
END
;

;WITH ns AS (
	SELECT
		 *
		,NearestStreetRN =
			ROW_NUMBER() OVER (
				PARTITION BY
					dp.[Guidewire Policy Number], dp.[From Date (inclusive)]            , dp.[To Date (exclusive)]  ,
					dp.[Miles Radius]           , dp.[Overnight Parking Only (10pm-4am)], dp.[Parking Location Rank]
				ORDER BY dp.ParkedLocation.STDistance(abf.Coordinate) ASC
			)
	FROM #DisjointParking dp
	LEFT JOIN sandbox.dbo.AddressBaseFile20190311 abf
		ON dp.ParkedLocation.STDistance(abf.Coordinate) <= ( 0.01 * 1609.344 )
)
SELECT
	 [Telematics Supplier]
	,[Guidewire Policy Number]
	,[From Date (inclusive)]
	,[To Date (exclusive)]
	,[Miles Radius]
	,[Overnight Parking Only (10pm-4am)]
	,[# Requested Parking Locations]
	,[Parking Location Rank]
	,[Parked Latitude]
	,[Parked Longitude]
	,[Street Description]  = Street_Description
	,[Town Name]           = Town_Name
	,[Administrative Area] = Administrative_Area
	,[Postcode Locator]    = Postcode_Locator
	,[Times Parked Within "Miles Radius"]
	,[Hours Parked Within "Miles Radius"]
	,[% Parked Within "Miles Radius"]
	,[Total Hours Parked]
FROM ns
WHERE NearestStreetRN = 1
ORDER BY
	 [Telematics Supplier]			     ASC
	,[Guidewire Policy Number]		     ASC
	,[From Date (inclusive)]			 ASC
	,[To Date (exclusive)]			     ASC
	,[Miles Radius]					     ASC
	,[Overnight Parking Only (10pm-4am)] ASC
	,[Parking Location Rank]			 ASC
OPTION ( RECOMPILE )

;

IF @Debug = 1
BEGIN
	INSERT #LogTbl (StartTime, Query, QueryFinishTime)
		VALUES (@StartTime, ''Output Topmost Parking Locations'', SYSDATETIME())
	;
END
;

SELECT
	 [Guidewire Policy Number]    = p.PolicyNumber
	,[Effective From (inclusive)] = p.EffectFromDate
	,[Effective To (exclusive)]   = p.EffectToDate
	,[Risk Address Line 1]        = p.RiskAddr1
	,[Risk Address Line 2]        = p.RiskAddr2
	,[Risk Address Line 3]        = p.RiskAddr3
	,[Risk Address Postcode]      = p.RiskPostcode
	,[Risk Address Latitude]	  = pc.latitude
	,[Risk Address Longitude]     = pc.longitude
FROM sandbox.dbo.PolCVPTrav p
LEFT JOIN sandbox.dbo.TEL0012_postcodes3 pc
	ON REPLACE(p.RiskPostcode, '' '', '''') = REPLACE(pc.Postcode, '' '', '''')
WHERE EXISTS (
	SELECT 1
	FROM @TVP pt
	WHERE p.PolicyNumber = pt.[Guidewire Policy Number]
		AND (
				( p.EffectFromDate <= pt.[From Date (inclusive)] AND p.EffectToDate >  pt.[From Date (inclusive)] )
			OR	( p.EffectFromDate <  pt.[To Date (exclusive)]   AND p.EffectToDate >= pt.[To Date (exclusive)]   )
			OR  ( p.EffectFromDate >= pt.[From Date (inclusive)] AND p.EffectToDate <  pt.[To Date (exclusive)]   )
		)
)
	AND p.TraversedFlag = ''1''
	AND p.EffectFromDate <= CONVERT(date, CURRENT_TIMESTAMP)
ORDER BY
	 [Guidewire Policy Number]	  ASC
	,[Effective From (inclusive)] ASC	 
OPTION ( RECOMPILE )
;

IF @Debug = 1
BEGIN
	INSERT #LogTbl (StartTime, Query, QueryFinishTime)
		VALUES (@StartTime, ''Output Risk Address'', SYSDATETIME())
	;
END
;'
;

EXEC sys.sp_executesql
	 @SQL
	,N'@TVP dbo.SJ_ParkingType READONLY, @Debug bit'
	,@TVP
	,@Debug
;

IF @Debug = 1
BEGIN
	PRINT SUBSTRING(@SQL, 1    , 4000 );
	PRINT SUBSTRING(@SQL, 4001 , 8000 );
	PRINT SUBSTRING(@SQL, 8001 , 12000);
	PRINT SUBSTRING(@SQL, 12001, 16000);
	PRINT SUBSTRING(@SQL, 16001, 20000);

	SELECT
		 *
		,SecondsElapsed =
			( DATEDIFF(
				 MILLISECOND
				,LAG(QueryFinishTime, 1, NULL) OVER (ORDER BY QueryFinishTime ASC)
				,QueryFinishTime
			) / 1000.0 )
	FROM #LogTbl
	ORDER BY QueryFinishTime ASC
	;
END
;

END TRY
BEGIN CATCH
	;THROW;
END CATCH
;

END
;

/*
DROP TYPE dbo.SJ_ParkingType;

CREATE TYPE dbo.SJ_ParkingType AS TABLE (
	 [Telematics Supplier]					varchar(15)		NOT NULL CHECK ( [Telematics Supplier] IN ('Vodafone', 'RedTail') )
	,[Guidewire Policy Number] 				varchar(20)		NOT NULL
		CHECK ( [Guidewire Policy Number] LIKE 'P' + REPLICATE(N'[0-9]', 8) + '-[0-9]%' )
	,[From Date (inclusive)]				date		    NOT NULL DEFAULT '20100101'
		CHECK ( [From Date (inclusive)] <= CONVERT(date, CURRENT_TIMESTAMP) 		     )
	,[To Date (exclusive)] 					date		    NOT NULL DEFAULT DATEADD(DAY, 1, CURRENT_TIMESTAMP)
	,[Miles Radius]							decimal(9, 5)	NOT NULL DEFAULT 0.25 CHECK ( [Miles Radius]	> 0 AND [Miles Radius] <= 0.5      )
	,[# Requested Parking Locations]		tinyint			NOT NULL DEFAULT 5    CHECK ( [# Requested Parking Locations] BETWEEN 1 AND 10     )
	,[Overnight Parking Only (10pm-4am)]	varchar(3)		NOT NULL DEFAULT 'No' CHECK ( [Overnight Parking Only (10pm-4am)] IN ('Yes', 'No') ) 

	,PRIMARY KEY CLUSTERED (
		 [Guidewire Policy Number]			 ASC
		,[From Date (inclusive)]			 ASC
		,[To Date (exclusive)]				 ASC
		,[Miles Radius]						 ASC
		,[Overnight Parking Only (10pm-4am)] ASC
	 )
	,CHECK ( [To Date (exclusive)] > [From Date (inclusive)] )
)
;

--DROP PROCEDURE IF EXISTS dbo.SJ_Parking;

DECLARE @TVP dbo.SJ_ParkingType;
INSERT  @TVP (
	[Telematics Supplier]			   , [Guidewire Policy Number], [From Date (inclusive)]		   ,
	[To Date (exclusive)]			   , [Miles Radius]			  , [# Requested Parking Locations],
	[Overnight Parking Only (10pm-4am)]
)
VALUES
	 ('Vodafone', 'P61731833-1', '20100101', '20200101', 0.25, 5, 'Yes')
	,('RedTail' , 'P60607202-1', '20100101', '20200101', 0.25, 5, 'Yes' )
;

EXEC sandbox.dbo.SJ_Parking
	 @TVP
	,1
;
*/
