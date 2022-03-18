
DROP TABLE IF EXISTS Sandbox.dbo.SJ_DFPP_Policies;

;WITH AVB AS (
SELECT PolicyNumber
FROM Sandbox.dbo.PolCVPTrav
WHERE TraversedFlag = '1'
AND EffectFromDate <= CAST(GETDATE() AS DATE)
AND EffectToDate > CAST(GETDATE() AS DATE)
AND TelematicsFlag = '1'
AND TeleDevSuppl = 'vodafone'
AND TeleDevRem = '0'
)
SELECT
PolicyNumber = CAST(PolicyNumber AS NVARCHAR(20))
,FirstDayOnCover = MIN(EffectFromDate)
INTO Sandbox.dbo.SJ_DFPP_Policies
FROM Sandbox.dbo.PolCVPTrav p
WHERE EXISTS (
SELECT 1
FROM AVB
WHERE p.PolicyNumber = avb.PolicyNumber
)
AND TraversedFlag = '1'
AND EffectFromDate <= CAST(GETDATE() AS DATE)
AND TelematicsFlag = '1'
AND TeleDevSuppl = 'vodafone'
AND TeleDevRem = '0'
GROUP BY PolicyNumber
;

CREATE CLUSTERED INDEX IX_SJDFPPPolicies_FirstDayOnCover ON Sandbox.dbo.SJ_DFPP_Policies (FirstDayOnCover ASC);

DROP TABLE IF EXISTS Sandbox.dbo.SJ_DFPP_JE;

;WITH Policies AS (
SELECT PolicyNumber
FROM Sandbox.dbo.SJ_DFPP_Policies
ORDER BY FirstDayOnCover ASC
OFFSET 0 ROWS
FETCH NEXT 1 ROWS ONLY
)
SELECT
ExternalContractNumber
,TripID
,EventTimeStamp
,Latitude
,Longitude
,VFMetresDriven = DeltaTripDistance * 100
,Coordinate = GEOGRAPHY::Point(Latitude, Longitude, 4326)
INTO Sandbox.dbo.SJ_DFPP_JE
FROM Vodafone.dbo.Trip t
WHERE EXISTS (
SELECT 1
FROM Policies p
WHERE t.ExternalContractNumber = p.PolicyNumber
)
;

DROP TABLE IF EXISTS Sandbox.dbo.SJ_DFPP_Distances;

INSERT Sandbox.dbo.SJ_DFPP_Distances WITH (TABLOCK) (
ExternalContractNumber
,TripID
,EventTimeStamp
,Latitude
,Longitude
,VFMetresDriven
,OurMetresDriven
)
SELECT
ExternalContractNumber
,TripID
,EventTimeStamp
,Latitude
,Longitude
,VFMetresDriven
,OurMetresDriven =
Coordinate.STDistance(
LAG(Coordinate, 1, NULL) OVER (PARTITION BY ExternalContractNumber, TripID ORDER BY EventTimeStamp ASC)
)
INTO Sandbox.dbo.SJ_DFPP_Distances
FROM Sandbox.dbo.SJ_DFPP_JE

SELECT
ExternalContractNumber
,TripID
,EventCount = COUNT(*)
,EventsOursGTVF = COUNT(CASE WHEN OurMetresDriven > VFMetresDriven AND OurMetresDriven > 100 THEN TripID ELSE NULL END)
,Percentage = CAST(COUNT(CASE WHEN OurMetresDriven > VFMetresDriven AND OurMetresDriven > 100 THEN TripID ELSE NULL END) / ( COUNT(*) * 1.0 ) AS NUMERIC(9, 8))
,VFJourneyMetres = SUM(VFMetresDriven)
,OurJourneyMetres = SUM(OurMetresDriven)
FROM Sandbox.dbo.SJ_DFPP_Distances
GROUP BY
ExternalContractNumber
,TripID
HAVING SUM(OurMetresDriven) > SUM(VFMetresDriven)
;


SELECT
--Latitude,
--Longitude,
*
FROM Sandbox.dbo.SJ_DFPP_Distances
WHERE TripID = N'77298820191116111429'
ORDER BY EventTimeStamp ASC
;

