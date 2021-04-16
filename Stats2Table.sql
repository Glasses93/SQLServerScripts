
CREATE TABLE dbo.SJ_Stats (RANGE_HI_KEY nvarchar(20) NULL, RANGE_ROWS float NOT NULL, EQ_ROWS float NOT NULL, DISTINCT_RANGE_ROWS bigint NOT NULL, AVG_RANGE_ROWS float NOT NULL);

INSERT dbo.SJ_Stats
EXEC (N'DBCC SHOW_STATISTICS(N''Vodafone.dbo.Trip'', N''TripAddressJourney'') WITH HISTOGRAM');

DBCC SHOW_STATISTICS(N'Vodafone.dbo.Trip', N'TripAddressJourney') WITH HISTOGRAM;

SELECT *
FROM dbo.SJ_Stats
;
