SELECT
	 *
	,Distracted =
		CONVERT(bit,
			CASE WHEN EXISTS (
				SELECT 1
				FROM DataSummary.dbo.CMTJourneys j
				WHERE t.PolicyNumber  = j.PolicyNumber
					AND t.RiskID      = j.RiskID	  
					AND j.JStartDate >= t.PolIncDate
					AND j.JEndDate   <  t.PeriodEndDate
					AND j.Trip_Mode IN ('car', 'driver')
					AND j.SumDistraction > 0
			)
				THEN 1
				ELSE 0
			END
		)
--INTO sandbox.dbo.CM_ServApp_DistractedDrivers
FROM sandbox.dbo.TEL1400_CMTBase02 t
;
