
SET STATISTICS IO, TIME ON;

;WITH x AS (
	SELECT
		--TOP (10) *
		 PolicyNumber
		,JourneyEndDate
		,RollingMileage =
			SUM(MilesDriven) OVER (
				PARTITION BY PolicyNumber
				ORDER BY	 JourneyEndDate ASC
				ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
			)
	FROM DataSummary.dbo.RedTailScoreJourney
	WHERE PolicyNumber LIKE 'AD%'
),
y AS (
	SELECT
		 PolicyNumber
		,JourneyEndDate
		,RN = ROW_NUMBER() OVER (PARTITION BY PolicyNumber ORDER BY JourneyEndDate ASC)
	FROM x
	WHERE RollingMileage >= 250
)
--INSERT dbo.SJ_RedTail250Miles WITH ( TABLOCK ) (
--	 PolicyNumber
--	,JourneyEndDate
--)
SELECT
	 PolicyNumber
	,JourneyEndDate
	--,RollingMileage
--INTO dbo.SJ_RedTail250Miles
FROM y
WHERE RN = 1
	--AND 1 = 2
ORDER BY JourneyEndDate ASC
;

;WITH x AS (
	SELECT
		--TOP (10) *
		 rsj.PolicyNumber
		,rsj.JourneyEndDate
		,RollingMileage =
			SUM(rsj.MilesDriven) OVER (
				PARTITION BY rsj.PolicyNumber
				ORDER BY	 rsj.JourneyEndDate ASC
				ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
			)
	FROM DataSummary.dbo.RedTailScoreJourney rsj
	LEFT JOIN dbo.SJ_BatchModeEnabler bme
		ON 1 = 0
	WHERE rsj.PolicyNumber LIKE 'AD%'
),
y AS (
	SELECT
		 x.PolicyNumber
		,n.n
		,x.RollingMileage
		,x.JourneyEndDate
		,RN = ROW_NUMBER() OVER (PARTITION BY x.PolicyNumber, n.n ORDER BY x.JourneyEndDate ASC)
	FROM x
	INNER JOIN (
		SELECT
			 n
			,nPlus250 = n + 250
		FROM dbo.Numbers
		WHERE n IN (250, 500, 750, 1000)
	) n
		ON  x.RollingMileage >= n.n
		AND x.RollingMileage <  n.nPlus250
	--WHERE RollingMileage >= 250
)
--INSERT dbo.SJ_RedTail250Miles WITH ( TABLOCK ) (
--	 PolicyNumber
--	,JourneyEndDate
--)
SELECT
	 PolicyNumber
	,n
	,RollingMileage
	,JourneyEndDate
--INTO dbo.SJ_RedTail250Miles
FROM y
WHERE RN = 1
	--AND 1 = 2
ORDER BY
	 PolicyNumber
	,n
;



ALTER TABLE dbo.SJ_RedTail250Miles ADD CONSTRAINT PK__SJ_RedTail250Miles__PolicyNumber PRIMARY KEY CLUSTERED ( PolicyNumber ASC );

SELECT
	 r.*
	,DaysTo250FromPeriodStartDate = DATEDIFF(DAY, a.PeriodStartDate, r.JourneyEndDate)
	,DaysTo250FromAssocStartDate  = DATEDIFF(DAY, a.AssocStartDate , r.JourneyEndDate)
	,DaysTo250FromFirstPluginDate = DATEDIFF(DAY, a.FirstPluginDate, r.JourneyEndDate)
	,a.VehMiles
INTO dbo.SJ_RedTail250Miles2
FROM dbo.SJ_RedTail250Miles r
INNER JOIN (
	SELECT a.*
	FROM (
		SELECT
			 PolicyNumber
			,PeriodStartDate
			,AssocStartDate = StartDate
			,FirstPluginDate
			,VehMiles = OrigDecMiles
			,RN = ROW_NUMBER() OVER (PARTITION BY PolicyNumber ORDER BY InsertedDate ASC)
		FROM DataSummary.dbo.RedTailScore
	) a
	WHERE a.RN = 1
) a
	ON r.PolicyNumber = a.PolicyNumber
;

SELECT r.*, DaysTo250FromFirstTripDate = DATEDIFF(DAY, rsj.FirstTripDate, r.JourneyEndDate)
INTO dbo.SJ_RedTail250Miles3
FROM dbo.SJ_RedTail250Miles2 r
INNER JOIN (
	SELECT PolicyNumber, FirstTripDate = MIN(JourneyStartDate)
	FROM DataSummary.dbo.RedTailScoreJourney
	GROUP BY PolicyNumber
) rsj
	ON r.PolicyNumber = rsj.PolicyNumber
;


;WITH x AS (
	SELECT DISTINCT
		 PolicyNumber
		,BrandName
	FROM dbo.PolCVPTrav
	WHERE EffectFromDate <= CONVERT(date, CURRENT_TIMESTAMP)
		AND TraversedFlag = '1'
)
SELECT
	--TOP (10) *
	 [System] = CASE WHEN r.PolicyNumber LIKE 'P%' THEN 'Guidewire' ELSE 'i90' END
	,ca.Brand
	,ca.DeclaredMileageBucket
	,AverageDaysTo250FromPeriodStartDate = AVG(CASE WHEN r.DaysTo250FromPeriodStartDate BETWEEN 0 AND 364 THEN r.DaysTo250FromPeriodStartDate END * 1.0)
	,AverageDaysTo250FromAssocStartDate  = AVG(CASE WHEN r.DaysTo250FromAssocStartDate  BETWEEN 0 AND 364 THEN r.DaysTo250FromAssocStartDate  END * 1.0)
	,AverageDaysTo250FromFirstPluginDate = AVG(CASE WHEN r.DaysTo250FromFirstPluginDate BETWEEN 0 AND 364 THEN r.DaysTo250FromFirstPluginDate END * 1.0)
	,AverageDaysTo250FromFirstTripDate   = AVG(CASE WHEN r.DaysTo250FromFirstTripDate   BETWEEN 0 AND 364 THEN r.DaysTo250FromFirstTripDate   END * 1.0)
	,Risks = COUNT(*)
FROM dbo.SJ_RedTail250Miles3 r
CROSS APPLY (
	SELECT
		 DeclaredMileageBucket =
			CASE
				WHEN VehMiles BETWEEN 0     AND 1999  THEN '0 - 2000 Miles'
				WHEN VehMiles BETWEEN 2000  AND 3999  THEN '2000 - 4000 Miles'
				WHEN VehMiles BETWEEN 4000  AND 5999  THEN '4000 - 6000 Miles'
				WHEN VehMiles BETWEEN 6000  AND 7999  THEN '6000 - 8000 Miles'
				WHEN VehMiles BETWEEN 8000  AND 9999  THEN '8000 - 10000 Miles'
				WHEN VehMiles BETWEEN 10000 AND 11999 THEN '10000 - 12000 Miles'
				WHEN VehMiles BETWEEN 12000 AND 13999 THEN '12000 - 14000 Miles'
				WHEN VehMiles BETWEEN 14000 AND 15999 THEN '14000 - 16000 Miles'
				WHEN VehMiles BETWEEN 16000 AND 17999 THEN '16000 - 18000 Miles'
				WHEN VehMiles BETWEEN 18000 AND 19999 THEN '18000 - 20000 Miles'
				WHEN VehMiles                >= 20000 THEN '20000+ Miles'
													  ELSE 'N/A'
			END
		,Brand =
			CASE
				WHEN r.PolicyNumber LIKE 'AD%' THEN 'Admiral'
				WHEN r.PolicyNumber LIKE 'BL%' THEN 'Bell'
											   ELSE (
					SELECT x.BrandName
					FROM x
					WHERE r.PolicyNumber = x.PolicyNumber
				)
			END
) ca
GROUP BY CUBE (
	 (CASE WHEN r.PolicyNumber LIKE 'P%' THEN 'Guidewire' ELSE 'i90' END)
	,(ca.DeclaredMileageBucket)
	,(ca.Brand)
)
ORDER BY
	 [System] ASC
	,ca.Brand ASC
	,CASE ca.DeclaredMileageBucket
		WHEN '0 - 2000 Miles'      THEN 1
		WHEN '2000 - 4000 Miles'   THEN 2
		WHEN '4000 - 6000 Miles'   THEN 3
		WHEN '6000 - 8000 Miles'   THEN 4
		WHEN '8000 - 10000 Miles'  THEN 5
		WHEN '10000 - 12000 Miles' THEN 6
		WHEN '12000 - 14000 Miles' THEN 7
		WHEN '14000 - 16000 Miles' THEN 8
		WHEN '16000 - 18000 Miles' THEN 9
		WHEN '18000 - 20000 Miles' THEN 10
		WHEN '20000+ Miles'		   THEN 11
		WHEN 'N/A'				   THEN 12
	 END ASC
;


SELECT
	--TOP (10) *
	 [System] = 'Guidewire'
	,ca.DeclaredMileageBucket
	,AverageDaysTo250FromCoverStart = AVG(CASE WHEN r.DaysTo250FromCoverStart BETWEEN 1 AND 364 THEN r.DaysTo250FromCoverStart END * 1.0)
	,AverageDaysTo250FromFirstTrip  = AVG(CASE WHEN r.DaysTo250FromFirstTrip  BETWEEN 1 AND 364 THEN r.DaysTo250FromFirstTrip  END * 1.0)
	,Terms = COUNT(*)
FROM dbo.SJ_Vodafone250Miles r
CROSS APPLY (
	SELECT DeclaredMileageBucket =
		CASE
			WHEN VehMiles BETWEEN 0     AND 1999  THEN '0 - 2000 Miles'
			WHEN VehMiles BETWEEN 2000  AND 3999  THEN '2000 - 4000 Miles'
			WHEN VehMiles BETWEEN 4000  AND 5999  THEN '4000 - 6000 Miles'
			WHEN VehMiles BETWEEN 6000  AND 7999  THEN '6000 - 8000 Miles'
			WHEN VehMiles BETWEEN 8000  AND 9999  THEN '8000 - 10000 Miles'
			WHEN VehMiles BETWEEN 10000 AND 11999 THEN '10000 - 12000 Miles'
			WHEN VehMiles BETWEEN 12000 AND 13999 THEN '12000 - 14000 Miles'
			WHEN VehMiles BETWEEN 14000 AND 15999 THEN '14000 - 16000 Miles'
			WHEN VehMiles BETWEEN 16000 AND 17999 THEN '16000 - 18000 Miles'
			WHEN VehMiles BETWEEN 18000 AND 19999 THEN '18000 - 20000 Miles'
			WHEN VehMiles                >= 20000 THEN '20000+ Miles'
													ELSE 'N/A'
		END
) ca
GROUP BY CUBE (
	 (ca.DeclaredMileageBucket)
)
ORDER BY
	 [System] ASC
	,CASE ca.DeclaredMileageBucket
		WHEN '0 - 2000 Miles'      THEN 1
		WHEN '2000 - 4000 Miles'   THEN 2
		WHEN '4000 - 6000 Miles'   THEN 3
		WHEN '6000 - 8000 Miles'   THEN 4
		WHEN '8000 - 10000 Miles'  THEN 5
		WHEN '10000 - 12000 Miles' THEN 6
		WHEN '12000 - 14000 Miles' THEN 7
		WHEN '14000 - 16000 Miles' THEN 8
		WHEN '16000 - 18000 Miles' THEN 9
		WHEN '18000 - 20000 Miles' THEN 10
		WHEN '20000+ Miles'		   THEN 11
		WHEN 'N/A'				   THEN 12
	 END ASC
;










;WITH x AS (
	SELECT DISTINCT
		 PolicyNumber
		,BrandName
	FROM dbo.PolCVPTrav
	WHERE EffectFromDate <= CONVERT(date, CURRENT_TIMESTAMP)
		AND TraversedFlag = '1'
)
select [System] = 'Guidewire', PolicyNumber, Brand, VehMiles, DaysTo250FromCoverStart, DaysTo250FromFirstTrip
into #Finale
from dbo.SJ_Vodafone250Miles
UNION ALL
SELECT CASE WHEN r.PolicyNumber LIKE 'P%' THEN 'Guidewire' ELSE 'i90' END, r.PolicyNumber,
CASE
	WHEN r.PolicyNumber LIKE 'AD%' THEN 'Admiral'
	WHEN r.PolicyNumber LIKE 'BL%' THEN 'Bell'
									ELSE (
		SELECT x.BrandName
		FROM x
		WHERE r.PolicyNumber = x.PolicyNumber
	)
END,
r.VehMiles
,r.DaysTo250FromPeriodStartDate, r.DaysTo250FromFirstTripDate
FROM dbo.SJ_RedTail250Miles3 r
;

SELECT
	--TOP (10) *
	 r.[System]
	,r.Brand
	,ca.DeclaredMileageBucket
	,AverageDaysTo250FromCoverStart = AVG(CASE WHEN r.DaysTo250FromCoverStart BETWEEN 1 AND 364 THEN r.DaysTo250FromCoverStart END * 1.0)
	,AverageDaysTo250FromFirstTrip  = AVG(CASE WHEN r.DaysTo250FromFirstTrip  BETWEEN 1 AND 364 THEN r.DaysTo250FromFirstTrip  END * 1.0)
	,Terms = COUNT(*)
FROM #Finale r
CROSS APPLY (
	SELECT DeclaredMileageBucket =
		CASE
			WHEN VehMiles BETWEEN 0     AND 1999  THEN '0 - 2000 Miles'
			WHEN VehMiles BETWEEN 2000  AND 3999  THEN '2000 - 4000 Miles'
			WHEN VehMiles BETWEEN 4000  AND 5999  THEN '4000 - 6000 Miles'
			WHEN VehMiles BETWEEN 6000  AND 7999  THEN '6000 - 8000 Miles'
			WHEN VehMiles BETWEEN 8000  AND 9999  THEN '8000 - 10000 Miles'
			WHEN VehMiles BETWEEN 10000 AND 11999 THEN '10000 - 12000 Miles'
			WHEN VehMiles BETWEEN 12000 AND 13999 THEN '12000 - 14000 Miles'
			WHEN VehMiles BETWEEN 14000 AND 15999 THEN '14000 - 16000 Miles'
			WHEN VehMiles BETWEEN 16000 AND 17999 THEN '16000 - 18000 Miles'
			WHEN VehMiles BETWEEN 18000 AND 19999 THEN '18000 - 20000 Miles'
			WHEN VehMiles                >= 20000 THEN '20000+ Miles'
													ELSE 'N/A'
		END
) ca
GROUP BY CUBE (
	 r.[System]
	,(r.Brand)
	,(ca.DeclaredMileageBucket)

)
ORDER BY
	 r.[System] ASC
	,r.Brand  ASC
	,CASE ca.DeclaredMileageBucket
		WHEN '0 - 2000 Miles'      THEN 1
		WHEN '2000 - 4000 Miles'   THEN 2
		WHEN '4000 - 6000 Miles'   THEN 3
		WHEN '6000 - 8000 Miles'   THEN 4
		WHEN '8000 - 10000 Miles'  THEN 5
		WHEN '10000 - 12000 Miles' THEN 6
		WHEN '12000 - 14000 Miles' THEN 7
		WHEN '14000 - 16000 Miles' THEN 8
		WHEN '16000 - 18000 Miles' THEN 9
		WHEN '18000 - 20000 Miles' THEN 10
		WHEN '20000+ Miles'		   THEN 11
		WHEN 'N/A'				   THEN 12
	 END ASC
;

-- SAS CODE:

--PROC SQL
--/*	INOBS = 100*/
--		;
--	CREATE TABLE VF1400 AS
--		SELECT
--			 PolicyNumber
--			,NumTerm
--			,date_inc         FORMAT DDMMYY10. AS PolIncDate
--			,RiskOrgOnCovDate FORMAT DDMMYY10.
--			,TelePolStartDate FORMAT DDMMYY10.
--			,Mileage_Orig                      AS VehMiles
--			,MinDataDate      FORMAT DDMMYY10. AS FirstTripDate
--			,MinValidDataDate FORMAT DDMMYY10. AS FirstValidTripDate
--			,Days_Box_Active
--			,Miles_Driven
--			,DaysToFit
--			,EffectiveDate    FORMAT DDMMYY10.
--			,InsertedOn       FORMAT DDMMYY10.
--		FROM Telema.TEL1400_VF_History
--		WHERE Miles_Driven >= 250
--		GROUP BY
--			 PolicyNumber
--			,NumTerm
--		HAVING MIN(EffectiveDate) = EffectiveDate
--		;
--QUIT;

--PROC SQL
--/*	INOBS = 100*/
--		;
--	CREATE TABLE VFTimeTo250 AS
--		SELECT
--/*			 **/
--			 a.PolicyNumber
--			,a.NumTerm
--			,b.BrandName AS Brand
--			,a.VehMiles
--			,INTCK('DAY', a.TelePolStartDate  , a.EffectiveDate) AS DaysTo250FromCoverStart
--			,INTCK('DAY',a. FirstValidTripDate, a.EffectiveDate) AS DaysTo250FromFirstTrip
--		FROM VF1400 a
--		INNER JOIN (
--			SELECT DISTINCT
--				 PolicyNumber
--				,BrandName
--			FROM Telema.PolCVPTrav_DontDelete
--			WHERE TraversedFlag = '1'
--				AND EffectFromDate <= TODAY()
--		) b
--			ON a.PolicyNumber = b.PolicyNumber
--		/* To remove cases where the same MinValidDataDate is attributed to two terms: */
--		WHERE INTCK('DAY', a.FirstValidTripDate, a.EffectiveDate) BETWEEN 0 AND 364
--			/* To remove any outliers (how many miles can one do in one day?): */
--			AND a.Miles_Driven < 750
--		;
--QUIT;

--PROC SQL;
--	CONNECT TO ODBC AS DDP (DSN = "Telematics_DDP_Sandbox" AuthDomain = "SPYDDPAuth");
--		EXEC(

--			DROP TABLE IF EXISTS sandbox.dbo.SJ_Vodafone250Miles;

--			CREATE TABLE sandbox.dbo.SJ_Vodafone250Miles (
--				 PolicyNumber				varchar(22)	NOT NULL
--				,NumTerm					tinyint		NOT NULL
--				,Brand						varchar(15)	NOT NULL
--				,VehMiles					integer		NOT NULL
--				,DaysTo250FromCoverStart 	smallint 	NOT NULL
--				,DaysTo250FromFirstTrip 	smallint	NOT NULL

--				,CONSTRAINT PK__SJ_Vodafone250Miles__PolicyNumberNumTerm PRIMARY KEY CLUSTERED (
--					 PolicyNumber ASC
--					,NumTerm      ASC
--				 )
--			)
--			;

--		) BY DDP;
--	DISCONNECT FROM DDP;
--QUIT;

--PROC APPEND
--	BASE = Sand_DDP.SJ_Vodafone250Miles
--	DATA = VFTimeTo250
--	FORCE;
--RUN;

--/**/