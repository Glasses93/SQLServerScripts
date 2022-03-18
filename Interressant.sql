SELECT *
INTO #YEET
FROM CMTSERV.dbo.AppAssociation
;

SET NOCOUNT ON;

INSERT #YEET
SELECT *
FROM #YEET
;

SELECT COUNT(*) FROM #YEET;

CREATE CLUSTERED INDEX CIX ON #YEET (RegistrationDate ASC);

SET STATISTICS IO, TIME ON;

SELECT
	 YEAR(RegistrationDate)
	,COUNT(*)
FROM #YEET
GROUP BY YEAR(RegistrationDate)
;

;WITH d AS (
	SELECT
		 d1 = d
		,d2 = DATEADD(YEAR, 1, d)
	FROM dbo.Dates
	WHERE d >= '20180101'
		AND d < '20210101'
		AND DATEPART(DAYOFYEAR, d) = 1
)
SELECT
	 d.d1
	,COUNT(*)
FROM #YEET y
INNER JOIN d
	ON  y.RegistrationDate >= d.d1
	AND y.RegistrationDate <  d.d2
GROUP BY d.d1
;

SELECT
	 YEAR(RegistrationDate), MONTH(RegistrationDate)
	,COUNT(*)
FROM #YEET
GROUP BY YEAR(RegistrationDate), MONTH(RegistrationDate)
;

;WITH d AS (
	SELECT
		 d1 = d
		,d2 = DATEADD(MONTH, 1, d)
	FROM dbo.Dates
	WHERE d >= '20180101'
		AND d < '20210101'
		AND DAY(d) = 1
)
SELECT
	 d.d1
	,COUNT(*)
FROM #YEET y
INNER JOIN d
	ON  y.RegistrationDate >= d.d1
	AND y.RegistrationDate <  d.d2
GROUP BY d.d1
;


SELECT
	 YEAR(RegistrationDate), MONTH(RegistrationDate)
	,COUNT(*)
FROM #YEET
GROUP BY YEAR(RegistrationDate), MONTH(RegistrationDate)
;

;WITH d AS (
	SELECT
		 d1 = d
		,d2 = DATEADD(MONTH, 1, d)
	FROM dbo.Dates
	WHERE d >= (SELECT DATEFROMPARTS(YEAR(MIN(RegistrationDate)), MONTH(MIN(RegistrationDate)), 1) FROM #YEET)
		AND d < (SELECT DATEADD(MONTH, 1, DATEFROMPARTS(YEAR(MAX(RegistrationDate)), MONTH(MAX(RegistrationDate)), 1)) FROM #YEET)
		AND DAY(d) = 1
)
SELECT
	 d.d1
	,COUNT(*)
FROM #YEET y
INNER JOIN d
	ON  y.RegistrationDate >= d.d1
	AND y.RegistrationDate <  d.d2
GROUP BY d.d1
;