
;WITH Taylor AS (
SELECT Polygon
FROM sandbox.dbo.SJ_Polygons
WHERE PolygonName = 'England & Wales Coastline'
)
INSERT sandbox.dbo.SJ_Coastlines
SELECT
'Vodafone'
,vj.enddate
,COUNT(DISTINCT vj.PolicyNumber)
FROM DataSummary.dbo.VodaJourneys_COVID vj
INNER JOIN Taylor t
ON t.Polygon.STIntersects(geography::Point(vj.end_lat, vj.end_long, 4326)) = 1
WHERE vj.enddate between '20200323' and '20200709'
AND vj.PolicyNumber IN (SELECT car.PolicyNumber FROM sandbox.dbo.SJ_Test car)
AND vj.end_lat IS NOT NULL
AND vj.end_long IS NOT NULL
group by vj.enddate
;


create table sandbox.dbo.SJ_Coastlines (
Supplier varchar(15) not null
,Date date not null
,RisksVisited smallint not null constraint df_lel default 0
)
;


declare @day date = '20200610';

while @day < '20200819'
begin

;WITH Taylor AS (
SELECT Polygon
FROM sandbox.dbo.SJ_Polygons
WHERE PolygonName = 'England & Wales Coastline'
)
INSERT sandbox.dbo.SJ_Coastlines
SELECT
'RedTail'
,@day
,COUNT(DISTINCT vj.PolicyNumber)
FROM DataSummary.dbo.RedTailScoreJourney vj
INNER JOIN Taylor t
ON t.Polygon.STIntersects(geography::Point(vj.journeyendlatitude , vj.journeyendlongitude , 4326)) = 1
WHERE vj.journeyenddate = @day
AND vj.PolicyNumber IN ( SELECT PolicyNumber FROM sandbox.dbo.SJ_TestRT WHERE RiskStartDate <= @Day AND RiskCXXDate > @Day )
AND vj.journeyendlatitude IS NOT NULL
AND vj.journeyendlongitude IS NOT NULL
--GROUP BY vj.JourneyEndDate
;

set @day = dateadd(day, 1, @day);

end
;

select *
from sandbox.dbo.SJ_Coastlines
;

select datepart(week, a.date), datename(weekday, a.date)
from sandbox.dbo.SJ_Coastlines a
inner join sandbox.dbo.sj_coastlines b
on year(a.date) = year(b.date) + 1
and datepart(week, a.date) = datepart(week, b.date)
and datename(weekday, a.date) = datename(weekday, b.date)
order by a.date desc
;

select *
from sandbox.dbo.SJ_Coastlines 
where year(date) = 2020
and supplier like 'v%'
order by date desc
;