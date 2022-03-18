
SET STATISTICS IO, TIME ON;

SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL))
FROM dbo.SJ_ONSPostcodeDirectory_202008
;

DROP INDEX IF EXISTS NCCI ON dbo.SJ_ONSPostcodeDirectory_202008;

CREATE NONCLUSTERED COLUMNSTORE INDEX NCCI ON dbo.SJ_ONSPostcodeDirectory_202008 (pcd)
WHERE pcd IS NULL
;

SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL))
FROM dbo.SJ_ONSPostcodeDirectory_202008
;

SELECT *
INTO dbo.SJ_Test
FROM staging.dbo.VodaTrip_RAW
;

CREATE NONCLUSTERED COLUMNSTORE INDEX NCCI ON dbo.SJ_Test (TripRawID)
WHERE TripRawID IS NULL
;

SET STATISTICS IO, TIME ON;

SELECT
	 ExternalContractNumber
	,EventTimeStamp_New
	,AccumlativeMileage =
		SUM(CONVERT(integer, DeltaTripDistance)) OVER (
			PARTITION BY ExternalContractNumber
			ORDER BY	 EventTimeStamp_New ASC
			ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
		)
FROM staging.dbo.VodaTrip_RAW a
CROSS APPLY dbo.SJ_SplitStrings(a.ExternalContractNumber, N'-') ss
ORDER BY
	 ExternalContractNumber
	,EventTimeStamp_New
;

SELECT
	 ExternalContractNumber
	,EventTimeStamp_New
	,AccumlativeMileage =
		SUM(CONVERT(integer, DeltaTripDistance)) OVER (
			PARTITION BY ExternalContractNumber
			ORDER BY	 EventTimeStamp_New ASC
			ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
		)
FROM dbo.SJ_Test
ORDER BY
	 ExternalContractNumber
	,EventTimeStamp_New
;
