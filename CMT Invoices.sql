
;WITH x AS (
	SELECT
		 ImportFileID
		,TripEndUTCDate = CONVERT(date, Trip_End)
		,rn				= ROW_NUMBER() OVER (PARTITION BY ImportFileID ORDER BY COUNT(*) DESC)
	FROM CMTSERV.dbo.CMTTripSummary_EL
	GROUP BY
		 ImportFileID
		,CONVERT(date, Trip_End)
)
SELECT UploadDate = DATEADD(DAY, 1, TripEndUTCDate)
FROM x
WHERE rn = 1
ORDER BY UploadDate DESC
;
