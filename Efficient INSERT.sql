
-- Test on whether an insert sorted by index order + a statistics update
-- is quicker than an insert into a heap then adding the index:
SET STATISTICS IO, TIME ON;

DROP TABLE dbo.SJ_Testow;
CREATE TABLE dbo.SJ_Testow (ExternalContractNumber nvarchar(20) NULL, a integer NULL);
CREATE CLUSTERED INDEX CIX ON dbo.SJ_Testow (ExternalContractNumber ASC);

INSERT dbo.SJ_Testow WITH (TABLOCK) (ExternalContractNumber, a)
SELECT ExternalContractNumber, TimeElapsed
FROM Vodafone.dbo.Trip
WHERE ExternalContractNumber > N''
	AND ExternalContractNumber < 'P605'
;

UPDATE STATISTICS dbo.SJ_Testow CIX WITH FULLSCAN;

--DROP TABLE dbo.SJ_Testow2;
--CREATE TABLE dbo.SJ_Testow2 (ExternalContractNumber nvarchar(20) NULL, a integer NULL);

INSERT dbo.SJ_Testow2 WITH (TABLOCK) (ExternalContractNumber, a)
SELECT ExternalContractNumber, TimeElapsed
FROM Vodafone.dbo.Trip
WHERE ExternalContractNumber > N''
	AND ExternalContractNumber < 'P605'
OPTION (MAXDOP 1)
;

CREATE CLUSTERED INDEX CIX ON dbo.SJ_Testow2 (ExternalContractNumber ASC);
