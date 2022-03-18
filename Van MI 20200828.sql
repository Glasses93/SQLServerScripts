SELECT *
FROM sandbox.dbo.SJ_DriverMonitoringVanMI
WHERE VehMake IS NOT NULL
AND VehModel IS NULL
AND YEAR(d) = 2020
ORDER BY d DESC
;

;WITH x AS (
SELECT
d = DATENAME(MONTH, d), m = MONTH(d)
,VehMake = CASE VehMake WHEN 'MERCEDES-B' THEN 'Mercedes' WHEN 'RENAULT TRUCKS' THEN 'Renault' ELSE VehMake END
--,RisksDriving
--,Trips
,MilesDriven = SUM(MilesDriven)
FROM sandbox.dbo.SJ_DriverMonitoringVanMI
WHERE VehMake IS NOT NULL
AND VehModel IS NULL
AND YEAR(d) = 2020
GROUP BY DATENAME(MONTH, d), CASE VehMake WHEN 'MERCEDES-B' THEN 'Mercedes' WHEN 'RENAULT TRUCKS' THEN 'Renault' ELSE VehMake END, MONTH(d)
)
SELECT d, p.CITROEN, p.FIAT, p.FORD, p.ISUZU, p.IVECO, p.[LAND ROVER], p.MERCEDES, p.MITSUBISHI, p.NISSAN, p.PEUGEOT, p.RENAULT, p.TOYOTA, p.VAUXHALL, p.VOLKSWAGEN
FROM x
PIVOT (
SUM(MilesDriven) FOR VehMake IN (CITROEN, FIAT, FORD, ISUZU, IVECO, [LAND ROVER], MERCEDES, MITSUBISHI, NISSAN, PEUGEOT, RENAULT, TOYOTA, VAUXHALL, VOLKSWAGEN)
) p
ORDER BY m DESC
;

;WITH OK AS (
SELECT d = DATENAME(MONTH, d), m = MONTH(d)
, KeyF
,MilesDriven = SUM(MilesDriven)
FROM sandbox.dbo.SJ_DriverMonitoringVanMI
WHERE KeyF IS NOT NULL
AND Home_V2F IS NULL
AND YEAR(d) = 2020
GROUP BY DATENAME(MONTH, d), KeyF, MONTH(d)
)
SELECT d, p.[1) Frontline NHS], p.[2) Other Care/Emergency], p.[3) Likely Key Workers (non-emergency)], p.[4) Possible Key Workers], p.[5) Not Key Workers]
FROM OK
PIVOT (
SUM(MilesDriven) FOR KeyF IN ([1) Frontline NHS], [2) Other Care/Emergency], [3) Likely Key Workers (non-emergency)], [4) Possible Key Workers], [5) Not Key Workers])
) p
ORDER by m DESC
;

;with lel as (
select m = datename(month, d), d = month(d), vehusedesc, milesdriven = sum(milesdriven)
from SJ_DriverMonitoringVanMI
where vehusedesc is not null
and year(d) = 2020
group by datename(month, d), month(d), vehusedesc
)
select
m, p.commuting, p.haulage, p.leisure , p.[own goods]
from lel
pivot (
max(milesdriven) for vehusedesc in (Commuting, Haulage, Leisure, [Own Goods])
) p
order by d desc
;


;with lel as (
select m = datename(month, d), d = month(d), 
vehmiles =
CASE WHEN VehMiles < 10000 THEN '10K'
WHEN VehMiles < 25000 THEN '25K'
WHEN VehMiles < 50000 THEN '50K'
WHEN VehMiles >= 50000 THEN '50K+'
END
, milesdriven = sum(milesdriven)
from SJ_DriverMonitoringVanMI
where vehmiles is not null
and year(d) = 2020
group by datename(month, d), month(d), 
CASE WHEN VehMiles < 10000 THEN '10K'
WHEN VehMiles < 25000 THEN '25K'
WHEN VehMiles < 50000 THEN '50K'
WHEN VehMiles >= 50000 THEN '50K+'
END
)
select
m, p.[10K], p.[25K], p.[50K], p.[50K+]
from lel
pivot (
max(milesdriven) for VEHMILES in ([10K], [25K], [50K], [50K+])
) p
order by d desc


;