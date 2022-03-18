DECLARE
	 @Account_ID	varchar(30) = NULL
	,@RegDate		date		= '20201201'
;

DECLARE @RegDatePlusOne date = DATEADD(DAY, 1, @RegDate);

DECLARE @nl nchar(1) = NCHAR(10);

DECLARE @SQL nvarchar(max) =
N'
SELECT *
FROM CMTSERV.dbo.AppAssociation
WHERE 1 = 1
'
+ CASE WHEN @Account_ID IS NOT NULL THEN N'	AND Account_ID = @Account_ID' + @nl		ELSE N'' END
+ CASE WHEN @RegDate    IS NOT NULL THEN N'	AND RegistrationDate >= @RegDate' + @nl ELSE N'' END
+ CASE WHEN @RegDate    IS NOT NULL THEN N'	AND RegistrationDate <  @RegDatePlusOne' + @nl ELSE N'' END
;

SELECT @SQL += N';';

PRINT @SQL;

EXEC sys.sp_executesql
	 @SQL
	,N'@Account_ID varchar(30), @RegDate date, @RegDatePlusOne date'
	,@Account_ID
	,@RegDate
	,@RegDatePlusOne
;
