DROP FUNCTION dbo.SJ_Least;
GO

CREATE OR ALTER FUNCTION dbo.SJ_Least (
	 @Parameter1	sql_variant
	,@Parameter2	sql_variant
)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN (
	SELECT Least = MIN(p)
	FROM (
		VALUES
			 (CASE WHEN TRY_CONVERT(datetime, @Parameter1) IS NULL THEN
				CASE WHEN TRY_CONVERT(numeric(38, 15), @Parameter1) IS NULL THEN TRY_CONVERT(nvarchar(100), @Parameter1) ELSE TRY_CONVERT(numeric(38, 15), @Parameter1) END
			  ELSE TRY_CONVERT(datetime, @Parameter1) END)
			,(CASE WHEN TRY_CONVERT(datetime, @Parameter2) IS NULL THEN
				CASE WHEN TRY_CONVERT(numeric(38, 15), @Parameter2) IS NULL THEN TRY_CONVERT(nvarchar(100), @Parameter2) ELSE TRY_CONVERT(numeric(38, 15), @Parameter2) END
			  ELSE TRY_CONVERT(datetime, @Parameter2) END)
	) v(p)
	LEFT JOIN dbo.SJ_BatchModeEnabler bme
		ON 1 = 0
)
;
GO

SELECT Least
FROM dbo.SJ_Least('37.4', '37.39999999999999')
;

-- 2016-04-25	2015-08-10	2015-11-10
