;WITH x AS (
SELECT TOP (0) OrderNumber
FROM RedTail.dbo.Association
)
SELECT ABS(OrderNumber)
FROM x
;

DECLARE @TableName sysname = N'AppAssociation_Log';
DECLARE @LOL varchar(70) = 'Index Rebuild';
DECLARE @SQL nvarchar(max) = N'
SELECT *
FROM dbo.AppAssociation_Log
WHERE StepName = @LOL
ORDER BY 1 DESC
;'
;
PRINT @SQL;

EXEC sys.sp_executesql @SQL, N'@LOL varchar(70)', @LOL;


SELECT TOP (100)
	 a.*
	,md.FirstDate
	,FirstDateColumn =
		CASE md.FirstDate
			WHEN a.SentDate         THEN 'Sent Date'
			WHEN a.StartDate        THEN 'Start Date'
			WHEN a.ReviewDate       THEN 'Review Date'
			WHEN a.ReturnDate       THEN 'Return Date'
			WHEN a.CancellationDate THEN 'Cancellation Date'
									ELSE 'Other'
		END
FROM RedTail.dbo.Association a
CROSS APPLY (
	SELECT FirstDate = MIN(v.d)
	FROM (
		VALUES
			 (SentDate)
			,(StartDate)
			,(ReviewDate)
			,(ReturnDate)
			,(CancellationDate)
	) v(d)
) md
;

DECLARE @Executive nvarchar(max) = N'
EXEC datawarehouse.sys.sp_executesql @SQL;
EXEC RedTail.sys.sp_executesql @SQL;
'
;

EXEC sys.sp_executesql @Executive, N'@SQL nvarchar(max)', N'SELECT TOP (100) * FROM dbo.JourneyEvent;';
