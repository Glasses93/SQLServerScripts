
SET SHOWPLAN_TEXT ON;
SET SHOWPLAN_TEXT OFF;

SELECT
PolicyNumber
,FinalDay = MAX(EffectToDate)
INTO #Policies
FROM Sandbox.dbo.PolCVPTrav
WHERE EffectFromDate <= '03/05/2020'
AND TraversedFlag = '1'
AND TelematicsFlag = '1'
AND TeleDevSuppl = 'vodafone'
AND TeleDevRem = '0'
GROUP BY PolicyNumber
;

CREATE CLUSTERED INDEX IX_Policies_PolicyNumberFinalDay ON #Policies (PolicyNumber ASC, FinalDay ASC);

DECLARE @Day DATE = '02/01/2020';

PRINT @Day;

WHILE @Day < '01/02/2020'
BEGIN

INSERT #ForeignDriving (ExternalContractNumber, EventTimeStamp, Latitude, Longitude)
SELECT
ExternalContractNumber
,EventTimeStamp
,Latitude
,Longitude
FROM Vodafone.dbo.Trip t
WHERE EXISTS (
SELECT 1
FROM #Policies p
WHERE t.ExternalContractNumber = p.PolicyNumber
AND p.FinalDay > @Day
)
AND EventTimeStamp >= DATEADD(DAY, DATEDIFF(DAY, 0, @Day), 0)
AND EventTimeStamp < DATEADD(DAY, DATEDIFF(DAY, 0, @Day), 1)
AND (
SELECT p2.Polygon FROM Sandbox.dbo.SJ_Polygons p2 WHERE p2.PolygonName = 'British Isles'
).STIntersects(GEOGRAPHY::Point(Latitude, Longitude, 4326)) = 0
;

IF CAST(GETDATE() AS TIME) BETWEEN '01:00:00' AND '03:00:00' BREAK;

SET @Day = DATEADD(DAY, 1, @Day);

END
;

SELECT *
FROM #ForeignDriving
;

SELECT *
INTO Sandbox.dbo.SJ_VFFD2020
FROM #ForeignDriving
;






