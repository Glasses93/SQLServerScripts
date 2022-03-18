
datawarehouse

dbo.Crash -- nada.
SELECT TOP (100) * FROM dbo.CRASHAcceleration WHERE AccelerationZ IS NOT NULL -- 1bn rows. acceleration events during a crash (more than one row per crash possible), no timestamp, though.
dbo.CrashOrg -- nada.
dbo.CrashPAirlock -- nada.
select top 1000 * from dbo.CRASHPosition where speed is not null or gpsquality_id is not null order by Crash_ID, CrashTime-- 39 milli. row per position of a crash. ts included, lat long too. Speed occasionally included.
dbo.CrashSAirlock -- nada.
select top 100 * from dbo.CRASHSummary where speed is not null and gpsquality_id is not null-- 2.17 milli. should be row per crash? ts, maxaccel, lat long, postcode, city street, roadtype, crashtype, speed sometimes present, gps, too.
dbo.CrashType -- 3 rows. potentially incomplete because CRASHSummary includes crash types of different values.

SELECT *
FROM staging.dbo.ImportFile
WHERE [Filename] LIKE '%OCTO%CRASH%'
ORDER BY LEFT([Filename], 18), EndTime DESC 
;

SELECT *
FROM staging.dbo.ImportFile_OCTO
ORDER BY ProcessedOn DESC
;
