DROP FUNCTION dbo.SJ_Scan ;
DROP FUNCTION dbo.SJ_Scan2;
DROP FUNCTION dbo.SJ_Scan3;

CREATE OR ALTER FUNCTION dbo.SJ_Scan (
	 @List		varchar(100)
	,@nth		smallint
	,@Delimiter	varchar(10)
)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN (
	SELECT
		 s.n
		,s.s
	FROM (
		SELECT
			 n
			,nth = ROW_NUMBER() OVER (ORDER BY n ASC)
			,s   = SUBSTRING(@List, n, CHARINDEX(@Delimiter, @List + @Delimiter, n) - n)
		FROM dbo.Numbers
		WHERE n <= LEN(@List)
			AND SUBSTRING(@Delimiter + @List, n, LEN(@Delimiter)) = @Delimiter
		UNION ALL
		SELECT
			 n
			,nth = ROW_NUMBER() OVER (ORDER BY n DESC) * -1
			,s   = SUBSTRING(@List, n, CHARINDEX(@Delimiter, @List + @Delimiter, n) - n)
		FROM dbo.Numbers
		WHERE n <= LEN(@List)
			AND SUBSTRING(@Delimiter + @List, n, LEN(@Delimiter)) = @Delimiter
	) s
	LEFT OUTER JOIN dbo.SJ_BatchModeEnabler bme
		ON 1 = 0
	WHERE s.nth = @nth
)
;
GO


CREATE OR ALTER FUNCTION dbo.SJ_Scan2 (
	 @List		varchar(100)
	,@nth		smallint
	,@Delimiter	varchar(10)
)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN (
	SELECT
		 s.n
		,s.s
	FROM (
		SELECT
			 n
			,ntha = ROW_NUMBER() OVER (ORDER BY n ASC )
			,nthd = ROW_NUMBER() OVER (ORDER BY n DESC) * -1
			,s    = SUBSTRING(@List, n, CHARINDEX(@Delimiter, @List + @Delimiter, n) - n)
		FROM dbo.Numbers
		WHERE n <= LEN(@List)
			AND SUBSTRING(@Delimiter + @List, n, LEN(@Delimiter)) = @Delimiter
	) s
	LEFT JOIN dbo.SJ_BatchModeEnabler bme
		ON 1 = 0
	WHERE @nth IN (s.ntha, s.nthd)
)
;
GO

CREATE OR ALTER FUNCTION dbo.SJ_Scan3 (
	 @List		nvarchar(max)
	,@nth		smallint
	,@Delimiter	nvarchar(255)
)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN (
	WITH x AS (
		SELECT
			 n
			,ntha = ROW_NUMBER() OVER (ORDER BY n ASC )
			,nthd = ROW_NUMBER() OVER (ORDER BY n DESC) * -1
			,s   = SUBSTRING(@List, n, CHARINDEX(@Delimiter, @List + @Delimiter, n) - n)
		FROM dbo.Numbers
		WHERE n <= LEN(@List)
			AND SUBSTRING(@Delimiter + @List, n, LEN(@Delimiter)) = @Delimiter
	)
	SELECT
		 x.n
		,x.s
	FROM x
	CROSS APPLY (
		VALUES
			 (x.n, x.ntha, x.s)
			,(x.n, x.nthd, x.s)
	) v(n, nth, s)
	WHERE v.nth = @nth
)
;
GO






SET STATISTICS IO ON;


SELECT
	 n
	,s
FROM dbo.SJ_Scan(N'Hello||There||', -1, N'||')
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
CROSS APPLY dbo.SJ_Scan(T.a, -2, N'||') SS
--ORDER BY SS.n
;

SELECT
	 T.a
	,SS.s
FROM #Temp T
CROSS APPLY dbo.SJ_Scan2(T.a, -2, N'||') SS
--ORDER BY SS.n
;

SELECT
	 T.a
	,SS.s
FROM #Temp T
CROSS APPLY dbo.SJ_Scan3(T.a, -2, N'||') SS
--ORDER BY SS.n
;
