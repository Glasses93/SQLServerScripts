;WITH x(Col) AS (
	--SELECT TOP (1) GPSDateTime
	--FROM Vodafone.dbo.Connection_Copy
	--WHERE GPSDateTime LIKE N'%[^0-9e£:T. \-]%' ESCAPE '\'
	--SELECT NCHAR(13)
	SELECT TOP (100) AnomalyID
	FROM Vodafone.dbo.GeneralMI
)
SELECT *
FROM x
OUTER APPLY (
	SELECT
		 n.n
		,[Character]		=				   SUBSTRING(x.Col, n.n, 1)
		,[ASCII/Unicode]	= /*UNICODE*/ASCII(SUBSTRING(x.Col, n.n, 1))
	FROM dbo.Numbers n
	WHERE n.n <= LEN(x.Col)
) ca
--WHERE x.Col LIKE N'%' + NCHAR(13) + N'%'
ORDER BY x.Col, ca.n
;

--SELECT
--	 *
--	,[ASCII]	=  CHAR(n)
--	,[Unicode]	= NCHAR(n)
--	,Identical	= IIF(CHAR(n) = NCHAR(n), 1, 0)
--FROM dbo.Numbers
--ORDER BY n
--;

