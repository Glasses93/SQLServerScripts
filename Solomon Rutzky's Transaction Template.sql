
SET XACT_ABORT, NOCOUNT ON;

BEGIN TRY
	SET DATEFIRST 1;

	DECLARE @InNestedTransaction bit;

	IF @@TRANCOUNT = 0
	BEGIN
		SET @InNestedTransaction = 0;
		BEGIN TRANSACTION;
	END
	ELSE
	BEGIN
		SET @InNestedTransaction = 1;
	END
	;

	-- ... 2 or more DML/DDL queries ...

	IF @InNestedTransaction = 0
	BEGIN
		COMMIT TRANSACTION;
	END
	;
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		AND @InNestedTransaction = 0
	BEGIN
		ROLLBACK TRANSACTION;
	END
	;

	;THROW;
END CATCH
;
