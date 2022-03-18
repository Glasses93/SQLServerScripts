SET STATISTICS IO ON;

SELECT TOP (26) CHAR(64 + ROW_NUMBER() OVER (ORDER BY [Month], [Day]))
FROM dbo.SJ_VFS_DawnDuskTime
ORDER BY [Month], [Day]
;


		DECLARE @LF	 nchar(1) = NCHAR(10);
		DECLARE @SQL nvarchar(max) =
					N'SELECT ...'
			+ @LF + N'FROM Tableau'
			+ @LF + N'WHERE ...'
			+ @LF + N';'
		;

PRINT @SQL;
SELECT @SQL;

