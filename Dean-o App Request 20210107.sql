SELECT DISTINCT
	 PolicyNumber
	,LoginDate
INTO ##Logins
FROM CMTSERV.dbo.SuccessfulLoginHistory_EL slh
WHERE LoginDate >= '20200901'
	AND LoginDate < '20210101'
	AND PolicyNumber IS NOT NULL
	AND RiskID IS NOT NULL
	AND NOT EXISTS (
		SELECT 1
		FROM dbo.ServiceApp_StaffTesters st
		WHERE slh.PolicyNumber = st.PolicyNumber
	)
;

SELECT DISTINCT
	 PolicyNumber
	,LoginDate = RegistrationDate
INTO ##Registrations
FROM CMTSERV.dbo.AppAssociation aa
WHERE StaffTester = 0
	AND RegistrationDate >= '20200901'
	AND RegistrationDate <  '20210101'
	AND Brand = 'Elephant'
	AND NOT EXISTS (
		SELECT 1
		FROM ##Logins l
		WHERE aa.PolicyNumber = l.PolicyNumber
			AND aa.RegistrationDate = l.LoginDate
	)
;

SELECT *
FROM ##Logins
UNION ALL
SELECT *
FROM ##Registrations
ORDER BY PolicyNumber DESC, LoginDate
;


SELECT
YEAR(registrationdate), month(Registrationdate), count(distinct account_id)
FROM CMTSERV.dbo.AppAssociation aa
where not exists ( select 1 from dbo.ServiceApp_StaffTesters sa where aa.PolicyNumber = sa.PolicyNumber )
GROUP BY YEAR(registrationdate), month(Registrationdate)
order by 1, 2