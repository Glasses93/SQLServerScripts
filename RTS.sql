
select b.PolicyNumber
	,a.Journey_ID
--into sandbox.dbo.RTS_FirstJourney
from redtail.dbo.journeyevent a
inner join (
			select a.PolicyNumber
				,b.IMEI
				,min(b.EventTimeStamp) as EventTimeStamp
			from sandbox.dbo.RTS_NewAssociation a
			left join redtail.dbo.journeyevent b
				on a.IMEI = b.IMEI
				and a.StartDate <= b.EventTimeStamp
				and (a.EndDate  >  b.EventTimeStamp or a.EndDate is null)
			group by a.PolicyNumber, b.IMEI
			) b
	on a.IMEI = b.IMEI
	and a.EventTimeStamp = b.EventTimeStamp
;


select b.PolicyNumber
	,a.Journey_ID
--into sandbox.dbo.RTS_FirstJourney
from redtail.dbo.journeyevent a
inner join (
			select a.PolicyNumber
				,b.IMEI
				,min(b.EventTimeStamp) as EventTimeStamp
			from sandbox.dbo.RTS_NewAssociation a
			left join redtail.dbo.journeyevent b
				on a.IMEI = b.IMEI
				and a.StartDate <= b.EventTimeStamp
				and (a.EndDate  >  b.EventTimeStamp or a.EndDate is null)
			group by a.PolicyNumber, b.IMEI
			) b
	on a.IMEI = b.IMEI
	and a.EventTimeStamp = b.EventTimeStamp
LEFT JOIN dbo.SJ_Test t
	ON 1 = 0
;


