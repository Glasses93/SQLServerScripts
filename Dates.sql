DROP TABLE dbo.Dates;

CREATE TABLE dbo.Dates (
	 d	date		NOT NULL
	,wd	varchar(15)	NOT NULL

	,CONSTRAINT CHK_Dates_d  CHECK (d BETWEEN '20150101' AND '20241231')
	,CONSTRAINT CHK_Dates_wd CHECK (
		wd IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')
	 )
)
;

DECLARE @Days smallint = DATEDIFF(DAY, '20150101', '20241231') + 1

INSERT dbo.Dates WITH (TABLOCK) (d, wd)
SELECT TOP(@Days)
	 DATEADD(
		 DAY
		,ROW_NUMBER() OVER (ORDER BY [object_id] ASC) - 1
		,CONVERT(date, '20150101')
	 )
	,DATENAME(WEEKDAY,
		 DATEADD(
			 DAY
			,ROW_NUMBER() OVER (ORDER BY [object_id] ASC) - 1
			,CONVERT(date, '20150101')
		 )
	 )
FROM staging.sys.all_columns
ORDER BY [object_id] ASC
;

ALTER TABLE dbo.Dates
ADD CONSTRAINT PK_Dates_d PRIMARY KEY CLUSTERED (d ASC)
;

CREATE NONCLUSTERED INDEX NCIX_Dates_wd
ON dbo.Dates (wd ASC)
;

SELECT *
FROM dbo.Dates
;
