USE sandbox;
GO

CREATE OR ALTER PROCEDURE dbo.SJ_Print
AS
BEGIN
	PRINT 'Hello there.';
END
;
GO

EXEC sandbox.dbo.SJ_Print;
GO

CREATE OR ALTER PROCEDURE dbo.SJ_Output100Rows
AS
BEGIN
	SELECT TOP (100) *
	FROM RedTail.dbo.JourneyEvent
	;
END
;
GO

EXEC sandbox.dbo.SJ_Output100Rows;
GO

CREATE OR ALTER PROCEDURE dbo.SJ_WriteData
AS
BEGIN
	SET NOCOUNT ON;

	IF OBJECT_ID('sandbox.dbo.SJ_SP', 'U') IS NULL
	BEGIN
		CREATE TABLE sandbox.dbo.SJ_SP ([Data] integer)
	END
	;

	INSERT sandbox.dbo.SJ_SP ([Data])
		VALUES (1)
	;

	--SELECT *
	--FROM sandbox.dbo.SJ_SP
	--;
END
;
GO

EXEC sandbox.dbo.SJ_WriteData;
GO

CREATE OR ALTER PROCEDURE dbo.SJ_OutputVFRiskData @ExternalContractNumber nvarchar(20)
AS
BEGIN
	SELECT *
	FROM Vodafone.dbo.Trip
	WHERE ExternalContractNumber = @ExternalContractNumber
	ORDER BY EventTimeStamp ASC
	OPTION ( RECOMPILE )
END
;
GO

EXEC sandbox.dbo.SJ_OutputVFRiskData @ExternalContractNumber = N'P61835327-1';
GO


CREATE OR ALTER PROCEDURE dbo.SJ_OutputRTRiskData
	 @PolicyNumber varchar(20)
	,@MinDate	   datetime	= '2010-01-01T00:00:00.000'
	,@MaxDate	   datetime	= '2030-01-01T00:00:00.000'
AS
BEGIN
	SELECT
		 [Source] = 'PolCVPTrav'
		,PolicyNumber
		,EffectFromDate
		,EffectToDate
		,VehType
		,VehMake
		,VehModel
		,VehCC
		,VehMiles
		,VehReg
	FROM sandbox.dbo.PolCVPTrav
	WHERE TraversedFlag = '1'
		AND EffectFromDate <= CONVERT(date, CURRENT_TIMESTAMP)
		AND PolicyNumber = @PolicyNumber
	ORDER BY EffectFromDate ASC
	OPTION ( RECOMPILE )
	;

	SELECT
		 [Source]     = 'RedTail JourneyEvent'
		,PolicyNumber = @PolicyNumber
		,MinDate      = @MinDate
		,MaxDate      = @MaxDate
		,je.*
	FROM RedTail.dbo.JourneyEvent je
	INNER JOIN RedTail.dbo.Association a
		ON    je.IMEI = CONVERT(bigint, a.IMEI)
		AND   je.EventTimeStamp >= a.StartDate
		AND ( je.EventTimeStamp <  a.EndDate OR a.EndDate IS NULL )
		AND   je.EventTimeStamp >= @MinDate
		AND   je.EventTimeStamp <  @MaxDate
		AND    a.PolicyNumber    = @PolicyNumber
	ORDER BY je.EventTimeStamp ASC
	OPTION ( RECOMPILE )
	;
END
;
GO

EXEC sandbox.dbo.SJ_OutputRTRiskData
	 @PolicyNumber = 'P60607202-1'
	,@MinDate      = '2016-11-01T13:00:00.000'
	,@MaxDate      = '2016-11-01T19:00:00.000'
;
GO

CREATE TYPE dbo.SJ_VFList AS TABLE (ExternalContractNumber nvarchar(20) PRIMARY KEY CLUSTERED)
GO

CREATE OR ALTER PROCEDURE dbo.SJ_VFLastData @TVP dbo.SJ_VFList READONLY
AS
BEGIN
	SET NOCOUNT ON;

	SELECT
		 [Policy Number 👽👽👽]		= ExternalContractNumber
		,[Last Event Time Stamp]	= MAX(EventTimeStamp)
	FROM Vodafone.dbo.Trip t
	WHERE EXISTS (
		SELECT 1
		FROM @TVP ecn
		WHERE t.ExternalContractNumber = ecn.ExternalContractNumber
	)
	GROUP BY ExternalContractNumber
	ORDER BY ExternalContractNumber ASC
	OPTION ( RECOMPILE )
	;
END
;
GO