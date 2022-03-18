
-- This will not raise an error because the ;THROW; is within the TRY block.
-- Also, execution post the ;THROW; proceeds:
BEGIN TRY
	BEGIN TRY
		EXEC sys.sp_executesql N'SELECT a = 1/0;';
	END TRY
	BEGIN CATCH
		PRINT 'LOL';
		;THROW;
	END CATCH
	;
END TRY
BEGIN CATCH
	PRINT 'HEY';
	--;THROW;
END CATCH
;

-- This will raise the error and the final HEY will not be printed:
BEGIN TRY
	EXEC sys.sp_executesql N'SELECT a = 1/0;';
END TRY
BEGIN CATCH
	BEGIN TRY
		EXEC sys.sp_executesql N'SELECT a = 1/0;';
	END TRY
	BEGIN CATCH
		PRINT 'LOL';
		;THROW;
	END CATCH
	;
	PRINT 'HEY';
END CATCH
;
