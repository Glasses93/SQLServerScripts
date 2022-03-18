
CREATE TABLE #T1 (a integer NULL);

INSERT #T1 SELECT 1 UNION ALL SELECT NULL;

SELECT *
FROM #T1
WHERE a = SOME (SELECT a FROM #T1)
;

SELECT *
FROM Vodafone.dbo.Trip
WHERE N'P61835327-1' = ALL (SELECT ExternalContractNumber FROM Vodafone.dbo.Trip)
;

SELECT *
FROM dbo.vw_SJ_Polygons
WHERE 'Cardiff' = ALL (SELECT PolygonName FROM dbo.vw_SJ_Polygons)
;

IF N'P61835327-1' = SOME (SELECT ExternalContractNumber FROM Vodafone.dbo.Trip)
BEGIN
	PRINT '1';
END
ELSE
BEGIN
	PRINT '0';
END
;

IF EXISTS (SELECT 1 FROM Vodafone.dbo.Trip WHERE ExternalContractNumber = N'P61835327-1')
BEGIN
	PRINT '1';
END
ELSE
BEGIN
	PRINT '0';
END
;
