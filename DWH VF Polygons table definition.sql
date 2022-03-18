

CREATE TABLE Sandbox.dbo.SJ_VodafonePolygonSummary (
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
	,MilesDriven			NUMERIC(9, 4)		NULL
	,HaversineMetresDriven	INT					NULL
	,SecondsDriven 			INT					NULL
	,AverageSpeedMPH   		NUMERIC(9, 4)		NULL
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
	,DistancePctOfJourney	NUMERIC(9, 8)		NULL
	,TimePctOfJourney		NUMERIC(9, 8)		NULL
	,InsertedDate			DATE			NOT NULL	CONSTRAINT DF_VodafonePolygonSummary_InsertedDate DEFAULT GETDATE()
)
;

CREATE CLUSTERED INDEX IX_VodafonePolygonSummary_ExternalContractNumberFirstTimeStamp
	ON DataSummary.dbo.VodafonePolygonSummary (
		 ExternalContractNumber ASC
		,FirstTimeStamp			ASC
	)
;

CREATE NONCLUSTERED INDEX IX_VodafonePolygonSummary_PolygonName
	ON DataSummary.dbo.VodafonePolygonSummary (PolygonName ASC)
;
