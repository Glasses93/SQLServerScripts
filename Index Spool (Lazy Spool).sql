
-- ~4,000 rows
SELECT *
FROM sandbox.dbo.SJ_IndexSpool
;

-- Feel free to change indexes on this table, it's not used by by any procedure or script.

-- DROP INDEX IX_SJIndexSpool_JourneysRNExternalContractNumberNumTerm ON sandbox.dbo.SJ_IndexSpool
--CREATE UNIQUE NONCLUSTERED INDEX IX_SJIndexSpool_JourneysRNExternalContractNumberNumTerm
--ON sandbox.dbo.SJ_IndexSpool (
--	 JourneysRN		        ASC
--	,ExternalContractNumber ASC
--	,NumTerm                ASC
--)
--INCLUDE (
--	 MilesFromRAToJourneyEnd
--	,UKEndTime
--	,NextUKStartTime
--)
--;

-- DROP INDEX IX_SJIndexSpool_MilesFromRAToJourneyEndExternalContractNumberNumTerm ON sandbox.dbo.SJ_IndexSpool;
CREATE NONCLUSTERED INDEX IX_SJIndexSpool_MilesFromRAToJourneyEndExternalContractNumberNumTerm
ON sandbox.dbo.SJ_IndexSpool (
	 MilesFromRAToJourneyEnd ASC
)
INCLUDE (
	 JourneysRN
	,ExternalContractNumber
	,NumTerm
	,UKEndTime
	,NextUKStartTime
)
;

;WITH x AS (
	SELECT
		 ExternalContractNumber
		,NumTerm
		,UKEndTime
		,NextUKStartTime
		,ConsecutiveGroup = JourneysRN - ROW_NUMBER() OVER ( PARTITION BY ExternalContractNumber, NumTerm ORDER BY JourneysRN ASC ) 
	FROM sandbox.dbo.SJ_IndexSpool
	WHERE MilesFromRAToJourneyEnd > 1
	--ORDER BY JourneysRN ASC
),
y AS (
	SELECT
		 ExternalContractNumber
		,NumTerm
		,Consec = DATEDIFF(DAY, MIN(UKEndTime), MAX(NextUKStartTime))
	FROM x
	GROUP BY
		 ExternalContractNumber
		,NumTerm
		,ConsecutiveGroup
)
SELECT
	 ExternalContractNumber
	,NumTerm
	,MaxConsecDaysNoParkLTE1MileToRA = MAX(Consec)
FROM y
GROUP BY
	 ExternalContractNumber
	,NumTerm
OPTION ( RECOMPILE )
;







-- This can sometimes run instantly or sometimes it can take between 10-15 seconds.
-- Actual Execution Plan on the longer runs shows the Index Spool (Lazy Spool) takes the longest bit
-- and the Actual Execution Plan on the quicker runs shows an identical plan (to my knowledge).
-- Unless something is happening with Memory Grants?
-- I think stats and estimates remain the same.
-- This is a bit beyond me.
-- I don't think it's do to do with reading from disk, either.
-- This query against a lot larger (potentially tens of millions of rows) table may be used in PR in the coming weeks each day
-- so I wanted to know if I need to find an alternative solution sooner rather than later.
-- Appreciate any help.
;WITH Recursion AS (
	SELECT
		 ExternalContractNumber
		,NumTerm
		,JourneysRN
		,UKEndTime
		,NextUKStartTime
		,MilesFromRAToJourneyEnd
		,EndTimeNoParkLTE1MileToRA = CASE WHEN MilesFromRAToJourneyEnd > 1 THEN UKEndTime END
	FROM sandbox.dbo.SJ_IndexSpool
	WHERE JourneysRN = 1
	UNION ALL
	SELECT
		 ixs.ExternalContractNumber
		,ixs.NumTerm
		,ixs.JourneysRN
		,ixs.UKEndTime
		,ixs.NextUKStartTime
		,ixs.MilesFromRAToJourneyEnd
		,EndTimeNoParkLTE1MileToRA =
			CASE
				WHEN r.MilesFromRAToJourneyEnd > 1 AND ixs.MilesFromRAToJourneyEnd > 1 THEN r.EndTimeNoParkLTE1MileToRA
				WHEN						           ixs.MilesFromRAToJourneyEnd > 1 THEN ixs.UKEndTime
			END
	FROM sandbox.dbo.SJ_IndexSpool ixs
	INNER JOIN Recursion r
		ON  ixs.JourneysRN			   = r.JourneysRN + 1
		AND ixs.ExternalContractNumber = r.ExternalContractNumber
		AND ixs.NumTerm				   = r.NumTerm
)
SELECT
	 ExternalContractNumber
	,NumTerm
	,MaxConsecDaysNoParkLTE1MileToRA = COALESCE(MAX(DATEDIFF(DAY, EndTimeNoParkLTE1MileToRA, NextUKStartTime)), 0)
FROM Recursion
GROUP BY
	 ExternalContractNumber
	,NumTerm
OPTION (
	 MAXRECURSION 0
	,RECOMPILE
)
;