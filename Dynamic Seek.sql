DROP TABLE dbo.SJ_Test;
CREATE TABLE dbo.SJ_Test (a varchar(20));
CREATE CLUSTERED rINDEX IX ON dbo.SJ_Test (a ASC);
INSERT dbo.SJ_Test WITH (TABLOCK) (a)
SELECT TOP (100000) CHAR(64 + (ROW_NUMBER() OVER (ORDER BY (SELECT 1)) % 27))
FROM dbo.SJ_ONSPostcodeDirectory_202008
;

DECLARE @LOL varchar(max) = 'Hello';

--SELECT *
--FROM dbo.SJ_Test 
--WHERE a = @LOL
--;

SELECT *
FROM dbo.SJ_Test 
WHERE a = @LOL
OPTION (RECOMPILE)
;

SELECT *
FROM dbo.SJ_Test 
WHERE a = N'C'
OPTION (RECOMPILE)
;

SELECT *
FROM dbo.SJ_Test 
WHERE a = 'C'
OPTION (RECOMPILE)
;

SELECT CHAR(n)
FROM dbo.Numbers
;
