PROC SQL;
	CREATE TABLE ServiceApp AS
		SELECT DISTINCT
			 BrandName AS Brand
			,PolicyNo
			,PolicyNumber
			,COMPRESS(PolicyNo || '.' || RatabaseID) AS Account_ID
			,MIN(SARegistrationDate) FORMAT DDMMYY10. AS ServiceAppRegistrationDate
		FROM Telema.PolCVPTrav_ServiceApp_DontDelete
		WHERE ServiceAppFlag = '1'
		GROUP BY PolicyNo
		;
QUIT;

PROC SQL;
	CREATE TABLE ServiceApp2 AS
		SELECT DISTINCT
			 a.*
			,b.SARegistrationOS
		FROM ServiceApp a
		INNER JOIN Telema.PolCVPTrav_ServiceApp_DontDelete b
			ON  a.PolicyNo = b.PolicyNo
			AND a.ServiceAppRegistrationDate = b.SARegistrationDate
		;
QUIT;

PROC SQL;
	CREATE TABLE CXX AS
		SELECT
			 PolicyNo
			,MAX(EffectToDate) FORMAT DDMMYY10. AS PolicyCXXDate
		FROM Telema.PolCVPTrav_ServiceApp_DontDelete
		WHERE TraversedFlag = '1'
		GROUP BY PolicyNo
		;
QUIT;

PROC SQL;
	CREATE TABLE NonTraversed AS
		SELECT DISTINCT
			 PolicyNo
			,MIN(PolOrigIncDate, RiskOrgOnCovDate) FORMAT DDMMYY10. AS PolOrigIncDate
		FROM Telema.PolCVPTrav_ServiceApp_DontDelete
		WHERE PolicyNo NOT IN (
			SELECT c.PolicyNo 
			FROM CXX c
			WHERE c.PolicyNo IS NOT NULL
		)
		GROUP BY PolicyNo
		;
QUIT;

PROC SQL;
	CREATE TABLE ServiceApp3 AS
		SELECT
			 a.*
			,COALESCE(b.PolicyCXXDate, c.PolOrigIncDate) FORMAT DDMMYY10. AS PolicyCXXDate
		FROM ServiceApp2 a
		LEFT JOIN CXX b
			ON a.PolicyNo = b.PolicyNo
		LEFT JOIN NonTraversed c
			ON a.PolicyNo = c.PolicyNo
		;
QUIT;

PROC SQL;
	CONNECT TO ODBC AS DDP (DSN = "Telematics_DDP_Sandbox" AuthDomain = "SPYDDPAuth");
		EXEC(

			DROP TABLE IF EXISTS Sandbox.dbo.SJ_PTSARequest;

			CREATE TABLE Sandbox.dbo.SJ_PTSARequest (
				 Brand						VARCHAR(15)	NOT NULL
				,PolicyNo					VARCHAR(20)	NOT NULL
				,PolicyNumber				VARCHAR(20)	NOT NULL
				,Account_ID					VARCHAR(30)	NOT NULL
				,ServiceAppRegistrationDate	DATE		NOT NULL
				,SARegistrationOS			VARCHAR(10) NOT NULL
				,PolicyCXXDate				DATE		NOT NULL
			)
			;

			CREATE CLUSTERED INDEX IX_SJPTSARequest_AccountID ON Sandbox.dbo.SJ_PTSARequest (Account_ID ASC);

		) BY DDP;
	DISCONNECT FROM DDP;
QUIT;

PROC APPEND
	BASE = Sand_DDP.SJ_PTSARequest
	DATA = ServiceApp3
	FORCE;
RUN;

/**/

;WITH CMTTripSummary AS (
SELECT
	 Account_ID
	,Trip_Start_Local
FROM CMTServ.dbo.CMTTripSummary

UNION ALL

SELECT
	 Account_ID
	,Trip_Start_Local
FROM CMTServ.dbo.CMTTripSummary_EL
)
SELECT DISTINCT
	 Account_ID = CAST(Account_ID AS VARCHAR(30))
	,Trip_Start_Local = CAST(Trip_Start_Local AS DATE)
INTO Sandbox.dbo.SJ_PTSARequestTrips
FROM CMTTripSummary
;

CREATE CLUSTERED INDEX IX_SJPTSARequestTrips_TripStartLocalAccountID ON Sandbox.dbo.SJ_PTSARequestTrips (Trip_Start_Local ASC, Account_ID ASC);

;WITH Logins AS (
SELECT
	 PolicyNumber
	,RiskID
	,LoginDate
FROM CMTServ.dbo.SuccessfulLoginHistory

UNION ALL

SELECT
	 PolicyNumber
	,RiskID
	,LoginDate
FROM CMTServ.dbo.SuccessfulLoginHistory_EL
)
SELECT DISTINCT
	 Account_ID = CAST(CONCAT(PolicyNumber, '.', RiskID) AS VARCHAR(30))
	,LoginDate = CAST(LoginDate AS DATE)
INTO Sandbox.dbo.SJ_PTSARequestLogins
FROM Logins
;

CREATE CLUSTERED INDEX IX_SJPTSARequestLogins_LoginDateAccountID ON Sandbox.dbo.SJ_PTSARequestLogins (LoginDate ASC, Account_ID ASC);

DECLARE @Day DATE = '01/06/2019';

WHILE @Day < '01/06/2020'
BEGIN

INSERT Sandbox.dbo.SJ_PTSARequestLoginsPlusReg WITH (TABLOCK) (
Date, Description, Brand, SARegistrationOS, PolicyCount
)
SELECT
	 Date = @Day
	,Description = 'Login in the last 14 days'
	,pt.Brand
	,pt.SARegistrationOS
	,PolicyCount = COUNT(DISTINCT pt.PolicyNo)
FROM Sandbox.dbo.SJ_PTSARequest pt
INNER JOIN Sandbox.dbo.SJ_PTSARequestLogins ptl
	ON  pt.Accunt_ID = ptl.Account_ID
	AND ptl.LoginDate BETWEEN DATEADD(DAY, -14, @Day) AND @Day
GROUP BY GROUPING SETS (
 ( )
,( pt.Brand )
,( pt.SARegistrationOS )
)
;

SET @Day = DATEADD(DAY, 1, @Day);

END
;

DECLARE @Day DATE = '01/06/2019';

WHILE @Day < '01/06/2020'
BEGIN

INSERT Sandbox.dbo.SJ_PTSARequestLoginsPlusReg WITH (TABLOCK) (
Date, Description, Brand, SARegistrationOS, PolicyCount
)
SELECT
	 Date = @Day
	,Description = 'Login / Registration in the last 14 days'
	,pt.Brand
	,pt.SARegistrationOS
	,PolicyCount = COUNT(DISTINCT pt.PolicyNo)
FROM Sandbox.dbo.SJ_PTSARequest pt
LEFT JOIN Sandbox.dbo.SJ_PTSARequestLogins ptl
	ON pt.Account_ID = ptl.Account_ID
WHERE (
		pt.ServiceAppRegistrationDate BETWEEN DATEADD(DAY, -14, @Day) AND @Day
	OR	ptl.LoginDate BETWEEN DATEADD(DAY, -14, @Day) AND @Day
)
GROUP BY GROUPING SETS (
 ( )
,( pt.Brand )
,( pt.SARegistrationOS )
)
;

SET @Day = DATEADD(DAY, 1, @Day);

END
;

DECLARE @Day DATE = '01/06/2019';

WHILE @Day < '01/06/2020'
BEGIN

INSERT Sandbox.dbo.SJ_PTSARequestLoginsPlusReg WITH (TABLOCK) (
	Date, Description, Brand, SARegistrationOS, PolicyCount
)
SELECT
	 Date = @Day
	,Description = 'Trips in the last 7 days'
	,pt.Brand
	,pt.SARegistrationOS
	,PolicyCount = COUNT(DISTINCT pt.PolicyNo)
FROM Sandbox.dbo.SJ_PTSARequest pt
INNER JOIN Sandbox.dbo.SJ_PTSARequestTrips ptt
	ON  pt.Account_ID = ptt.Account_ID
	AND	ptt.Trip_Start_Local BETWEEN DATEADD(DAY, 7, @Day) AND @Day
GROUP BY GROUPING SETS (
 ( )
,( pt.Brand )
,( pt.SARegistrationOS )
)
;

SET @Day = DATEADD(DAY, 1, @Day);

END
;

--

SELECT
	 a.*
	,AVB = b.PolicyCount
FROM Sandbox.dbo.SJ_PTSARequestLoginsPlusReg a
INNER JOIN Sandbox.dbo.SJ_PTSARequestAVB b
	ON a.Date = b.Date
	AND (
			( a.Brand IS NULL AND a.SARegistrationOS IS NULL AND b.Brand IS NULL AND b.SARegistrationOS IS NULL )
		OR	( a.Brand = b.Brand )
		OR	( a.SARegistrationOS = b.SARegistrationOS )
	)
ORDER BY a.Date DESC, a.Description ASC, a.Brand DESC, a.SARegistrationOS DESC
;

