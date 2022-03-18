
SELECT *
INTO #YEET
FROM CMTSERV.dbo.AppAssociation
;

CREATE CLUSTERED INDEX CIX ON #YEET (RegistrationDate ASC)
INCLUDE (Account_ID)
;

SET STATISTICS IO, TIME ON;

SELECT
	 d.d
	,Registrations = ISNULL(COUNT(DISTINCT aa.Account_ID), 0)
FROM dbo.Dates d
LEFT OUTER JOIN #YEET aa
	ON  aa.RegistrationDate >= d.d
	AND aa.RegistrationDate <  DATEADD(DAY, 1, d.d)
WHERE d.wd = 'Monday'
	--AND d.d = '20201214'
GROUP BY d.d
ORDER BY d.d
;

SELECT
	 d.d
	,Registrations = ISNULL(COUNT(DISTINCT aa.Account_ID), 0)
FROM dbo.Dates d
LEFT OUTER JOIN #YEET aa
	ON CONVERT(date, aa.RegistrationDate) = d.d
WHERE d.wd = 'Monday'
	--AND d.d = '20201214'
GROUP BY d.d
ORDER BY d.d
;

--SELECT
--	 d.d
--	,Registrations = ISNULL(COUNT(DISTINCT ca.Account_ID), 0)
--FROM dbo.Dates d
--OUTER APPLY (
--	SELECT aa.Account_ID
--	FROM #YEET aa
--	WHERE aa.RegistrationDate >= d.d
--		AND aa.RegistrationDate < DATEADD(DAY, 1, d.d)
--) ca
--WHERE d.wd = 'Monday'
--	--AND d.d = '20201214'
--GROUP BY d.d
--ORDER BY d.d
--;

