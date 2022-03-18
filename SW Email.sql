USE [msdb]
GO

/****** Object:  Job [DWH - File Transfer]    Script Date: 29/10/2018 11:57:25 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 29/10/2018 11:57:25 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DWH - File Transfer', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'This job sends out the load status email after ETL jobs have completed. Also populates the file transfer table', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'SQLServerDBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [DWH Status Email]    Script Date: 29/10/2018 11:57:26 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'DWH Status Email', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
 
 DECLARE @BodyFail varchar(max)
declare @TableHeadFail varchar(max)
declare @TableTailFail varchar(max)

DECLARE @BodyOCTO varchar(max)
declare @TableHeadOCTO varchar(max)
declare @TableTailOCTO varchar(max)

DECLARE @BodyVodafone varchar(max)
declare @TableHeadVodafone varchar(max)
declare @TableTailVodafone varchar(max)

DECLARE @BodyCMT varchar(max)
declare @TableHeadCMT varchar(max)
declare @TableTailCMT varchar(max)

DECLARE @BodyRedTail varchar(max)
declare @TableHeadRedTail varchar(max)
declare @TableTailRedTail varchar(max)

DECLARE @BodyImportFile varchar(max)
declare @TableHeadImportFile varchar(max)
declare @TableTailImportFile varchar(max)

DECLARE @DWHLOADBodyVodafone varchar(max)
declare @DWHLOADTableHeadVodafone varchar(max)
declare @DWHLOADTableTailVodafone varchar(max)

DECLARE @DWHLOADBodyCMT varchar(max)
declare @DWHLOADTableHeadCMT varchar(max)
declare @DWHLOADTableTailCMT varchar(max)

DECLARE @DWHLOADBodyOCTO varchar(max)
declare @DWHLOADTableHeadOCTO varchar(max)
declare @DWHLOADTableTailOCTO varchar(max)

DECLARE @DWHLOADBodyRedTail varchar(max)
declare @DWHLOADTableHeadRedTail varchar(max)
declare @DWHLOADTableTailRedTail varchar(max)


DECLARE @BodyFinal varchar(max)
DECLARE @subject varchar(max)

declare @mailitem_id as int
declare @statusMsg as varchar(max)
declare @Error as varchar(max) 
declare @Note as varchar(max)




Set NoCount On;
set @mailitem_id = null
set @statusMsg = null
set @Error = null
set @Note = null
Set @TableTailFail = ''</table></body></html>'';
Set @TableTailOCTO = ''</table></body></html>'';
Set @TableTailVodafone=''</table></body></html>'';
Set @TableTailCMT=''</table></body></html>'';
Set @TableTailRedTail  =''</table></body></html>'';
Set @TableTailImportFile=''</table></body></html>'';
Set @DWHLOADTableTailOCTO=''</table></body></html>'';
Set @DWHLOADTableTailVodafone=''</table></body></html>'';
Set @DWHLOADTableTailCMT  =''</table></body></html>'';
Set @DWHLOADTableTailRedTail  =''</table></body></html>'';

---- Failed LIST --------

--HTML layout--
Set @TableHeadFail = ''<html><head>'' +
''<H2 align="center" style="color: #000000"> DDP DWH Load Daily Status Report</H2>'' +

 -- ''<H4 style="color: #0000CC">Load Date: </H4>''CAST( CONVERT (DATE, GETDATE()) as nvarchar(13))  +
    ''Load Date: ''+CAST( CONVERT (DATE, GETDATE()) as nvarchar(13)) +
    
''<H3 style="color: #FF0000">Failed Jobs List</H3>'' +
--''<style>'' +
--''td {border: solid black 1px;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font-size:9pt;color:Black;} '' +
--''</style>'' +
    N''<style type=''''text/css''''>''+
N''table {border-collapse:collapse;border:2px solid #00FFFF;font;5pt verdana;color:#343434; }'' +
N''table td, table th, table caption { border:1px solid #3399FF;  }'' +
N''table th { background-color:#FFFFFF; font-weight:bold; }'' +
N''</style>''+
''</head>'' +
''<body><table cellpadding=2 cellspacing=2 border=2>'' +
''<tr bgcolor=#F6AC5D>''+
''<td align=left><b>PackageName</b></td> <TH> &nbsp</TH>''+
''<td style="color: #FF0000" align=center><b>Status</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>StartTime</b></td><TH> &nbsp</TH>'' +
--''<td align=center><b>EndTime</b></td><TH> &nbsp</TH>'' + 
''<td align=center><b>InsertCount</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>UpdateCount</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>DeleteCount</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>OtherCount</b></td><TH> &nbsp</TH>'' + 
''<td align=center><b>ErrorCount</b></td><TH> &nbsp</TH>'' + 
''<td align=center><b>DurationHMS</b></td></tr>'';

WITH FailStatus AS (

(
SELECT distinct T.PackageName, 
                   (Case when (RunCode=''S'')     then ''Sucess''
                                when RunCode=''F'' then ''FAIL''
                                when RunCode=''R'' then ''Running''
                         END) RunCode ,
                    TaskStartTime, 
               --     TaskEndTime,
               --  CONVERT(VARCHAR(30),TaskStartTime,113) TaskStartTime,
                    isnull(InsertCount,0) InsertCount,
                    isnull(UpdateCount,0) UpdateCount,
                     isnull(DeleteCount,0) DeleteCount,
                     isnull(OtherCount,0) OtherCount,
                    isnull(ErrorCount,0) ErrorCount, 
                     isnull(DurationHMS,0) DurationHMS
                    
           FROM [ETLFramework].[ETLControl].[TaskLog] T

JOIN [ETLFramework].[ETLControl].[PackageQueue]  P

--on REPLACE(P.PackageName,''.DTSX'','''')=T.PackageName
on (Case when (P.PackageName=''EventAdHoc.dtsx'') then ''DWEvent''

   else REPLACE(P.PackageName,''.DTSX'','''') 
   end)=T.PackageName

   where cast(T.taskstarttime as date)>=cast(getdate() as DATE)    AND --''2014-12-30'' AND   --
   T.PackageName  in (SELECT T.PackageName FROM ETLFramework.ETLControl.TaskLog)
   AND T.TaskName in (SELECT T.TaskName FROM ETLFramework.ETLControl.TaskLog )
   AND RunCode=''F''
   AND InsertCount<>0
      
       UNION
          ( Select ''--'',''--'',GETDATE(),0,0,0,0,0,''0'')
  
  
  )
)
--SELECT * FROM  FailStatus


--Select information for the Report-- 

Select @BodyFail= 
(	  Select 
PackageName As [TD], '''',td='''', ''  '',
RunCode As [TD],td='''', ''  '',
TaskStartTime As [TD],td='''', ''  '',
--TaskEndTime As [TD],td='''', ''  '',
InsertCount As [TD],td='''', ''  '',
UpdateCount As [TD],td='''', ''  '',
DeleteCount As [TD],td='''', ''  '',
OtherCount As [TD],td='''', ''  '',
ErrorCount  As [TD],td='''', ''  '',
DurationHMS As [TD]

FROM FailStatus


For XML raw(''tr''), Elements)

-- Replace the entity codes and row numbers
Set @BodyFail = Replace(@BodyFail, ''_x0020_'', space(2))
Set @BodyFail = Replace(@BodyFail, ''_x003D_'', ''='')
Set @BodyFail = Replace(@BodyFail, ''<tr><TRRow>1</TRRow>'', ''<tr bgcolor=##FF0000>'')
Set @BodyFail = Replace(@BodyFail, ''<TRRow>0</TRRow>'', '''')


Set @BodyFail = @TableHeadFail + @BodyFail + @TableTailFail

--- END FAIL LIST--------

--------  OCTO BEGIN -----

--HTML layout--
Set @TableHeadOCTO = ''<html><head>'' +
''<H2 align="center" style="color: #3300FF">Success Jobs List</H2>'' +

''<H3 style="color: #330099">OCTO</H3>'' +
--''<style>'' +
--''td {border: solid black 1px;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font-size:9pt;color:Black;} '' +
--''</style>'' +
    N''<style type=''''text/css''''>''+
N''table {border-collapse:collapse;border:1px solid #00FFFF;font;10pt verdana;color:#343434; }'' +
N''table td, table th, table caption { border:1px solid #3399FF;  }'' +
N''table th { background-color:#FFFFFF; font-weight:bold; }'' +
N''</style>''+
''</head>'' +
''<body><table cellpadding=0 cellspacing=0 border=0>'' +
''<tr bgcolor=#F6AC5D>''+
''<td align=left><b>PackageName</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>Status</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>StartTime</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>EndTime</b></td><TH> &nbsp</TH>'' + 
''<td align=center><b>InsertCount</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>UpdateCount</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>DeleteCount</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>OtherCount</b></td><TH> &nbsp</TH>'' + 
''<td align=center><b>ErrorCount</b></td><TH> &nbsp</TH>'' + 
''<td align=center><b>DurationHMS</b></td></tr>'';

WITH OCTOStatus AS (

(
SELECT  T.PackageName, 
                   (Case when (RunCode=''S'')     then ''Sucess''
                                when RunCode=''F'' then ''FAIL''
                                when RunCode=''R'' then ''Running''
                         END) RunCode ,
                    TaskStartTime, 
                    TaskEndTime,
                    isnull(InsertCount,0) InsertCount,
                    isnull(UpdateCount,0) UpdateCount,
                     isnull(DeleteCount,0) DeleteCount,
                     isnull(OtherCount,0) OtherCount,
                    isnull(ErrorCount,0) ErrorCount, 
                     isnull(DurationHMS,0) DurationHMS
                    
           FROM [ETLFramework].[ETLControl].[TaskLog] T

JOIN [ETLFramework].[ETLControl].[PackageQueue]  P

--on REPLACE(P.PackageName,''.DTSX'','''')=T.PackageName
on (Case when (P.PackageName=''EventAdHoc.dtsx'') then ''DWEvent''

   else REPLACE(P.PackageName,''.DTSX'','''') 
   end)=T.PackageName
   where cast(T.taskstarttime as date)=cast(getdate() as DATE)    AND 
   T.PackageName  in (''DWVoucherResponse'',''DWLogin'',''DWCrashDetail'',''DWCrashSummary'',''DWTripp'',''DWTripp_BALUMBA'',''DWDeviceType'',''DWAnomaly'',''DWInstallerNetwork'')
   AND T.TaskName in (''Merge into VoucherResponse'',''Merge into Login'',''Data Flow Task'',''Merge into CrashSummary'',''Data Flow Task'',''DFT Tripp'',''DFT Tripp BALUMBA'',''DFT DeviceType'',''DFT Anomaly'',''DFT InstallerNetwork'')
   AND RunCode in (''R'',''S'')
    --  order by T.TaskStartTime ASC
      
         UNION
       --   ( Select ''Nodata'',''Nodata'',GETDATE(),GETDATE(),0,0,0,0,0,''aaa'')
         ( Select ''--'',''--'',GETDATE(),GETDATE(),0,0,0,0,0,''0'')
   
	  )
	)
--SELECT * FROM  CurrRateHistory


--Select information for the Report-- 
Select @BodyOCTO= 
(	  Select 
PackageName As [TD],'''',td='''', ''  '',
RunCode As [TD],'''',td='''', ''  '',
TaskStartTime As [TD],'''',td='''', ''  '',
TaskEndTime As [TD],'''',td='''', ''  '',
InsertCount As [TD],'''',td='''', ''  '',
UpdateCount As [TD],'''',td='''', ''  '',
DeleteCount As [TD],'''',td='''', ''  '',
OtherCount As [TD],'''',td='''', ''  '',
ErrorCount  As [TD],'''',td='''', ''  '',
DurationHMS As [TD]

FROM OCTOStatus


--union(
--  	Select 1,getdate(),getdate(),''a'' ,''Nodata'' )

For XML raw(''tr''), Elements)

-- Replace the entity codes and row numbers
Set @BodyOCTO = Replace(@BodyOCTO, ''_x0020_'', space(1))
Set @BodyOCTO = Replace(@BodyOCTO, ''_x003D_'', ''='')
Set @BodyOCTO = Replace(@BodyOCTO, ''<tr><TRRow>1</TRRow>'', ''<tr bgcolor=#C6CFFF>'')
Set @BodyOCTO = Replace(@BodyOCTO, ''<TRRow>0</TRRow>'', '''')


Set @BodyOCTO = @TableHeadOCTO + @BodyOCTO + @TableTailOCTO

---- OCTO END-----

-------Vodafone Begin---------


--------
--HTML layout--
Set @TableHeadVodafone = ''<html><head>'' +

''<H3 style="color: #330099">Vodafone</H3>'' +
--''<style>'' +
--''td {border: solid black 1px;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font-size:9pt;color:Black;} '' +
--''</style>'' +
    N''<style type=''''text/css''''>''+
N''table {border-collapse:collapse;border:1px solid #00FFFF;font;10pt verdana;color:#343434; }'' +
N''table td, table th, table caption { border:1px solid #3399FF;  }'' +
N''table th { background-color:#FFFFFF; font-weight:bold; }'' +
N''</style>''+
''</head>'' +
''<body><table cellpadding=0 cellspacing=0 border=0>'' +
''<tr bgcolor=#F6AC5D>''+
''<td align=left><b>PackageName</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>Status</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>StartTime</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>EndTime</b></td><TH> &nbsp</TH>'' + 
''<td align=center><b>InsertCount</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>UpdateCount</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>DeleteCount</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>OtherCount</b></td><TH> &nbsp</TH>'' + 
''<td align=center><b>ErrorCount</b></td><TH> &nbsp</TH>'' + 
''<td align=center><b>DurationHMS</b></td></tr>'';

WITH VodafoneStatus AS (

(
SELECT  T.PackageName, 
                   (Case when (RunCode=''S'')     then ''Sucess''
                                when RunCode=''F'' then ''FAIL''
                                when RunCode=''R'' then ''Running''
                         END) RunCode ,
                    TaskStartTime, 
                    TaskEndTime,
                    isnull(InsertCount,0) InsertCount,
                    isnull(UpdateCount,0) UpdateCount,
                     isnull(DeleteCount,0) DeleteCount,
                     isnull(OtherCount,0) OtherCount,
                    isnull(ErrorCount,0) ErrorCount, 
                     isnull(DurationHMS,0) DurationHMS
                    
           FROM [ETLFramework].[ETLControl].[TaskLog] T

JOIN [ETLFramework].[ETLControl].[PackageQueue]  P

--on REPLACE(P.PackageName,''.DTSX'','''')=T.PackageName
on REPLACE(P.PackageName,''.DTSX'','''')=T.PackageName
   where cast(T.taskstarttime as date)=cast(getdate() as DATE)    AND 
     T.PackageName  in (''DWVoucherRequest'',''DWVoucherResponse'',''DWTrip'',''DWAnomalies'',''DWGeneral'',''DWSummary'')
   AND T.TaskName in (''DFT Insert into VoucherRequest'',''DFT Insert into VoucherResponse'',''DFT Insert into Trip'',''DFT Insert into Anomalies'',''DFT Insert into General'',''DFT Insert into Summary'' )
   and RunCode in (''R'',''S'')
   --  order by T.TaskStartTime ASC
      
         UNION
      --    ( Select ''Nodata'',''Nodata'',GETDATE(),GETDATE(),0,0,0,0,0,''aaa'')
        ( Select ''--'',''--'',GETDATE(),GETDATE(),0,0,0,0,0,''0'')
   
	  )
	)
--SELECT * FROM  CurrRateHistory


--Select information for the Report-- 
Select @BodyVodafone= 
(	  Select 
PackageName As [TD],'''',td='''', ''  '',
RunCode As [TD],'''',td='''', ''  '',
TaskStartTime As [TD],'''',td='''', ''  '',
TaskEndTime As [TD],'''',td='''', ''  '',
InsertCount As [TD],'''',td='''', ''  '',
UpdateCount As [TD],'''',td='''', ''  '',
DeleteCount As [TD],'''',td='''', ''  '',
OtherCount As [TD],'''',td='''', ''  '',
ErrorCount  As [TD],'''',td='''', ''  '',
DurationHMS As [TD]

FROM VodafoneStatus


--union(
--  	Select 1,getdate(),getdate(),''a'' ,''Nodata'' )

For XML raw(''tr''), Elements)

-- Replace the entity codes and row numbers
Set @BodyVodafone = Replace(@BodyVodafone, ''_x0020_'', space(1))
Set @BodyVodafone = Replace(@BodyVodafone, ''_x003D_'', ''='')
Set @BodyVodafone = Replace(@BodyVodafone, ''<tr><TRRow>1</TRRow>'', ''<tr bgcolor=#C6CFFF>'')
Set @BodyVodafone = Replace(@BodyVodafone, ''<TRRow>0</TRRow>'', '''')


Set @BodyVodafone = @TableHeadVodafone + @BodyVodafone + @TableTailVodafone



----Vodafone END------

-------CMT Begin-------

Set @TableHeadCMT = ''<html><head>'' +
''<H2 align="center" style="color: #3300FF">Success Jobs List</H2>'' +

''<H3 style="color: #330099">CMT</H3>'' +
--''<style>'' +
--''td {border: solid black 1px;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font-size:9pt;color:Black;} '' +
--''</style>'' +
    N''<style type=''''text/css''''>''+
N''table {border-collapse:collapse;border:1px solid #00FFFF;font;10pt verdana;color:#343434; }'' +
N''table td, table th, table caption { border:1px solid #3399FF;  }'' +
N''table th { background-color:#FFFFFF; font-weight:bold; }'' +
N''</style>''+
''</head>'' +
''<body><table cellpadding=0 cellspacing=0 border=0>'' +
''<tr bgcolor=#F6AC5D>''+
''<td align=left><b>PackageName</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>Status</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>StartTime</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>EndTime</b></td><TH> &nbsp</TH>'' + 
''<td align=center><b>InsertCount</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>UpdateCount</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>DeleteCount</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>OtherCount</b></td><TH> &nbsp</TH>'' + 
''<td align=center><b>ErrorCount</b></td><TH> &nbsp</TH>'' + 
''<td align=center><b>DurationHMS</b></td></tr>'';

WITH CMTStatus AS (

(
SELECT  T.PackageName, 
                   (Case when (RunCode=''S'')     then ''Sucess''
                                when RunCode=''F'' then ''FAIL''
                                when RunCode=''R'' then ''Running''
                         END) RunCode ,
                    TaskStartTime, 
                    TaskEndTime,
                    isnull(InsertCount,0) InsertCount,
                    isnull(UpdateCount,0) UpdateCount,
                     isnull(DeleteCount,0) DeleteCount,
                     isnull(OtherCount,0) OtherCount,
                    isnull(ErrorCount,0) ErrorCount, 
                     isnull(DurationHMS,0) DurationHMS
                    
           FROM [ETLFramework].[ETLControl].[TaskLog] T

JOIN [ETLFramework].[ETLControl].[PackageQueue]  P

--on REPLACE(P.PackageName,''.DTSX'','''')=T.PackageName
on (Case when (P.PackageName=''EventAdHoc.dtsx'') then ''DWEvent''

  else REPLACE(P.PackageName,''.DTSX'','''') 
   end)=T.PackageName
   where cast(T.taskstarttime as date)=cast(getdate() as DATE)    AND 
   T.PackageName  in (''EndavaCancellation'',''CancellationHistory'',''RemoteSwitchOff'',''RemoteSwitchOn'',''SuccessfulLoginHistory'',''LocationPermissionChange'',''FailedLoginHistory'',''CMTMI'',''CMTTrip'')
   AND T.TaskName in (''Data Flow Task'',''Merge into CMTSERV Cancellation'')
  AND RunCode in (''R'',''S'')
    --  order by T.TaskStartTime ASC
      
         UNION
       --   ( Select ''Nodata'',''Nodata'',GETDATE(),GETDATE(),0,0,0,0,0,''aaa'')
         ( Select ''--'',''--'',GETDATE(),GETDATE(),0,0,0,0,0,''0'')
   
	  )
	)
--SELECT * FROM  CurrRateHistory


--Select information for the Report-- 
Select @BodyCMT= 
(	  Select 
PackageName As [TD],'''',td='''', ''  '',
RunCode As [TD],'''',td='''', ''  '',
TaskStartTime As [TD],'''',td='''', ''  '',
TaskEndTime As [TD],'''',td='''', ''  '',
InsertCount As [TD],'''',td='''', ''  '',
UpdateCount As [TD],'''',td='''', ''  '',
DeleteCount As [TD],'''',td='''', ''  '',
OtherCount As [TD],'''',td='''', ''  '',
ErrorCount  As [TD],'''',td='''', ''  '',
DurationHMS As [TD]

FROM CMTStatus


--union(
--  	Select 1,getdate(),getdate(),''a'' ,''Nodata'' )

For XML raw(''tr''), Elements)

-- Replace the entity codes and row numbers
Set @BodyCMT = Replace(@BodyCMT, ''_x0020_'', space(1))
Set @BodyCMT = Replace(@BodyCMT, ''_x003D_'', ''='')
Set @BodyCMT = Replace(@BodyCMT, ''<tr><TRRow>1</TRRow>'', ''<tr bgcolor=#C6CFFF>'')
Set @BodyCMT = Replace(@BodyCMT, ''<TRRow>0</TRRow>'', '''')


Set @BodyCMT = @TableHeadCMT + @BodyCMT + @TableTailCMT


-------CMT End-------

---------REDTAIL BEGIN-------------------


--------
--HTML layout--
Set @TableHeadRedTail = ''<html><head>'' +

''<H3 style="color: #330099">RedTail</H3>'' +
--''<style>'' +
--''td {border: solid black 1px;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font-size:9pt;color:Black;} '' +
--''</style>'' +
    N''<style type=''''text/css''''>''+
N''table {border-collapse:collapse;border:1px solid #00FFFF;font;10pt verdana;color:#343434; }'' +
N''table td, table th, table caption { border:1px solid #3399FF;  }'' +
N''table th { background-color:#FFFFFF; font-weight:bold; }'' +
N''</style>''+
''</head>'' +
''<body><table cellpadding=0 cellspacing=0 border=0>'' +
''<tr bgcolor=#F6AC5D>''+
''<td align=left><b>PackageName</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>Status</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>StartTime</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>EndTime</b></td><TH> &nbsp</TH>'' + 
''<td align=center><b>InsertCount</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>UpdateCount</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>DeleteCount</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>OtherCount</b></td><TH> &nbsp</TH>'' + 
''<td align=center><b>ErrorCount</b></td><TH> &nbsp</TH>'' + 
''<td align=center><b>DurationHMS</b></td></tr>'';

WITH RedTailStatus AS (

(
SELECT  T.PackageName , -- T.TaskName,
                   (Case when (RunCode=''S'')     then ''Sucess''
                                when RunCode=''F'' then ''FAIL''
                                when RunCode=''R'' then ''Running''
                         END) RunCode ,
                    TaskStartTime, 
                    TaskEndTime,
                    isnull(InsertCount,0) InsertCount,
                    isnull(UpdateCount,0) UpdateCount,
                     isnull(DeleteCount,0) DeleteCount,
                     isnull(OtherCount,0) OtherCount,
                    isnull(ErrorCount,0) ErrorCount, 
                     isnull(DurationHMS,0) DurationHMS
                    
           FROM [ETLFramework].[ETLControl].[TaskLog] T

JOIN [ETLFramework].[ETLControl].[PackageQueue]  P

--on REPLACE(P.PackageName,''.DTSX'','''')=T.PackageName
on REPLACE(P.PackageName,''.DTSX'','''')=T.PackageName
   where cast(T.taskstarttime as date)=cast(getdate() as DATE)    AND 
     T.PackageName  in (''DWCTDIOrder'',''DWFulFilledOrder'',''DWRTDailyConfirmation'',
''DWPolicyStatusUpdate'',''DWCustomerContact'',''DWRTDailyUpdate'',
''DWConnection'',''DWJourneyEvent'',''DWReturnDevice'',''DWPolicyReview'')
   AND T.TaskName in (''DFT Daily Update'',''Data Flow Task'',''JouneyEvent''
,''Insert Data into Connection'',''Insert Data into Return Device'' ,''Insert Data into Policy Review'')
   and RunCode in (''R'',''S'')
   --  order by T.TaskStartTime ASC
      
         UNION
      --    ( Select ''Nodata'',''Nodata'',GETDATE(),GETDATE(),0,0,0,0,0,''aaa'')
        ( Select ''--'',''--'',GETDATE(),GETDATE(),0,0,0,0,0,''0'')
   
	  )
	)
--SELECT * FROM  RedTailStatus


--Select information for the Report-- 
Select @BodyRedTail= 
(	  Select 
PackageName As [TD],'''',td='''', ''  '',
RunCode As [TD],'''',td='''', ''  '',
TaskStartTime As [TD],'''',td='''', ''  '',
TaskEndTime As [TD],'''',td='''', ''  '',
InsertCount As [TD],'''',td='''', ''  '',
UpdateCount As [TD],'''',td='''', ''  '',
DeleteCount As [TD],'''',td='''', ''  '',
OtherCount As [TD],'''',td='''', ''  '',
ErrorCount  As [TD],'''',td='''', ''  '',
DurationHMS As [TD]

FROM RedTailStatus


--union(
--  	Select 1,getdate(),getdate(),''a'' ,''Nodata'' )

For XML raw(''tr''), Elements)

-- Replace the entity codes and row numbers
Set @BodyRedTail = Replace(@BodyRedTail, ''_x0020_'', space(1))
Set @BodyRedTail = Replace(@BodyRedTail, ''_x003D_'', ''='')
Set @BodyRedTail = Replace(@BodyRedTail, ''<tr><TRRow>1</TRRow>'', ''<tr bgcolor=#C6CFFF>'')
Set @BodyRedTail = Replace(@BodyRedTail, ''<TRRow>0</TRRow>'', '''')


Set @BodyRedTail = @TableHeadRedTail + @BodyRedTail + @TableTailRedTail

--- REDTAIL END-------------

--- IMPORT FILE BEGING ---

--HTML layout--
Set @TableHeadImportFile= ''<html><head>'' +

''<H3 style="color: #330099">ImportFile Report</H3>'' +

    N''<style type=''''text/css''''>''+
N''table {border-collapse:collapse;border:1px solid #00FFFF;font;10pt verdana;color:#343434; }'' +
N''table td, table th, table caption { border:1px solid #3399FF;  }'' +
N''table th { background-color:#FFFFFF; font-weight:bold; }'' +
N''</style>''+
''</head>'' +
''<body><table cellpadding=0 cellspacing=0 border=0>'' +
''<tr bgcolor=#F6AC5D>''+
''<td align=left><b>Filename</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>FileDate</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>Status</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>RowsExpected</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>RowsImported</b></td><TH> &nbsp</TH>'' + 
''<td align=center><b>StartTime</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>EndTime</b></td></tr>'';

WITH ImportFile AS (

(
SELECT  	    Filename,
                    ISNULL(FileDate,'''') FileDate,
                    (case when ( IsSuccess=0) then ''FAIL''
                         when ( IsSuccess=1) then ''Sucess''
                         when ( IsSuccess IS NULL) then ''Running''
                         End) Status,
                    
                    ISNULL(RowsExpected,0) RowsExpected,
                    ISNULL(RowsImported,0) RowsImported,
                    ISNULL(StartTime,'''') StartTime, 
                    ISNULL(EndTime,'''') EndTime
                   
                    
                   
           FROM [staging].[dbo].[ImportFile] 
           where cast(StartTime as date)=cast(getdate() as DATE)
           
         --UNION  ( Select ''--'',''--'',0,0,GETDATE(),GETDATE(),0)
   
	  )
	)
--SELECT * FROM  ImportFile


--Select information for the Report-- 
Select @BodyImportFile= 
(	  Select 
Filename As [TD],'''',td='''', ''  '',
FileDate As [TD],'''',td='''', ''  '',
Status As [TD],'''',td='''', ''  '',
RowsExpected As [TD],'''',td='''', ''  '',
RowsImported As [TD],'''',td='''', ''  '',
StartTime As [TD],'''',td='''', ''  '',
EndTime As [TD]


FROM ImportFile


--union(
--  	Select 1,getdate(),getdate(),''a'' ,''Nodata'' )

For XML raw(''tr''), Elements)

-- Replace the entity codes and row numbers
Set @BodyImportFile = Replace(@BodyImportFile, ''_x0020_'', space(2))
Set @BodyImportFile = Replace(@BodyImportFile, ''_x003D_'', ''='')
Set @BodyImportFile = Replace(@BodyImportFile, ''<tr><TRRow>2</TRRow>'', ''<tr bgcolor=#CC0033>'')
Set @BodyImportFile = Replace(@BodyImportFile, ''<TRRow>1</TRRow>'', '''')


Set @BodyImportFile = @TableHeadImportFile + @BodyImportFile + @TableTailImportFile

--- IMPORT FILE END -----


----------  DWH JOB LOAD Vodafone BEGIN -----

--HTML layout--
Set @DWHLOADTableHeadVodafone = ''<html><head>'' +
--''<H2 align="center" style="color: #3300FF">Success Jobs List</H2>'' +
''<H3 style="color: #330099">Vodafone Job Details</H3>'' +

    N''<style type=''''text/css''''>''+
N''table {border-collapse:collapse;border:1px solid #00FFFF;font;10pt verdana;color:#343434; }'' +
N''table td, table th, table caption { border:1px solid #3399FF;  }'' +
N''table th { background-color:#FFFFFF; font-weight:bold; }'' +
N''</style>''+
''</head>'' +
''<body><table cellpadding=0 cellspacing=0 border=0>'' +
''<tr bgcolor=#F6AC5D>''+
''<td align=left><b>JobName</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>StepName</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>RunDateTime</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>RunDurationMinutes</b></td><TH> &nbsp</TH>'' + 
''<td align=center><b>RunStatus</b></td></tr>'';
  
 
WITH DWHLOADVodafoneStatus AS (

(
  select 
 j.name as JobName,
s.step_name as StepName,

msdb.dbo.agent_datetime(run_date, run_time) as RunDateTime,

((run_duration/10000*3600 + (run_duration/100)%100*60 + run_duration%100 + 31 ) / 60)      as RunDurationMinutes,

       CASE h.run_status
       WHEN 0 THEN ''Failed''
       WHEN 1 THEN ''Success''
       WHEN 2 THEN ''Retry''
       WHEN 3 THEN ''Cancelled''
       END AS Run_Status 
From msdb.dbo.sysjobs j 
INNER JOIN msdb.dbo.sysjobsteps s 
 ON j.job_id = s.job_id
INNER JOIN msdb.dbo.sysjobhistory h 
 ON s.job_id = h.job_id 
 AND s.step_id = h.step_id 
 AND h.step_id <> 0 
where j.name = ( ''DW - ETL - Vodafone'')
and cast(msdb.dbo.agent_datetime(run_date,0)as date)=cast(GETDATE() as date)

--order by msdb.dbo.agent_datetime(run_date, run_time) asc
   
	  )
	  	   union(
  	Select ''--'',''--'',getdate(),''0'' ,''---'' )
	)

 --SELECT JobName,StepName,RunDateTime,RunDurationMinutes,Run_Status FROM DWHLOADOCTOStatus
 

--Select information for the Report-- 
Select @DWHLOADBodyVodafone= 
(
	  Select 
JobName  As [TD],'''',td='''', ''  '',
StepName As [TD],'''',td='''', ''  '',
RunDateTime As [TD],'''',td='''', ''  '',
RunDurationMinutes As [TD],'''',td='''', ''  '',
Run_Status As [TD]

FROM DWHLOADVodafoneStatus


--union(
--  	Select 1,getdate(),getdate(),''a'' ,''Nodata'' )

For XML raw(''tr''), Elements)

-- Replace the entity codes and row numbers
Set @DWHLOADBodyVodafone = Replace(@DWHLOADBodyVodafone, ''_x0020_'', space(1))
Set @DWHLOADBodyVodafone = Replace(@DWHLOADBodyVodafone, ''_x003D_'', ''='')
Set @DWHLOADBodyVodafone = Replace(@DWHLOADBodyVodafone, ''<tr><TRRow>1</TRRow>'', ''<tr bgcolor=#C6CFFF>'')
Set @DWHLOADBodyVodafone = Replace(@DWHLOADBodyVodafone, ''<TRRow>0</TRRow>'', '''')


Set @DWHLOADBodyVodafone = @DWHLOADTableHeadVodafone + @DWHLOADBodyVodafone + @DWHLOADTableTailVodafone

---- DWH JOB LOAD Vodafone END-----



----------  DWH JOB LOAD CMT BEGIN -----

--HTML layout--
Set @DWHLOADTableHeadCMT = ''<html><head>'' +
--''<H2 align="center" style="color: #3300FF">Success Jobs List</H2>'' +
''<H3 style="color: #330099">CMT Job Details</H3>'' +

    N''<style type=''''text/css''''>''+
N''table {border-collapse:collapse;border:1px solid #00FFFF;font;10pt verdana;color:#343434; }'' +
N''table td, table th, table caption { border:1px solid #3399FF;  }'' +
N''table th { background-color:#FFFFFF; font-weight:bold; }'' +
N''</style>''+
''</head>'' +
''<body><table cellpadding=0 cellspacing=0 border=0>'' +
''<tr bgcolor=#F6AC5D>''+
''<td align=left><b>JobName</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>StepName</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>RunDateTime</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>RunDurationMinutes</b></td><TH> &nbsp</TH>'' + 
''<td align=center><b>RunStatus</b></td></tr>'';
  
 
WITH DWHLOADCMTStatus AS (

(
  select 
 j.name as JobName,
s.step_name as StepName,

msdb.dbo.agent_datetime(run_date, run_time) as RunDateTime,

((run_duration/10000*3600 + (run_duration/100)%100*60 + run_duration%100 + 31 ) / 60)      as RunDurationMinutes,

       CASE h.run_status
       WHEN 0 THEN ''Failed''
       WHEN 1 THEN ''Success''
       WHEN 2 THEN ''Retry''
       WHEN 3 THEN ''Cancelled''
       END AS Run_Status 
From msdb.dbo.sysjobs j 
INNER JOIN msdb.dbo.sysjobsteps s 
 ON j.job_id = s.job_id
INNER JOIN msdb.dbo.sysjobhistory h 
 ON s.job_id = h.job_id 
 AND s.step_id = h.step_id 
 AND h.step_id <> 0 
where j.name = ( ''DW - ETL - CMTSERV'')
and cast(msdb.dbo.agent_datetime(run_date,0)as date)=cast(GETDATE() as date)

--order by msdb.dbo.agent_datetime(run_date, run_time) asc
   
	  )
	  	   union(
  	Select ''--'',''--'',getdate(),''0'' ,''---'' )
	)

 --SELECT JobName,StepName,RunDateTime,RunDurationMinutes,Run_Status FROM DWHLOADOCTOStatus
 

--Select information for the Report-- 
Select @DWHLOADBodyCMT= 
(
	  Select 
JobName  As [TD],'''',td='''', ''  '',
StepName As [TD],'''',td='''', ''  '',
RunDateTime As [TD],'''',td='''', ''  '',
RunDurationMinutes As [TD],'''',td='''', ''  '',
Run_Status As [TD]

FROM DWHLOADCMTStatus


--union(
--  	Select 1,getdate(),getdate(),''a'' ,''Nodata'' )

For XML raw(''tr''), Elements)

-- Replace the entity codes and row numbers
Set @DWHLOADBodyCMT = Replace(@DWHLOADBodyCMT, ''_x0020_'', space(1))
Set @DWHLOADBodyCMT = Replace(@DWHLOADBodyCMT, ''_x003D_'', ''='')
Set @DWHLOADBodyCMT = Replace(@DWHLOADBodyCMT, ''<tr><TRRow>1</TRRow>'', ''<tr bgcolor=#C6CFFF>'')
Set @DWHLOADBodyCMT = Replace(@DWHLOADBodyCMT, ''<TRRow>0</TRRow>'', '''')


Set @DWHLOADBodyCMT = @DWHLOADTableHeadCMT + @DWHLOADBodyCMT + @DWHLOADTableTailCMT

---- DWH JOB LOAD CMT END-----


----------  DWH JOB LOAD OCTO BEGIN -----

--HTML layout--
Set @DWHLOADTableHeadOCTO = ''<html><head>'' +
--''<H2 align="center" style="color: #3300FF">Success Jobs List</H2>'' +
''<H3 style="color: #330099">OCTO Job Details</H3>'' +

    N''<style type=''''text/css''''>''+
N''table {border-collapse:collapse;border:1px solid #00FFFF;font;10pt verdana;color:#343434; }'' +
N''table td, table th, table caption { border:1px solid #3399FF;  }'' +
N''table th { background-color:#FFFFFF; font-weight:bold; }'' +
N''</style>''+
''</head>'' +
''<body><table cellpadding=0 cellspacing=0 border=0>'' +
''<tr bgcolor=#F6AC5D>''+
''<td align=left><b>JobName</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>StepName</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>RunDateTime</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>RunDurationMinutes</b></td><TH> &nbsp</TH>'' + 
''<td align=center><b>RunStatus</b></td></tr>'';
  
 
WITH DWHLOADOCTOStatus AS (

(
  select 
 j.name as JobName,
s.step_name as StepName,

msdb.dbo.agent_datetime(run_date, run_time) as RunDateTime,

((run_duration/10000*3600 + (run_duration/100)%100*60 + run_duration%100 + 31 ) / 60)      as RunDurationMinutes,

       CASE h.run_status
       WHEN 0 THEN ''Failed''
       WHEN 1 THEN ''Success''
       WHEN 2 THEN ''Retry''
       WHEN 3 THEN ''Cancelled''
       END AS Run_Status 
From msdb.dbo.sysjobs j 
INNER JOIN msdb.dbo.sysjobsteps s 
 ON j.job_id = s.job_id
INNER JOIN msdb.dbo.sysjobhistory h 
 ON s.job_id = h.job_id 
 AND s.step_id = h.step_id 
 AND h.step_id <> 0 
where j.name = ( ''DW - ETL - OCTO'')
and s.step_name <> ''*** DR -- Delete out of date TRIPP files from X_datawarehouse FOR DR --****''
and cast(msdb.dbo.agent_datetime(run_date,0)as date)=cast(GETDATE() as date)

--order by msdb.dbo.agent_datetime(run_date, run_time) asc
   
	  )
	  
	  	   union(
  	Select ''--'',''--'',getdate(),''0'' ,''---'' )
	)

 --SELECT JobName,StepName,RunDateTime,RunDurationMinutes,Run_Status FROM DWHLOADOCTOStatus
 

--Select information for the Report-- 
Select @DWHLOADBodyOCTO= 
(
	  Select 
JobName  As [TD],'''',td='''', ''  '',
StepName As [TD],'''',td='''', ''  '',
RunDateTime As [TD],'''',td='''', ''  '',
RunDurationMinutes As [TD],'''',td='''', ''  '',
Run_Status As [TD]

FROM DWHLOADOCTOStatus


--union(
--  	Select 1,getdate(),getdate(),''a'' ,''Nodata'' )

For XML raw(''tr''), Elements)

-- Replace the entity codes and row numbers
Set @DWHLOADBodyOCTO = Replace(@DWHLOADBodyOCTO, ''_x0020_'', space(1))
Set @DWHLOADBodyOCTO = Replace(@DWHLOADBodyOCTO, ''_x003D_'', ''='')
Set @DWHLOADBodyOCTO = Replace(@DWHLOADBodyOCTO, ''<tr><TRRow>1</TRRow>'', ''<tr bgcolor=#C6CFFF>'')
Set @DWHLOADBodyOCTO = Replace(@DWHLOADBodyOCTO, ''<TRRow>0</TRRow>'', '''')


Set @DWHLOADBodyOCTO = @DWHLOADTableHeadOCTO + @DWHLOADBodyOCTO + @DWHLOADTableTailOCTO

---- DWH JOB LOAD OCTO END-----



----------  DWH JOB LOAD REDTAIL BEGIN -----

--HTML layout--
Set @DWHLOADTableHeadRedTail = ''<html><head>'' +

''<H3 style="color: #330099">RedTail Job Details</H3>'' +

    N''<style type=''''text/css''''>''+
N''table {border-collapse:collapse;border:1px solid #00FFFF;font;10pt verdana;color:#343434; }'' +
N''table td, table th, table caption { border:1px solid #3399FF;  }'' +
N''table th { background-color:#FFFFFF; font-weight:bold; }'' +
N''</style>''+
''</head>'' +
''<body><table cellpadding=0 cellspacing=0 border=0>'' +
''<tr bgcolor=#F6AC5D>''+
''<td align=left><b>JobName</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>StepName</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>RunDateTime</b></td><TH> &nbsp</TH>'' +
''<td align=center><b>RunDurationMinutes</b></td><TH> &nbsp</TH>'' + 
''<td align=center><b>RunStatus</b></td></tr>'';
  
 
WITH DWHLOADRedTailStatus AS (

(
  select 
 j.name as JobName,
s.step_name as StepName,

msdb.dbo.agent_datetime(run_date, run_time) as RunDateTime,

((run_duration/10000*3600 + (run_duration/100)%100*60 + run_duration%100 + 31 ) / 60)      as RunDurationMinutes,

       CASE h.run_status
       WHEN 0 THEN ''Failed''
       WHEN 1 THEN ''Success''
       WHEN 2 THEN ''Retry''
       WHEN 3 THEN ''Cancelled''
       END AS Run_Status 
From msdb.dbo.sysjobs j 
INNER JOIN msdb.dbo.sysjobsteps s 
 ON j.job_id = s.job_id
INNER JOIN msdb.dbo.sysjobhistory h 
 ON s.job_id = h.job_id 
 AND s.step_id = h.step_id 
 AND h.step_id <> 0 
where j.name = ( ''DW - ETL - RedTail'')
and cast(msdb.dbo.agent_datetime(run_date,0)as date)=cast(GETDATE() as date)

--order by msdb.dbo.agent_datetime(run_date, run_time) asc
   
	  )
	   union(
  	Select ''--'',''--'',getdate(),''0'' ,''---'' )
	)

 --SELECT JobName,StepName,RunDateTime,RunDurationMinutes,Run_Status FROM DWHLOADRedTailStatus
 

--Select information for the Report-- 
Select @DWHLOADBodyRedTail = 
(
	  Select 
JobName  As [TD],'''',td='''', ''  '',
StepName As [TD],'''',td='''', ''  '',
RunDateTime As [TD],'''',td='''', ''  '',
RunDurationMinutes As [TD],'''',td='''', ''  '',
Run_Status As [TD]

FROM DWHLOADRedTailStatus


--union(
--  	Select ''No Data'',''No Data'',getdate(),0 ,''Nodata'' )

For XML raw(''tr''), Elements)

-- Replace the entity codes and row numbers
Set @DWHLOADBodyRedTail  = Replace(@DWHLOADBodyRedTail, ''_x0020_'', space(1))
Set @DWHLOADBodyRedTail = Replace(@DWHLOADBodyRedTail, ''_x003D_'', ''='')
Set @DWHLOADBodyRedTail = Replace(@DWHLOADBodyRedTail, ''<tr><TRRow>1</TRRow>'', ''<tr bgcolor=#C6CFFF>'')
Set @DWHLOADBodyRedTail = Replace(@DWHLOADBodyRedTail, ''<TRRow>0</TRRow>'', '''')


Set @DWHLOADBodyRedTail = @DWHLOADTableHeadRedTail + @DWHLOADBodyRedTail+ @DWHLOADTableTailRedTail

---- DWH JOB LOAD RedTail  END-----



----Final Set ---------
Set @BodyFinal =  @BodyFail+ @BodyOCTO +@BodyVodafone+@BodyCMT+@BodyRedTail+@BodyImportFile+@DWHLOADBodyOCTO+@DWHLOADBodyVodafone+@DWHLOADBodyCMT+@DWHLOADBodyRedTail
---------
-- Set Subject --
Select @subject= (select ''DWH Load Daily Status Report''+'' - ''+CAST( CONVERT (DATE, GETDATE()) as nvarchar(13)))
----

-- return output--
Select @BodyFinal

--Email
EXEC msdb.dbo.sp_send_dbmail @recipients=''may.wong@admiralgroup.co.uk;michael.cole@admiralgroup.co.uk;john.richards11@admiralgroup.co.uk;Emmanuel.Kanagala2@admiralgroup.co.uk;TelematicsDataTeam@admiralgroup.co.uk'',
    @subject = @subject,
    @body = @BodyFinal,
    @body_format = ''HTML'' ;
', 
		@database_name=N'msdb', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Populate File Transfer table]    Script Date: 29/10/2018 11:57:26 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Populate File Transfer table', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--TRUNCATE TABLE staging.dbo.FileTransfer
--SELECT * FROM staging.dbo.FileTransfer where lastupdated = cast(getdate() as date)

/*
Declare start and end date variables. 
Start date will be 30 days previous
End date will be today''s date

All queries will have CTE''s this will populate the table so 
we can see if there are dates which do no have data.
*/
DECLARE
@StartDate date = dateadd(dd,-30, cast(getdate() as date)),
@EndDate date = CAST(GETDATE()AS DATE),
@interval smallint = 1


/*
/*
DriveFactor Device
*/

;WITH CTEADR as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTEADR
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)

INSERT INTO staging.dbo.FileTransfer
SELECT 
	CAST(StDt AS DATE) as [Date],
	Count(device.deviceid)  AS ''Rows'',
	CAST(GETDATE()AS DATE) AS ''LastUpdated'',
	''Device'' AS ''TableType'',
	importfiletest.ImportFileID, 
	filename,
	NULL
FROM CTEADR cte
	JOIN staging.dbo.ImportFile ImportFileTest ON
	cast(left(right(ImportFileTest.Filename,14),10) as date) = CAST(StDt AS DATE)
	AND left(filename,22) = ''admiral_device_report_''
	LEFT OUTER JOIN development.dbo.Device Device ON
	Device.ImportFile_ID = ImportFileTest.ImportFileID 
GROUP BY 
	importfiletest.ImportFileID, 
	ImportFileTest.Filename,
	CAST(StDt AS DATE) 
ORDER BY 
	StDt desc

/*
StoneEvent
*/
;WITH CTEStone as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTEStone
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)
INSERT INTO staging.dbo.FileTransfer
SELECT 
	CAST(StDt AS DATE) as [Date],
	Count(s.device_id)  AS ''Rows'',
	CAST(GETDATE()AS DATE) AS ''LastUpdated'',
	''StoneEvent'' AS ''TableType'',
	'''' AS ImportFile_ID, 
	'''' AS filename,
	NULL
FROM CTEStone cte
	LEFT OUTER JOIN development.dbo.stoneeventmain s ON 
	cast(enddatetime as date) = CAST(StDt AS DATE)
GROUP BY 
	CAST(StDt AS DATE) 
ORDER BY 
	StDt desc


/*/*
Event Group

;WITH CTEEventG as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTEEventG
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)

INSERT INTO staging.dbo.FileTransfer
SELECT 
	CAST(StDt AS DATE) as [Date],
	RowsImported  AS ''Rows'',
	CAST(GETDATE()AS DATE) AS ''LastUpdated'',
	''EventGroup'' AS ''TableType'',
	ImportFileID, 
	filename,
	NULL
FROM CTEEventG cte
	JOIN staging.dbo.ImportFile ImportFileTest ON
	cast(left(right(ImportFileTest.Filename,14),10) as date) = CAST(StDt AS DATE)
	AND left(filename,27) = ''admiral_event_group_report_''
ORDER BY
	 StDt desc
*/
/*
Event

;WITH CTE as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTE
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)

INSERT INTO staging.dbo.FileTransfer
SELECT 
	CAST(StDt AS DATE) as [Date],
	RowsImported  AS ''Rows'',
	CAST(GETDATE()AS DATE) AS ''LastUpdated'',
	''Event'' AS ''TableType'',
	ImportFileID, 
	filename,
	NULL
FROM CTE cte
	JOIN staging.dbo.ImportFile ImportFileTest ON
	cast(left(right(ImportFileTest.Filename,14),10) as date) = CAST(StDt AS DATE)
	AND Filename like  ''admiral_event_report_%''
ORDER BY 
	StDt desc
*/*/
/*
Plugin
*/
;WITH CTEPlugin as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTEPlugin
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)

INSERT INTO staging.dbo.FileTransfer
SELECT CAST(StDt AS DATE) as [Date],
RowsImported  AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''Plugin'' AS ''TableType'',
ImportFileTest.ImportFileID, 
filename,
	NULL
FROM CTEPlugin cte
JOIN staging.dbo.ImportFile ImportFileTest ON
cast(left(right(ImportFileTest.Filename,14),10) as date) = CAST(StDt AS DATE)
AND Filename like  ''admiral_plugin_report_%''
ORDER BY StDt desc
*/
 /*
Device Type
*/

;WITH CTETYP as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTETYP
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)

INSERT INTO staging.dbo.FileTransfer
SELECT StDt as [Date],
ImportFileTest.RowsImported  AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''DEVICE TYPE'' AS ''TableType'',
ImportFileTest.ImportFileID, 
filename,
NULL
FROM CTETYP cte
LEFT OUTER JOIN staging.dbo.ImportFile ImportFileTest ON
cast(substring((Filename ) ,24,10) as date) = StDt
where   Filename like ''OCTO_ADMUK_DEVICE_TYPE%''
ORDER BY StDt desc

/*
Voucher Request
*/
;WITH CTEVoReq as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTEVoReq
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)

INSERT INTO staging.dbo.FileTransfer
SELECT CAST(StDt AS DATE) as [Date],
ImportFileTest.RowsImported  AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''VoucherRequest'' AS ''TableType'',
ImportFileTest.ImportFileID, 
filename,
	NULL
FROM CTEVoReq cte
LEFT OUTER JOIN staging.dbo.ImportFile ImportFileTest ON
cast(substring((Filename ) ,28,10) as date) = CAST(StDt AS DATE)
where  Filename like ''OCTO_ADMUK_VOUCHER_REQUEST%''
ORDER BY StDt desc



/*
BOLT Voucher Request
*/
;WITH CTEVoReqB as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTEVoReqB
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)

INSERT INTO staging.dbo.FileTransfer
SELECT CAST(StDt AS DATE) as [Date],
ImportFileTest.RowsImported  AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''VoucherRequest'' AS ''TableType'',
ImportFileTest.ImportFileID, 
filename,
	NULL
FROM CTEVoReqB cte
LEFT OUTER JOIN staging.dbo.ImportFile ImportFileTest ON
cast(substring((Filename ) ,32,10) as date) = CAST(StDt AS DATE)
where  Filename like ''OCTO_ADMUKBOLT_VOUCHER_REQUEST%''
ORDER BY StDt desc

/*
Voucher Response
*/

;WITH CTEVoRes as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTEVoRes
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)

INSERT INTO staging.dbo.FileTransfer
SELECT CAST(StDt AS DATE) as [Date],
ImportFileTest.RowsImported  AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''VoucherResponse'' AS ''TableType'',
ImportFileTest.ImportFileID, 
filename,
	NULL
FROM CTEVoRes cte
LEFT OUTER JOIN staging.dbo.ImportFile ImportFileTest ON
--cast(substring((Filename ) ,29,10) as date) = CAST(StDt AS DATE)
cast(left(right(Filename,16),10) as date) = CAST(StDt AS DATE)
where  Filename like ''OCTO_ADMUK_VOUCHER_RESPONSE%''
ORDER BY StDt desc


/*
BOLT Voucher Response
*/

;WITH CTEVoResB as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTEVoResB
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)

INSERT INTO staging.dbo.FileTransfer
SELECT CAST(StDt AS DATE) as [Date],
ImportFileTest.RowsImported  AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''VoucherResponse'' AS ''TableType'',
ImportFileTest.ImportFileID, 
filename,
	NULL
FROM CTEVoResB cte
LEFT OUTER JOIN staging.dbo.ImportFile ImportFileTest ON
cast(substring((Filename ) ,33,10) as date) = CAST(StDt AS DATE)
where  Filename like ''OCTO_ADMUKBOLT_VOUCHER_RESPONSE%''
ORDER BY StDt desc

/*
/*
Tamper Detail
*/

;WITH CTETampDe as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTETampDe
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)

INSERT INTO staging.dbo.FileTransfer
SELECT CAST(StDt AS DATE) as [Date],
ImportFileTest.RowsImported  AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''TamperDetail'' AS ''TableType'',
ImportFileTest.ImportFileID, 
filename,
NULL
FROM CTETampDe cte
LEFT OUTER JOIN staging.dbo.ImportFile ImportFileTest ON
cast(left(right(Filename,14),10) as date) = CAST(StDt AS DATE)
 WHERE Filename like ''admiral_tamper_24hr_detail_report_%''
ORDER BY StDt desc


/*
Tamper Summary
*/
;WITH CTETampSum as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTETampSum
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)

INSERT INTO staging.dbo.FileTransfer
SELECT CAST(StDt AS DATE) as [Date],
ImportFileTest.RowsImported  AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''TamperSummary'' AS ''TableType'',
ImportFileTest.ImportFileID, 
filename,
NULL
FROM CTETampSum cte
LEFT OUTER JOIN staging.dbo.ImportFile ImportFileTest ON
cast(left(right(Filename,14),10) as date) = CAST(StDt AS DATE)
 WHERE Filename like ''admiral_tamper_24hr_summary_report_%''
ORDER BY StDt desc
*/
/*
Login
*/

;WITH CTELOG as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTELOG
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)

INSERT INTO staging.dbo.FileTransfer
SELECT StDt as [Date],
ImportFileTest.RowsImported  AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''LOGIN'' AS ''TableType'',
ImportFileTest.ImportFileID, 
filename,
NULL
FROM CTELOG cte
LEFT OUTER JOIN staging.dbo.ImportFile ImportFileTest ON
cast(substring((Filename ) ,18,10) as date) = StDt
where   Filename like ''OCTO_ADMUK_LOGIN%''
ORDER BY StDt desc


/*
CrashD
*/
;WITH CTECRD as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTECRD
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)
INSERT INTO staging.dbo.FileTransfer
SELECT StDt as [Date],
ImportFileTest.RowsImported  AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''CrashD'' AS ''TableType'',
ImportFileTest.ImportFileID, 
filename,
NULL
FROM CTECRD cte
LEFT OUTER JOIN staging.dbo.ImportFile ImportFileTest ON
cast(substring((Filename ) ,19,10) as date) = StDt
where   Filename like ''OCTO_ADMUK_CRASHD%''
ORDER BY StDt desc

/*
CrashS
*/

;WITH CTECRS as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTECRS
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)

INSERT INTO staging.dbo.FileTransfer
SELECT StDt as [Date],
ImportFileTest.RowsImported  AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''CrashS'' AS ''TableType'',
ImportFileTest.ImportFileID, 
filename,
NULL
FROM CTECRS cte
LEFT OUTER JOIN staging.dbo.ImportFile ImportFileTest ON
cast(substring((Filename ) ,19,10) as date) = StDt
where   Filename like ''OCTO_ADMUK_CRASHS%''
ORDER BY StDt desc

/*
TRIPP BALUMBA
*/

;WITH CTETRBAL as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTETRBAL
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)
INSERT INTO staging.dbo.FileTransfer
SELECT StDt as [Date],
ImportFileTest.RowsImported  AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''TRIPP_BALUMBA'' AS ''TableType'',
ImportFileTest.ImportFileID, 
filename,
NULL
FROM CTETRBAL cte
LEFT OUTER JOIN staging.dbo.ImportFile ImportFileTest ON
cast(substring((Filename ) ,20,10) as date) = StDt
where   Filename like ''OCTO_BALUMBA_TRIPP%''
ORDER BY StDt desc

/*
Policy
*/
;WITH CTEPOL as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTEPOL
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)
INSERT INTO staging.dbo.FileTransfer
SELECT StDt as [Date],
COUNT(p.PolicyID)  AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''Policy'' AS ''TableType'',
'''',
'''',
	NULL
FROM CTEPOL cte
left join datawarehouse.dbo.contract c
 ON cast(c.associationdate as date) = StDt
LEFT OUTER JOIN datawarehouse.dbo.Policy p
on p.policyid = c.policy_id 
GROUP BY StDt
ORDER BY StDt desc


/*
Contract
*/
;WITH CTECon as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTECon
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)
INSERT INTO staging.dbo.FileTransfer
SELECT StDt as [Date],
COUNT(c.ContractID)  AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''Contract'' AS ''TableType'',
'''',
'''',
	NULL
FROM CTECon cte
left join datawarehouse.dbo.contract c
 ON cast(c.associationdate as date) = StDt
GROUP BY StDt
ORDER BY StDt desc


/*
TRIPP
*/
;WITH CTETRIPP as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTETRIPP
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)
INSERT INTO staging.dbo.FileTransfer
SELECT StDt as [Date],
ImportFileTest.RowsImported  AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''TRIPP'' AS ''TableType'',
ImportFileTest.ImportFileID, 
filename,
	NULL
FROM CTETRIPP cte
LEFT OUTER JOIN staging.dbo.ImportFile ImportFileTest ON
cast(substring((Filename ) ,18,10) as date) = StDt
where   Filename like ''OCTO_ADMUK_TRIPP_2%''
ORDER BY StDt desc



;WITH CTETRIPP2 as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTETRIPP2
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)
INSERT INTO staging.dbo.FileTransfer
SELECT StDt as [Date],
ImportFileTest.RowsImported  AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''TRIPP'' AS ''TableType'',
ImportFileTest.ImportFileID, 
filename,
	NULL
FROM CTETRIPP2 cte
LEFT OUTER JOIN staging.dbo.ImportFile ImportFileTest ON
CAST( substring((Filename ) ,20,10) as date) = StDt
where Filename like ''OCTO_ADMUK_TRIPP_A%''
or Filename like ''OCTO_ADMUK_TRIPP_B%''
ORDER BY StDt desc

/*
RedTail Association
*/


;WITH CTERTA as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTERTA
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)

INSERT INTO staging.dbo.FileTransfer
SELECT CAST(StDt AS DATE) as [Date],
COUNT(asso.AssociationID)  AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''Association'' AS ''TableType'',
'''', 
'''',
	NULL
FROM CTERTA cte
LEFT OUTER JOIN RedTail.dbo.association asso ON 
cast(insertedon as date) = CAST(StDt AS DATE)
GROUP BY CAST(StDt AS DATE)
ORDER BY StDt desc

/*
RedTail Journey Event
*/
;WITH CTERTJ as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTERTJ
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)

INSERT INTO staging.dbo.FileTransfer
SELECT CAST(StDt AS DATE) as [Date],
COUNT(JourneyEventID)  AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''RedTailJourneyEvent'' AS ''TableType'',
'''', 
'''',
	NULL
FROM CTERTJ cte
JOIN Redtail.dbo.journeyevent EV ON 
cast(eventtimestamp as date) = CAST(StDt AS DATE)
GROUP BY CAST(StDt AS DATE)
ORDER BY StDt desc


/*
OCTO Journey Event
*/

;WITH CTEOJE as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTEOJE
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)

INSERT INTO staging.dbo.FileTransfer
SELECT CAST(StDt AS DATE) as [Date],
COUNT(JourneyEventID)  AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''JourneyEvent'' AS ''TableType'',
'''', 
'''',
	NULL
FROM CTEOJE cte
JOIN datawarehouse.dbo.journeyevent EV ON 
cast(eventtimestamp as date) = CAST(StDt AS DATE)
GROUP BY CAST(StDt AS DATE)
ORDER BY StDt desc


/*
OCTO Journey
*/
;WITH CTEOJ as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTEOJ
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)

INSERT INTO staging.dbo.FileTransfer
SELECT CAST(StDt AS DATE) as [Date],
COUNT(JourneyID)  AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''Journey'' AS ''TableType'',
'''', 
'''',
	NULL
FROM CTEOJ cte
JOIN datawarehouse.dbo.journey EV ON 
cast(starttime as date) = CAST(StDt AS DATE)
GROUP BY CAST(StDt AS DATE)
ORDER BY StDt desc

/*
UserList


;WITH CTEUSR as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTEUSR
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)

INSERT INTO staging.dbo.FileTransfer
SELECT CAST(StDt AS DATE) as [Date],
Count(phoneid)  AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''UserList'' AS ''TableType'',
'''', 
'''',
	NULL
FROM CTEUSR cte
LEFT OUTER JOIN datawarehouse.dbo.UserList UserList ON
cast(UserList.RegistrationDTM as date) = CAST(StDt AS DATE)
GROUP BY CAST(StDt AS DATE) 
ORDER BY StDt desc
*/
/*
AppyDriver

;WITH CTEAPP as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTEAPP
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)

INSERT INTO staging.dbo.FileTransfer
SELECT CAST(StDt AS DATE) as [Date],
RowsImported  AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''AppyDriver'' AS ''TableType'',
ImportFileID, 
Filename,
	NULL
FROM CTEAPP cte
JOIN staging.dbo.ImportFile importfile ON
 convert(date,stuff(stuff(substring((Filename ) ,12,8),5,0,''-''),3,0,''-''),103) = CAST(StDt AS DATE)
where Filename like ''appydriver%'' 
ORDER BY StDt desc

*/


/*
This is to get the counts for Event without having to run the Event Script everyday.
Looks at Staging.dbo.Event table to only update the figures where we have new data.

Insert a new day into file transfer table 

insert into staging.dbo.FileTransfer
select CAST(getdate() as date),0,CAST(getdate() as date),''EventCount'',0,'''',NULL

/*
Copy the figures from previous day
*/
INSERT INTO staging.dbo.FileTransfer
select DATE, Rows, CAST(GETDATE()AS DATE), 
TableType, ImportFileID, Filename,LatestDate
 from staging.dbo.FileTransfer
where TableType = ''EventCount''
and LastUpdated = DATEADD(day, -1, convert(date, GETDATE()))
and DATE between @StartDate and @EndDate

/*
Insert new figures from staging into temporary table
*/
select CAST(eventdate as date) as date, COUNT(*) as newRows
into #staging --drop table #staging
FROM staging.dbo.Event
group by CAST(eventdate as date) 
order by date desc
 
 /*
 Update the copied figures in file transfer 
 table by comparing with staging table
 */
  
  update staging.dbo.FileTransfer
  set rows = rows+newRows
  FROM #staging e
  JOIN staging.dbo.FileTransfer t ON
  t.Date = e.Date
  where LastUpdated = CAST(GETDATE()AS DATE)
  AND TableType = ''EventCount''
*/

/*
Installer Network
*/

insert into staging.dbo.FileTransfer
select i.FileDate as ''Date'',
COUNT(*) as ''Rows''
,CAST(getdate() as date) as ''LastUpdated''
,''INSTALLER NETWORK'' as ''TableType''
,ImportFile_ID as ''ImportFileID''
,Filename
,NULL as ''LatestDate''
from datawarehouse.dbo.InstallerNetwork i
join staging.dbo.ImportFile imp on 
imp.ImportFileID = i.ImportFile_ID
where i.FileDate between dateadd(dd,-30, cast(getdate() as date)) and GETDATE()
group by i.FileDate,ImportFile_ID,filename
order by i.FileDate desc
  
/*
TRIPP CONTE
*/

;WITH CTETRCON as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTETRCON
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)
INSERT INTO staging.dbo.FileTransfer
SELECT StDt as [Date],
ImportFileTest.RowsImported  AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''TRIPP_CONTE'' AS ''TableType'',
ImportFileTest.ImportFileID, 
filename,
NULL
FROM CTETRCON cte
LEFT OUTER JOIN staging.dbo.ImportFile ImportFileTest ON
cast(substring((Filename ) ,18,10) as date) = StDt
where   Filename like ''OCTO_CONTE_TRIPP%''
ORDER BY StDt desc


/*******************************************
VODAFONE
*********************************************/

--VOUCHER REQUEST

;WITH CTEVVR AS
(
	SELECT @StartDate as StDt
	UNION ALL
	SELECT DATEADD(day,@interval,StDt)
	FROM CTEVVR
	WHERE DATEADD(day, @interval, StDt) <= @EndDate
)

INSERT INTO staging.dbo.FileTransfer
SELECT StDt AS [Date],
ImportFile.RowsImported AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''VodaVoucherRequest'' AS ''TableType'',
ImportFile.ImportFileID, 
filename,
NULL
FROM CTEVVR cte
LEFT OUTER JOIN staging.dbo.ImportFile ImportFile ON
CAST(SUBSTRING((Filename),27,8) as date) = StDt
where Filename like ''ADMUK_VODA_MASTER_REQUEST%''
Order by StDt desc



--VOUCHER RESPONSE

;WITH CTEVVS AS
(
	SELECT @StartDate as StDt
	UNION ALL
	SELECT DATEADD(day,@interval,StDt)
	FROM CTEVVS
	WHERE DATEADD(day, @interval, StDt) <= @EndDate
)

INSERT INTO staging.dbo.FileTransfer
SELECT StDt AS [Date],
ImportFile.RowsImported AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''VodaVoucherResponse'' AS ''TableType'',
ImportFile.ImportFileID, 
filename,
NULL
FROM CTEVVS cte
LEFT OUTER JOIN staging.dbo.ImportFile ImportFile ON
CAST(SUBSTRING((Filename),21,8) as date) = StDt
where Filename like ''VODA_ADMUK_RESPONSE%''
Order by StDt desc




--ANOMALIES MI

;WITH CTEVVA AS
(
	SELECT @StartDate as StDt
	UNION ALL
	SELECT DATEADD(day,@interval,StDt)
	FROM CTEVVA
	WHERE DATEADD(day, @interval, StDt) <= @EndDate
)

INSERT INTO staging.dbo.FileTransfer
SELECT StDt AS [Date],
ImportFile.RowsImported AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''VodaAnomaliesMI'' AS ''TableType'',
ImportFile.ImportFileID, 
filename,
NULL
FROM CTEVVA cte
LEFT OUTER JOIN staging.dbo.ImportFile ImportFile ON
CAST(SUBSTRING((Filename),25,8) as date) = StDt
where Filename like ''VODA_ADMUK_MI_ANOMALIES%''
Order by StDt desc



--GENERAL MI

;WITH CTEVVM AS
(
	SELECT @StartDate as StDt
	UNION ALL
	SELECT DATEADD(day,@interval,StDt)
	FROM CTEVVM
	WHERE DATEADD(day, @interval, StDt) <= @EndDate
)

INSERT INTO staging.dbo.FileTransfer
SELECT StDt AS [Date],
ImportFile.RowsImported AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''VodaGeneralMI'' AS ''TableType'',
ImportFile.ImportFileID, 
filename,
NULL
FROM CTEVVM cte
LEFT OUTER JOIN staging.dbo.ImportFile ImportFile ON
CAST(SUBSTRING((Filename),23,8) as date) = StDt
where Filename like ''VODA_ADMUK_MI_GENERAL%''
Order by StDt DESC


--SUMMARY MI

;WITH CTEVVS AS
(
	SELECT @StartDate as StDt
	UNION ALL
	SELECT DATEADD(day,@interval,StDt)
	FROM CTEVVS
	WHERE DATEADD(day, @interval, StDt) <= @EndDate
)

INSERT INTO staging.dbo.FileTransfer
SELECT StDt AS [Date],
ImportFile.RowsImported AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''VodaSummaryMI'' AS ''TableType'',
ImportFile.ImportFileID, 
filename,
NULL
FROM CTEVVS cte
LEFT OUTER JOIN staging.dbo.ImportFile ImportFile ON
CAST(SUBSTRING((Filename),23,8) as date) = StDt
where Filename like ''VODA_ADMUK_MI_SUMMARY%''
Order by StDt desc

--TRIP

;WITH CTEVVT AS
(
	SELECT @StartDate as StDt
	UNION ALL
	SELECT DATEADD(day,@interval,StDt)
	FROM CTEVVT
	WHERE DATEADD(day, @interval, StDt) <= @EndDate
)

INSERT INTO staging.dbo.FileTransfer
SELECT StDt AS [Date],
ImportFile.RowsImported AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''VodaTrip'' AS ''TableType'',
ImportFile.ImportFileID, 
filename,
NULL
FROM CTEVVT cte
LEFT OUTER JOIN staging.dbo.ImportFile ImportFile ON
CAST(SUBSTRING((Filename),22,8) as date) = StDt
where Filename like ''VODA_ADMUK_TRIP%''
Order by StDt desc



/*
Vodafone Journey
*/
;WITH CTEVJ as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTEVJ
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)

INSERT INTO staging.dbo.FileTransfer
SELECT CAST(StDt AS DATE) as [Date],
COUNT(TripID)  AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''VodaJourney'' AS ''TableType'',
'''', 
'''',
	NULL
FROM CTEVJ cte
JOIN Vodafone.dbo.trip EV ON 
cast(EventTimeStamp as date) = CAST(StDt AS DATE)
AND EventTypeID = 1
GROUP BY CAST(StDt AS DATE)
ORDER BY StDt DESC



/*
Vodafone Journey Event
*/

;WITH CTEVJE as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTEVJE
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)

INSERT INTO staging.dbo.FileTransfer
SELECT CAST(StDt AS DATE) as [Date],
COUNT(*)  AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''VodaJourneyEvent'' AS ''TableType'',
'''', 
'''',
	NULL
FROM CTEVJE cte
JOIN Vodafone.dbo.Trip EV ON 
cast(eventtimestamp as date) = CAST(StDt AS DATE)
GROUP BY CAST(StDt AS DATE)
ORDER BY StDt desc


/*****************************************************
New FileTransfer Code for OCTO & REDTAIL Files
******************************************************/


/*
ANOMALY
*/

;WITH CTEAnom as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTEAnom
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)

INSERT INTO staging.dbo.FileTransfer
SELECT StDt as [Date],
ImportFileTest.RowsImported  AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''ANOMALY'' AS ''TableType'',
ImportFileTest.ImportFileID, 
filename,
NULL
FROM CTEAnom cte
LEFT OUTER JOIN staging.dbo.ImportFile ImportFileTest ON
cast(substring((Filename ) ,20,10) as date) = StDt
where   Filename like ''OCTO_ADMUK_ANOMALY%''
ORDER BY StDt desc

/*
CONTE VOUCHER REQUEST
*/

;WITH CTECONTVoReq as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTECONTVoReq
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)

INSERT INTO staging.dbo.FileTransfer
SELECT StDt as [Date],
ImportFileTest.RowsImported  AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''Conte_VoucherRequest'' AS ''TableType'',
ImportFileTest.ImportFileID, 
filename,
NULL
FROM CTECONTVoReq cte
LEFT OUTER JOIN staging.dbo.ImportFile ImportFileTest ON
cast(substring((Filename ) ,28,10) as date) = StDt
where   Filename like ''OCTO_CONTE_VOUCHER_REQUEST%''
ORDER BY StDt desc


/*
CONTE VOUCHER RESPONSE
*/

;WITH CTECONTVoRes as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTECONTVoRes
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)

INSERT INTO staging.dbo.FileTransfer
SELECT StDt as [Date],
ImportFileTest.RowsImported  AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''Conte_VoucherResponse'' AS ''TableType'',
ImportFileTest.ImportFileID, 
filename,
NULL
FROM CTECONTVoRes cte
LEFT OUTER JOIN staging.dbo.ImportFile ImportFileTest ON
cast(substring((Filename ) ,29,10) as date) = StDt
where   Filename like ''OCTO_CONTE_VOUCHER_RESPONSE%''
ORDER BY StDt desc

/****************************************************************
REDTAIL
****************************************************************/

/*
RedTail Journey
*/
;WITH CTERTJ as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTERTJ
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)

INSERT INTO staging.dbo.FileTransfer
SELECT CAST(StDt AS DATE) as [Date],
COUNT(Journey_ID)  AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''RedTailJourney'' AS ''TableType'',
'''', 
'''',
NULL
FROM CTERTJ cte
JOIN Redtail.dbo.journeyevent JOU ON 
cast(eventtimestamp as date) = CAST(StDt AS DATE)
AND EventTypeID = 1
GROUP BY CAST(StDt AS DATE)
ORDER BY StDt desc


/*
RedTail Events
*/
;WITH CTERTEVe as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTERTEve
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)

INSERT INTO staging.dbo.FileTransfer
SELECT CAST(StDt AS DATE) as [Date],
COUNT(JourneyEventID)  AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''RedTailConnection'' AS ''TableType'',
'''', 
'''',
NULL
FROM CTERTEve cte
JOIN Redtail.dbo.Connection CON ON 
cast(eventtimestamp as date) = CAST(StDt AS DATE)
GROUP BY CAST(StDt AS DATE)
ORDER BY StDt desc


/*
RedTail Update
*/

;WITH CTERTUPD as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTERTUPD
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)

INSERT INTO staging.dbo.FileTransfer
SELECT StDt as [Date],
ImportFileTest.RowsImported  AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''RedTailUpdate'' AS ''TableType'',
ImportFileTest.ImportFileID, 
filename,
NULL
FROM CTERTUPD cte
LEFT OUTER JOIN staging.dbo.ImportFile ImportFileTest ON
cast(substring((Filename),19,10) as date) = StDt
where   Filename like ''ADMUK_RT_RTUPDATE%''
ORDER BY StDt desc

/*
RedTail CTDI Request
*/

;WITH CTERTCTDI as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTERTCTDI
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)

INSERT INTO staging.dbo.FileTransfer
SELECT StDt as [Date],
ImportFileTest.RowsImported  AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''RedTailCTDIReq'' AS ''TableType'',
ImportFileTest.ImportFileID, 
filename,
NULL
FROM CTERTCTDI cte
LEFT OUTER JOIN staging.dbo.ImportFile ImportFileTest ON
cast(substring((Filename),22,10) as date) = StDt
where   Filename like ''ADMUK_CTDI_RTREQUEST_20%''
ORDER BY StDt desc

/*
RedTail Fulfilled Orders
*/

;WITH CTERTFul as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTERTFul
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)

INSERT INTO staging.dbo.FileTransfer
SELECT StDt as [Date],
ImportFileTest.RowsImported  AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''RedTailFulOrd'' AS ''TableType'',
ImportFileTest.ImportFileID, 
filename,
NULL
FROM CTERTFul cte
LEFT OUTER JOIN staging.dbo.ImportFile ImportFileTest ON
cast(substring((Filename),21,10) as date) = StDt
where   Filename like ''RT_FULFILLED_ORDERS_20%''
ORDER BY StDt desc

/*
RedTail CTDI Request Process Errors
*/

;WITH CTERTProEr as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTERTProEr
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)

INSERT INTO staging.dbo.FileTransfer
SELECT StDt as [Date],
ImportFileTest.RowsImported  AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''RedTailCTDIErrors'' AS ''TableType'',
ImportFileTest.ImportFileID, 
filename,
NULL
FROM CTERTProEr cte
LEFT OUTER JOIN staging.dbo.ImportFile ImportFileTest ON
cast(substring((Filename),37,10) as date) = StDt
where   Filename like ''ADMUK_CTDI_RTREQUEST_PROCESS_ERRORS%''
ORDER BY StDt desc

/*
RedTail Device Returns
*/

;WITH CTERTDvRtn as
(
       SELECT @StartDate as StDt
       UNION ALL
       SELECT DATEADD(day, @interval, StDt)
       FROM   CTERTDvRtn
       WHERE  DATEADD(day, @interval, StDt) <= @EndDate    
)

INSERT INTO staging.dbo.FileTransfer
SELECT StDt as [Date],
ImportFileTest.RowsImported  AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''RedTailDeviceReturn'' AS ''TableType'',
ImportFileTest.ImportFileID, 
filename,
NULL
FROM CTERTDvRtn cte
LEFT OUTER JOIN staging.dbo.ImportFile ImportFileTest ON
cast(substring((Filename),19,10) as date) = StDt
where   Filename like ''RT_DEVICE_RETURNS%''
ORDER BY StDt desc

/*******************************************
  CMT
*********************************************/

-- Outgoing Cancellations

;WITH CTECXX AS
(
	SELECT @StartDate as StDt
	UNION ALL
	SELECT DATEADD(day,@interval,StDt)
	FROM CTECXX
	WHERE DATEADD(day, @interval, StDt) <= @EndDate
)

INSERT INTO staging.dbo.FileTransfer
SELECT StDt AS [Date],
ImportFile.RowsImported AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''EndavaCancellation'' AS ''TableType'',
ImportFile.ImportFileID, 
filename,
NULL
FROM CTECXX cte
LEFT OUTER JOIN staging.dbo.ImportFile ImportFile ON
CAST(SUBSTRING((Filename),27,8) as date) = StDt
where Filename like ''ADMUK_ENDAVA_APPV1_0_CXXS%''
Order by StDt desc

-- Incoming Cancellations

;WITH CTECXX AS
(
	SELECT @StartDate as StDt
	UNION ALL
	SELECT DATEADD(day,@interval,StDt)
	FROM CTECXX
	WHERE DATEADD(day, @interval, StDt) <= @EndDate
)

INSERT INTO staging.dbo.FileTransfer
SELECT StDt AS [Date],
ImportFile.RowsImported AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''EndavaCancellation'' AS ''TableType'',
ImportFile.ImportFileID, 
filename,
NULL
FROM CTECXX cte
LEFT OUTER JOIN staging.dbo.ImportFile ImportFile ON
CAST(SUBSTRING((Filename),27,8) as date) = StDt
where Filename like ''ENDAVA_ADMUK_APPV1_0_CXXS%''
Order by StDt desc

-- Failed Login History

;WITH CTELOGF AS
(
	SELECT @StartDate as StDt
	UNION ALL
	SELECT DATEADD(day,@interval,StDt)
	FROM CTELOGF
	WHERE DATEADD(day, @interval, StDt) <= @EndDate
)

INSERT INTO staging.dbo.FileTransfer
SELECT StDt AS [Date],
ImportFile.RowsImported AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''EndavaFailedLoginHistory'' AS ''TableType'',
ImportFile.ImportFileID, 
filename,
NULL
FROM CTELOGF cte
LEFT OUTER JOIN staging.dbo.ImportFile ImportFile ON
CAST(SUBSTRING((Filename),27,8) as date) = StDt
where Filename like ''ENDAVA_ADMUK_APPV1_0_LOGF%''
Order by StDt desc

-- Location permission change

;WITH CTELOCP AS
(
	SELECT @StartDate as StDt
	UNION ALL
	SELECT DATEADD(day,@interval,StDt)
	FROM CTELOCP
	WHERE DATEADD(day, @interval, StDt) <= @EndDate
)

INSERT INTO staging.dbo.FileTransfer
SELECT StDt AS [Date],
ImportFile.RowsImported AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''EndavaLocationPermissionChange'' AS ''TableType'',
ImportFile.ImportFileID, 
filename,
NULL
FROM CTELOCP cte
LEFT OUTER JOIN staging.dbo.ImportFile ImportFile ON
CAST(SUBSTRING((Filename),27,8) as date) = StDt
where Filename like ''ENDAVA_ADMUK_APPV1_0_LOCP%''
Order by StDt desc

-- Remote Switch off

;WITH CTERTSW AS
(
	SELECT @StartDate as StDt
	UNION ALL
	SELECT DATEADD(day,@interval,StDt)
	FROM CTERTSW
	WHERE DATEADD(day, @interval, StDt) <= @EndDate
)

INSERT INTO staging.dbo.FileTransfer
SELECT StDt AS [Date],
ImportFile.RowsImported AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''EndavaRemoteSwitchOff'' AS ''TableType'',
ImportFile.ImportFileID, 
filename,
NULL
FROM CTERTSW cte
LEFT OUTER JOIN staging.dbo.ImportFile ImportFile ON
CAST(SUBSTRING((Filename),27,8) as date) = StDt
where Filename like ''ENDAVA_ADMUK_APPV1_0_RTSW%''
Order by StDt desc

-- Remote Switch On

;WITH CTERTSO AS
(
	SELECT @StartDate as StDt
	UNION ALL
	SELECT DATEADD(day,@interval,StDt)
	FROM CTERTSO
	WHERE DATEADD(day, @interval, StDt) <= @EndDate
)

INSERT INTO staging.dbo.FileTransfer
SELECT StDt AS [Date],
ImportFile.RowsImported AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''EndavaRemoteSwitchOn'' AS ''TableType'',
ImportFile.ImportFileID, 
filename,
NULL
FROM CTERTSO cte
LEFT OUTER JOIN staging.dbo.ImportFile ImportFile ON
CAST(SUBSTRING((Filename),27,8) as date) = StDt
where Filename like ''ENDAVA_ADMUK_APPV1_0_RTSO%''
Order by StDt desc

-- Successful Logins

;WITH CTELOGS AS
(
	SELECT @StartDate as StDt
	UNION ALL
	SELECT DATEADD(day,@interval,StDt)
	FROM CTELOGS
	WHERE DATEADD(day, @interval, StDt) <= @EndDate
)
INSERT INTO staging.dbo.FileTransfer
SELECT StDt AS [Date],
ImportFile.RowsImported AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''EndavaSuccessfulLoginHistory'' AS ''TableType'',
ImportFile.ImportFileID, 
filename,
NULL
FROM CTELOGS cte
LEFT OUTER JOIN staging.dbo.ImportFile ImportFile ON
CAST(SUBSTRING((Filename),27,8) as date) = StDt
where Filename like ''ENDAVA_ADMUK_APPV1_0_LOGS%''
Order by StDt desc

-- MI

;WITH CTEMI AS
(	
	SELECT @StartDate as StDt
	UNION ALL
	SELECT DATEADD(day,@interval,StDt)
	FROM CTEMI
	WHERE DATEADD(day, @interval, StDt) <= @EndDate
)

INSERT INTO staging.dbo.FileTransfer
SELECT StDt AS [Date],
ImportFile.RowsImported AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''CMTMI'' AS ''TableType'',
ImportFile.ImportFileID, 
filename,
NULL
FROM CTEMI cte
LEFT OUTER JOIN staging.dbo.ImportFile ImportFile ON
CAST(SUBSTRING((Filename),24,8) as date) = StDt
where Filename like ''ADMUK_ADMUK_APPV1_0_MI%''
Order by StDt desc

-- Trip
/*
;WITH CTETrip AS
(	
	SELECT @StartDate as StDt
	UNION ALL
	SELECT DATEADD(day,@interval,StDt)
	FROM CTETrip
	WHERE DATEADD(day, @interval, StDt) <= @EndDate
)

INSERT INTO staging.dbo.FileTransfer
SELECT StDt AS [Date],
ImportFile.RowsImported AS ''Rows'',
CAST(GETDATE()AS DATE) AS ''LastUpdated'',
''CMTTrip'' AS ''TableType'',
ImportFile.ImportFileID, 
filename,
NULL
FROM CTETrip cte
LEFT OUTER JOIN staging.dbo.ImportFile ImportFile ON
CAST(SUBSTRING((Filename),28,8) as date) = StDt
where Filename like ''CMT_ADMUK_APPV1_0_DRIVEDTL%''
Order by StDt desc
*/', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Update TRIPP and TRIPP_BALUMBA dates]    Script Date: 29/10/2018 11:57:26 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Update TRIPP and TRIPP_BALUMBA dates', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec [dbo].[FileTransferUpdate]', 
		@database_name=N'staging', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily 6:30', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=127, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20180621, 
		@active_end_date=99991231, 
		@active_start_time=63000, 
		@active_end_time=235959, 
		@schedule_uid=N'b83cf40a-b4d3-48c6-a023-8ee6e8907d6f'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


