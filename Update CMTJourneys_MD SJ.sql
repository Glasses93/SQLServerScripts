
-- ===================================================================
-- MD one-off Script to:
	-- add Braking_Points variable to Staging.CMTTripSummaryCombined_test
	-- add also to DS.CMTJourneys and backdate values from CMTServ.dbo.CMTTripSummary
	-- add index to DS.CMTJourneys
-- ===================================================================


--TEST:
-- select *
-- into sandbox.dbo.MD_CMTTripSummaryCombined_test 
-- from staging.dbo.CMTTripSummaryCombined

-- select * from sandbox.dbo.MD_CMTTripSummaryCombined_test 
-- ALTER TABLE sandbox.dbo.MD_CMTTripSummaryCombined_test 
-- ADD Braking_Points NUMERIC(18,6);

-- select *
-- into sandbox.dbo.MD_CMTJourneys_test
-- from datasummary.dbo.CMTJourneys

-- select top 100 * from sandbox.dbo.MD_CMTJourneys_test
-- ALTER TABLE sandbox.dbo.MD_CMTJourneys_test
-- ADD Braking_Points NUMERIC(18,6);

-- select top 100 * from sandbox.dbo.MD_CMTJourneys_test
-- WITH all_past_braking (Account_ID, DriveID, Braking_Points) AS (
	-- SELECT
		 -- Account_ID
		-- ,DriveID
		-- ,Braking_Points
	-- FROM CMTServ.dbo.CMTTripSummary
	
	-- UNION ALL
	
	-- SELECT
		 -- Account_ID
		-- ,DriveID
		-- ,Braking_Points
	-- FROM CMTServ.dbo.CMTTripSummary_EL
	-- )
-- UPDATE sandbox.dbo.MD_CMTJourneys_test
-- SET Braking_Points = c.Braking_Points
-- FROM sandbox.dbo.MD_CMTJourneys_test ds
-- INNER JOIN all_past_braking c
	-- ON ds.Account_ID = c.Account_ID
	-- and ds.DriveID = c.DriveID
-- CREATE CLUSTERED INDEX IX_DS_CMTJourneys ON sandbox.dbo.MD_CMTJourneys_test (PolicyNumber ASC, JEndDate ASC);

--check matching values
-- select top 100 a.Braking_Points , b.braking_points
-- from CMTServ.dbo.CMTTripSummary a
-- inner join sandbox.dbo.MD_CMTJourneys_test b
-- on a.account_id = b.account_id
-- and a.driveid = b.driveid
-- where a.braking_points != b.braking_points
--END of TEST



--DW Code
--Needs to run all on same day after ETL
-- SJ: After ETL? Or day prior to first ETL of new script?

--add column to truncated staging table
ALTER TABLE staging.dbo.CMTTripSummaryCombined
ADD Braking_Points NUMERIC(18,6);

--add column to DataSummary table
ALTER TABLE datasummary.dbo.CMTJourneys
ADD Braking_Points NUMERIC(18,6);

--populate datasummary table with existing braking_points data from cmt
WITH all_past_braking (Account_ID, DriveID, Braking_Points) AS (
	SELECT
		 Account_ID
		,DriveID
		,Braking_Points
	FROM CMTServ.dbo.CMTTripSummary
	
	UNION ALL
	
	SELECT
		 Account_ID
		,DriveID
		,Braking_Points
	FROM CMTServ.dbo.CMTTripSummary_EL
	)
UPDATE DataSummary.dbo.CMTJourneys 
-- 		^^^^^^^^^^^^^^^^^^^^^^^^^ SJ: you may want to get used to using the alias here (ds) as this method of update can cause problems in a self-join.
SET Braking_Points = c.Braking_Points
FROM DataSummary.dbo.CMTJourneys ds
INNER JOIN all_past_braking c
	ON ds.Account_ID = c.Account_ID
	and ds.DriveID = c.DriveID
-- SJ: I would have written it exactly this way too, however, what we need to be careful about is if there's more than one row per Account_ID, DriveID with differing Braking_Points.
-- Not that we should ever get this, but if we did, the UPDATE would be arbitrary and non-deterministic.
-- Other than that, (Y).

/* Add index to DataSummary */ --MD CHANGE 13/08/2020 
CREATE CLUSTERED INDEX IX_DS_CMTJourneys ON DataSummary.[dbo].[CMTJourneys] (PolicyNumber ASC, JEndDate ASC);
