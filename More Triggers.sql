-- How to allow transaction to complete even if triggering code errors:
DROP TABLE IF EXISTS dbo.SJ_Testies;
CREATE TABLE dbo.SJ_Testies (a integer NOT NULL PRIMARY KEY);
INSERT dbo.SJ_Testies SELECT 3;
GO

CREATE OR ALTER TRIGGER dbo.TR_SJ_INS
ON dbo.SJ_Testies
AFTER INSERT
AS
BEGIN
	BEGIN TRY
		SET XACT_ABORT OFF;
		INSERT dbo.SJ_Testies (a) SELECT 1;
		SET XACT_ABORT ON;
	END TRY
	BEGIN CATCH
		SET XACT_ABORT ON;
		SELECT msg = 'HEY';
	END CATCH
	;
END
;

-- Quicker to use @@ROWCOUNT (or ROWCOUNT_BIG()) if you can use it safely, as opposed to counting rows from the inserted/deleted tables:
DROP TABLE IF EXISTS dbo.SJ_Testies;
CREATE TABLE dbo.SJ_Testies (a integer NULL);
INSERT dbo.SJ_Testies (a) SELECT * FROM dbo.Numbers;
UPDATE dbo.SJ_Testies SET a = 1;
DELETE dbo.SJ_Testies;

MERGE dbo.SJ_Testies AS t
USING (SELECT 1 UNION ALL SELECT 3) AS s(n)
ON (t.a = s.n)
WHEN MATCHED THEN
	UPDATE SET t.a = s.n
WHEN NOT MATCHED THEN
INSERT (a)
VALUES (s.n)
;
GO

CREATE OR ALTER TRIGGER dbo.SJ_TR_DEL
ON dbo.SJ_Testies
AFTER DELETE
AS
BEGIN
	--SELECT
	--	 'DELETE'
	--	,rc  = @@ROWCOUNT
	--	,ins = (SELECT COUNT(*) FROM inserted)
	--	,del = (SELECT COUNT(*) FROM deleted)
	--;
END
;
GO

CREATE OR ALTER TRIGGER dbo.SJ_TR_INS
ON dbo.SJ_Testies
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	DECLARE @RowsAffected bigint = ROWCOUNT_BIG();

	SET NOCOUNT ON;

	BEGIN TRY
		IF EXISTS (SELECT 1 FROM inserted)
			AND NOT EXISTS (SELECT 1 FROM deleted)
		BEGIN
			DECLARE @TimeNow datetime2(7) = SYSDATETIME();

			SELECT
			 	 op  = 'INSERT'
				,ins = (SELECT COUNT_BIG(*) FROM inserted)
			;

			SELECT DATEDIFF(MILLISECOND, @TimeNow, SYSDATETIME());
			SET @TimeNow = SYSDATETIME()

			SELECT
				 op  = 'INSERT'
				,ins = @RowsAffected
			;
			
			SELECT DATEDIFF(MILLISECOND, @TimeNow, SYSDATETIME());
		END
		;
		
		--IF EXISTS (SELECT 1 FROM inserted)
		--	AND EXISTS (SELECT 1 FROM deleted)
		--BEGIN
		--	SELECT
		--		 op
		--		,ins
		--		,del = ins
		--	FROM (
		--		SELECT
		--			 op  = 'UPDATE'
		--			,ins = (SELECT COUNT_BIG(*) FROM inserted)
		--	) a
		--	;
		--END
		--;
		
		--IF NOT EXISTS (SELECT 1 FROM inserted)
		--	AND EXISTS (SELECT 1 FROM deleted)
		--BEGIN
		--	SELECT
		--		 op  = 'DELETE'
		--		,del = (SELECT COUNT_BIG(*) FROM deleted)
		--	;
		--END
		--;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK TRANSACTION;
		END
		;

		;THROW;
	END CATCH
	;
END
;
GO

CREATE OR ALTER TRIGGER dbo.SJ_TR_UPD
ON dbo.SJ_Testies
AFTER UPDATE
AS
BEGIN
	SELECT
		 'UPDATE'
		,rc  = @@ROWCOUNT
		,ins = (SELECT COUNT(*) FROM inserted)
		,del = (SELECT COUNT(*) FROM deleted)
	;
END
;
GO
