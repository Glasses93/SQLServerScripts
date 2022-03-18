--SELECT TOP (100) *
--FROM Vodafone.dbo.Trip
--;

--SET STATISTICS IO, TIME ON;
--SET NOCOUNT ON;

BEGIN TRY

	DECLARE
		 @Offset integer = 0
		,@MaxNum integer
	;

	SELECT @MaxNum = COUNT(*)
	FROM dbo.SJ_VFAVB_20210217
	;

	WHILE @Offset < @MaxNum
	BEGIN

		;WITH y AS (
			SELECT PolicyNumber
			FROM dbo.SJ_VFAVB_20210217
			ORDER BY PolicyNumber ASC
			OFFSET @Offset ROWS
			FETCH NEXT 500 ROWS ONLY
		),
		x AS (
			SELECT
				 [Policy Number]			 = t.ExternalContractNumber
				,[Distance Travelled (100m)] = t.DeltaTripDistance
				,[Geodetic Distance Travelled (Floored (100m))] =
					FLOOR(
						ca.Coordinate.STDistance(
							LAG(ca.Coordinate, 1, NULL) OVER (
								PARTITION BY t.ExternalContractNumber, t.TripID
								ORDER BY	 t.EventTimeStamp ASC
							)
						)
						/ 100
					)
				,[VF's Reported Distance Shy Than 10% of Geodetic Distance?] =
					CASE WHEN
						t.DeltaTripDistance <
							FLOOR(
								ca.Coordinate.STDistance(
									LAG(ca.Coordinate, 1, NULL) OVER (
										PARTITION BY t.ExternalContractNumber, t.TripID
										ORDER BY	 t.EventTimeStamp ASC
									)
								)
								/ 100
							)
							* 0.9
						THEN 1
						ELSE 0
					END
			FROM Vodafone.dbo.Trip t
			CROSS APPLY (
				SELECT
					Coordinate =
						geography::Point(
							 CASE WHEN t.Latitude  >= -90  AND t.Latitude  <= 90  THEN t.Latitude  ELSE 90  END
							,CASE WHEN t.Longitude >= -180 AND t.Longitude <= 180 THEN t.Longitude ELSE 180 END
							,4326
						)
			) ca
			--WHERE t.ExternalContractNumber = N'P61835327-1'
			WHERE EXISTS (
				SELECT 1
				FROM y
				WHERE t.ExternalContractNumber = y.PolicyNumber
			)
				AND t.TripID		 IS NOT NULL
				AND t.EventTimeStamp IS NOT NULL
		)
		INSERT dbo.SJ_VFGeodistVsReportedDist (
			 PolicyNumber
			,NumberOfEligibleEvents
			,NumberOfFlaggedEvents
		)
		SELECT
			 [Policy Number]
			,[# of Eligible Events]	= COUNT(*)
			,[# of Flagged Events]  = SUM([VF's Reported Distance Shy Than 10% of Geodetic Distance?])
		FROM x
		WHERE [Distance Travelled (100m)] BETWEEN 0 AND 50
			AND [Geodetic Distance Travelled (Floored (100m))] <= 100
		GROUP BY [Policy Number]
		OPTION (RECOMPILE)
		;

		SET @Offset += 500;

	END
	;

END TRY
BEGIN CATCH
	;THROW;
END CATCH
;

SELECT 
	 *
	,[Risks Processed]		=  COUNT(*) OVER ()
	,[% of AVB Processed]	= (COUNT(*) OVER () / 45214.0) * 100
	
	,[% of Flagged Events]			=     (NumberOfFlaggedEvents / (NumberOfEligibleEvents * 1.0)) * 100
	,[Average % of Flagged Events]	= AVG((NumberOfFlaggedEvents / (NumberOfEligibleEvents * 1.0)) * 100) OVER ()
FROM dbo.SJ_VFGeodistVsReportedDist
--WHERE NumberOfEligibleEvents >= 120
ORDER BY [% of Flagged Events] DESC
;










--DROP TABLE dbo.SJ_VFGeodistVsReportedDist
--CREATE TABLE dbo.SJ_VFGeodistVsReportedDist (
--	 PolicyNumber				varchar(22)		NOT NULL
--	,NumberOfEligibleEvents		integer			NOT NULL
--	,NumberOfFlaggedEvents		integer			NOT NULL

--	,CONSTRAINT PK_SJ_VFGeodistVsReportedDist PRIMARY KEY CLUSTERED (PolicyNumber ASC)
--)
--;

--SELECT DISTINCT PolicyNumber = ISNULL(CONVERT(nvarchar(20), PolicyNumber), N'OK')
--INTO dbo.SJ_VFAVB_20210217
--FROM dbo.PolCVPTrav
--WHERE PolicyNumber IS NOT NULL
--	AND TelematicsFlag = '1'
--	AND TeleDevRem = '0'
--	AND TraversedFlag = '1'
--	AND EffectFromDate <= CONVERT(date, CURRENT_TIMESTAMP)
--	AND EffectToDate > CONVERT(date, CURRENT_TIMESTAMP)
--	AND TeleDevSuppl = 'vodafone'
--;

--ALTER TABLE dbo.SJ_VFAVB_20210217 ADD CONSTRAINT PK__SJ_VFAVB_20210217 PRIMARY KEY CLUSTERED (PolicyNumber ASC);
