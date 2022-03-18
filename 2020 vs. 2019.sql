
SELECT
vf.Date
,risks = vf.risks + rt.risks
,trips = vf.trips + rt.trips
,mileage = vf.mileage + rt.mileage
into #dailysum
FROM sandbox.dbo.TEL1386_VFDailySummary2 vf
INNER JOIN sandbox.dbo.TEL1386_RTDailySummary2 rt
ON vf.Date = rt.Date
AND vf.KeyF IS NULL
AND vf.Home_V2F IS NULL
AND rt.KeyF IS NULL
AND rt.Home_V2F IS NULL
ORDER BY vf.Date ASC
;

select * from #dailysum where day(date) = 28 and month(date) = 2

select
a.date
,[2019Risks] = a.risks
,[2019trips] = a.trips
,[2019mileage] = a.mileage
,[2020risks] = b.risks
,[2020trips] = b.trips
,[2020mileage] = b.mileage
from #dailysum a
inner join #dailysum b
on a.date = dateadd(year, -1, b.date)
order by a.date desc


select
a.date
,b.date
,datepart(week, a.date)
,datename(weekday, a.date)
,[2020Risks] = a.risks
,[2020trips] = a.trips
,[2020mileage] = a.mileage
,[2019risks] = b.risks
,[2019trips] = b.trips
,[2019mileage] = b.mileage
from #dailysum a
inner join #dailysum b
on year(a.date) = year(b.date) + 1
and datepart(week, a.date) = datepart(week, b.date)
and datename(weekday, a.date) = datename(weekday, b.date)
order by a.date desc
;

select
Month = datename(month, a.date)
,DayOfMonth = count(a.date)
from #yeet a
inner join #yeet b
on year(a.date) = year(b.date) - 1
and month(a.date) = month(b.date)
and day(a.date) = day(b.date)
and year(a.date) = 2019
group by  datename(month, a.date)
;