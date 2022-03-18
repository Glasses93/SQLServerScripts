
--DROP TABLE dbo.SJ_Logarithms;
--CREATE TABLE dbo.SJ_Logarithms (
--	 [Schema]		sysname			NOT NULL
--	,[Table]		sysname			NOT NULL
--	,LastModified	datetime2(7)	NOT NULL

--	,CONSTRAINT PK_Logarithms_TableSchema PRIMARY KEY CLUSTERED (
--		 [Table]  ASC
--		,[Schema] ASC
--	)
--)
--;

USE sandbox;
GO

DECLARE @SQL  nvarchar(max) = N'';
DECLARE @CRLF nchar(2)		= NCHAR(13) + NCHAR(10)

SELECT @SQL +=
																								+ @CRLF
	+	N'CREATE TRIGGER ' + QUOTENAME(s.[name]) + N'.[TR_Mod_' + LEFT(t.[name], 122) + N']'	+ @CRLF
	+	N'ON '			   + QUOTENAME(s.[name]) + N'.' + QUOTENAME(t.[name])					+ @CRLF
	+	N'AFTER INSERT, UPDATE, DELETE'															+ @CRLF
	+	N'AS'																					+ @CRLF
	+	N'BEGIN'																				+ @CRLF
	+	N'
	SET NOCOUNT ON;
	SET LOCK_TIMEOUT 10000;

	BEGIN TRY
		SET XACT_ABORT OFF;

		UPDATE dbo.SJ_Logarithms WITH (UPDLOCK, SERIALIZABLE)
			SET LastModified = SYSDATETIME()
		WHERE [Schema] = N'''  + s.[name] + N'''
			AND [Table] = N''' + t.[name] + N'''
		;

		IF @@ROWCOUNT = 0
		BEGIN
			INSERT dbo.SJ_Logarithms (
				 [Schema]
				,[Table]
				,LastModified
			)
			SELECT N''' + s.[name] + N''', N''' + t.[name] + N''', SYSDATETIME()
			;
		END
		;
		SET XACT_ABORT ON;
	END TRY
	BEGIN CATCH
		SET XACT_ABORT ON;
	END CATCH
	;'			+ @CRLF
	+	N'END'	+ @CRLF
	+	N';'	+ @CRLF
	+	N'GO'	+ @CRLF
FROM sys.schemas s
INNER JOIN sys.tables t
	ON s.[schema_id] = t.[schema_id]
;

PRINT @SQL;

--SELECT *
--FROM dbo.SJ_Logarithms
--ORDER BY [Schema], [Table]
--;

--CREATE OR ALTER TRIGGER dbo.TR_Mod_SJ_VFTESTINGS
--ON dbo.SJ_VFTESTINGS
--AFTER INSERT, UPDATE, DELETE
--AS
--BEGIN
--	SET NOCOUNT ON;
--	SET LOCK_TIMEOUT 10000;

--	BEGIN TRY
--		SET XACT_ABORT OFF;

--		UPDATE dbo.SJ_Logarithms WITH (UPDLOCK, SERIALIZABLE)
--			SET LastModified = SYSDATETIME()
--		WHERE [Schema] = N'dbo'
--			AND [Table] = N'SJ_VFTESTINGS'
--		;

--		IF @@ROWCOUNT = 0
--		BEGIN
--			INSERT dbo.SJ_Logarithms (
--				 [Schema]
--				,[Table]
--				,LastModified
--			)
--			SELECT
--				 N'dbo'
--				,N'SJ_VFTESTINGS'
--				,SYSDATETIME()
--			;
--		END
--		;
--		SET XACT_ABORT ON;
--	END TRY
--	BEGIN CATCH
--		SET XACT_ABORT ON;
--	END CATCH
--	;
--END
--;
