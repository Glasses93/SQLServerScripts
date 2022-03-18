
--SET STATISTICS IO, TIME ON;

DECLARE @LOL TABLE (a integer NOT NULL PRIMARY KEY);

INSERT @LOL (a)
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1)) + 1999
FROM DNA.sys.all_objects
;

SELECT *
FROM dbo.Numbers n
WHERE EXISTS (
	SELECT 1
	FROM @LOL lol
	WHERE n.n = lol.a
)
;

SELECT *
FROM dbo.Numbers n
WHERE EXISTS (
	SELECT 1
	FROM @LOL lol
	WHERE n.n = lol.a
)
OPTION (RECOMPILE)
;

SELECT n.*
FROM dbo.Numbers n
INNER JOIN @LOL lol
	ON n.n = lol.a
;

SELECT
	 ca.FirstIMEI
	,ca.LastIMEI
	,Diff = ca.LastIMEI - ca.FirstIMEI
	,ca.RC
	,RowsPer = (ca.LastIMEI - ca.FirstIMEI) / ca.RC
FROM (
	SELECT
		 FirstIMEI = MIN(je.IMEI)
		,LastIMEI  = MAX(je.IMEI)
		,RC        = (SELECT SUM([rows]) * 1.0 FROM RedTail.sys.partitions WHERE index_id = 1 AND [object_id] = OBJECT_ID(N'RedTail.dbo.JourneyEvent', N'U'))
	FROM RedTail.dbo.JourneyEvent je
) ca
;
