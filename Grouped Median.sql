
SET STATISTICS IO, TIME ON;

;WITH x AS (
	SELECT
		 ExternalContractNumber
		,RC = COUNT_BIG(*)
	FROM Vodafone.dbo.Trip
	WHERE ExternalContractNumber IN (SELECT TOP (100) CONVERT(nvarchar(20), PolicyNumber) FROM Vodafone.dbo.VoucherResponse WHERE PolicyNumber IS NOT NULL)
	GROUP BY ExternalContractNumber
)
SELECT x.ExternalContractNumber, ca.Median
FROM x
CROSS APPLY (
	SELECT Median = AVG(dms.DeltaMaxSpeed * 1.0)
	FROM (
		SELECT t.DeltaMaxSpeed
		FROM Vodafone.dbo.Trip t
		WHERE x.ExternalContractNumber = t.ExternalContractNumber
		ORDER BY t.DeltaMaxSpeed ASC
		OFFSET (x.RC - 1) / 2 ROWS
		FETCH NEXT 2 - (x.RC % 2) ROWS ONLY
	) dms
) ca
;

;WITH x AS (
	SELECT
		 ExternalContractNumber
		,RC = COUNT_BIG(*)
	FROM Vodafone.dbo.Trip
	WHERE ExternalContractNumber IN (SELECT TOP (100) CONVERT(nvarchar(20), PolicyNumber) FROM Vodafone.dbo.VoucherResponse WHERE PolicyNumber IS NOT NULL)
		AND DeltaMaxSpeed IS NOT NULL
	GROUP BY ExternalContractNumber
)
SELECT x.ExternalContractNumber, ca.Median
FROM x
CROSS APPLY (
	SELECT Median = AVG(dms.DeltaMaxSpeed * 1.0)
	FROM (
		SELECT t.DeltaMaxSpeed
		FROM Vodafone.dbo.Trip t
		WHERE x.ExternalContractNumber = t.ExternalContractNumber
			AND t.DeltaMaxSpeed IS NOT NULL
		ORDER BY t.DeltaMaxSpeed ASC
		OFFSET (x.RC - 1) / 2 ROWS
		FETCH NEXT 2 - (x.RC % 2) ROWS ONLY
	) dms
) ca
;


;WITH Counts AS
(
   SELECT ExternalContractNumber, c
   FROM
   (
      SELECT ExternalContractNumber, c1 = (c+1)/2, 
        c2 = CASE c%2 WHEN 0 THEN 1+c/2 ELSE 0 END
      FROM
      (
        SELECT ExternalContractNumber, c=COUNT_BIG(*)
        FROM Vodafone.dbo.Trip
		WHERE ExternalContractNumber IN (SELECT TOP (100) CONVERT(nvarchar(20), PolicyNumber) FROM Vodafone.dbo.VoucherResponse WHERE PolicyNumber IS NOT NULL)
        GROUP BY ExternalContractNumber
      ) a
   ) a
   CROSS APPLY (VALUES(c1),(c2)) b(c)
)
SELECT a.ExternalContractNumber, Median=AVG(0.+b.deltamaxspeed)
FROM
(
   SELECT ExternalContractNumber, deltamaxspeed, rn = ROW_NUMBER() OVER 
     (PARTITION BY ExternalContractNumber ORDER BY deltamaxspeed)
   FROM Vodafone.dbo.Trip a
) a
CROSS APPLY
(
   SELECT deltamaxspeed FROM Counts b
   WHERE a.ExternalContractNumber = b.ExternalContractNumber AND a.rn = b.c
) b
GROUP BY a.ExternalContractNumber
;



SELECT
	 ExternalContractNumber
	,DeltaMaxSpeed
FROM Vodafone.dbo.Trip
WHERE ExternalContractNumber = N'P61835327-1'
ORDER BY DeltaMaxSpeed
;

