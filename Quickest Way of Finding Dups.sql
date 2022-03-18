
DECLARE @Now datetime2(7) = SYSDATETIME();

IF EXISTS (
	SELECT 1
	FROM Vodafone.dbo.Trip_COVID
	GROUP BY ExternalContractNumber
	HAVING COUNT_BIG(*) > 1
)
BEGIN
	PRINT 'Found.';
END
;

DECLARE @Time integer = DATEDIFF(SECOND, @Now, SYSDATETIME());
RAISERROR('Test #1: Number of seconds passed = %d', 0, 1, @Time) WITH NOWAIT;
SELECT @Now = SYSDATETIME();

IF EXISTS (
	SELECT 1
	FROM Vodafone.dbo.Trip_COVID a1
	INNER HASH JOIN Vodafone.dbo.Trip_COVID a2
		ON  a1.ExternalContractNumber = a2.ExternalContractNumber
		AND EXISTS (
			SELECT a1.EventTimeStamp
			EXCEPT
			SELECT a2.EventTimeStamp
		)
)
BEGIN
	PRINT 'Found.';
END
;

SELECT @Time = DATEDIFF(SECOND, @Now, SYSDATETIME());
RAISERROR('Test #2: Number of seconds passed = %d', 0, 1, @Time) WITH NOWAIT;
SELECT @Now = SYSDATETIME();

IF EXISTS (
	SELECT 1
	FROM Vodafone.dbo.Trip_COVID a1
	INNER JOIN Vodafone.dbo.Trip_COVID a2
		ON  a1.ExternalContractNumber = a2.ExternalContractNumber
		AND EXISTS (
			SELECT a1.EventTimeStamp
			EXCEPT
			SELECT a2.EventTimeStamp
		)
)
BEGIN
	PRINT 'Found.';
END
;

SELECT @Time = DATEDIFF(SECOND, @Now, SYSDATETIME());
RAISERROR('Test #3: Number of seconds passed = %d', 0, 1, @Time) WITH NOWAIT;
SELECT @Now = SYSDATETIME();
















IF EXISTS (
	SELECT 1
	FROM (
		SELECT RN = ROW_NUMBER() OVER (PARTITION BY PolicyNumber ORDER BY (SELECT 1))
		FROM RedTail.dbo.Association
		WHERE PolicyNumber IS NOT NULL
	) rn
	WHERE RN = 2
)
BEGIN
	PRINT 'Found.';
END
;

IF EXISTS (
	SELECT 1
	FROM RedTail.dbo.Association a1
	WHERE EXISTS (
		SELECT 1
		FROM RedTail.dbo.Association a2
		WHERE a1.PolicyNumber = a2.PolicyNumber
			AND EXISTS (
				SELECT a1.AssociationID
				EXCEPT
				SELECT a2.AssociationID
			)
	)
)
BEGIN
	PRINT 'Found.';
END
;

IF EXISTS (
	SELECT 1
	FROM (
		SELECT RN = ROW_NUMBER() OVER (PARTITION BY PolicyNumber ORDER BY (SELECT 1))
		FROM RedTail.dbo.Association
		WHERE PolicyNumber IS NOT NULL
	) rn
	WHERE RN > 2
)
BEGIN
	PRINT 'Found.';
END
;
