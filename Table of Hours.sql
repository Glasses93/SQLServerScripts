
DROP TABLE IF EXISTS #Hours;
CREATE TABLE #Hours (HourStart datetime NOT NULL, HourEnd datetime NOT NULL);

INSERT #Hours (HourStart, HourEnd)
SELECT
	 HourStart = h.[Hour]
	,HourEnd   = DATEADD(HOUR, 1, h.[Hour])
FROM dbo.Dates d
CROSS APPLY (
	SELECT [Hour] = DATEADD(HOUR, n.n - 1, CONVERT(datetime, d.[Date]))
	FROM dbo.Numbers n
	WHERE n.n BETWEEN 1 AND 24
) h
WHERE d.[Date] >= '20210101'
	AND d.[Date] < '20210201'
ORDER BY HourStart
;

ALTER TABLE #Hours ADD PRIMARY KEY CLUSTERED (HourStart ASC);

SELECT *
FROM #Hours
WHERE HourStart >= '20210101'
	AND HourEnd < '20210120'
;

;WITH x AS (
	SELECT [Hour] = DATEADD(HOUR, n - 1, '20210101')
	FROM dbo.Numbers
	WHERE n BETWEEN 1 AND DAY(EOMONTH('20210101')) * 24
)
SELECT
	 HourStart = [Hour]
	,HourEnd   = DATEADD(HOUR, 1, [Hour])
FROM x
ORDER BY HourStart
;
