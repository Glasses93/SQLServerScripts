
;WITH x AS (
	SELECT 
		 *
		,RN = ROW_NUMBER() OVER (PARTITION BY PolicyNumber ORDER BY InsertedDate DESC)
	FROM DataSummary.dbo.RedTailScore
	WHERE Pricing_Score IS NOT NULL
	
	SELECT 
		 *
		,RN = ROW_NUMBER() OVER (PARTITION BY PolicyNumber ORDER BY InsertedDate DESC)
	FROM DataSummary.dbo.RedTailScore
	WHERE Pricing_Score IS NOT NULL
	OPTION (MAXDOP 1)
)
SELECT *
FROM x
WHERE RN = 1
;

SELECT rs.*
FROM DataSummary.dbo.RedTailScore rs
INNER JOIN (
	SELECT
		 PolicyNumber
		,Maximom = MAX(InsertedDate)
	FROM DataSummary.dbo.RedTailScore
	GROUP BY PolicyNumber
) mid
	ON  rs.PolicyNumber = mid.PolicyNumber
	AND rs.InsertedDate = mid.Maximom
;
