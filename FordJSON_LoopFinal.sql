
/* set up numbered JSONs for iterating over*/
-- drop table if exists sandbox.dbo.MD_FordJSONs
-- create table sandbox.dbo.MD_FordJSONs (
	  -- row			int identity(1,1)
	 -- ,jsonString	varchar(max)
	-- )

-- insert into sandbox.dbo.MD_FordJSONs (jsonString)
-- select jsonString
-- from sandbox.dbo.MD_FordAllFiles

/*create table outputs*/
drop table if exists sandbox.dbo.MD_FordSpeeds;
create table sandbox.dbo.MD_FordSpeeds (
		 shardkey				varchar(50)
		,vin					varchar(30)
		,timestamp				datetime2(0)
		,speed_mps				numeric(14,9)
);
drop table if exists sandbox.dbo.MD_FordAccels;
create table sandbox.dbo.MD_FordAccels (
		 shardkey				varchar(50)
		,vin					varchar(30)
		,timestamp				datetime2(0)
		,accel_x				numeric(6,3)
		,accel_y				numeric(6,3)
);
drop table if exists sandbox.dbo.MD_FordPosition;
create table sandbox.dbo.MD_FordPosition (
		 shardkey				varchar(50)
		,vin					varchar(30)
		,timestamp				datetime2(0)
		,latitude				numeric(8,6)	
		,longitude				numeric(9,6)	
		,altitude       	    numeric(8,3)
);
drop table if exists sandbox.dbo.MD_FordOdometer;
create table sandbox.dbo.MD_FordOdometer (
		 shardkey				varchar(50)
		,vin					varchar(30)
		,timestamp				datetime2(0)
		,odometer_km			numeric(6,0)
);
drop table if exists sandbox.dbo.MD_FordCollision;
create table sandbox.dbo.MD_FordCollision (
		 shardkey				varchar(50)
		,vin					varchar(30)
		,timestamp				datetime2(0)
		,collisionWarningStatus	varchar(20)	
);
drop table if exists sandbox.dbo.MD_FordAlarm;
create table sandbox.dbo.MD_FordAlarm (
		 shardkey				varchar(50)
		,vin					varchar(30)
		,timestamp				datetime2(0)
		,alarmStatus			varchar(20)
);
drop table if exists sandbox.dbo.MD_FordFailures;
create table sandbox.dbo.MD_FordFailures (
		 shardkey				varchar(50)
		,vin					varchar(30)
		,timestamp				datetime2(0)
		,blindSpot				varchar(20)
		,blindSpotFailure		varchar(20)
);
drop table if exists sandbox.dbo.MD_FordDriverAssist;
create table sandbox.dbo.MD_FordDriverAssist (
		 shardkey				varchar(50)
		,vin					varchar(30)
		,timestamp				datetime2(0)
		,driverAssist			varchar(20)
);
drop table if exists sandbox.dbo.MD_FordIgnition;
create table sandbox.dbo.MD_FordIgnition (
		 shardkey						varchar(50)
		,vin							varchar(30)
		,timestamp						datetime2(0)
		,ignitionStatus					varchar(20)
		,latitude						numeric(8,6)	
		,longitude						numeric(9,6)	
		,altitude       			    numeric(8,3)	
		,odometerKMs					numeric(6,0)
		,heading						numeric(3,0)
		,oemCorrelationId				varchar(20)
);
drop table if exists sandbox.dbo.MD_FordSeatbelt;
create table sandbox.dbo.MD_FordSeatbelt (
		 shardkey						varchar(50)
		,vin							varchar(20)
		,timestamp						datetime2(0)
		,seatbeltStatus					varchar(50)
		,latitude						numeric(8,6)	
		,longitude						numeric(9,6)	
		,altitude       			    numeric(8,3)	
		,odometerKMs					numeric(6,0)
		,heading						numeric(3,0)
		,oemCorrelationId				varchar(20)
);
drop table if exists sandbox.dbo.MD_FordTripReport;
create table sandbox.dbo.MD_FordTripReport (
		 shardkey						varchar(50)
		,vin							varchar(30)
		,timestamp						datetime2(0)
		,latitude						numeric(8,6)
		,longitude						numeric(9,6)
		,altitude       			    numeric(8,3)
		,odometer_km                    numeric(6,0)
		,engineTime_s                   numeric(6,0)
		,engineIdleTime_s               numeric(6,0)
		,tripFuel_l                     numeric(10,6)
		,tripFuelIdle_l                 numeric(10,6)
		,tripDistance_km                numeric(7,0)
		,tripMaxSpeed_ms				numeric(10,7)
		,oemCorrelationId				varchar(20)
);
drop table if exists sandbox.dbo.MD_FordTripSummary;
create table sandbox.dbo.MD_FordTripSummary (
		 journeyID						bigint identity(1,1)
		,shardkey						varchar(50)
		,vin							varchar(30)
		,starttime						datetime2(0)
		,endtime						datetime2(0)
		,startLatitude					numeric(8,6)
		,startLongitude					numeric(9,6)
		,tripTime_s						numeric(6,0)
		,tripDistance_km                numeric(7,0)
		,tripMaxSpeed_ms				numeric(10,7)
		,tripEngineTime_s               numeric(6,0)
		,tripEngineIdleTime_s           numeric(6,0)
		,tripFuel_l                     numeric(10,6)
		,tripFuelIdle_l                 numeric(10,6)
		,startOdometer_km               numeric(6,0)
		,endOdometer_km                 numeric(6,0)
		,startAltitude     			    numeric(8,3)
		,endAltitude     			    numeric(8,3)
		,startHeading     			    numeric(3,0)
		,endHeading     			    numeric(3,0)
		,tripReportTimestamp			datetime2(0)
);
drop table if exists sandbox.dbo.MD_FordTrip;
create table sandbox.dbo.MD_FordTrip (
		 journeyID						bigint
		,shardkey						varchar(50)
		,vin							varchar(30)
		,timestamp						datetime2(0)
		,latitude						numeric(8,6)
		,longitude						numeric(9,6)
		,altitude       			    numeric(8,3)
		,speed_mps						numeric(13,8)	
		,accel_x						numeric(6,3)
		,accel_y						numeric(6,3)
		,seatbeltStatus					varchar(20)	
		,collisionWarningStatus			varchar(20)	
		,alarmStatus					varchar(20)	
		,blindSpot						varchar(20)
		,blindSpotFailure				varchar(20)
		,driverAssist					varchar(20)
);

/*set up iteration logic*/
declare @i int = 0;
declare @rows int;
select @rows = count(*)
from sandbox.dbo.MD_FordJSONs;

while @i < @rows

/*loop*/
begin
	set @i +=1;

	drop table if exists #singleJSON

	select jsonString
	into #singleJSON
	from sandbox.dbo.MD_FordJSONs
	where row = @i

	declare @json varchar(max);

	select @json = jsonString
	from #singleJSON

	if json_value(@json, '$.data.tags[0].value.sampleRate') = N'UP_TO_1_SECOND'
	
	begin
	
		if json_value(@json, '$.data.signal.wksSignal') = N'SPEED'

			insert into sandbox.dbo.MD_FordSpeeds
			select
				 shardkey
				,vin
				,timestamp = convert(datetime2(0), startTime, 127)
				,speed_mps = convert(numeric(13,8), speedValue)
			from openjson(@json)
			with	(
					 shardkey				varchar(50)
					,vin					varchar(50)
					,startTime				varchar(50)		'$.data.startTime'
					,speedValue				varchar(50)		'$.data.speedValue.speed'
			)

		else if json_value(@json, '$.data.signal.wksSignal') = N'ACCELERATION'

			insert into sandbox.dbo.MD_FordAccels
			select
				 shardkey
				,vin
				,timestamp = convert(datetime2(0), startTime, 127)		
				,accel_x = convert(numeric(6,3), x)
				,accel_y = convert(numeric(6,3), y)
			from openjson(@json)
			with	(
					 shardkey					varchar(50)
					,vin						varchar(50)
					,startTime					varchar(50)		'$.data.startTime'
					,x							varchar(50)		'$.data.threeAxisValue.x'
					,y							varchar(50)		'$.data.threeAxisValue.y'
					
			)	
		
		else if json_value(@json, '$.data.signal.wksSignal') = N'POSITION'
		
			insert into sandbox.dbo.MD_FordPosition
			select
				 j1.shardkey
				,j1.vin
				,timestamp = convert(datetime2(0), j1.startTime, 127)
				,latitude = convert(numeric(8,6) ,j2.latitude)
				,longitude = convert(numeric(9,6) ,j2.longitude)
				,altitude = convert(numeric(8,3) ,j2.altitude)
			from openjson(@json)
			with	(
					 shardkey					varchar(50)
					,vin						varchar(50)
					,startTime					varchar(50)		'$.data.startTime'
					,location					nvarchar(max)	'$.data.positionValue.location' as json
			) j1
			cross apply	openjson(location)
			with	(	
					 latitude					varchar(50)		'$.threeDPoint.latitude'
					,longitude					varchar(50)		'$.threeDPoint.longitude'
					,altitude					varchar(50)		'$.threeDPoint.altitude'	
			) j2
			
	end;

	else if json_value(@json, '$.data.signal.wksSignal') = N'ODOMETER'
		
			insert into sandbox.dbo.MD_FordOdometer
			select
				 shardkey
				,vin
				,timestamp = convert(datetime2(0), startTime, 127)
				,odometer_km = convert(numeric(6,0) ,doubleValue)
			from openjson(@json)
			with	(
					 shardkey					varchar(50)
					,vin						varchar(50)
					,startTime					varchar(50)		'$.data.startTime'
					,doubleValue				varchar(50)		'$.data.doubleValue'
			)
			
	else if json_value(@json, '$.data.signal.wksSignal') = N'FORWARD_COLLISION_WARNING_SYSTEM_STATUS'
	
			insert into sandbox.dbo.MD_FordCollision
			select
				 shardkey
				,vin
				,timestamp = convert(datetime2(0), startTime, 127)
				,collisionWarningStatus = activeInactiveStatus
			from openjson(@json)
			with	(
					 shardkey					varchar(50)
					,vin						varchar(50)
					,startTime					varchar(50)		'$.data.startTime'
					,activeInactiveStatus		varchar(50)		'$.data.enumValue.activeInactiveStatus'
			)	
			
	else if json_value(@json, '$.data.signal.wksSignal') = N'ALARM_STATUS'
	
			insert into sandbox.dbo.MD_FordAlarm
			select
				 shardkey
				,vin
				,timestamp = convert(datetime2(0), startTime, 127)
				,alarmStatus
			from openjson(@json)
			with	(
					 shardkey					varchar(50)
					,vin						varchar(50)
					,startTime					varchar(50)		'$.data.startTime'
					,alarmStatus				varchar(50)		'$.data.enumValue.alarmStatus'
			)

	else if json_value(@json, '$.data.signal.wksSignal') = N'BLIND_SPOT_WARNING_SYSTEM_STATUS'
	
			insert into sandbox.dbo.MD_FordFailures
			select
				 shardkey
				,vin
				,timestamp = convert(datetime2(0), startTime, 127)
				,blindSpot = monitorCoverageTagValue
				,blindSpotFailure = source
			from openjson(@json)
			with	(
					 shardkey					varchar(50)
					,vin						varchar(50)
					,startTime					varchar(50)		'$.data.startTime'
					,monitorCoverageTagValue	varchar(50)		'$.data.tags[0].value.monitorCoverageTagValue'
					,source						varchar(50)		'$.data.errorValue.source'
			)	
			
	else if json_value(@json, '$.data.signal.wksSignal') = N'DRIVER_ASSIST_SYSTEM_STATUS'
	
			insert into sandbox.dbo.MD_FordDriverAssist
			select
				 shardkey
				,vin
				,timestamp = convert(datetime2(0), startTime, 127)
				,driverAssist = offOnStatus
			from openjson(@json)
			with	(
					 shardkey					varchar(50)
					,vin						varchar(50)
					,startTime					varchar(50)		'$.data.startTime'
					,offOnStatus				varchar(50)		'$.data.enumValue.offOnStatus'
			)

	else if json_value(@json, '$.data.id') = N'aui:event:au:well_known:ignition_event'
		
		with ignitions as	(
							select
								 j1.shardkey
								,j1.vin
								,timestamp = convert(datetime2(0), j1.timestamp, 127)
								,j1.ignitionStatus
								,latitude = convert(numeric(8,6) ,j2.latitude)
								,longitude = convert(numeric(9,6) ,j2.longitude)
								,altitude = convert(numeric(8,3) ,j2.altitude)
								,odometerKMs = convert(numeric(6,0) ,j2.odometer)
								,heading = convert(numeric(3,0), j2.heading)
								,j1.oemCorrelationId
							from openjson(@json)
							with	(
									 shardkey						varchar(50)
									,vin							varchar(50)
									,timestamp						varchar(50)		'$.data.timestamp'
									,ignitionStatus					varchar(50)		'$.data.payload.conditions[0].condition'
									,metrics						nvarchar(max)	'$.data.payload.metrics' as json
									,oemCorrelationId				varchar(50)		'$.data.oemCorrelationId'
							) j1
							cross apply openjson(j1.metrics)
							with	(
									 latitude						varchar(50)		'$.positionValue.location[0].threeDPoint.latitude'
									,longitude						varchar(50)		'$.positionValue.location[0].threeDPoint.longitude'
									,altitude						varchar(50)		'$.positionValue.location[0].threeDPoint.altitude'
									,odometer						varchar(50)		'$.doubleValue'
									,heading						varchar(50)		'$.headingValue.heading'
							) j2
		)
		insert into sandbox.dbo.MD_FordIgnition
		select
			 a.shardkey
			,a.vin
			,a.timestamp
			,a.ignitionStatus
			,b.latitude
			,b.longitude
			,b.altitude
			,c.odometerKMs
			,d.heading
			,a.oemCorrelationId
		from	(
				select distinct
					 shardkey
					,vin
					,timestamp
					,ignitionStatus
					,oemCorrelationId
				from ignitions
				) a
		left join ignitions b
			on a.shardkey = b.shardkey
			and a.vin = b.vin
			and a.timestamp = b.timestamp
			and coalesce(b.latitude, b.longitude, b.altitude) is not null
		left join ignitions c
			on a.shardkey = c.shardkey
			and a.vin = c.vin
			and a.timestamp = c.timestamp
			and c.odometerKMs is not null
		left join ignitions d
			on a.shardkey = d.shardkey
			and a.vin = d.vin
			and a.timestamp = d.timestamp
			and d.heading is not null
					
	else if json_value(@json, '$.data.id') = N'aui:event:au:well_known:seat_belt_status_while_moving_event'
		
		with seatbelts as	(
							select
								 j1.shardkey
								,j1.vin
								,timestamp = convert(datetime2(0), j1.timestamp, 127)
								,j1.seatbeltStatus
								,latitude = convert(numeric(8,6) ,j2.latitude)
								,longitude = convert(numeric(9,6) ,j2.longitude)
								,altitude = convert(numeric(8,3) ,j2.altitude)
								,odometerKMs = convert(numeric(6,0) ,j2.odometer)
								,heading = convert(numeric(3,0), j2.heading)
								,j1.oemCorrelationId
							from openjson(@json)
							with	(
									 shardkey						varchar(50)
									,vin							varchar(50)
									,timestamp						varchar(50)		'$.data.timestamp'
									,seatbeltStatus					varchar(50)		'$.data.payload.conditions[0].metric.enumValue.seatbeltStatus'
									,metrics						nvarchar(max)	'$.data.payload.metrics' as json
									,oemCorrelationId				varchar(50)		'$.data.oemCorrelationId'
							) j1
							cross apply openjson(j1.metrics)
							with	(
									 latitude						varchar(50)		'$.positionValue.location[0].threeDPoint.latitude'
									,longitude						varchar(50)		'$.positionValue.location[0].threeDPoint.longitude'
									,altitude						varchar(50)		'$.positionValue.location[0].threeDPoint.altitude'
									,odometer						varchar(50)		'$.doubleValue'
									,heading						varchar(50)		'$.headingValue.heading'
							) j2
		)
		insert into sandbox.dbo.MD_FordSeatbelt
		select
			 a.shardkey
			,a.vin
			,a.timestamp
			,a.seatbeltStatus
			,b.latitude
			,b.longitude
			,b.altitude
			,c.odometerKMs
			,d.heading
			,a.oemCorrelationId
		from	(
				select distinct
					 shardkey
					,vin
					,timestamp
					,seatbeltStatus
					,oemCorrelationId
				from seatbelts
				) a
		left join seatbelts b
			on a.shardkey = b.shardkey
			and a.vin = b.vin
			and a.timestamp = b.timestamp
			and coalesce(b.latitude, b.longitude, b.altitude) is not null
		left join seatbelts c
			on a.shardkey = c.shardkey
			and a.vin = c.vin
			and a.timestamp = c.timestamp
			and c.odometerKMs is not null
		left join seatbelts d
			on a.shardkey = d.shardkey
			and a.vin = d.vin
			and a.timestamp = d.timestamp
			and d.heading is not null

	else if json_value(@json, '$.data.id') = N'aui:event:au:well_known:trip_report'
		
		with trip as	(
						select
							 j1.shardkey
							,j1.vin
							,timestamp = convert(datetime2(0), j1.timestamp, 127)
							,j2.metric
							,j2.units
							,j2.value
							,latitude = convert(numeric(8,6) ,j2.latitude)
							,longitude = convert(numeric(9,6) ,j2.longitude)
							,altitude = convert(numeric(8,3) ,j2.altitude)
							,j1.oemCorrelationId
						from openjson(@json)
						with	(
								 shardkey						varchar(50)
								,vin							varchar(50)
								,timestamp						varchar(50)		'$.data.timestamp'
								,metrics						nvarchar(max)	'$.data.payload.metrics' as json
								,oemCorrelationId				varchar(50)		'$.data.oemCorrelationId'
						) j1
						cross apply openjson(j1.metrics)
						with	(
								 metric							varchar(50)		'$.signal.wksSignal'
								,units							varchar(50)		'$.tags[0].value.stringValue'
								,value							varchar(50)		'$.doubleValue'
								,latitude						varchar(50)		'$.positionValue.location[0].threeDPoint.latitude'
								,longitude						varchar(50)		'$.positionValue.location[0].threeDPoint.longitude'
								,altitude						varchar(50)		'$.positionValue.location[0].threeDPoint.altitude'
						) j2
		)
		,pivotMetrics as	(
							select
								 shardkey
								,vin
								,timestamp
								,[ODOMETER]
								,[TOTAL_ENGINE_TIME]
								,[TOTAL_ENGINE_TIME_IDLE]
								,[TRIP_FUEL_CONSUMED]
								,[TRIP_FUEL_CONSUMED_IDLE]
								,[TRIP_DISTANCE_ACCUMULATED]
								,[TRIP_MAXIMUM_SPEED]
							from trip a
							pivot	(
									max(value)
									for metric in ([ODOMETER], [TOTAL_ENGINE_TIME], [TOTAL_ENGINE_TIME_IDLE], [TRIP_FUEL_CONSUMED], [TRIP_FUEL_CONSUMED_IDLE], [TRIP_DISTANCE_ACCUMULATED], [TRIP_MAXIMUM_SPEED])
									) pvt
		)
		insert into sandbox.dbo.MD_FordTripReport
		select
			 a.shardkey
			,a.vin
			,a.timestamp
			,b.latitude
			,b.longitude
			,b.altitude
			,odometer_km = convert(numeric(6,0), max(c.ODOMETER))
			,engineTime_s = convert(numeric(6,0), max(c.TOTAL_ENGINE_TIME))
			,engineIdleTime_s = convert(numeric(6,0), max(TOTAL_ENGINE_TIME_IDLE))
			,tripFuel_l = convert(numeric(10,6), max(TRIP_FUEL_CONSUMED))
			,tripFuelIdle_l = convert(numeric(10,6), max(TRIP_FUEL_CONSUMED_IDLE))
			,tripDistance_km = convert(numeric(7,0), max(c.TRIP_DISTANCE_ACCUMULATED))
			,tripMaxSpeed_ms = convert(numeric(10,7), max(c.TRIP_MAXIMUM_SPEED))
			,a.oemCorrelationId
		from	(
				select distinct
					 shardkey
					,vin
					,timestamp
					,oemCorrelationId
				from trip
				) a
		left join trip b
			on a.shardkey = b.shardkey
			and a.vin = b.vin
			and a.timestamp = b.timestamp
			and metric = 'POSITION'
		left join pivotMetrics c
			on a.shardkey = c.shardkey
			and a.vin = c.vin
			and a.timestamp = c.timestamp
		group by a.shardkey, a.vin, a.timestamp, b.latitude, b.longitude, b.altitude, a.oemCorrelationId

end;

/* fix ignition data points to tripreport*/
;with starttimes as (
	select 
		 a.shardkey
		,a.vin
		,starttime = b.timestamp
		,endtime = c.timestamp
		,startLatitude = b.latitude
		,startLongitude = b.longitude
		,startAltitude = b.altitude
		,startOdometer_km = b.odometerKMs
		,startHeading = b.heading
		,endLatitude = c.latitude
		,endLongitude = c.longitude
		,endAltitude = c.altitude
		,endOdometer_km = c.odometerKMs
		,endHeading = c.heading
		,a.oemCorrelationId
		,rn =
			row_number() over (
				partition by c.timestamp
				order by b.timestamp desc
				)
	from sandbox.dbo.MD_FordTripReport a
	left join sandbox.dbo.MD_FordIgnition b
		on a.shardkey = b.shardkey
		and a.vin = b.vin
		and b.ignitionStatus = 'IGNITION_ON'
		and b.timestamp < a.timestamp
	left join sandbox.dbo.MD_FordIgnition c
		on a.shardkey = c.shardkey
		and a.vin = c.vin
		and c.ignitionStatus = 'IGNITION_OFF'
		and a.oemCorrelationID = c.oemCorrelationID
)
insert into sandbox.dbo.MD_FordTripSummary (
	 shardkey
	,vin
	,starttime
	,endtime
	,startLatitude
	,startLongitude
	,tripTime_s
	,tripDistance_km
	,tripMaxSpeed_ms
	,tripEngineTime_s
	,tripEngineIdleTime_s
	,tripFuel_l
	,tripFuelIdle_l
	,startOdometer_km
	,endOdometer_km
	,startAltitude
	,endAltitude
	,startHeading
	,endHeading
	,tripReportTimestamp
)
select
	 a.shardkey
	,a.vin
	,b.starttime
	,b.endtime
	,b.startLatitude
	,b.startLongitude
	,tripTime_s = datediff(s, b.starttime, b.endtime)
	,a.tripDistance_km
	,a.tripMaxSpeed_ms
	,tripEngineTime_s =
		a.engineTime_s - lag(a.engineTime_s) over (
							partition by a.shardkey, a.vin
							order by a.timestamp asc
							)
	,tripEngineIdleTime_s =
		a.engineIdleTime_s - lag(a.engineIdleTime_s) over (
							partition by a.shardkey, a.vin
							order by a.timestamp asc
							)
	,a.tripFuel_l
	,a.tripFuelIdle_l
	,b.startOdometer_km
	,b.endOdometer_km
	,b.startAltitude
	,b.endAltitude
	,b.startHeading
	,b.endHeading
	,tripReportTimestamp = a.timestamp
from sandbox.dbo.MD_FordTripReport a
left join starttimes b
	on a.shardkey = b.shardkey
	and a.vin = b.vin
	and a.oemCorrelationId = b.oemCorrelationId
	and b.rn = 1
;

/*include OEM data in trip*/
insert into sandbox.dbo.MD_FordTrip (
	 shardkey
	,vin
	,timestamp
	,latitude
	,longitude
	,altitude
	,speed_mps
	,accel_x
	,accel_y
	,seatbeltStatus
	,collisionWarningStatus
	,alarmStatus
	,blindSpot
	,blindSpotFailure
	,driverAssist
)
select distinct
	 p.shardkey
	,p.vin
	,p.timestamp
	,latitude =
		first_value(p.latitude) over (
			partition by p.timestamp
			order by p.timestamp
			)
	,longitude =
		first_value(p.longitude) over (
			partition by p.timestamp
			order by p.timestamp
			)
	,altitude =
		first_value(p.altitude) over (
			partition by p.timestamp
			order by p.timestamp
			)
	,speed_mps =
		first_value(s.speed_mps) over (
			partition by s.timestamp
			order by s.timestamp
			)
	,accel_x =
		first_value(a.accel_x) over (
			partition by a.timestamp
			order by a.timestamp
			)
	,accel_y =
		first_value(a.accel_y) over (
			partition by a.timestamp
			order by a.timestamp
			)
	,sb.seatbeltStatus
	,c.collisionWarningStatus
	,al.alarmStatus
	,f.blindSpot
	,f.blindSpotFailure
	,d.driverAssist
from sandbox.dbo.MD_FordPosition p
left join sandbox.dbo.MD_FordSpeeds s
	on p.shardkey = s.shardkey
	and p.vin = s.vin
	and p.timestamp = s.timestamp
left join sandbox.dbo.MD_FordAccels a
	on p.shardkey = a.shardkey
	and p.vin = a.vin
	and p.timestamp = a.timestamp
left join sandbox.dbo.MD_FordSeatbelt sb
	on p.shardkey = sb.shardkey
	and p.vin = sb.vin
	and p.timestamp = sb.timestamp
left join sandbox.dbo.MD_FordCollision c
	on p.shardkey = c.shardkey
	and p.vin = c.vin
	and p.timestamp = c.timestamp
left join sandbox.dbo.MD_FordAlarm al
	on p.shardkey = al.shardkey
	and p.vin = al.vin
	and p.timestamp = al.timestamp
left join sandbox.dbo.MD_FordFailures f
	on p.shardkey = f.shardkey
	and p.vin = f.vin
	and p.timestamp = f.timestamp
left join sandbox.dbo.MD_FordDriverAssist d
	on p.shardkey = d.shardkey
	and p.vin = d.vin
	and p.timestamp = d.timestamp
;

/*add journeyID to trip data*/
update t
	set t.journeyID = (
		select r.journeyID
		from sandbox.dbo.MD_FordTripSummary r
		where t.shardkey = r.shardkey
			and t.vin = r.vin
			and (t.timestamp between dateadd(s, -5, r.starttime) and r.endtime)
		)
from sandbox.dbo.MD_FordTrip t
;


--select * from sandbox.dbo.MD_FordJSONs

--select * from sandbox.dbo.MD_FordSpeeds
--select * from sandbox.dbo.MD_FordAccels
--select * from sandbox.dbo.MD_FordPosition


--select * from sandbox.dbo.MD_FordOdometer
--select * from sandbox.dbo.MD_FordCollision
--select * from sandbox.dbo.MD_FordAlarm
--select * from sandbox.dbo.MD_FordFailures
--select * from sandbox.dbo.MD_FordDriverAssist
--select * from sandbox.dbo.MD_FordIgnition


--select * from sandbox.dbo.MD_FordTrip
--select * from sandbox.dbo.MD_FordTripReport
--select * from sandbox.dbo.MD_FordTripSummary

