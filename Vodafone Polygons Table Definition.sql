
CREATE TABLE DataSummary.dbo.VodafonePolygons (
	 ExternalContractNumber	VARCHAR(20)		NOT NULL
	,PlateNumber			VARCHAR(50)		NOT NULL
	,TripID					VARCHAR(50)		NOT NULL
	,PolygonName			VARCHAR(30)		NOT NULL
	,FirstTimeStamp			DATETIME2(2)		NULL
	,LastTimeStamp			DATETIME2(2)		NULL
	,FirstLatitude			FLOAT(53)		NOT	NULL
	,FirstLongitude			FLOAT(53)		NOT	NULL
	,LastLatitude			FLOAT(53)		NOT	NULL
	,LastLongitude			FLOAT(53)		NOT	NULL
	,HaversineMetres		INT					NULL
	,MetresDriven 			INT					NULL
	,MilesDriven			NUMERIC(9, 5)		NULL
	,HaversineMetresDriven	INT					NULL
	,SecondsDriven 			INT					NULL
	,AverageSpeedMPH   		NUMERIC(9, 6)		NULL
	,MaxSpeedMPH			NUMERIC(9, 1)		NULL
	,CountMaxGT75MPH  		SMALLINT			NULL
	,CountMaxGT85MPH  		SMALLINT			NULL
	,CountMaxGT100MPH  		SMALLINT			NULL
	,IdleTime				INT					NULL
	,NightSeconds			INT					NULL
	,NightMetres			INT					NULL	
	,Country				NVARCHAR(5)			NULL
	,County					NVARCHAR(50)		NULL
	,City					NVARCHAR(50)		NULL
	,DistancePctOfJourney	NUMERIC(9, 6)		NULL
	,TimePctOfJourney		NUMERIC(9, 6)		NULL
	,InsertedDate			DATE			NOT NULL	CONSTRAINT DF_VodafonePolygons_InsertedDate DEFAULT GETDATE()
)
;

CREATE CLUSTERED    INDEX IX_VodafonePolygons_ExternalContractNumberFirstTimeStamp ON DataSummary.dbo.VodafonePolygons (ExternalContractNumber ASC, FirstTimeStamp ASC);
CREATE NONCLUSTERED INDEX IX_VodafonePolygons_PolygonName                          ON DataSummary.dbo.VodafonePolygons (PolygonName ASC);