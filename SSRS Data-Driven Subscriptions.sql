
DECLARE @Today    date         = CURRENT_TIMESTAMP;
DECLARE @Time     time(0)      = CURRENT_TIMESTAMP;
DECLARE @CRLF     nchar(2)     = nchar(13) + nchar(10);
DECLARE @Greeting nvarchar(10) =
    CASE
        WHEN @Time <  '12:00:00' THEN N'Morning,'
        WHEN @Time >= '12:00:00' AND @Time < '18:00:00' THEN N'Afternoon,'
        WHEN @Time >= '18:00:00' THEN N'Evening,'
        ELSE N''
    END
;

;WITH d(d) AS (
    SELECT MAX([Date])
    FROM dim.DimDate
    WHERE BusinessWorkingDay = 1
        AND [Date] <= EOMONTH(@Today)
)
SELECT
     [To]             = N'stephen.jarvis@principality.co.uk; bethan.thomas1@principality.co.uk'
    ,[Cc]             = N'stephen.jarvis@principality.co.uk'
    ,[Bcc]            = N'stephen.jarvis@principality.co.uk'
    ,[Reply-To]       = N'stephen.jarvis@principality.co.uk'
    ,[Include Report] = CONVERT(bit, 1)
    ,[Render Format]  = 'EXCELOPENXML'
    ,[Priority]       = 'Low'
    ,[Subject]        = N'Report Scanner'
    ,[Comment]        = @Greeting +  REPLICATE(@CRLF, 2) + N'This is a data-driven subscription test.' + REPLICATE(@CRLF, 2) + N'Please ignore attachment.'
    ,[Include Link]   = CONVERT(bit, 0)
WHERE EXISTS (
    SELECT 1
    FROM d
    --WHERE d.d = @Today
)
;
