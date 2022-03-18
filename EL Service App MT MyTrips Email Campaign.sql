
/*-------------------------------- Elephant Service App MidTerm MyTrips Email Campaign --------------------------------
	WHAT:
		Email via Marketing to Elephant motor policies that are 3-6 months into their first term with a premium higher
		than £700 promoting the	MyTrips feature on the Service App by advertising a potential discount on their
		premium at renewal.
		  
	WHY: In order to increase Service App registrations and MyTrips engagement.
	
	WHEN: Following analysis on the Sausage Roll campaign after it ends.
	
	HOW:
		A daily SAS job uploads Marketing trigger files including eligible policies identified via Guidewire, Endava,
		and	CMT data.
		
	WHO: SJ
  ---------------------------------------------------------------------------------------------------------------------*/

;WITH EligibleRisks (PolicyNo, SubPolicyID, GWTermNo, ModelNo) AS (
	SEL --DISTINCT
		 a.PolicyNo
		,a.SubPolicyID
		,a.GWTermNo
		,a.ModelNo
	FROM (
		SEL
			 p.PolicyNo
			,cvp.SubPolicyID
			,p.GWTermNo
			,p.ModelNo
			,p.PolCanDate
			,cvp.RiskOrgOnCovDate
			,cvp.SliceNo
			,cvp.SliceDate
			,cvp.SliceExpDate
		FROM PR1_PL_SAS_Views.Policy p
		INNER JOIN PR1_PL_SAS_Views.Coverable_Vehicle_Policy cvp
			ON  p.PolicyNo = cvp.PolicyNo
			AND p.GWTermNo = cvp.GWTermNo
			AND p.ModelNo  = cvp.ModelNo
		WHERE p.BrandName = 'Elephant'
			AND cvp.VehType = 'Car'
			AND a.NumTerm = 1
			AND p.PolOrigIncDate BETWEEN ( CURRENT_DATE - 180 ) AND ( CURRENT_DATE - 90 )
								 -- Date ranges will roll.
								 -- Between 90 and 180 days or 3 and 6 months as of calendar date?
		QUALIFY RANK() OVER (PARTITION BY p.PolicyNo ORDER BY p.GWTermNo DESC, p.ModelNo DESC) = 1
	) a
	WHERE a.PolCanDate IS NULL
		AND a.RiskOrgOnCovDate <= CURRENT_DATE -- There can be more than one RiskOrgOnCovDate per risk.
		AND a.SliceDate <= CURRENT_DATE
		AND a.SliceExpDate > CURRENT_DATE
)
	
SEL
	 fcp.PolicyNo
	,fcp.SubPolicyID
	,SUM(fcp.CvgAPrem) CoverageAnnualPremium
	--,SUM(fcp.PrmAftOvrd) PremiumAfterOverride
	--,SUM(ftp.CvgTranPrm) CoverageTransactionPremium
FROM PR1_PL_SAS_Views.Financial_Cost_Policy fcp
--FROM PR1_PL_SAS_Views.Financial_Trans_Policy ftp
INNER JOIN EligibleRisks er
	ON  fcp.PolicyNo    = er.PolicyNo
	AND fcp.SubPolicyID = er.SubPolicyID
	AND fcp.GWTermNo    = er.GWTermNo
	AND fcp.ModelNo     = er.ModelNo
/*
WHERE EXISTS (
	SEL 1
	FROM PR1_PL_SAS_Views.Financial_Cost_Policy fcp
	WHERE fcp.PolicyNo = er.PolicyNo
		AND fcp.SubPolicyID = er.SubPolicyID
		AND fcp.GWTermNo    = er.GWTermNo
		AND fcp.ModelNo     = er.ModelNo
		
)
*/
	AND fcp.GWTermNo = 1
	AND fcp.ModelNo  = 1
GROUP BY
	 1
	,2
--HAVING SUM(fcp.CvgAPrem) > 700
;			


