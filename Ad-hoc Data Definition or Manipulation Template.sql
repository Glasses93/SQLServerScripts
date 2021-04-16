
-- Switch to the right DB:
USE ;

-- Ignore these variable declarations:
DECLARE @CRLF			 char(2)   = CHAR(13) + CHAR(10);
DECLARE @ProdSrvErrorMsg varchar(250) =
		'You are on a production server, by the way.'
	+	@CRLF
	+	'Have you tested this work on a development server first?'
	+	REPLICATE(@CRLF, 2)
	+	'This batch will abort here.'
	+	@CRLF
	+	'Comment out this check and re-run the batch if you wish to ignore this message.'
;

DECLARE @OpenTranErrorMsg varchar(250) =
		'You are already in a transaction, by the way.'
	+	@CRLF
	+	'Should you not COMMIT/ROLLBACK that transaction before doing more work?'
	+	REPLICATE(@CRLF, 2)
	+	'This batch will abort here.'
	+	@CRLF
	+	'Comment out this check and re-run the batch if you wish to ignore this message.'
;

-- Server check:
IF @@SERVERNAME = N'PR-SQLD-001'
BEGIN
	RAISERROR(@ProdSrvErrorMsg, 1, 0);
	RETURN;
END
;

-- Open transaction check:
IF @@TRANCOUNT > 0
BEGIN
	RAISERROR(@OpenTranErrorMsg, 1, 0);
	RETURN;
END
;

-- Optional:
/*SET TRANSACTION ISOLATION LEVEL ...*/

-- Additional info:
SELECT
	[Current Transaction Isolation Level] =
		CASE transaction_isolation_level
			WHEN 0 THEN 'Unspecified'
			WHEN 1 THEN 'Read Uncommitted'
			WHEN 2 THEN 'Read Committed'
			WHEN 3 THEN 'Repeatable'
			WHEN 4 THEN 'Serializable'
			WHEN 5 THEN 'Snapshot'
		END
FROM sys.dm_exec_sessions
WHERE session_id = @@SPID
;

-- No need for more than one open transaction because you may forget to COMMIT them all and actually make any changes:
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRANSACTION;
END
;

	-- Make changes here...











-- Changes are good to go?
/*COMMIT TRANSACTION;*/

-- An accident occurred?
/*ROLLBACK TRANSACTION;*/

-- Remember not to leave for lunch/holiday with an open transaction!:
SELECT [# of Open Transactions] = @@TRANCOUNT;
