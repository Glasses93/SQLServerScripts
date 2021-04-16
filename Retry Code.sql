
SET NOCOUNT, XACT_ABORT ON;

BEGIN TRY
	DECLARE @AttemptsRemaining tinyint = 3;
	DECLARE @Success		   bit     = 0;

	WHILE @AttemptsRemaining > 0
		AND @Success = 0
	BEGIN
		BEGIN TRY
			DROP TABLE IF EXISTS dbo.SJ_PolCVPTrav;

			BEGIN TRANSACTION;
				CREATE TABLE dbo.SJ_PolCVPTrav (a integer NULL);

				INSERT dbo.SJ_PolCVPTrav (a)
				SELECT TOP (0) 1
				;

				IF @@ROWCOUNT = 0
				BEGIN
					RAISERROR('There was an error inserting rows into sandbox.dbo.PolCVPTrav.', 16, 1);
				END
				;
			COMMIT TRANSACTION;

			SET @Success = 1;
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0
			BEGIN
				ROLLBACK TRANSACTION;
			END
			;

			SET @AttemptsRemaining -= 1;
			PRINT 'Attempts remaining: ' + CONVERT(char(1), @AttemptsRemaining);

			IF @AttemptsRemaining = 0
			BEGIN
				;THROW;
			END
			;
		END CATCH
		;
	END
	;
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
--SELECT @@TRANCOUNT;

--SELECT *
--FROM dbo.SJ_PolCVPTrav
--;
