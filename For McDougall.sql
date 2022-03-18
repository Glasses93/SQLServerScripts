
-- List of VF risks:
CREATE TABLE sandbox.dbo.SJ_VFPolicies (
	-- A Primary Key created a clustered index on its column by default (which means less SQL for us because it's a good choice here):
	 ID 			int				IDENTITY(1, 1)	PRIMARY KEY
	,PolicyNumber 	nvarchar(20)	NOT NULL
)
;

INSERT sandbox.dbo.SJ_VFPolicies WITH (TABLOCK) (PolicyNumber)
SELECT DISTINCT PolicyNumber
FROM Vodafone.dbo.VoucherRequest vr
WHERE PolicyNumber IS NOT NULL
	-- Just so we don't insert the same bloke twice:
	AND NOT EXISTS (
		SELECT 1
		FROM sandbox.dbo.SJ_VFPolicies p
		WHERE vr.PolicyNumber = p.PolicyNumber
	)
;

-- Confirm she looks okay:
SELECT *
FROM sandbox.dbo.SJ_VFPolicies
ORDER BY ID ASC
;

-- Let's try 100 at a time:
DECLARE @Min int = 1;
DECLARE @Max int = @Min + 99;
-- We only need to loop until we've covered all risks and no further:
DECLARE @MaxID int;

SELECT @MaxID = MAX(ID)
FROM sandbox.dbo.SJ_VFPolicies
;

-- Confirm she looks okay:
SELECT
	 @Min
	,@Max
	,[Total Number of Risks] = @MaxID
;

-- Create a table to store the timestamps of each loop? Not mandatory:
CREATE TABLE sandbox.dbo.SJ_LoopTimeStamps (
	 [Min Value] 		int				NOT NULL
	-- A "Default" constraint means that if you insert a NULL into this column it will instead place the DEFAULT value (in this case SYSDATETIME a.k.a GETDATE()):
	,[Time Finished]	datetime2(7)	DEFAULT SYSDATETIME()
)
;

WHILE @Min <= @MaxID
BEGIN
	
	SELECT
		/* ... columns required ... */
	FROM Vodafone.dbo.Trip t
	WHERE EXISTS (
		SELECT 1
		FROM sandbox.dbo.SJ_VFPolicies p
		WHERE t.ExternalContractNumber = p.PolicyNumber
			AND p.ID BETWEEN @Min AND @Max
	)
	-- This bad boy I would have to explain verbally (though its absence is not the cause of your slow query):
	OPTION (
		OPTIMIZE FOR (
			 @Min = 1
			,@Max = 100
		)
	)
	;
	
	/* ... all your other code ... */

	-- Log time of finish:
	INSERT sandbox.dbo.SJ_LoopTimeStamps ([Min Value])
	SELECT @Min
	;
	
	-- Time-check:
	IF CONVERT(time, CURRENT_TIMESTAMP) BETWEEN '01:00:00' AND '06:00:00'
	BEGIN
		PRINT
			'I''m exiting from this loop, Micah, because the ETL (Extract, Transform, Load) will try to INSERT data into Vodafone.dbo.Trip soon and it ' +
			'will require a lock on the table that the topmost query in this loop would prevent.' + CHAR(10) + CHAR(13) + 'See you tomorrow evening?' 
		;
		BREAK;
	END
	;

	-- Onto the next 100 risks, por favor:
	SET @Min = @Min + 100;
	SET @Max = @Min + 99 ;
	
END
;