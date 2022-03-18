--DROP TABLE sandbox.dbo.SJ_VFWeeklyMileage;

CREATE TABLE sandbox.dbo.SJ_VFWeeklyMileage (
	 PolicyNumber		varchar(20)		NOT NULL
	,WeekCommencing		date			NOT NULL
	,InstallationDate	date				NULL
	,RiskCXXDate		date				NULL
	,MilesDriven		numeric(9, 4)		NULL

	CONSTRAINT PK_SJVFWeeklyMileage_PolicyNumberWeekCommencing PRIMARY KEY CLUSTERED (PolicyNumber ASC, WeekCommencing ASC)
)
;


;WITH p AS (
	SELECT
		 Polygonname
		,Polygon
	FROM sandbox.dbo.SJ_Polygons
	WHERE PolygonName IN (
	 	 'Leicester'
		,'Leeds'
		,'Glasgow'
		,'Aberdeen'
		,'Manchester'
		,'Caerphilly'
	)
		AND Artist = 'OSM - Original (Reduced)'
),
j AS (
	SELECT
		 PolicyNumber
		,miles_driven
		,startdate
		,start_lat
		,start_long
		,end_lat
		,end_long
	FROM DataSummary.dbo.VodaJourneys
	UNION ALL
	SELECT
		 PolicyNumber
		,miles_driven
		,startdate
		,start_lat
		,start_long
		,end_lat
		,end_long
	FROM DataSummary.dbo.VodaJourneys_COVID
)
INSERT sandbox.dbo.SJ_AJLocalisedLockdownJourneys WITH (TABLOCK) (PolygonName, PolicyNumber, WeekCommencing, MilesDriven)
SELECT
	 p.PolygonName
	,j.PolicyNumber
	,WeekCommencing = DATEADD(DAY, 1 - DATEPART(WEEKDAY, j.startdate), j.startdate)
	,MilesDriven    = SUM(j.miles_driven)
FROM j
INNER JOIN p
	ON  p.Polygon.STIntersects(geography::Point(j.start_lat, j.start_long, 4326)) = 1
	AND p.Polygon.STIntersects(geography::Point(j.end_lat  , j.end_long  , 4326)) = 1
	--AND j.startdate  >= '20190603' _ORIGINALNOTDONE
	--AND j.startdate  <  '20200810'
	--AND j.startdate  >= '20200316' _COVID
	--AND j.startdate  <  '20200706'
	--AND j.startdate  >= '20200713' _POSTCOVID
	--AND j.startdate  <  '20200907'
	--AND j.startdate  >= '20190603' --_PRECOVID
	--AND j.startdate  <  '20200309'
	AND (
			(
				j.startdate  >= '20200309' --_MISSEDWEEKSCOVID
					AND j.startdate  <  '20200316'
			)
		OR
			(
				j.startdate  >= '20200706' --_MISSEDWEEKSCOVID
					AND j.startdate  <  '20200713'
			)
	)
WHERE EXISTS (
	SELECT 1
	FROM sandbox.dbo.TEL1386_VFCXX cxx
	WHERE j.PolicyNumber = cxx.PolicyNumber
		AND j.startdate  < cxx.RiskCXXDate
)
	/*
	AND NOT EXISTS (
		SELECT 1
		FROM sandbox.dbo.SJ_AJLocalisedLockdownJourneys lj
		WHERE j.PolicyNumber = lj.PolicyNumber
			AND DATEADD(DAY, 1 - DATEPART(WEEKDAY, j.startdate), j.startdate) = lj.WeekCommencing
	)
	*/
GROUP BY
	 p.PolygonName
	,j.PolicyNumber
	,DATEADD(DAY, 1 - DATEPART(WEEKDAY, j.startdate), j.startdate)
;

SELECT *
FROM sandbox.dbo.SJ_AJLocalisedLockdownJourneys 
;

ALTER TABLE sandbox.dbo.SJ_VFWeeklyMileage
ADD
	 Glasgow 	numeric(9, 4) null
	,Aberdeen 	numeric(9, 4) null
	,Manchester numeric(9, 4) null
	,Leeds 		numeric(9, 4) null
	,Leicester 	numeric(9, 4) null
	,Caerphilly numeric(9, 4) null
;

ALTER TABLE sandbox.dbo.SJ_VFWeeklyMileage
ADD
	 [Glasgow %] 	numeric(9, 4) null
	,[Aberdeen %] 	numeric(9, 8) null
	,[Manchester %] numeric(9, 8) null
	,[Leeds %] 		numeric(9, 8) null
	,[Leicester %] 	numeric(9, 8) null
	,[Caerphilly %] numeric(9, 8) null
;

UPDATE sandbox.dbo.SJ_VFWeeklyMileage
SET
	 [Glasgow %]    = Glasgow    / NULLIF(MilesDriven, 0)
	,[Aberdeen %]   = Aberdeen   / NULLIF(MilesDriven, 0)
	,[Manchester %] = Manchester / NULLIF(MilesDriven, 0)
	,[Leeds %]      = Leeds      / NULLIF(MilesDriven, 0)
	,[Leicester %]  = Leicester  / NULLIF(MilesDriven, 0)
	,[Caerphilly %] = Caerphilly / NULLIF(MilesDriven, 0)
WHERE (
		Glasgow    IS NOT NULL
	OR  Aberdeen   IS NOT NULL
	OR  Manchester IS NOT NULL
	OR 	Leeds      IS NOT NULL
	OR 	Leicester  IS NOT NULL
	OR 	Caerphilly IS NOT NULL
)
;

;WITH y AS (
	SELECT
		 PolicyNumber
		,WeekCommencing
		,p.Glasgow
		,p.Aberdeen
		,p.Leeds
		,p.Leicester
		,p.Manchester
		,p.Caerphilly
	FROM sandbox.dbo.SJ_AJLocalisedLockdownJourneys
	PIVOT (
		MAX(MilesDriven) FOR PolygonName IN (Glasgow, Aberdeen, Manchester, Leeds, Leicester, Caerphilly)
	) p
)
UPDATE a
SET
	 a.Glasgow    = y.Glasgow
	,a.Aberdeen   = y.Aberdeen
	,a.Manchester = y.Manchester
	,a.Leeds      = y.Leeds
	,a.Leicester  = y.Leicester
	,a.Caerphilly = y.Caerphilly
FROM sandbox.dbo.SJ_VFWeeklyMileage a
INNER JOIN y
	ON  a.PolicyNumber   = y.PolicyNumber
	AND a.WeekCommencing = y.WeekCommencing
;

-->=16/03 < 6/07
--sent to aj 13/08

;WITH x AS (
	SELECT
		 PolicyNumber
		,StartDate
		,Miles_Driven
	FROM DataSummary.dbo.VodaJourneys
	UNION ALL
	SELECT
		 PolicyNumber
		,StartDate
		,Miles_Driven
	FROM DataSummary.dbo.VodaJourneys_COVID
)
INSERT sandbox.dbo.SJ_VFWeeklyMileage WITH (TABLOCK) (PolicyNumber, WeekCommencing, MilesDriven, RiskCXXDate)
SELECT
	 x.PolicyNumber
	,DATEADD(WEEK, DATEDIFF(WEEK, '19000101', DATEADD(DAY, -1, x.StartDate)), '19000101')
	,SUM(x.Miles_Driven)
	,cxx.RiskCXXDate
FROM x
INNER JOIN sandbox.dbo.TEL1386_VFCXX cxx
	ON  x.PolicyNumber = cxx.PolicyNumber
	AND x.StartDate	   < cxx.RiskCXXDate
	--AND x.StartDate >= '20190603'
	--AND x.StartDate <  '20200810'
GROUP BY
	 x.PolicyNumber
	,DATEADD(WEEK, DATEDIFF(WEEK, '19000101', DATEADD(DAY, -1, x.StartDate)), '19000101')
	,cxx.RiskCXXDate
;

;WITH y AS (
	SELECT
		 vr.PolicyNumber
		,InstallationDate = MIN(g.EquipmentActivationDateTime)
	FROM Vodafone.dbo.GeneralMI g
	INNER JOIN Vodafone.dbo.VoucherResponse vr
		ON g.VoucherID = vr.VoucherID
	GROUP BY vr.PolicyNumber
)
UPDATE wm
	SET wm.InstallationDate = y.InstallationDate
FROM sandbox.dbo.SJ_VFWeeklyMileage wm
INNER JOIN y
	ON wm.PolicyNumber = y.PolicyNumber
;

;WITH z AS (
	SELECT
		 *
		,FirstWeek = MIN(WeekCommencing) OVER (PARTITION BY PolicyNumber)
	FROM sandbox.dbo.SJ_VFWeeklyMileage
)
UPDATE z
	SET InstallationDate = FirstWeek 
WHERE (
		FirstWeek < DATEADD(DAY, -6, InstallationDate)
	OR 	InstallationDate IS NULL
)
;

;WITH REC (Date) AS (
	SELECT CONVERT(date, '20190603')
	UNION ALL
	SELECT DATEADD(DAY, 7, Date)
	FROM REC
	WHERE DATEADD(DAY, 7, Date) < '20200810'
)
SELECT *
INTO #Dates
FROM REC
OPTION (MAXRECURSION 1000)
;

;WITH z AS (
	SELECT *
	FROM #Dates d
	INNER JOIN (
		SELECT DISTINCT PolicyNumber, InstallationDate, RiskCXXDate
		FROM sandbox.dbo.SJ_VFWeeklyMileage
	) wm
		ON  d.Date >= DATEADD(WEEK, DATEDIFF(WEEK, '19000101', DATEADD(DAY, -1, wm.InstallationDate)), '19000101')
		AND d.Date < wm.RiskCXXDate
)
INSERT sandbox.dbo.SJ_VFWeeklyMileage (PolicyNumber, WeekCommencing, InstallationDate, RiskCXXDate, MilesDriven)
SELECT
	 PolicyNumber
	,WeekCommencing = Date
	,InstallationDate
	,RiskCXXDate
	,MilesDriven = NULL
FROM z
WHERE NOT EXISTS (
	SELECT 1
	FROM sandbox.dbo.SJ_VFWeeklyMileage wm
	WHERE z.PolicyNumber = wm.PolicyNumber
		AND z.Date = wm.WeekCommencing
)
;

CREATE NONCLUSTERED INDEX IX_SJVFWeeklyMileage_MilesDriven ON sandbox.dbo.SJ_VFWeeklyMileage (MilesDriven ASC);

;WITH X AS (
	SELECT
		 *
		,RN = COUNT(*) OVER (PARTITION BY PolicyNumber, WeekCommencing)
	FROM sandbox.dbo.SJ_VFWeeklyMileage
)
SELECT *
FROM X
WHERE RN > 1
ORDER BY
	 PolicyNumber ASC
	,WeekCommencing ASC
;
