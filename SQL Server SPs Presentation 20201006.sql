/*
SQL Server Stored Procedures 101
20201006
*/























-- Print a message:
EXEC sandbox.dbo.SJ_Print;


































-- Output rows:
EXEC sandbox.dbo.SJ_Output100Rows;


































-- Write data:
EXEC sandbox.dbo.SJ_WriteData;




SELECT *
FROM sandbox.dbo.SJ_SP
;



































-- A stored procedure with a single scalar mandatory parameter
-- This procedure returns all Trip data for a given ExternalContractNumber ordered by EventTimeStamp ascending:
EXEC sandbox.dbo.SJ_OutputVFRiskData
	 @ExternalContractNumber = N'P61835327-1'
;

































-- A stored procedure with three scalar parameters with the last two being optional.
-- This procedure returns journey event data for a given risk between certain dates and times
-- and all PolCVPTrav data for that risk.
-- If no time is specificed, it returns all event data for the risk:
EXEC sandbox.dbo.SJ_OutputRTRiskData
	 @PolicyNumber = 'P60607202-1'
					-- 1pm, 1st November 2016:
	,@MinDate      = '2016-11-01T13:00:00.000'
	--				-- 7pm, 1st November 2016:
	,@MaxDate      = '2016-11-01T19:00:00.000'
;




























-- This procedure returns the row counts of all tables in a given database between certain row counts.
-- If no database is specified, the procedure returns all databases in the server.
-- If no row counts are specificed, all tables are returned:
EXEC sandbox.dbo.SJ_RowCounts
	 @DBName = N'staging'
	,@Lower  = 0
	,@Upper  = 0
;





























-- Firstly, we create a local variable table of a user-defined type (the table's definition was created elsewhere):
DECLARE @TVP dbo.SJ_VFList;

-- Secondly, we populate this table with the data we're interested in:
INSERT @TVP ( ExternalContractNumber )
SELECT DISTINCT TOP (10) PolicyNumber
FROM Vodafone.dbo.VoucherResponse
;

-- Lastly, we run the procedure for the above table:
EXEC sandbox.dbo.SJ_VFLastData
	 @TVP
;











