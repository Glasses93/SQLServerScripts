
--CREATE TABLE dbo.SJ_VFMedianSpeed (
--	 ExternalContractNumber	varchar(22)		NOT NULL
--	,TripID					varchar(40)		NOT NULL
--	,Median					decimal(4, 1)	NOT NULL
--)
--;

DECLARE @Lower nvarchar(20) = N'';
DECLARE @Upper nvarchar(20) = N'P';

-- Test #1: PC (11 secs):
;WITH c AS (
	SELECT
		 ExternalContractNumber
		,TripID
		,PC =
			PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY HorizontalSpeed ASC) OVER (
				PARTITION BY ExternalContractNumber, TripID
			)
	FROM Vodafone.dbo.Trip
	WHERE ExternalContractNumber >= @Lower
		AND ExternalContractNumber < @Upper
		AND TripID IS NOT NULL
		AND HorizontalSpeed BETWEEN 0 AND 250
)
--INSERT dbo.SJ_VFMedianSpeed WITH (TABLOCK) (
--	 ExternalContractNumber
--	,TripID
--	,Median
--)
SELECT
	 ExternalContractNumber
	,TripID
	,Median = MAX(PC)
FROM c
GROUP BY
	 ExternalContractNumber
	,TripID
;

-- Test #2: funny method (12 secs):
;WITH Counts AS
(
   SELECT ExternalContractNumber, TripID, c
   FROM
   (
      SELECT ExternalContractNumber, TripID, c1 = (c+1)/2, 
        c2 = CASE c%2 WHEN 0 THEN 1+c/2 ELSE 0 END
      FROM
      (
        SELECT ExternalContractNumber, TripID, c=COUNT(*)
        FROM Vodafone.dbo.Trip
		WHERE ExternalContractNumber >= @Lower
			AND ExternalContractNumber < @Upper
			AND TripID IS NOT NULL
			AND HorizontalSpeed BETWEEN 0 AND 250
        GROUP BY ExternalContractNumber, TripID
      ) a
   ) a
   CROSS APPLY (VALUES(c1),(c2)) b(c)
)
SELECT a.ExternalContractNumber, a.TripID, Median=AVG(0.+b.HorizontalSpeed)
FROM
(
   SELECT ExternalContractNumber, TripID, HorizontalSpeed, rn = ROW_NUMBER() OVER 
     (PARTITION BY ExternalContractNumber, TripID ORDER BY HorizontalSpeed ASC)
   FROM Vodafone.dbo.Trip
	WHERE ExternalContractNumber >= @Lower
		AND ExternalContractNumber < @Upper
		AND TripID IS NOT NULL
		AND HorizontalSpeed BETWEEN 0 AND 250
) a
CROSS APPLY
(
   SELECT a.HorizontalSpeed FROM Counts b
   WHERE a.ExternalContractNumber = b.ExternalContractNumber AND a.TripID = b.TripID AND a.rn = b.c
) b
GROUP BY a.ExternalContractNumber, a.TripID
;
GO

--CREATE TABLE dbo.SJ_VFMedianSpeedData (
--	 ExternalContractNumber	varchar(22)	NOT NULL
--	,TripID					varchar(40)	NOT NULL
--	,HorizontalSpeed		tinyint		NOT NULL
--)
--;

-- Test #3: OFFSET FETCH (36 secs):
DECLARE @Lower nvarchar(20) = N'';
DECLARE @Upper nvarchar(20) = N'P';

INSERT dbo.SJ_VFMedianSpeedData WITH (TABLOCK) (
	 ExternalContractNumber
	,TripID
	,HorizontalSpeed
)
SELECT ExternalContractNumber, TripID, HorizontalSpeed
FROM Vodafone.dbo.Trip
WHERE ExternalContractNumber >= @Lower
	AND ExternalContractNumber < @Upper
	AND TripID IS NOT NULL
	AND HorizontalSpeed BETWEEN 0 AND 250
;

-- Slow!:
CREATE CLUSTERED INDEX CIX ON dbo.SJ_VFMedianSpeedData (
	 ExternalContractNumber
	,TripID
	,HorizontalSpeed
)
;

-- Quick with index!:
;WITH c AS (
	SELECT
		 ExternalContractNumber
		,TripID
		,RC = COUNT(*)
	FROM dbo.SJ_VFMedianSpeedData
	GROUP BY
		 ExternalContractNumber
		,TripID
)
--INSERT dbo.SJ_VFMedianSpeed WITH (TABLOCK) (
--	 ExternalContractNumber
--	,TripID
--	,Median
--)
SELECT
	 c.ExternalContractNumber
	,c.TripID
	,ca.Median
FROM c
CROSS APPLY (
	SELECT Median = AVG(m.HorizontalSpeed * 1.0)
	FROM (
		SELECT t.HorizontalSpeed
		FROM dbo.SJ_VFMedianSpeedData t
		WHERE c.ExternalContractNumber = t.ExternalContractNumber
			AND c.TripID               = t.TripID
		ORDER BY t.HorizontalSpeed ASC
		OFFSET (c.RC - 1) / 2 ROWS
		FETCH NEXT 2 - (c.RC % 2) ROWS ONLY
	) m
) ca
;
