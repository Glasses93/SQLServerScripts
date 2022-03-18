
CREATE TABLE sandbox.dbo.AddressBaseFile20190311 (
	 Latitude				float(53)	NOT NULL
	,Longitude				float(53)	NOT NULL
	,Street_Description		varchar(50)	NOT	NULL
	,Town_Name				varchar(25)	NOT	NULL
	,Administrative_Area	varchar(25)	NOT	NULL
	,Postcode_Locator		varchar(16)	NOT	NULL
)
;

ALTER TABLE sandbox.dbo.AddressBaseFile20190311
ADD ID int NOT NULL IDENTITY(1, 1)
;

ALTER TABLE sandbox.dbo.AddressBaseFile20190311
ADD Coordinate AS geography::Point(Latitude, Longitude, 4326) PERSISTED
;

ALTER TABLE sandbox.dbo.AddressBaseFile20190311
ADD CONSTRAINT PK_AddressBaseFile20190311_ID PRIMARY KEY CLUSTERED ( ID ASC )
;

CREATE SPATIAL INDEX IX_AddressBaseFile20190311_Coordinate ON sandbox.dbo.AddressBaseFile20190311 ( Coordinate );
CREATE NONCLUSTERED INDEX IX_AddressBaseFile20190311_PostcodeLocator ON sandbox.dbo.AddressBaseFile20190311 ( Postcode_Locator ASC );

;WITH x AS (
SELECT MyHouse = geography::Point(51.529085, -3.202239, 4326)
)
SELECT x.*, oa.*
FROM x
OUTER APPLY (
SELECT TOP (1) WITH TIES *
FROM sandbox.dbo.AddressBaseFile20190311 abf
WHERE x.MyHouse.STDistance(abf.Coordinate) <= 0.01 * 1609.344
ORDER BY x.MyHouse.STDistance(abf.Coordinate) ASC
) oa
