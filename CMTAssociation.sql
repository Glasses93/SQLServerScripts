USE [CMTSERV]
GO

/****** Object:  StoredProcedure [dbo].[usp_ProcessCMTAssociation]    Script Date: 05/11/2019 14:00:28 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO






/*******************************************************************************************************************************************/
--OBJECT:		etl.usp_ProcessEndavaCancellation
--DESCRIPTION:  Processes data for the Endava Cancellation table
--AUTHOR:		Adam Beecham
--CREATED:		2018-01-16
--
--DATE MODIFIED		NAME			COMMENTS
--19-02-2018		Adam Beecham	Initial creation
--05-03-2018		Adam Beecham	Changes to SuccessfulDailyLogins, FirstLoginDate, 
--									StartDate logic
--06-03-2018		John Richards	Added platform column to Association table 
--					May Wong		Added logic to update firstlogin date and ever consented
--26-03-2018		Adam Beecham	Fixed Ever consented logic so flag applied at sequence level
--									Fixed End Date logic so future cancellation files do not
--									overwrite the end date for future rows of the same BKID
-- 08-05-18			John Richards	Amended StartDate logic to only update if the date supplied is earlier than the current StartDate based on
-- 									email, Deviceid and PolicyNumber
-- 									Amended EndDate logic to pick a common (Minimum) Policy end date
-- 									Added Left Outer Joins in section 6 - Populate Cancellation Dates section
-- 04-07-18			John Richards	Amended parts of the logic to use the CMTSERV database rather than the staging database,
-- 									as using this database allows retrospective population of the association table,
--									whereas the old approach did not. Also amended some of the logic in other steps
-- 01-04-2019		Emmanuuel K		Added RiskID join condition in 'New StartDate logic'
/*******************************************************************************************************************************************/

CREATE PROC [dbo].[usp_ProcessCMTAssociation]
AS

INSERT INTO CMTSERV.dbo.BusinessKeyLKP (
	 PolicyNumber
	,RiskID
	,Email
)
SELECT distinct
	 LogS.PolicyNumber
	,LogS.RiskID
	,LogS.Email

FROM
	CMTSERV.dbo.SuccessfulLoginHistory LogS
LEFT JOIN
	CMTSERV.dbo.BusinessKeyLKP Bkid
		ON LogS.PolicyNumber = Bkid.PolicyNumber
		AND LogS.RiskID = Bkid.RiskID
		AND LogS.Email = Bkid.Email
WHERE Bkid.PolicyNumber IS NULL

-- select * from CMTSERV.dbo.BusinessKeyLKP order by BKID 



-- Identify existing associations
;WITH CTE_ExAssocs AS(
	SELECT
		 AssociationBKID
		,Email
		,PolicyNumber
		,RiskID
		,DeviceID
	FROM
		CMTServ.dbo.Association
)
-- Identify new Associations
,CTE_NewAssocs AS
(
	SELECT
		 Bkid.Bkid 
		,LogS.Email
		,LogS.PolicyNumber
		,LogS.RiskID
		,LogS.DoB
		,LogS.Brand
		,LogS.LoginDate
		,LogS.DeviceID
		,SUBSTRING(LogS.DeviceID,1,16) AS DeviceIDShort
		,LogS.Platform
		,LogS.ImportFileID
		,LogS.InsertedDate
		------------------------
		-- For Join debugging --
		--,Exa.DeviceID
		--,Exa.Email
		--,Exa.PolicyNumber
		--,Exa.RiskID
		------------------------
		-- Rank in case we have loaded multiple rows per policy/riskid
		,ROW_NUMBER() OVER(
			PARTITION BY 
				 LogS.PolicyNumber
				,LogS.RiskID
				,LogS.Email
				,LogS.DeviceID
			ORDER BY
				 LogS.LoginDate 
		) AS RowNum
	FROM 
		CMTSERV.dbo.SuccessfulLoginHistory LogS
	INNER JOIN 
		staging.dbo.ImportFile Imf 
			ON logs.ImportFileID = imf.ImportFileID
	INNER JOIN
		CMTSERV.dbo.BusinessKeyLKP Bkid
			ON Bkid.PolicyNumber = LogS.PolicyNumber
			AND Bkid.RiskID = LogS.RiskID
			AND Bkid.Email = LogS.Email
	LEFT JOIN 
		CTE_ExAssocs Exa
			ON Exa.PolicyNumber = LogS.PolicyNumber
			AND Exa.RiskID = LogS.RiskID
			AND Exa.DeviceID = LogS.DeviceID
			AND Exa.Email = Logs.Email
	WHERE Exa.PolicyNumber IS NULL
)

-- Insert New Associations from first known successful login
-- of Policy/Risk/Device/Email combination
 INSERT INTO CMTSERV.dbo.Association(
	 AssociationBKID
	,Email
	,DeviceID
	,DeviceIDShort
	,PolicyNumber
	,RiskID
	,DoB
	,Brand
	,StartDate
	,MostRecentLoginDate
	,FirstLoginDate
	,LogsFileDate
	,Platform
) 
SELECT
	 LogS.Bkid
	,LogS.Email
	,LogS.DeviceID
	,LogS.DeviceIDShort
	,LogS.PolicyNumber
	,LogS.RiskID
	,LogS.DoB
	,LogS.Brand
	,LogS.LoginDate
	,LogS.LoginDate
	-- First login date is at the Policy/RiskID Level
	,LogS.LoginDate
	,GETDATE()
	,LogS.Platform
FROM 
	CTE_NewAssocs LogS
WHERE RowNum = 1

-- select * from cmtserv.dbo.Association_Test

-- Set the start date and first login date correctly
-- First known login for all Policy, RiskID combinations
;WITH CTE_FirstLoginDate_PolicyRisk AS(
	SELECT
		 PolicyNumber
		,RiskID
		,MIN(FirstLoginDate) AS FirstLoginDate
	FROM 
		CMTSERV.dbo.Association
	GROUP BY
		 PolicyNumber
		,RiskID
)
-- First known login for all Policy, RiskID, Device, Email combinations
,CTE_FirstLoginDate_DeviceEmail AS(
	SELECT
		 PolicyNumber
		,RiskID
		,Email
		,DeviceID 
		,MIN(FirstLoginDate) AS FirstLoginDate
	FROM 
		CMTSERV.dbo.Association
	GROUP BY
		 PolicyNumber
		,RiskID
		,DeviceID
		,Email
)
UPDATE CMTSERV.dbo.Association
SET 
	 FirstLoginDate = FLogPR.FirstLoginDate
	 -- Amended logic Only amend the StartDate if the date supplied is earlier than the Startdate currently stored
	--,StartDate = CASE WHEN StartDate > FLogDE.FirstLoginDate THEN FLogDE.FirstLoginDate ELSE Assoc.StartDate END 

FROM 
	CMTSERV.dbo.Association Assoc
INNER JOIN
	CTE_FirstLoginDate_PolicyRisk FLogPR
		ON Assoc.PolicyNumber = FLogPR.PolicyNumber
		AND Assoc.RiskID = Assoc.RiskID
INNER JOIN
	CTE_FirstLoginDate_DeviceEmail FLogDE
		ON Assoc.PolicyNumber = FLogDE.PolicyNumber
		AND Assoc.RiskID = FLogDE.RiskID
		AND Assoc.Email = FLogDE.Email
		AND Assoc.DeviceID = FLogDE.DeviceID

-------------------------- New Startdate Logic -------------------------------------
-- Created by John Richards 16/05/18

-- select * from cmtserv.[dbo].[SuccessfulLoginHistory]

;WITH CTE_FirstLoginDate AS
(
SELECT a.email,a.PolicyNumber,a.DeviceID,a.RiskID, MIN(loginDate) NewEarliestLoginDate, a.startdate AS CurrentStartDate, a.SequenceNumber
FROM cmtserv.[dbo].Association a
Left JOIN cmtserv.[dbo].[SuccessfulLoginHistory] s
ON s.email = a.Email
AND s.PolicyNumber = a.PolicyNumber
AND s.DeviceID = a.DeviceID
AND s.RiskID = a.RiskID
GROUP BY a.email,a.PolicyNumber,a.DeviceID,a.RiskID,a.startdate,a.SequenceNumber
HAVING MIN(logindate) <> isnull(a.startdate,'19000101') 
)

--select * from cmtserv.[dbo].Association
--select * from CTE_FirstLoginDate 

UPDATE cmtserv.[dbo].Association
SET StartDate = NewEarliestLoginDate
FROM CTE_FirstLoginDate fl
WHERE StartDate <> NewEarliestLoginDate
AND fl.email = Association.Email
AND fl.PolicyNumber = Association.PolicyNumber
AND fl.DeviceID = Association.DeviceID
AND fl.RiskID = Association.RiskID


------------------------- 3 - Update Login data -------------------------

-- Identify existing associations
;WITH CTE_ExAssocs AS(
	SELECT
		Email,
		PolicyNumber,
		RiskID,
		DeviceID
	FROM
		CMTServ.dbo.Association
)
-- Existing Associations with new login data
,CTE_UpdatedAssocs AS
(
	SELECT 
		 LogS.Email
		,LogS.PolicyNumber
		,LogS.RiskID
		,LogS.DeviceID
		,MAX(LogS.LoginDate) AS MostRecentLoginDate
	FROM 
		CMTSERV.dbo.SuccessfulLoginHistory LogS
	INNER JOIN 
		staging.dbo.ImportFile Imf 
			ON logs.ImportFileID = imf.ImportFileID
	INNER JOIN 
		CTE_ExAssocs Exa
			ON Exa.PolicyNumber = LogS.PolicyNumber
			AND Exa.RiskID = LogS.RiskID
			AND Exa.DeviceID = LogS.DeviceID
			AND Exa.Email = LogS.Email
	GROUP BY
		 LogS.PolicyNumber
		,LogS.RiskID
		,LogS.Email
		,LogS.DeviceID

)
-- Apply most recent login date
UPDATE CMTSERV.dbo.Association
SET 
	MostRecentLoginDate = 
	CASE 
		WHEN LogS.MostRecentLoginDate > ISNULL(assoc.MostRecentLoginDate,'19000101') 
		THEN LogS.MostRecentLoginDate 
		ELSE assoc.MostRecentLoginDate 
	END,
	LOGSFileDate = GETDATE()
FROM 
	CMTSERV.dbo.Association assoc
INNER JOIN
	CTE_UpdatedAssocs LogS
		ON assoc.PolicyNumber = LogS.PolicyNumber
		AND assoc.RiskID = LogS.RiskID
		AND assoc.Email = LogS.Email
		AND assoc.DeviceID = LogS.DeviceID


------------------------- 4 - Populate Sequence Number -------------------------
-- Get the max sequence number for each Policy/Risk/Email/Device
-- combination
;WITH CTE_SeqNo AS(
	SELECT 
		PolicyNumber,
		RiskID, 
		MAX(ISNULL(SequenceNumber,0)) MaxSeqNo 
	FROM 
		CMTSERV.dbo.Association
	GROUP BY 
		PolicyNumber,
		RiskID
),
-- Calculate a new sequence number for all combinations that don't
-- have a sequence number yet
CTE_NewSeqNo AS(
	SELECT 
		 Assoc.PolicyNumber
		,Assoc.RiskID
		,Assoc.email
		,Assoc.DeviceID
		,(ROW_NUMBER() OVER(
			PARTITION BY 
				 Assoc.PolicyNumber
				,Assoc.RiskID 
			ORDER BY 
				Assoc.StartDate
		)) + Seq.MaxSeqNo AS NewSeqNo
	FROM 
		CMTSERV.dbo.Association Assoc
	INNER JOIN 
		CTE_SeqNo Seq
			ON Assoc.PolicyNumber = Seq.PolicyNumber
			AND Assoc.RiskID = Seq.RiskID
	WHERE 
		SequenceNumber IS NULL
)
-- Apply the new sequence number
UPDATE CMTSERV.dbo.Association
SET SequenceNumber = NewSeqNo
FROM 
	CMTSERV.dbo.Association assoc
INNER JOIN 
	CTE_NewSeqNo Seq
		ON Assoc.PolicyNumber = Seq.PolicyNumber
		AND Assoc.RiskID = Seq.RiskID
		AND Assoc.Email = Seq.Email
		AND Assoc.DeviceID = Seq.DeviceID



------------------------- 5 - Populate Location Permission Data -------------------------
-- Check for consent to use location data at the policy/risk level
-- and set the consented flag accordingly. Only update the LOCP date
-- if this flag changes from 0 to 1
;with CTE_Latest_LocationPermission_Consented
as
(
select  PolicyNumber,
		RiskID,
		Email,
		deviceid, 
		sum(case when status='enabled' then 1 else 0 end) as EnabledCount, 
		sum(case when status='Disabled' then 1 else 0 end) as DisabledCount, 
		Max(InsertedDate) as MaxConsentedDate
from cmtserv.dbo.LocationPermissionChange 
-- where Status = 'enabled'
group by PolicyNumber,RiskID,Email,deviceid
)


--select PolicyNumber,RiskID,Email,deviceid, case when Status='enabled' then 1 else 0 end,
--max(insertedDate)
--from cmtserv.dbo.LocationPermissionChange 
--group by PolicyNumber,RiskID,Email,deviceid, status
--order by PolicyNumber,RiskID,Email,deviceid


UPDATE CMTSERV.dbo.Association
SET 
	 EverConsented = case when EnabledCount>0 then 1 else 0 end 
	,LOCPFileDate = MaxConsentedDate
FROM 
	CMTSERV.dbo.Association Assoc
INNER JOIN CTE_Latest_LocationPermission_Consented elc
ON Assoc.PolicyNumber = elc.PolicyNumber
		AND Assoc.RiskID = elc.RiskID
		AND assoc.Email = elc.Email
		AND assoc.DeviceID = elc.DeviceID
where MaxConsentedDate >= isnull(Assoc.LOCPFileDate,'1900-01-01')



------------------------- 6 - Populate Cancellation Dates -------------------------
-- 26-06-2018
-- As the logic is still evolving in relation to the cancellation data,
-- each component is calculated seperately.
-- As the cancellation is small (we hopefully won't get lots of cancellations), the query is still quick to run
;with CTE_CancellationData
as
(
 select distinct c.PolicyNumber,c.RiskID,c.email
		,c2.EndDate
		,c3.CXXSentDate as CXXSentDate
		,c4.CXXSSuccessdate as CXXSSuccessdate
		,case when successcount > 0 then c4.CXXSSuccessdate else c5.CXXSReturnDate end as CXXSReturnDate
 from cmtserv.dbo.Cancellation c
 left join 
 (select PolicyNumber,RiskID,email,MIN(cancellationdate) as EndDate from cmtserv.dbo.Cancellation
 group by PolicyNumber,RiskID,email) c2
 on c.PolicyNumber = c2.PolicyNumber
 and c.RiskID = c2.RiskID
 and c.Email = c2.Email
 left join
 (select PolicyNumber,RiskID,email,MIN(CXXS_Date) as CXXSentDate from cmtserv.dbo.Cancellation
 group by PolicyNumber,RiskID,email) c3
 on c.PolicyNumber = c3.PolicyNumber
 and c.RiskID = c3.RiskID
 and c.Email = c3.Email
 left join 
 (select PolicyNumber,RiskID,email,MIN(Updatedate) as CXXSSuccessDate, COUNT(*) as SuccessCount  from cmtserv.dbo.Cancellation
 where Success =1
 group by PolicyNumber,RiskID,email) c4
 on c.PolicyNumber = c4.PolicyNumber
 and c.RiskID = c4.RiskID
 and c.Email = c4.Email
 left join
 (select PolicyNumber,RiskID,email,MIN(Updatedate) as CXXSReturnDate from cmtserv.dbo.Cancellation
  group by PolicyNumber,RiskID,email) c5
 on c.PolicyNumber = c5.PolicyNumber
 and c.RiskID = c5.RiskID
 and c.Email = c5.Email
--  order by Email
 )
 
  
 update cmtserv.dbo.Association
 set	Association.EndDate = c.EndDate
		,Association.CXXSentDate = c.CXXSentDate	
		,Association.CXXSuccessDate = c.CXXSSuccessdate
		,Association.CXXSReturnDate = c.CXXSReturnDate 
 from CTE_CancellationData c
 where Association.PolicyNumber = c.PolicyNumber
 and Association.RiskID = c.RiskID
 and Association.Email = c.Email


---- 26-04-2018 AB
---- Identify existing end dates for each BKID
---- New code
--;WITH CTE_ExEndDate AS(
--	SELECT
--		PolicyNumber,
--		RiskID,
--		Email,
--		MIN(cxxs.CancellationDate) EndDate -- keep this column even though i'm flipping the data......
--	FROM
--		CMTServ.dbo.CancellationHistory Cxxs
--	GROUP BY
--		 PolicyNumber
--		,RiskID
--		,Email
--)


---- Populate the cancellation sent date with the
---- date of the file that was sent to endava/cmt.
---- This also marks the end date of the record
--UPDATE CMTSERV.dbo.Association 
--SET 
--	CXXSentDate = 
--		CASE 
--			WHEN Imf.FileDate > ISNULL(assoc.CXXSentDate,'19000101') 
--				THEN Imf.FileDate
--			ELSE assoc.CXXSentDate
--		END,
--	EndDate = COALESCE(exCXXS.EndDate, Imf.FileDate)		-- 26-04-2018 AB (previously just equal to Imf.FileDate)
--FROM 
--	CMTSERV.dbo.Association Assoc
--LEFT JOIN 
--	dbo.EndavaCancellation Cxxs 
--		ON Assoc.PolicyNumber = Cxxs.PolicyNumber
--		AND Assoc.RiskID = Cxxs.RiskID
--LEFT JOIN
--	dbo.ImportFile Imf
--		ON Cxxs.ImportFileID = Imf.ImportFileID
--LEFT JOIN													-- 26-04-2018 AB
--	CTE_ExEndDate exCXXS									-- New Code
--		ON Assoc.PolicyNumber = exCXXS.PolicyNumber			--
--		AND Assoc.RiskID = exCXXS.RiskID					--
--		AND Assoc.Email = exCXXS.email						--
--WHERE 
--	Cxxs.Success IS NULL
--	AND Assoc.CXXSentDate IS NULL

---- Populate the cancellation return date with the
---- date of the file that was sent to endava/cmt,
---- even if the cancellation failed  
--UPDATE CMTSERV.dbo.Association
--SET CXXReturnDate = 
--	CASE 
--			WHEN Imf.FileDate > ISNULL(assoc.CXXReturnDate,'19000101') 
--			THEN Imf.FileDate
--			ELSE assoc.CXXReturnDate
--	END
--FROM 
--	CMTSERV.dbo.Association Assoc
--INNER JOIN 
--	dbo.EndavaCancellation Cxxs 
--		ON Assoc.PolicyNumber = Cxxs.PolicyNumber
--		AND	Assoc.RiskID = Cxxs.RiskID
--INNER JOIN
--	dbo.ImportFile Imf
--		ON Cxxs.ImportFileID = Imf.ImportFileID
--WHERE 
--	Cxxs.Success IS NOT NULL

---- Populate the cancellation success date with the
---- cancellation date
--UPDATE CMTSERV.dbo.Association
--	SET CXXSuccessDate = 
--		CASE 
--			WHEN Imf.FileDate > ISNULL(assoc.CXXSuccessDate,'19000101') 
--			THEN Imf.FileDate
--			ELSE assoc.CXXSuccessDate
--	END
--FROM 
--	CMTSERV.dbo.Association Assoc
--INNER JOIN 
--	dbo.EndavaCancellation Cxxs 
--		ON Assoc.PolicyNumber = Cxxs.PolicyNumber
--		AND Assoc.RiskID = Cxxs.RiskID
--INNER JOIN
--	dbo.ImportFile Imf
--		ON Cxxs.ImportFileID = Imf.ImportFileID
--WHERE 
--	Cxxs.Success = 1




------------------------- 7 - Populate Successful Daily Logins -------------------------

-- Calculate the number of logins per policy/risk/email/device combinations and divide by
-- number of contiguous days since the start date and the last known login date
;WITH CTE_NumLogins AS(
		-- All login dates
		SELECT
			 PolicyNumber
			,RiskID
			,DeviceID
			,Email
			,COUNT(DISTINCT CAST( LoginDate AS DATE)) AS SuccessfulDailyLogins
		FROM 
			CMTSERV.dbo.SuccessfulLoginHistory
		GROUP BY
			 PolicyNumber
			,RiskID
			,DeviceID
			,Email
)
UPDATE CMTSERV.dbo.Association
SET SuccessfulDailyLogins = Logins.SuccessfulDailyLogins
FROM 
	CMTSERV.dbo.Association Assoc
INNER JOIN 
	CTE_NumLogins Logins
		ON Assoc.PolicyNumber = Logins.PolicyNumber
		AND Assoc.RiskID = Logins.RiskID
		AND Assoc.Email = Logins.Email
		AND Assoc.DeviceID = Logins.DeviceID
		
		
	------------------------- 8 - Update FirstLoginDate  -------------------------

--Update the FirstLoginDate to cater for any records where the actual FirstLogin record was sent in late
;WITH CTE_ActualFirstLogin AS (
		
SELECT MIN(logindate) AS FirstLogin, policynumber, riskid, email
FROM CMTSERV.dbo.SuccessfulLoginHistory
GROUP  BY PolicyNumber,RiskID,email
)

UPDATE CMTSERV.dbo.Association
SET FirstLoginDate = FirstLogin
FROM CTE_ActualFirstLogin t
JOIN CMTSERV.dbo.Association c ON
c.PolicyNumber = t.policyNumber
AND c.riskid = t.riskid
AND c.email = t.email
GO


