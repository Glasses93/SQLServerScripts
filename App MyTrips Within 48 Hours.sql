
SELECT
	 Brand
	,RegistrationYear  = YEAR(RegistrationDate)
	,RegistrationMonth = MONTH(RegistrationDate)
	,Registrations     = COUNT(DISTINCT Account_ID)
	,RisksSentTripWithin48Hrs = COUNT(DISTINCT CASE WHEN DATEDIFF(MINUTE, RegistrationDate, FirstTripDate) <= 2880 THEN Account_ID END)
	,[Percentage] = (COUNT(DISTINCT CASE WHEN DATEDIFF(MINUTE, RegistrationDate, FirstTripDate) <= 2880 THEN Account_ID END) / (COUNT(DISTINCT Account_ID) * 1.0))
FROM CMTSERV.dbo.AppAssociation aa
WHERE NOT EXISTS (
	SELECT 1
	FROM dbo.PolCVPTrav p
	WHERE aa.PolicyNumber = p.PolicyNo
)
GROUP BY GROUPING SETS (
	 (Brand)
	,(       YEAR(RegistrationDate), MONTH(RegistrationDate))
	,(Brand, YEAR(RegistrationDate), MONTH(RegistrationDate))
	,()
)
ORDER BY
	 1 ASC
	,2 DESC
	,3 DESC
;
