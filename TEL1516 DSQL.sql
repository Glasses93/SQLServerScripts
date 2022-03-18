
			SET NOCOUNT ON;
			SET XACT_ABORT ON;

			BEGIN TRY
				BEGIN TRANSACTION;

					CREATE CLUSTERED INDEX IX_TEL1516TraversedSlices_RiskCXXDate
						ON sandbox.dbo.TEL1516_TraversedSlices (RiskCXXDate ASC)
					;

					IF OBJECT_ID('sandbox.dbo.TEL1516_TripsPerDay', 'U') IS NULL
					BEGIN

						CREATE TABLE sandbox.dbo.TEL1516_TripsPerDay (
							 Account_ID	varchar(30)	NULL
							,Day		date		NULL
						)
						;

						;WITH TripSummary AS (
							SELECT
								 Account_ID
								,Trip_Start_Local
							FROM CMTSERV.dbo.CMTTripSummary
							WHERE CONVERT(date, Trip_Start_Local) <= CONVERT(date, FileDate, 112)

							UNION ALL

							SELECT
								 Account_ID
								,Trip_Start_Local
							FROM CMTSERV.dbo.CMTTripSummary_EL
							WHERE CONVERT(date, Trip_Start_Local) <= CONVERT(date, FileDate, 112)
						)
						INSERT sandbox.dbo.TEL1516_TripsPerDay WITH (TABLOCK) (Account_ID, Day)
						SELECT DISTINCT
							 Account_ID
							,CONVERT(date, Trip_Start_Local)
						FROM TripSummary
						;
							
						CREATE CLUSTERED INDEX IX_TEL1516TripsPerDay_Day
							ON sandbox.dbo.TEL1516_TripsPerDay (Day ASC)
						;

					END
					ELSE
					BEGIN

						;WITH TripSummary AS (
							SELECT
								 Account_ID
								,Trip_Start_Local
							FROM CMTSERV.dbo.CMTTripSummary
							WHERE ID >
								( 
									SELECT ID
									FROM sandbox.dbo.TEL1516_MaxID 
								)
								AND CONVERT(date, Trip_Start_Local) <= CONVERT(date, FileDate, 112)

							UNION ALL

							SELECT
								 Account_ID
								,Trip_Start_Local
							FROM CMTSERV.dbo.CMTTripSummary_EL
							WHERE CONVERT(date, Trip_Start_Local) <= CONVERT(date, FileDate, 112)
						)
						INSERT sandbox.dbo.TEL1516_TripsPerDay WITH (TABLOCK) (Account_ID, Day)
						SELECT DISTINCT
							 Account_ID
							,CONVERT(date, Trip_Start_Local)
						FROM TripSummary ts
						WHERE NOT EXISTS (
							SELECT 1
							FROM sandbox.dbo.TEL1516_TripsPerDay tpd
							WHERE ts.Account_ID = tpd.Account_ID
								AND CONVERT(date, ts.Trip_Start_Local) = tpd.Day
						)
						;

						DECLARE @SQL   nvarchar(max) = N'';
						DECLARE @Value nvarchar(max);

						SELECT @Value = MAX(Id)
						FROM CMTSERV.dbo.CMTTripSummary
						;

						DROP TABLE IF EXISTS sandbox.dbo.TEL1516_MaxID;

						SELECT @SQL = N'CREATE TABLE sandbox.dbo.TEL1516_MaxID (ID int PRIMARY KEY CHECK ( ID = ' + @Value + N' ));';
			
						PRINT @SQL;
						EXEC sys.sp_executesql @SQL;

						INSERT sandbox.dbo.TEL1516_MaxID (ID)
						SELECT MAX(Id)
						FROM CMTSERV.dbo.CMTTripSummary
						;

					END
					;

				COMMIT TRANSACTION;

			END TRY
			BEGIN CATCH
				
				IF @@TRANCOUNT > 0
				BEGIN
					ROLLBACK TRANSACTION;
				END
				;

				;THROW;

			END CATCH
			;


--PRINT @@TRANCOUNT;

--sp_help TEL1516_MaxID