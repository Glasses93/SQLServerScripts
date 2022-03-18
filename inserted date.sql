;with lel as (
select account_id, driveid
from cmtserv.dbo.cmttripsummary
union all
select account_id, driveid
from cmtserv.dbo.cmttripsummary_el
)
select *
from lel a
where not exists
(
select 1
from datasummary.dbo.cmtjourneys b
where a.account_id = b.account_id
and a.driveid = b.driveid
)
;

select policynumber, riskid, driveid
from sandbox.dbo.cmttripsummary  a
where not exists
(
select 1
from datasummary.dbo.cmtjourneys b
where concat(a.policynumber, '.', a.riskid) = b.account_id
and a.driveid = b.driveid
) 



SELECT *
FROM sandbox.dbo.&CMTBase02

select TOP 10 * from TEL1400_CMTBase02 WHERE POLICYNUMBER = 'P67279476'

-- 620,072
-- 601,135

select *
--sum(distance_miles) * 1609.34
from datasummary.dbo.cmtjourneys
where account_id like 'P15048192%'
and trip_mode = 'car'
and driveid in (
select driveid
from datasummary.dbo.cmtjourneys
where account_id like 'P15048192%'
and trip_mode = 'car'
except
SELECT driveid
FROM sandbox.dbo.cmttripsummary WHERE POLICYNUMBER = 'P15048192' AND TRIP_MODE = 'car'
)

select a.driveid, a.distance_miles, b.distance_miles as bdistancemiles
from datasummary.dbo.cmtjourneys a
inner join sandbox.dbo.cmttripsummary b
on a.policynumber = b.policynumber
and a.riskid = b.riskid
and a.account_id like 'P64238589%'
and a.driveid = b.driveid
and (
( a.distance_miles != b.distance_miles )
or (a.distance_miles is null and b.distance_miles is not null )
or (a.distance_miles is not null and b.distance_miles is null )
)

select driveid, distance_mapmatched_km * 0.62037
from cmtserv.dbo.cmttripsummary
where driveid in ('8B4153F8-A8E9-4EAE-B669-F69F3F15F454', '7ACB20CE-A670-4DEF-90F8-B6D7EB2001FD')

8B4153F8-A8E9-4EAE-B669-F69F3F15F454	7.98962115600
7ACB20CE-A670-4DEF-90F8-B6D7EB2001FD	8.79269012100


select *
into #yeet
from cmtserv.dbo.cmttrip
where account_id = 'P15088548.M001'
and driveid in ('8B4153F8-A8E9-4EAE-B669-F69F3F15F454', '7ACB20CE-A670-4DEF-90F8-B6D7EB2001FD')


select distinct inserteddate
into #yeet2
from #yeet

select distinct lel = datediff_big(ms, a.inserteddate, b.inserteddate)
from #yeet2 a
inner join #yeet2 b
on datepart(day, a.inserteddate) = datepart(day, b.inserteddate)


select inserteddate
from #yeet


SELECT *
FROM CMTSERV.DBO.ASSOCIATION WHERE POLICYNUMBER = 'P67279476'


select *
from sandbox.dbo.sj_cmt1400_testpolicies a
where not exists (
select 1
from #batchone b
where a.policyno = b.policyno
and a.riskid = b.riskid
)
;

select *
into #batchone
from sandbox.dbo.sj_cmt1400_testpolicies a --6824
where exists (
select 1
from cmtserv.dbo.cmttrip b
where concat(a.policyno, '.', a.riskid) = b.account_id
and convert(date, b.inserteddate) in ('20200705', '20200626')
)
;


select distinct account_id, importfileid,  inserteddate
into sandbox.dbo.SJ_distinctinserteddate
from cmtserv.dbo.cmttrip a
where exists (
select 1
from sandbox.dbo.sj_cmt1400_testpolicies b
where account_id = b.policyno + '.' + b.riskid
)
;

select distinct a.account_id, a.importfileid, a.inserteddate, b.inserteddate as binserteddate, difference = datediff_big(ms, a.inserteddate, b.inserteddate)
into sandbox.dbo.SJ_distinctinserteddate2
from sandbox.dbo.SJ_distinctinserteddate a
inner join sandbox.dbo.SJ_distinctinserteddate b
on  a.account_id = b.account_id
and a.importfileid = b.importfileid
and convert(date, a.inserteddate) = convert(date, b.inserteddate)
and a.inserteddate != b.inserteddate

select distinct account_id
from sandbox.dbo.SJ_distinctinserteddate2


select *
into #remainingbatch
from sandbox.dbo.sj_cmt1400_testpolicies a
where not exists (
select 1
from sandbox.dbo.SJ_distinctinserteddate2  b
where a.policyno + '.' + a.riskid = b.account_id
)

select *
into sandbox.dbo.SJ_1400CMTRemainingBatch
from #remainingbatch

select top 100 *
from cmtserv.dbo.cmttriplabel

;with lel as (
select distinct a.account_id, a.driveid, lastlabel = last_value(a.new_label) over (partition by a.account_id, a.driveid order by a.label_change_Date asc)
from (
select account_id, driveid, new_label, label_change_date
from cmtserv.dbo.cmttripsummary
union all
select account_id, driveid, new_label, label_change_date
from cmtserv.dbo.cmttripsummary_el
) a
)
select account_id, sum(distance_mapmatched_km)
from cmtserv.dbo.cmttripsummary a
left join lel b
on a.account_id = b.account_id
and a.driveid = b.driveid
where a.account_id in ( select x.policyno + '.' + x.riskid from sandbox.dbo.SJ_1400CMTRemainingBatch x )
and a.inserteddate < '20200909'
and coalesce(b.lastlabel, a.user_label, a.trip_mode) 

select top 10 *
from cmtserv.dbo.cmttripsummary 

group by account_id



select *
from cmtserv.dbo.appassociation
where account_id like 'P62300393%'

select *
from cmtserv.dbo.successfulloginhistory
where policynumber = 'P18933626'

select *
from cmtserv.dbo.cmttripsummary
where account_id like 'P18933626%'

49243E09-F67E-BDF8-0D2A-23DA261E9456
select *
from cmtserv.dbo.association
where policynumber like 'P18933626%'