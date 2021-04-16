/*    ==Scripting Parameters==

    Source Server Version : SQL Server 2016 (13.0.5850)
    Source Database Engine Edition : Microsoft SQL Server Standard Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2016
    Target Database Engine Edition : Microsoft SQL Server Standard Edition
    Target Database Engine Type : Standalone SQL Server
*/

USE [sandbox]
GO

/****** Object:  UserDefinedFunction [dbo].[SJ_SplitStringsLite]    Script Date: 04/01/2021 20:08:20 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER   FUNCTION [dbo].[SJ_SplitStringsLite] (
	 @List		varchar(200)
	,@Delimiter	varchar(10)
)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN (
	SELECT
		 n
		,s = SUBSTRING(@List, n, CHARINDEX(@Delimiter, @List + @Delimiter, n) - n)
		--,rn = ROW_NUMBER() OVER (ORDER BY n ASC)
	FROM dbo.Numbers
	WHERE n <= CONVERT(smallint, LEN(@List))
		AND SUBSTRING(@Delimiter + @List, n, LEN(@Delimiter)) = @Delimiter
)
;
GO


