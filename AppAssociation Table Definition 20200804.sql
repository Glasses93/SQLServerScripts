-- Table definition:
CREATE TABLE CMTSERV.dbo.AppAssociation (
	 Account_ID					varchar(30)		NOT NULL
	,PolicyNumber				varchar(18)		NOT NULL
	,RiskID					    char(4)			NOT NULL
	,Brand					 	varchar(15)			NULL
	,Email						varchar(256)		NULL
	,Platform					varchar(15)			NULL
	,DeviceID				    char(36)			NULL
	,DeviceIDShort			    char(16)			NULL
	,RegistrationDate			datetime2(2)		NULL
	,MostRecentLoginDate		datetime2(2)		NULL
	,LoginCount					smallint			NULL	CONSTRAINT DF_AppAssociation_LoginCount DEFAULT 1
	,EndDate					date				NULL
	,CXXSentDate				date				NULL
	,CXXSSuccessDate			date				NULL
	,CXXSReturnDate				date				NULL
	,FirstLOCP					varchar(25)			NULL
	,FirstLOCPDate				datetime2(2)		NULL
	,MostRecentLOCP				varchar(25)			NULL
	,MostRecentLOCPDate			datetime2(2)		NULL
	,FirstTripDate				datetime2(2)		NULL
	,MostRecentTripDate			datetime2(2)		NULL
	,Mileage					numeric(9, 2)		NULL
	,MostRecentAchievement		varchar(25)			NULL
	,MostRecentAchievementDate	datetime2(2)		NULL
	,Notifications				varchar(40)			NULL
	,NotificationsDate			datetime2(2)		NULL
	,PushNotified			  	varchar(40)			NULL
	,PushNotifiedDate			smalldatetime		NULL
	,OSVersion				    varchar(20)			NULL
	,AppVersion				    varchar(20)			NULL
	,Environment				varchar(15)			NULL
	,StaffTester				bit					NULL
	,CoverType				    char(5)				NULL
)
;

-- Index:
CREATE CLUSTERED INDEX IX_AppAssociation_AccountID
ON CMTSERV.dbo.AppAssociation (Account_ID ASC)
;