
DROP TABLE IF EXISTS #T1, #YEET;

CREATE TABLE #T1 (
	 a	nvarchar(100)	NULL
	,b	nvarchar(100)	NULL
	,c	nvarchar(100)	NULL
	,d	nvarchar(100)	NULL
	,e	nvarchar(100)	NULL
	,f	nvarchar(100)	NULL
	,g	nvarchar(100)	NULL
	,h	nvarchar(100)	NULL
)
;

INSERT #T1 (a, b, c, d, e, f, g, h)
VALUES
	 (N'1', N'20200101'					  , N'2017.01.01', N'256'  , N'30000000.075', N'Helloāāā', N'Hello', N'13:00:00.0000008')
	,(N'0', N'20200101'					  , N'2017.01.01', N'32767', N'30000000.075', N'Helloāāā', N'Hello', N'13:00:00.0000008')
	,(N'1', N'20201201'					  , N'2017.01.01', N'32768', N'30000000.075', N'Helloāāā', N'Hello', N'13:00:00.0000008')
	,(NULL, N'20200101'					  , N'2017.01.01', N'256.8', N'30000000.075', N'Helloāāā', N'Hello', N'13:00:00.0000008')
	,(NULL, N'2020-01-01T13:00:00.0000006', N'2017.01.01', N'256.8', N'30000000.075', N'Helloāāā', N'Hello', N'13:00:00.0000008')
;

SELECT
	 ca.ColumnPosition
	,ca.ColumnName
	,[OnlyNulls/Blanks]		= MIN(CASE WHEN ca.ColumnValue != N''  THEN 0 ELSE 1 END)
	,OnlyNonNulls			= MIN(CASE WHEN ca.ColumnValue IS NULL THEN 0 ELSE 1 END)

	--,MinValue				= MIN(ca.ColumnValue)
	--,MaxValue				= MAX(ca.ColumnValue)

	,MinLength				= MIN(LEN(ca.ColumnValue))
	,[MaxLength]			= MAX(LEN(ca.ColumnValue))
	,AverageLength			= AVG(LEN(ca.ColumnValue) * 1.0)

	,MaxLenPreDecimal		= MAX(CHARINDEX(N'.',		  ca.ColumnValue))  - 1
	,MaxLenPostDecimal		= MAX(CHARINDEX(N'.', REVERSE(ca.ColumnValue))) - 1

	,LikelyString			= MAX(CASE WHEN ca.ColumnValue LIKE N'%[^0-9E£:T. \-]%' ESCAPE '\' THEN 1 ELSE 0 END)
	,LikelyUnicode			= MAX(CASE WHEN ca.ColumnValue != TRY_CONVERT(varchar(200), ca.ColumnValue) THEN 1 ELSE 0 END)
	,LikelyNumeric			= MIN(CASE WHEN ca.ColumnValue LIKE N'%[^0-9E£.+\-]%' ESCAPE '\' THEN 0 ELSE 1 END)
	,[LikelyDateTime/Time]	= MIN(CASE WHEN ca.ColumnValue NOT LIKE N'%:%' THEN 0 ELSE 1 END)
	,LikelyBit				= MIN(CASE WHEN ca.ColumnValue NOT IN (N'0', N'1', N'TRUE', N'FALSE') THEN 0 ELSE 1 END)

	,CanVarbinary			= MIN(CASE WHEN ca.ColumnValue IS NOT NULL AND TRY_CONVERT(varbinary		, ca.ColumnValue) IS NULL THEN 0 ELSE 1 END)
	,CanUniqueIdentifier	= MIN(CASE WHEN ca.ColumnValue IS NOT NULL AND TRY_CONVERT(uniqueidentifier	, ca.ColumnValue) IS NULL THEN 0 ELSE 1 END)
	,CanTinyint				= MIN(CASE WHEN ca.ColumnValue IS NOT NULL AND TRY_CONVERT(tinyint			, ca.ColumnValue) IS NULL THEN 0 ELSE 1 END)
	,CanSmallint			= MIN(CASE WHEN ca.ColumnValue IS NOT NULL AND TRY_CONVERT(smallint			, ca.ColumnValue) IS NULL THEN 0 ELSE 1 END)
	,CanInteger				= MIN(CASE WHEN ca.ColumnValue IS NOT NULL AND TRY_CONVERT(integer			, ca.ColumnValue) IS NULL THEN 0 ELSE 1 END)
	,CanBigint				= MIN(CASE WHEN ca.ColumnValue IS NOT NULL AND TRY_CONVERT(bigint			, ca.ColumnValue) IS NULL THEN 0 ELSE 1 END)
	,CanSmallMoney			= MIN(CASE WHEN ca.ColumnValue IS NOT NULL AND TRY_CONVERT(smallmoney		, ca.ColumnValue) IS NULL THEN 0 ELSE 1 END)
	,CanMoney				= MIN(CASE WHEN ca.ColumnValue IS NOT NULL AND TRY_CONVERT(money			, ca.ColumnValue) IS NULL THEN 0 ELSE 1 END)
	,CanDecimal				= MIN(CASE WHEN ca.ColumnValue IS NOT NULL AND TRY_CONVERT(decimal(38, 0)	, ca.ColumnValue) IS NULL THEN 0 ELSE 1 END)
	,CanReal				= MIN(CASE WHEN ca.ColumnValue IS NOT NULL AND TRY_CONVERT(real				, ca.ColumnValue) IS NULL THEN 0 ELSE 1 END)
	,CanFloat				= MIN(CASE WHEN ca.ColumnValue IS NOT NULL AND TRY_CONVERT(float(53)		, ca.ColumnValue) IS NULL THEN 0 ELSE 1 END)
	,CanTime				= MIN(CASE WHEN ca.ColumnValue IS NOT NULL AND TRY_CONVERT(time(7)			, ca.ColumnValue) IS NULL THEN 0 ELSE 1 END)
	,CanDate				= MIN(CASE WHEN ca.ColumnValue IS NOT NULL AND TRY_CONVERT(date				, ca.ColumnValue) IS NULL THEN 0 ELSE 1 END)
	,CanSmallDateTime		= MIN(CASE WHEN ca.ColumnValue IS NOT NULL AND TRY_CONVERT(smalldatetime	, ca.ColumnValue) IS NULL THEN 0 ELSE 1 END)
	,CanDateTime			= MIN(CASE WHEN ca.ColumnValue IS NOT NULL AND TRY_CONVERT(datetime			, ca.ColumnValue) IS NULL THEN 0 ELSE 1 END)
	,CanDateTime2			= MIN(CASE WHEN ca.ColumnValue IS NOT NULL AND TRY_CONVERT(datetime2(7)		, ca.ColumnValue) IS NULL THEN 0 ELSE 1 END)
	,CanDateTimeOffset		= MIN(CASE WHEN ca.ColumnValue IS NOT NULL AND TRY_CONVERT(datetimeoffset	, ca.ColumnValue) IS NULL THEN 0 ELSE 1 END)
	,CanXML					= MIN(CASE WHEN ca.ColumnValue IS NOT NULL AND TRY_CONVERT(xml				, ca.ColumnValue) IS NULL THEN 0 ELSE 1 END)
FROM #T1 T
CROSS APPLY (
	VALUES
		 (N'a', T.a, 1)
		,(N'b', T.b, 2)
		,(N'c', T.c, 3)
		,(N'd', T.d, 4)
		,(N'e', T.e, 5)
		,(N'f', T.f, 6)
		,(N'g', T.g, 7)
		,(N'h', T.h, 8)
) ca(ColumnName, ColumnValue, ColumnPosition)
GROUP BY
	 ca.ColumnPosition
	,ca.ColumnName
ORDER BY ca.ColumnPosition
;

-- A real life example:
SELECT
	 sch	= s.[name]
	,tbl	= t.[name]
	,col	= c.[name]
	,[SQL]	= REPLICATE(CHAR(9), 3) + N',(N''' + c.[name] + N''', T.' + QUOTENAME(c.[name]) + N', ' + CONVERT(nvarchar(4), c.[column_id]) + N')'
FROM [Vodafone].sys.schemas s
INNER JOIN [Vodafone].sys.tables t
	ON s.[schema_id] = t.[schema_id]
INNER JOIN [Vodafone].sys.columns c
	ON t.[object_id] = c.[object_id]
WHERE s.[name] = N'dbo'
	AND t.[name] = N'Connection_Copy'
	AND EXISTS (
		SELECT 1
		FROM sys.types ty
		WHERE c.[system_type_id] = ty.[system_type_id]
			AND ty.[name] = N'nvarchar'
	)
ORDER BY c.[column_id]
;

SELECT
	 ca.ColumnPosition
	,ca.ColumnName
	,[OnlyNulls/Blanks]		= MIN(CASE WHEN ca.ColumnValue != N''  THEN 0 ELSE 1 END)
	,OnlyNonNulls			= MIN(CASE WHEN ca.ColumnValue IS NULL THEN 0 ELSE 1 END)

	--,MinValue				= MIN(ca.ColumnValue)
	--,MaxValue				= MAX(ca.ColumnValue)

	,MinLength				= MIN(LEN(ca.ColumnValue))
	,[MaxLength]			= MAX(LEN(ca.ColumnValue))
	,AverageLength			= AVG(LEN(ca.ColumnValue) * 1.0)

	,MaxLenPreDecimal		= MAX(CHARINDEX(N'.',		  ca.ColumnValue))  - 1
	,MaxLenPostDecimal		= MAX(CHARINDEX(N'.', REVERSE(ca.ColumnValue))) - 1

	,LikelyString			= MAX(CASE WHEN ca.ColumnValue LIKE N'%[^0-9E£:T. \-]%' ESCAPE '\' THEN 1 ELSE 0 END)
	,LikelyUnicode			= MAX(CASE WHEN ca.ColumnValue != TRY_CONVERT(varchar(200), ca.ColumnValue) THEN 1 ELSE 0 END)
	,LikelyNumeric			= MIN(CASE WHEN ca.ColumnValue LIKE N'%[^0-9E£.+\-]%' ESCAPE '\' THEN 0 ELSE 1 END)
	,[LikelyDateTime/Time]	= MIN(CASE WHEN ca.ColumnValue NOT LIKE N'%:%' THEN 0 ELSE 1 END)
	,LikelyBit				= MIN(CASE WHEN ca.ColumnValue NOT IN (N'0', N'1', N'TRUE', N'FALSE') THEN 0 ELSE 1 END)

	,CanVarbinary			= MIN(CASE WHEN ca.ColumnValue IS NOT NULL AND TRY_CONVERT(varbinary		, ca.ColumnValue) IS NULL THEN 0 ELSE 1 END)
	,CanUniqueIdentifier	= MIN(CASE WHEN ca.ColumnValue IS NOT NULL AND TRY_CONVERT(uniqueidentifier	, ca.ColumnValue) IS NULL THEN 0 ELSE 1 END)
	,CanTinyint				= MIN(CASE WHEN ca.ColumnValue IS NOT NULL AND TRY_CONVERT(tinyint			, ca.ColumnValue) IS NULL THEN 0 ELSE 1 END)
	,CanSmallint			= MIN(CASE WHEN ca.ColumnValue IS NOT NULL AND TRY_CONVERT(smallint			, ca.ColumnValue) IS NULL THEN 0 ELSE 1 END)
	,CanInteger				= MIN(CASE WHEN ca.ColumnValue IS NOT NULL AND TRY_CONVERT(integer			, ca.ColumnValue) IS NULL THEN 0 ELSE 1 END)
	,CanBigint				= MIN(CASE WHEN ca.ColumnValue IS NOT NULL AND TRY_CONVERT(bigint			, ca.ColumnValue) IS NULL THEN 0 ELSE 1 END)
	,CanSmallMoney			= MIN(CASE WHEN ca.ColumnValue IS NOT NULL AND TRY_CONVERT(smallmoney		, ca.ColumnValue) IS NULL THEN 0 ELSE 1 END)
	,CanMoney				= MIN(CASE WHEN ca.ColumnValue IS NOT NULL AND TRY_CONVERT(money			, ca.ColumnValue) IS NULL THEN 0 ELSE 1 END)
	,CanDecimal				= MIN(CASE WHEN ca.ColumnValue IS NOT NULL AND TRY_CONVERT(decimal(38, 0)	, ca.ColumnValue) IS NULL THEN 0 ELSE 1 END)
	,CanReal				= MIN(CASE WHEN ca.ColumnValue IS NOT NULL AND TRY_CONVERT(real				, ca.ColumnValue) IS NULL THEN 0 ELSE 1 END)
	,CanFloat				= MIN(CASE WHEN ca.ColumnValue IS NOT NULL AND TRY_CONVERT(float(53)		, ca.ColumnValue) IS NULL THEN 0 ELSE 1 END)
	,CanTime				= MIN(CASE WHEN ca.ColumnValue IS NOT NULL AND TRY_CONVERT(time(7)			, ca.ColumnValue) IS NULL THEN 0 ELSE 1 END)
	,CanDate				= MIN(CASE WHEN ca.ColumnValue IS NOT NULL AND TRY_CONVERT(date				, ca.ColumnValue) IS NULL THEN 0 ELSE 1 END)
	,CanSmallDateTime		= MIN(CASE WHEN ca.ColumnValue IS NOT NULL AND TRY_CONVERT(smalldatetime	, ca.ColumnValue) IS NULL THEN 0 ELSE 1 END)
	,CanDateTime			= MIN(CASE WHEN ca.ColumnValue IS NOT NULL AND TRY_CONVERT(datetime			, ca.ColumnValue) IS NULL THEN 0 ELSE 1 END)
	,CanDateTime2			= MIN(CASE WHEN ca.ColumnValue IS NOT NULL AND TRY_CONVERT(datetime2(7)		, ca.ColumnValue) IS NULL THEN 0 ELSE 1 END)
	,CanDateTimeOffset		= MIN(CASE WHEN ca.ColumnValue IS NOT NULL AND TRY_CONVERT(datetimeoffset	, ca.ColumnValue) IS NULL THEN 0 ELSE 1 END)
	,CanXML					= MIN(CASE WHEN ca.ColumnValue IS NOT NULL AND TRY_CONVERT(xml				, ca.ColumnValue) IS NULL THEN 0 ELSE 1 END)
--INTO #YEET
FROM Vodafone.dbo.Connection_Copy T
CROSS APPLY (
	SELECT
		 v.ColumnName
		,v.ColumnValue
		,ColumnPosition = CONVERT(tinyint, v.ColumnPosition)
	FROM (
		VALUES
			 (N'VoucherID', T.[VoucherID], 1)
			,(N'ExternalContractNumber', T.[ExternalContractNumber], 2)
			,(N'PlateNumber', T.[PlateNumber], 3)
			,(N'VIN', T.[VIN], 4)
			,(N'DeviceSerialNumber', T.[DeviceSerialNumber], 5)
			,(N'TripID', T.[TripID], 6)
			,(N'RecordIndex', T.[RecordIndex], 7)
			,(N'TripSegmentType', T.[TripSegmentType], 8)
			,(N'RTCDateTime', T.[RTCDateTime], 9)
			,(N'GPSDateTime', T.[GPSDateTime], 10)
			,(N'GPSAccuracy', T.[GPSAccuracy], 11)
			,(N'HDOPGood', T.[HDOPGood], 12)
			,(N'Latitude', T.[Latitude], 13)
			,(N'Longitude', T.[Longitude], 14)
			,(N'Direction', T.[Direction], 15)
			,(N'Altitude', T.[Altitude], 16)
			,(N'HorizontalSpeed', T.[HorizontalSpeed], 17)
			,(N'DeltaMaxSpeed', T.[DeltaMaxSpeed], 18)
			,(N'AccumulatedTripDistance', T.[AccumulatedTripDistance], 19)
			,(N'DeltaTripDistance', T.[DeltaTripDistance], 20)
			,(N'AccumulatedTripIdleTime', T.[AccumulatedTripIdleTime], 21)
			,(N'DeltaTripIdleTime', T.[DeltaTripIdleTime], 22)
			,(N'AccumulatedTripRunTime', T.[AccumulatedTripRunTime], 23)
			,(N'Country', T.[Country], 24)
			,(N'County', T.[County], 25)
			,(N'City', T.[City], 26)
			,(N'PostalCode', T.[PostalCode], 27)
			,(N'Street', T.[Street], 28)
			,(N'TimeZone', T.[TimeZone], 29)
			,(N'StreetType', T.[StreetType], 30)
			,(N'RoadSpeedLimit', T.[RoadSpeedLimit], 31)
			,(N'DeltaAccelerations1', T.[DeltaAccelerations1], 32)
			,(N'DeltaAccelerations2', T.[DeltaAccelerations2], 33)
			,(N'DeltaAccelerations3', T.[DeltaAccelerations3], 34)
			,(N'DeltaAccelerations4', T.[DeltaAccelerations4], 35)
			,(N'DeltaAccelerations5', T.[DeltaAccelerations5], 36)
			,(N'DeltaAccelerations6', T.[DeltaAccelerations6], 37)
			,(N'DeltaAccelerations7', T.[DeltaAccelerations7], 38)
			,(N'DeltaAccelerations8', T.[DeltaAccelerations8], 39)
			,(N'DeltaAccelerations9', T.[DeltaAccelerations9], 40)
			,(N'DeltaAccelerations10', T.[DeltaAccelerations10], 41)
			,(N'DeltaDecelerations1', T.[DeltaDecelerations1], 42)
			,(N'DeltaDecelerations2', T.[DeltaDecelerations2], 43)
			,(N'DeltaDecelerations3', T.[DeltaDecelerations3], 44)
			,(N'DeltaDecelerations4', T.[DeltaDecelerations4], 45)
			,(N'DeltaDecelerations5', T.[DeltaDecelerations5], 46)
			,(N'DeltaDecelerations6', T.[DeltaDecelerations6], 47)
			,(N'DeltaDecelerations7', T.[DeltaDecelerations7], 48)
			,(N'DeltaDecelerations8', T.[DeltaDecelerations8], 49)
			,(N'DeltaDecelerations9', T.[DeltaDecelerations9], 50)
	) v(ColumnName, ColumnValue, ColumnPosition)
) ca
GROUP BY
	 ca.ColumnPosition
	,ca.ColumnName
ORDER BY ca.ColumnPosition
;

