DROP FUNCTION dbo.SJ_SplitStrings ;
DROP FUNCTION dbo.SJ_SplitStrings2;
GO

CREATE OR ALTER FUNCTION dbo.SJ_SplitStrings (
	 @List		nvarchar(max)
	,@Delimiter	nvarchar(255)
)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN (
	SELECT
		 n
		,s = SUBSTRING(@List, n, CHARINDEX(@Delimiter, @List + @Delimiter, n) - n)
		--,rn = ROW_NUMBER() OVER (ORDER BY n ASC)
	FROM dbo.Numbers
	WHERE n <= CONVERT(smallint, LEN(@List))
		AND SUBSTRING(@Delimiter + @List, n, LEN(@Delimiter)) = @Delimiter
)
;
GO

CREATE OR ALTER FUNCTION dbo.SJ_SplitStringsLite (
	 @List		varchar(200)
	,@Delimiter	varchar(10)
)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN (
	SELECT
		 n
		,s = SUBSTRING(@List, n, CHARINDEX(@Delimiter, @List + @Delimiter, n) - n)
		--,rn = ROW_NUMBER() OVER (ORDER BY n ASC)
	FROM dbo.Numbers
	WHERE n <= CONVERT(smallint, LEN(@List))
		AND SUBSTRING(@Delimiter + @List, n, LEN(@Delimiter)) = @Delimiter
)
;
GO

SELECT
	 n
	,s
FROM dbo.SJ_SplitStrings(N'Hello||There||', N'||')
;

DROP TABLE IF EXISTS #Temp;	
CREATE TABLE #Temp (a varchar(50) NULL);
INSERT #Temp (a) --DEFAULT VALUES;
SELECT TOP (100000) 'Hello||there||my|| name||  is.'
FROM dbo.SJ_ONSPostcodeDirectory_202008
;

SELECT
	 T.a
	,SS.s
FROM #Temp T
OUTER APPLY dbo.SJ_SplitStrings(T.a, N'||') SS
;

SELECT
	 T.a
	,SS.s
FROM #Temp T
OUTER APPLY dbo.SJ_SplitStringsLite(T.a, N'||') SS
;

SELECT
	 a.*
	,ss.*
	,ROW_NUMBER() OVER (ORDER BY ss.n ASC)
FROM RedTail.dbo.Association a
CROSS APPLY dbo.SJ_SplitStrings(a.PolicyNumber, N'-') ss
;

SELECT
	 a.*
	,ss.*
	,ROW_NUMBER() OVER (ORDER BY ss.n ASC)
FROM RedTail.dbo.Association a
CROSS APPLY dbo.SJ_SplitStringsLite(a.PolicyNumber, '-') ss
;

