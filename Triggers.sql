
DROP TABLE IF EXISTS dbo.SJ_Testings;

SELECT *
INTO dbo.SJ_Testings
FROM RedTail.dbo.Association
;
GO

CREATE OR ALTER TRIGGER dbo.TR_Upd_Association
ON dbo.SJ_Testings
AFTER UPDATE
AS
SET NOCOUNT ON;

BEGIN TRY
	IF (
			NOT UPDATE(EndDate)
		OR	NOT EXISTS (SELECT 1 FROM inserted)
		OR	NOT	EXISTS (SELECT 1 FROM deleted )
	)
	BEGIN
		RETURN;
	END
	;

	IF EXISTS (
		SELECT 1
		FROM inserted i
		CROSS APPLY (
			SELECT [Should be EndDate?] = MIN(v.EndDate)
			FROM (
				VALUES
					 (CancellationDate)
					,(ReviewDate      )
					,(ReturnDate      )
			) v(EndDate)
		) ca
		WHERE EXISTS (
			SELECT i.EndDate
			EXCEPT
			SELECT ca.[Should be EndDate?]
		)
	)
	BEGIN
		RAISERROR('EndDate would not equal the minimum of CancellationDate, ReviewDate, and ReturnDate.', 16, 1);
	END
	;
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION;

	;THROW;
END CATCH
;
GO

UPDATE TOP (1) dbo.SJ_Testings
	SET EndDate = NULL
WHERE 1 = 0
;

UPDATE TOP (1) dbo.SJ_Testings
	SET EndDate = EndDate
WHERE 1 = 1
;

UPDATE TOP (100) dbo.SJ_Testings
	SET EndDate = DATEADD(DAY, 1, EndDate)
WHERE 1 = 1
;

UPDATE TOP (1) dbo.SJ_Testings
	SET ReturnDate = DATEADD(DAY, 1, EndDate)
WHERE 1 = 1
;

SELECT *
FROM RedTail.dbo.Association a
--FROM dbo.SJ_Testings a
CROSS APPLY (
	SELECT [Should be EndDate?] = MIN(v.EndDate)
	FROM (
		VALUES
			 (CancellationDate)
			,(ReviewDate)
			,(ReturnDate)
	) v(EndDate)
) ca
WHERE EXISTS (
	SELECT a.EndDate
	EXCEPT
	SELECT ca.[Should be EndDate?]
)
;
