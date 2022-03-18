
DECLARE @LOL TABLE (ID integer NOT NULL IDENTITY(1, 1), String varchar(10) NULL);

INSERT @LOL SELECT 'Hello' UNION ALL SELECT 'Hello2' UNION ALL SELECT NULL UNION ALL SELECT 'Goodbye' UNION ALL SELECT NULL UNION ALL SELECT NULL

SELECT *
FROM @LOL
ORDER BY ID ASC
;

;WITH x AS (
	SELECT
		 *
		,[Group] =
			MAX(CASE WHEN String IS NOT NULL THEN ID END) OVER (
				ORDER BY ID ASC
				ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
			)
	FROM @LOL
)
SELECT
	 *
	,Gapless = MAX(String) OVER (PARTITION BY [Group])
FROM x
ORDER BY ID ASC
;