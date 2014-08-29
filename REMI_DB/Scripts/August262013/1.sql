/*
Run this script on:

        sql51ykf\ha6.remi    -  This database will be modified

to synchronize it with:

        SQLQA10YKF\HAQA1.RemiQA

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 8/20/2013 11:35:02 AM

*/
SET NUMERIC_ROUNDABORT OFF
GO
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#tmpErrors')) DROP TABLE #tmpErrors
GO
CREATE TABLE #tmpErrors (Error int)
GO
SET XACT_ABORT ON
GO
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO
BEGIN TRANSACTION
GO
PRINT N'Altering [dbo].[Tests]'
GO
ALTER TABLE [dbo].[Tests] ADD
[IsArchived] [bit] NULL CONSTRAINT [DF__Tests__IsArchive__0915401C] DEFAULT ((0))
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
alter table TrackingLocations add Status INT NULL
GO
ALTER PROCEDURE [dbo].[remispTrackingLocationsInsertUpdateSingleItem]
	@ID int OUTPUT,
	@trackingLocationName nvarchar(400),
	@TrackingLocationTypeID int, 
	@GeoLocationID INT, 
	@ConcurrencyID rowversion OUTPUT,
	@Status int,
	@LastUser nvarchar(255),
	@Comment nvarchar(1000) = null,
	@HostName nvarchar(255) = null,
	@Decommissioned BIT = 0,
	@IsMultiDeviceZone BIT = 0,
	@PluginName NVARCHAR(250),
	@LocationStatus INT
AS
	DECLARE @ReturnValue int
	DECLARE @AlreadyExists as integer 

	IF (@ID IS NULL) -- New Item
	BEGIN
		IF (@ID IS NULL) -- New Item
		BEGIN
			set @AlreadyExists = (select ID from TrackingLocations 
			where TrackingLocationName = @trackingLocationName and TestCenterLocationID = @GeoLocationID)

			if (@AlreadyExists is not null) 
				return -1
			end

			PRINT 'INSERTING'

			INSERT INTO TrackingLocations (TrackingLocationName, TestCenterLocationID, TrackingLocationTypeID, LastUser, Comment, Decommissioned, IsMultiDeviceZone, PluginName, Status)
			VALUES (@TrackingLocationname, @GeoLocationID, @TrackingLocationtypeID, @LastUser, @Comment, @Decommissioned, @IsMultiDeviceZone, @PluginName, @LocationStatus)
			
			SELECT @ReturnValue = SCOPE_IDENTITY()

			INSERT INTO TrackingLocationsHosts (TrackingLocationID, HostName, LastUser, Status) VALUES (@ReturnValue, @HostName, @LastUser, @Status)
		END
		ELSE -- Exisiting Item
		BEGIN
			PRINT 'UDPATING TrackingLocations'
		
			UPDATE TrackingLocations 
			SET TrackingLocationName=@TrackingLocationName, 
				TestCenterLocationID=@GeoLocationID, 
				TrackingLocationTypeID=@TrackingLocationtypeID,
				LastUser = @LastUser,
				Comment = @Comment,
				Decommissioned = @Decommissioned,
				IsMultiDeviceZone = @IsMultiDeviceZone,
				PluginName = @PluginName,
				Status = @LocationStatus
			WHERE ID = @ID AND ConcurrencyID = @ConcurrencyID
		
			SELECT @ReturnValue = @ID
		END

		SET @ConcurrencyID = (SELECT ConcurrencyID FROM TrackingLocations WHERE ID = @ReturnValue)
		SET @ID = @ReturnValue
	
		IF (@@ERROR != 0)
		BEGIN
			RETURN -1
		END
		ELSE
		BEGIN
			RETURN 0
		END
GO
GRANT EXECUTE ON remispTrackingLocationsInsertUpdateSingleItem TO Remi
GO
ALTER PROCEDURE [dbo].[remispTrackingLocationsSearchFor]
/*	'===============================================================
	'   NAME:                	remispTrackingLocationsSearchFor
	'   DATE CREATED:       	21 Oct 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves paged data from table: TrackingLocations OR the number of records in the table
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/
@RecordCount int = NULL OUTPUT,
@ID int = null,
@TrackingLocationName nvarchar(400)= null, 
@GeoLocationID INT= null, 
@Status int = null,
@TrackingLocationTypeID int= null,
@TrackingLocationTypeName nvarchar(400)=null,
@TrackingLocationFunction int = null,
@HostName nvarchar(255) = null,
@OnlyActive INT = 0,
@RemoveHosts INT = 0
AS
DECLARE @TrueBit BIT
DECLARE @FalseBit BIT
SET @TrueBit = CONVERT(BIT, 1)
SET @FalseBit = CONVERT(BIT, 0)

IF (@RecordCount IS NOT NULL)
BEGIN
	SET @RecordCount = (SELECT distinct COUNT(*) 
	FROM TrackingLocations as tl 
		INNER JOIN TrackingLocationTypes as tlt ON tl.TrackingLocationTypeID = tlt.ID
		LEFT OUTER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
	WHERE (tl.ID = @ID or @ID is null) 
	and (tlh.status = @Status or @Status is null)
	and (tl.TrackingLocationName = @TrackingLocationName or @TrackingLocationName is null)
	and (TestCenterLocationID = @GeoLocationID or @GeoLocationID is null)
	and (tlh.HostName = @HostName or tlh.HostName='all' or @HostName is null)
	and (tl.TrackingLocationTypeID = @TrackingLocationTypeID or @TrackingLocationTypeID is null)
	and ((tl.TrackingLocationTypeID= tlt.id and tlt.TrackingLocationTypeName = @TrackingLocationTypeName) or @TrackingLocationTypeName is null)
	 and ((tl.TrackingLocationTypeID= tlt.id and tlt.TrackingLocationFunction = @TrackingLocationFunction )or @TrackingLocationFunction is null)
	 AND (
				(@OnlyActive = 1 AND ISNULL(tl.Decommissioned, 0) = 0)
				OR
				(@OnlyActive = 0)
			)
	)
	RETURN
END

SELECT DISTINCT tl.ID, tl.TrackingLocationName, tl.TestCenterLocationID, 
	CASE WHEN @RemoveHosts = 1 THEN 1 ELSE CASE WHEN tlh.Status IS NULL THEN 3 ELSE tlh.Status END END AS Status, 
	tl.LastUser, 
	CASE WHEN @RemoveHosts = 1 THEN '' ELSE tlh.HostName END AS HostName,
	tl.ConcurrencyID, tl.comment,l3.[Values] AS GeoLocationName, 
	CASE WHEN @RemoveHosts = 1 THEN 0 ELSE ISNULL(tlh.ID,0) END AS TrackingLocationHostID,
	(
		SELECT COUNT(*) as CurrentCount 
		FROM TestUnits AS tu
			INNER JOIN DeviceTrackingLog AS dtl ON dtl.TestUnitID = tu.ID
		WHERE dtl.TrackingLocationID = tl.ID and (dtl.OutUser IS NULL)
	) AS CurrentCount,
	tlt.wilocation as TLTWILocation, tlt.UnitCapacity as TLTUnitCapacity, tlt.Comment as TLTComment, tlt.ConcurrencyID as TLTConcurrencyID, tlt.LastUser as TLTLastUser,
	tlt.ID as TLTID, tlt.TrackingLocationTypeName as TLTName, tlt.TrackingLocationFunction as TLTFunction,
	(
		SELECT TOP(1) tu.CurrentTestName as CurrentTestName
		FROM TestUnits AS tu
			INNER JOIN DeviceTrackingLog AS dtl ON dtl.TestUnitID = tu.ID
		WHERE tu.CurrentTestName is not null and dtl.TrackingLocationID = tl.ID and (dtl.OutUser IS NULL)
	) AS CurrentTestName,
	(CASE WHEN EXISTS (SELECT TOP 1 1 FROM DeviceTrackingLog dl WHERE dl.TrackingLocationID=tl.ID) THEN @FalseBit ELSE @TrueBit END) As CanDelete,
	ISNULL(tl.Decommissioned, 0) AS Decommissioned, ISNULL(tl.IsMultiDeviceZone, 0) AS IsMultiDeviceZone, PluginName As PluginName, tl.Status AS LocationStatus
	FROM TrackingLocations as tl
		INNER JOIN TrackingLocationTypes as tlt ON tl.TrackingLocationTypeID = tlt.ID
		LEFT OUTER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
		LEFT OUTER JOIN Lookups l3 ON l3.Type='TestCenter' AND l3.lookupID=tl.TestCenterLocationID
	WHERE (tl.ID = @ID or @ID is null) and (tlh.status = @Status or @Status is null)
		and (tl.TrackingLocationName = @TrackingLocationName or @TrackingLocationName is null)
		and (TestCenterLocationID = @GeoLocationID or @GeoLocationID is null)
		and 
		(
			tlh.HostName = @HostName 
			or 
			tlh.HostName='all'
			or
			@HostName is null 
			or 
			(
				@HostName is not null 
				and exists 
					(
						SELECT tlt1.TrackingLocationTypeName 
						FROM TrackingLocations as tl1
							INNER JOIN trackinglocationtypes as tlt1 ON tlt1.ID = tl1.TrackingLocationTypeID
							INNER JOIN TrackingLocationsHosts tlh1 ON tl1.ID = tlh1.TrackingLocationID
						WHERE tlh1.HostName = @HostName and tlt1.TrackingLocationTypeName = 'Storage'
					)
			)
		)
		and (tl.TrackingLocationTypeID= tlt.id and tlt.id = @TrackingLocationTypeID or @TrackingLocationTypeID is null)
		and (tl.TrackingLocationTypeID= tlt.id and tlt.TrackingLocationTypeName = @TrackingLocationTypeName or @TrackingLocationTypeName is null)
		and (tl.TrackingLocationTypeID= tlt.id and tlt.TrackingLocationFunction = @TrackingLocationFunction or @TrackingLocationFunction is null)
		AND (
				(@OnlyActive = 1 AND ISNULL(tl.Decommissioned, 0) = 0)
				OR
				(@OnlyActive = 0)
			)
	ORDER BY ISNULL(tl.Decommissioned, 0), tl.TrackingLocationName
GO
GRANT EXECUTE ON remispTrackingLocationsSearchFor TO Remi
GO
ALTER PROCEDURE Relab.remispResultsFileProcessing
AS
BEGIN
	BEGIN TRANSACTION

	BEGIN TRY
		DECLARE @ID INT
		DECLARE @idoc INT
		DECLARE @RowID INT
		DECLARE @xml XML
		DECLARE @xmlPart XML
		DECLARE @FinalResult BIT
		DECLARE @StartDate DATETIME
		DECLARE @EndDate NVARCHAR(MAX)
		DECLARE @Duration NVARCHAR(MAX)
		DECLARE @StationName NVARCHAR(400)
		DECLARE @MaxID INT
		DECLARE @VerNum INT
		DECLARE @ResultID INT
		DECLARE @Val INT

		IF ((SELECT COUNT(*) FROM Relab.ResultsXML x WHERE ISNULL(IsProcessed,0)=0)=0)
		BEGIN
			GOTO HANDLE_SUCCESS
			RETURN
		END
		
		SET NOCOUNT ON
		
		SELECT @Val = COUNT(*) FROM Relab.ResultsXML x WHERE ISNULL(isProcessed,0)=0
		
		SELECT TOP 1 @ID=x.ID, @xml = x.ResultXML, @VerNum = x.VerNum, @ResultID = x.ResultID
		FROM Relab.ResultsXML x
		WHERE ISNULL(IsProcessed,0)=0
		ORDER BY ResultID, VerNum ASC
		
		PRINT '# Files To Process: ' + CONVERT(VARCHAR, @Val)
		PRINT 'XMLID: ' + CONVERT(VARCHAR, @ID)
		PRINT 'ResultID: ' + CONVERT(VARCHAR, @ResultID)

		SELECT @xmlPart = T.c.query('.') 
		FROM @xml.nodes('/TestResults/Header') T(c)
				
		select @EndDate = T.c.query('DateCompleted').value('.', 'nvarchar(max)'),
			@Duration = T.c.query('Duration').value('.', 'nvarchar(max)'),
			@StationName = T.c.query('StationName').value('.', 'nvarchar(400)')
		FROM @xmlPart.nodes('/Header') T(c)

		SELECT @EndDate= STUFF(@EndDate, CHARINDEX('-',@EndDate,(charindex('-',@EndDate, (charindex('-',@EndDate)+1))+1)), 1, ' ')
		SELECT @EndDate= STUFF(@EndDate, CHARINDEX('-',@EndDate,(charindex('-',@EndDate, (charindex('-',@EndDate)+1))+1)), 1, ':')
		SELECT @EndDate= STUFF(@EndDate, CHARINDEX('-',@EndDate,(charindex('-',@EndDate, (charindex('-',@EndDate)+1))+1)), 1, ':')
				
		If (CHARINDEX('.', @Duration) > 0)
			SET @Duration = SUBSTRING(@Duration, 1, CHARINDEX('.', @Duration)-1)
		
		SET @StartDate=dateadd(s,-datediff(s,0,convert(DATETIME,@Duration)), CONVERT(DATETIME, @EndDate))
	
		PRINT 'INSERT Lookups UnitType'
		SELECT DISTINCT (1) AS LookupID, T.c.query('Units').value('.', 'nvarchar(max)') AS UnitType, 1 AS Active
		INTO #LookupsUnitType
		FROM @xml.nodes('/TestResults/Measurements/Measurement') T(c)
		WHERE LTRIM(RTRIM(CONVERT(VARCHAR(MAX), T.c.query('Units').value('.', 'nvarchar(max)')))) NOT IN ( (SELECT [Values] FROM Lookups WHERE Type='UnitType')) 
			AND CONVERT(VARCHAR(MAX), T.c.query('Units').value('.', 'nvarchar(max)')) NOT IN ('N/A')
		
		SELECT @MaxID = MAX(LookupID)+1 FROM Lookups
		
		INSERT INTO Lookups (LookupID, Type,[Values], IsActive)
		SELECT (ROW_NUMBER() OVER (ORDER BY LookupID)) + @MaxID AS LookupID, 'UnitType' AS Type, UnitType AS [Values], Active
		FROM #LookupsUnitType
		
		DROP TABLE #LookupsUnitType
		
		PRINT 'INSERT Lookups MeasurementType'
		SELECT DISTINCT (1) AS LookupID, T.c.query('MeasurementName').value('.', 'nvarchar(max)') AS MeasurementType, 1 AS Active
		INTO #LookupsMeasurementType
		FROM @xml.nodes('/TestResults/Measurements/Measurement') T(c)
		WHERE LTRIM(RTRIM(CONVERT(VARCHAR(MAX), T.c.query('MeasurementName').value('.', 'nvarchar(max)')))) NOT IN ( (SELECT [Values] FROM Lookups WHERE Type='MeasurementType')) 
			AND CONVERT(VARCHAR(MAX), T.c.query('MeasurementName').value('.', 'nvarchar(max)')) NOT IN ('N/A')
		
		SELECT @MaxID = MAX(LookupID)+1 FROM Lookups
		
		INSERT INTO Lookups (LookupID, Type, [Values], IsActive)
		SELECT (ROW_NUMBER() OVER (ORDER BY LookupID)) + @MaxID AS LookupID, 'MeasurementType' AS Type, MeasurementType AS [Values], Active
		FROM #LookupsMeasurementType
		
		DROP TABLE #LookupsMeasurementType
		
		PRINT 'Load Measurements into temp table'
		SELECT  ROW_NUMBER() OVER (ORDER BY T.c) AS RowID, T.c.query('.') AS value 
		INTO #temp2
		FROM @xml.nodes('/TestResults/Measurements/Measurement') T(c)
		WHERE LOWER(T.c.query('MeasurementName').value('.', 'nvarchar(max)')) <> LOWER('cableloss')

		SELECT @RowID = MIN(RowID) FROM #temp2
		
		WHILE (@RowID IS NOT NULL)
		BEGIN
			DECLARE @FileName NVARCHAR(200)
			SET @FileName = NULL

			SELECT @xmlPart  = value FROM #temp2 WHERE RowID=@RowID	

			select l2.LookupID AS MeasurementTypeID,
				T.c.query('LowerLimit').value('.', 'nvarchar(max)') AS LowerLimit,
				T.c.query('UpperLimit').value('.', 'nvarchar(max)') AS UpperLimit,
				T.c.query('MeasuredValue').value('.', 'nvarchar(max)') AS MeasurementValue,
				(CASE WHEN T.c.query('PassFail').value('.', 'nvarchar(max)') = 'Pass' THEN 1 ELSE 0 END) AS PassFail,
				l.LookupID AS UnitTypeID,
				T.c.query('FileName').value('.', 'nvarchar(max)') AS [FileName], 
				[Relab].[ResultsXMLParametersComma] ((select T.c.query('.') from @xmlPart.nodes('/Measurement/Parameters') T(c))) AS Parameters,
				T.c.query('Comments').value('.', 'nvarchar(400)') AS [Comment]
			INTO #measurement
			FROM @xmlPart.nodes('/Measurement') T(c)
				LEFT OUTER JOIN Lookups l ON l.Type='UnitType' AND l.[Values]=LTRIM(RTRIM(CONVERT(VARCHAR(MAX), T.c.query('Units').value('.', 'nvarchar(max)'))))
				LEFT OUTER JOIN Lookups l2 ON l2.Type='MeasurementType' AND l2.[Values]=LTRIM(RTRIM(CONVERT(VARCHAR(MAX), T.c.query('MeasurementName').value('.', 'nvarchar(max)'))))

			IF (@VerNum = 1)
			BEGIN
				PRINT 'INSERT Version 1 Measurements'
				INSERT INTO Relab.ResultsMeasurements (ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, MeasurementUnitTypeID, PassFail, ReTestNum, Archived, XMLID, Comment)
				SELECT @ResultID As ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, UnitTypeID, CONVERT(BIT, PassFail), 1, 0, @ID, Comment
				FROM #measurement

				DECLARE @ResultMeasurementID INT
				SET @ResultMeasurementID = @@IDENTITY
				
				PRINT 'INSERT Version 1 Parameters'
				INSERT INTO Relab.ResultsParameters (ResultMeasurementID, ParameterName, Value)
				SELECT @ResultMeasurementID AS ResultMeasurementID, T.c.value('@ParameterName','nvarchar(max)') AS ParameterName, T.c.query('.').value('.', 'nvarchar(max)') AS Value
				FROM @xmlPart.nodes('/Measurement/Parameters/Parameter') T(c)

				SELECT @FileName = LTRIM(RTRIM([FileName]))
				FROM #measurement
				
				IF (@FileName IS NOT NULL AND @FileName <> '')
					BEGIN
						UPDATE Relab.ResultsMeasurementsFiles 
						SET ResultMeasurementID=@ResultMeasurementID 
						WHERE LOWER(LTRIM(RTRIM(FileName)))=LOWER(@FileName) AND ResultMeasurementID IS NULL
					END
			END
			ELSE
			BEGIN
				DECLARE @MeasurementTypeID INT
				DECLARE @Parameters NVARCHAR(MAX)
				DECLARE @MeasuredValue NVARCHAR(500)
				DECLARE @OldMeasuredValue NVARCHAR(500)
				DECLARE @ReTestNum INT
				SET @ReTestNum = 1
				SET @OldMeasuredValue = NULL
				SET @MeasuredValue = NULL
				SET @Parameters = NULL
				SET @MeasurementTypeID = NULL
				SELECT @MeasurementTypeID=MeasurementTypeID, @Parameters=LTRIM(RTRIM(ISNULL(Parameters, ''))), @MeasuredValue=MeasurementValue FROM #measurement
				
				SELECT @OldMeasuredValue = MeasurementValue , @ReTestNum = reTestNum+1
				FROM Relab.ResultsMeasurements 
				WHERE ResultID=@ResultID AND MeasurementTypeID=@MeasurementTypeID AND LTRIM(RTRIM(ISNULL(Relab.ResultsParametersComma(ID),''))) = LTRIM(RTRIM(ISNULL(@Parameters,''))) AND Archived=0

				IF ((@OldMeasuredValue IS NOT NULL AND @OldMeasuredValue <> @MeasuredValue) OR (@OldMeasuredValue IS NOT NULL AND @OldMeasuredValue = @MeasuredValue))
				--That result has that measurement type and exact parameters but measured value is different
				--OR
				--That result has that measurement type and exact parameters and measured value is the same
				BEGIN
					PRINT 'INSERT ReTest Measurements'
					INSERT INTO Relab.ResultsMeasurements (ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, MeasurementUnitTypeID, PassFail, ReTestNum, Archived, XMLID, Comment)
					SELECT @ResultID As ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, UnitTypeID, CONVERT(BIT, PassFail), @ReTestNum, 0, @ID, Comment
					FROM #measurement
					
					DECLARE @ResultMeasurementID2 INT
					SET @ResultMeasurementID2 = @@IDENTITY
					
					SELECT @FileName = LTRIM(RTRIM([FileName]))
					FROM #measurement
				
					IF (@FileName IS NOT NULL AND @FileName <> '')
						BEGIN
							UPDATE Relab.ResultsMeasurementsFiles 
							SET ResultMeasurementID=@ResultMeasurementID2 
							WHERE LOWER(LTRIM(RTRIM(FileName)))=LOWER(@FileName) AND ResultMeasurementID IS NULL
						END

					IF (@Parameters <> '')
					BEGIN
						PRINT 'INSERT ReTest Parameters'
						INSERT INTO Relab.ResultsParameters (ResultMeasurementID, ParameterName, Value)
						SELECT @ResultMeasurementID2 AS ResultMeasurementID, T.c.value('@ParameterName','nvarchar(max)') AS ParameterName, T.c.query('.').value('.', 'nvarchar(max)') AS Value
						FROM @xmlPart.nodes('/Measurement/Parameters/Parameter') T(c)
					END

					UPDATE Relab.ResultsMeasurements 
					SET Archived=1 
					WHERE ResultID=@ResultID AND Archived=0 AND MeasurementTypeID=@MeasurementTypeID AND LTRIM(RTRIM(ISNULL(Relab.ResultsParametersComma(ID),''))) = LTRIM(RTRIM(ISNULL(@Parameters,''))) AND ReTestNum < @ReTestNum
				END
				ELSE
				--That result does not have that measurement type and exact parameters
				BEGIN
					PRINT 'INSERT New Measurements'
					INSERT INTO Relab.ResultsMeasurements (ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, MeasurementUnitTypeID, PassFail, ReTestNum, Archived, XMLID, Comment)
					SELECT @ResultID As ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, UnitTypeID, CONVERT(BIT, PassFail), 1, 0, @ID, Comment
					FROM #measurement

					DECLARE @ResultMeasurementID3 INT
					SET @ResultMeasurementID3 = @@IDENTITY
					
					SELECT @FileName = LTRIM(RTRIM([FileName]))
					FROM #measurement
				
					IF (@FileName IS NOT NULL AND @FileName <> '')
						BEGIN
							UPDATE Relab.ResultsMeasurementsFiles 
							SET ResultMeasurementID=@ResultMeasurementID3 
							WHERE LOWER(LTRIM(RTRIM(FileName)))=LOWER(@FileName) AND ResultMeasurementID IS NULL
						END
					
					IF (@Parameters <> '')
					BEGIN								
						PRINT 'INSERT New Parameters'
						INSERT INTO Relab.ResultsParameters (ResultMeasurementID, ParameterName, Value)
						SELECT @ResultMeasurementID3 AS ResultMeasurementID, T.c.value('@ParameterName','nvarchar(max)') AS ParameterName, T.c.query('.').value('.', 'nvarchar(max)') AS Value
						FROM @xmlPart.nodes('/Measurement/Parameters/Parameter') T(c)
					END
				END
			END
			
			DROP TABLE #measurement
		
			SELECT @RowID = MIN(RowID) FROM #temp2 WHERE RowID > @RowID
		END
		
		PRINT 'Update Result'
		UPDATE Relab.ResultsXML 
		SET EndDate=CONVERT(DATETIME, @EndDate), StartDate =@StartDate, IsProcessed=1, StationName=@StationName
		WHERE ID=@ID
		
		UPDATE Relab.Results
		SET PassFail=CASE WHEN (SELECT COUNT(*) FROM Relab.ResultsMeasurements WHERE ResultID=@ResultID AND Archived=0 AND PassFail=0) > 0 THEN 0 ELSE 1 END
		WHERE ID=@ResultID
	
		DROP TABLE #temp2
		SET NOCOUNT OFF

		GOTO HANDLE_SUCCESS
	END TRY
	BEGIN CATCH
		SET NOCOUNT OFF
		SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_SEVERITY() AS ErrorSeverity, ERROR_STATE() as ErrorState, ERROR_PROCEDURE() as ErrorProcedure, ERROR_LINE() as ErrorLine, ERROR_MESSAGE() as ErrorMessage

		GOTO HANDLE_ERROR
	END CATCH

	HANDLE_SUCCESS:
		IF @@TRANCOUNT > 0
		BEGIN
			PRINT 'COMMIT TRANSACTION'
			COMMIT TRANSACTION
		END
		RETURN	
	
	HANDLE_ERROR:
		IF @@TRANCOUNT > 0
		BEGIN
			PRINT 'ROLLBACK TRANSACTION'
			ROLLBACK TRANSACTION
		END
		RETURN
END
GO
GRANT EXECUTE ON Relab.remispResultsFileProcessing TO REMI
GO
PRINT N'Altering [dbo].[remispTestRecordsInsertUpdateSingleItem]'
GO
ALTER PROCEDURE [dbo].[remispTestRecordsInsertUpdateSingleItem]
	@ID int OUTPUT,	
	@TestUnitID int,
	@TestStageName nvarchar(400),
	@JobName nvarchar(400),
	@TestName nvarchar(400),
	@FailDocRQID int = null,
	@Status int,
	@ResultSource int = null,
	@FailDocNumber nvarchar(500) = null,
	@RelabVersion int,	
	@Comment nvarchar(1000)=null,
	@ConcurrencyID rowversion OUTPUT,
	@LastUser nvarchar(255),
	@TestID INT = NULL,
	@TestStageID INT = NULL
AS
BEGIN
	DECLARE @JobID INT
	DECLARE @ReturnValue INT
	
	IF (@ID is null or @ID <=0 ) --no dupes allowed here!
	BEGIN
		SET @ID = (SELECT ID FROM TestRecords WHERE TestStageName = @TestStageName AND JobName = @JobName AND testname=@TestName AND testunitid=@TestUnitID)
	END
	
	if (@TestID is null and @TestName is not null)
	begin
		SELECT @TestID=ID FROM Tests WHERE TestName=@TestName
	END

	if (@TestStageID is null and @TestStageName is not null)
	begin
		SELECT @JobID=ID FROM Jobs WHERE JobName=@JobName
		SELECT @TestStageID=ID FROM TestStages WHERE JobID=@JobID AND TestStageName=@TestStageName
	END

	IF (@ID IS NULL) -- New Item
	BEGIN
		INSERT INTO TestRecords (TestUnitID, Status, FailDocNumber, TestStageName, JobName, TestName, RelabVersion, LastUser, Comment,
			ResultSource, FailDocRQID, TestID, TestStageID)
		VALUES (@TestUnitID, @Status, @FailDocNumber, @TestStageName, @JobName, @TestName, @RelabVersion, @lastUser, @Comment,
			@ResultSource, @FailDocRQID, @TestID, @TestStageID)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE -- Exisiting Item
	BEGIN
		UPDATE TestRecords 
		SET TestUnitID = @TestUnitID, 
			Status = @Status, 
			FailDocNumber = @FailDocNumber,
			TestStageName = @TestStageName,
			JobName = @JobName,
			TestName = @TestName,
			RelabVersion = @RelabVersion,
			lastuser = @LastUser,
			Comment = @Comment,
			ResultSource = @ResultSource,
			FailDocRQID = @FailDocRQID,
			TestID=@TestID,
			TestStageID=@TestStageID
		WHERE ID = @ID AND ConcurrencyID = @ConcurrencyID

		SELECT @ReturnValue = @ID
	END

	SET @ConcurrencyID = (SELECT ConcurrencyID FROM TestRecords WHERE ID = @ReturnValue)
	SET @ID = @ReturnValue
	
	IF (@@ERROR != 0)
	BEGIN
		RETURN -1
	END
	ELSE
	BEGIN
		RETURN 0
	END
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestExceptionsGetTestUnitTable]'
GO
ALTER PROCEDURE [dbo].[remispTestExceptionsGetTestUnitTable]
/*	'===============================================================
	'   NAME:                	remispTestExceptionsGetTestUnitTable
	'   DATE CREATED:       	09 Oct 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves a list of test names / boolean
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/
	@QRANumber nvarchar(11) = null,
	@BatchunitNumber int = null,
	@TestStageName nvarchar(400) = null,
	@TestStageID INT = NULL
AS
	declare @pid int
	declare @testunitid int
	declare @TestStageType int
		
	--get the test unit id
	if @QRANumber is not null and @BatchUnitNumber is not null
	begin
		set @testUnitID = (select tu.Id from TestUnits as tu, Batches as b where b.QRANumber = @QRANumber AND tu.BatchID = b.ID AND tu.batchunitnumber = @Batchunitnumber)
		PRINT 'TestUnitID: ' + CONVERT(NVARCHAR, ISNULL(@testUnitID,''))
	end
		
	--get the product group name for the test unit's batch
	set @pid= (select p.ID from Batches as b, TestUnits as tu, products p where b.id = tu.BatchID and tu.ID= @testunitid and p.id=b.productID)
	PRINT 'ProductID: ' + CONVERT(NVARCHAR, ISNULL(@pid,''))

	if (@TestStageID is null and @TestStageName is not null)
	begin
		set @TestStageID = (select ts.ID from Teststages as ts,jobs as j, Batches as b, TestUnits as tu
		where ts.TestStageName = @TestStageName and ts.JobID = j.id 
			and j.jobname = b.jobname 
			and tu.ID = @testunitid
			and b.ID = tu.BatchID)
	END

	PRINT 'TestStageID: ' + CONVERT(NVARCHAR, ISNULL(@TestStageID,''))

	--set up the required tables
	declare @testUnitExemptions table (exTestName nvarchar(255))

	insert into @testunitexemptions
	SELECT DISTINCT TestName
	FROM vw_ExceptionsPivoted as pvt
		INNER JOIN Tests t ON pvt.Test = t.ID
	where (
			(pvt.TestUnitID = @TestUnitID and pvt.ProductID is null) 
			or 
			(pvt.TestUnitID is null and pvt.ProductID = @pid)
		  ) and( pvt.TestStageID = @TestStageID or @TestStageID is null)

	SELECT TestName AS Name, (CASE WHEN (SELECT exTestName FROM @testUnitExemptions WHERE exTestName = t.TestName) IS NOT NULL THEN 'True' ELSE 'False' END ) AS TestUnitException
	FROM Tests t, teststages as ts
	WHERE --where teststage type is environmental, the test name and test stage id's match
	ts.id = @TeststageID  and ((ts.TestStageType = 2  and ts.TestID = t.id) or
	--test stage type = incoming eval and test type is parametric
	( ts.TestStageType = 3 and t.testtype = 3) or
	--OR where test stage type is parametric and test type is also parametric (ie get all the measurment tests)
	(( ts.TeststageType = 1 ) and t.TestType = 1))
	ORDER BY TestName
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispGetFastScanData]'
GO
ALTER procedure [dbo].[remispGetFastScanData]
@qranumber nvarchar(11),
@unitnumber int,
@Hostname nvarchar(255)=  null,
@TLID int = null,
@testName nvarchar(300)=null,
@teststagename nvarchar(300)=null
AS
--initialise return data
declare @currenttlname nvarchar(400)
declare @tlCapacityRemaining int
declare @testunitcurrenttest nvarchar(300)
declare @testUnitCurrentTestStage nvarchar(300)
declare @teststageisvalid bit
declare @testisvalid bit
declare @isDNP bit
declare @testrecordstatus int
declare @OLDtestrecordstatus int
declare @numberoftests int
declare @batchstatus int
declare @inFA bit
declare @inQuarantine bit
declare @testType int
declare @trackinglocationCurrentTestName nvarchar(300)
declare @productname nvarchar(400)
declare @jobWILocation nvarchar(400)
declare @tlWILocation nvarchar(400)
declare @tlfunction int
declare @BSN bigint
declare @TestIsValidForLocation bit
declare @testIsTimed bit
declare @requiredTestTime float
declare @batchSpecificDuration float 
declare @totalTestTimeMinutes float
declare @ApplicableTestStages nvarchar(1000)=''
declare @ApplicableTests nvarchar(1000)=''
-----------------------
--Vars for use in SP --
-----------------------

--jobname-- product group
declare @jobname nvarchar(400)

select @jobname=jobname, @productname=p.ProductGroupName from Batches inner join Products p on p.ID=Batches.ProductID where Batches.QRANumber = @qranumber

declare @jobID int
-- job WI
select @jobWILocation=j.WILocation,@jobid=j.ID from Jobs as j where j.JobName = @jobname

--tracking location id
if @tlid is null
begin
	SELECT TOP (1) @tlid = TrackingLocationID
	FROM TrackingLocationsHosts tlh
	WHERE tlh.HostName = @Hostname and @HostName is not null
end

--tracking location wi
set	@tlWILocation = (select tlt.WILocation from TrackingLocations as tl, TrackingLocationTypes as tlt where tl.ID = @tlid and tlt.ID = tl.TrackingLocationTypeID)

-- tracking location current test name

set @trackinglocationCurrentTestName = (SELECT     top(1) tu.CurrentTestName as CurrentTestName
		                    FROM TestUnits AS tu, DeviceTrackingLog AS dtl 
		                                          where tu.ID = dtl.TestUnitID 
		                                          and tu.CurrentTestName is not null
		                                          and dtl.TrackingLocationID = @TLID 
		                                          and (dtl.OutUser IS NULL))
--test unit id
declare @testunitid int
if (@qranumber is not null and @unitnumber is not null )
begin
	set @testunitid = (select tu.id from testunits as tu, Batches as b 
	where tu.BatchID = b.ID and b.QRANumber = @qranumber and tu.BatchUnitNumber = @unitnumber)
end
--test unit's current test stage
select @testunitcurrenttest=tu.CurrentTestName,@testunitcurrentteststage=tu.CurrentTestStageName 
from TestUnits as tu where tu.ID = @testunitid

--bsn
set @bsn = (select bsn from TestUnits where ID = @testunitid)

--teststage id
declare @teststageID int
set @teststageid = (select ts.id from teststages as ts, jobs as j
where j.JobName = @jobname and ts.JobID = j.ID and ts.TestStageName = @teststagename)

--test id
declare @testID int
set @testid = 	(SELECT  t.ID FROM  Tests AS t, TestStages as ts WHERE    
		    ts.ID = @TestStageID  
		    and ((ts.TestStagetype = 2 and t.TestName=ts.teststagename and t.TestName = @testName
		    and t.id = ts.TestID) --if its an env teststage get the equivelant test
		    or (ts.teststagetype = 1
		    and t.testtype = 1 and t.TestName = @testName)--otherwise if its a para test stage get the para test
		       or (ts.teststagetype = 3
		    and t.testtype = 3 and t.TestName = @testName))) --or the incoming eval test
--test id
declare @currentTestID int
set @currentTestID = 	(SELECT  t.ID FROM  Tests AS t, TestStages as ts WHERE    
		    ts.TestStageName = @testUnitCurrentTestStage
		    and ts.JobID = @jobid
		    and ((ts.TestStagetype = 2 and t.TestName=ts.teststagename and t.TestName = @testunitcurrenttest
		    and t.id = ts.TestID) --if its an env teststage get the equivelant test
		    or (ts.teststagetype = 1
		    and t.testtype = 1 and t.TestName = @testunitcurrenttest)--otherwise if its a para test stage get the para test
		       or (ts.teststagetype = 3
		    and t.testtype = 3 and t.TestName = @testunitcurrenttest))) --or the incoming eval test
--test record id
declare @trid int
set @trid = (select Tr.id from TestRecords as tr where
tr.JobName = @jobname and tr.TestStageName = @teststagename and tr.TestName = @testName and tr.TestUnitID = @testunitid)

--OLD test record id
declare @OLDtrid int
set @OLDtrid = (select Tr.id from TestRecords as tr where
tr.JobName = @jobname and tr.TestStageName = @testUnitCurrentTestStage and tr.TestName = @testunitcurrenttest and tr.TestUnitID = @testunitid)

--time info. adjusted to select the batch specific duration if applicable
set @testIsTimed = (select ResultBasedOntime from Tests where ID = @currentTestID)
set @batchSpecificDuration = (select Duration from BatchSpecificTestDurations, Batches where TestID = @testID and BatchID = Batches.ID and Batches.QRANumber = @qranumber)
set @requiredTestTime = case when @batchSpecificDuration is not null then @batchSpecificDuration else (select Tests.Duration from Tests where ID = @testID) end

set @totalTestTimeMinutes = (Select sum(datediff(MINUTE,dtl.intime,
(case when (dtl.OutTime IS null) then GETUTCDATE() else dtl.outtime  end ))) 
	 from Testrecordsxtrackinglogs as trXtl, DeviceTrackingLog as dtl 
	 where trXtl.TestRecordID = @trid and dtl.ID = trXtl.TrackingLogID)


-----------------------
-- GET RETURN PARAMS --
-----------------------
-- batch status
set @batchstatus = (select BatchStatus from Batches where QRANumber = @qranumber)
--tlname
set	@currenttlname = (select trackinglocationname from TrackingLocations where id = @tlid)

--tlcapacity
set @tlCapacityRemaining = (select tlt.UnitCapacity - (SELECT COUNT(dtl.ID)--currentcount
		                    FROM  DeviceTrackingLog AS dtl
		                                          where 
		                                           dtl.TrackingLocationID = @tlid
		                                          and (dtl.OutUser IS NULL))
		                                          
		                                          from TrackingLocations as tl, TrackingLocationTypes as tlt
		                                          where tl.id = @tlid
		                                          and tlt.ID = tl.TrackingLocationTypeID)
--tlfunction
set @tlfunction = (select tlt.TrackingLocationFunction		                  	                                          
		                                          from TrackingLocations as tl, TrackingLocationTypes as tlt
		                                          where tl.id = @tlid
		                                          and tlt.ID = tl.TrackingLocationTypeID)


--teststage is valid
set @teststageisvalid = (case when (@teststageID IS NULL) then 0 else 1 end)

--testisvalid
set @testisvalid = (case when (@testID IS NULL) then 0 else 1 end)

--test type
set @testType = (select testtype from Tests where ID = @testID)

-- is dnp'd
declare @exceptionsTable table(name nvarchar(300), TestUnitException nvarchar(50))
insert @exceptionsTable exec remispTestExceptionsGetTestUnitTable @qranumber, @unitnumber, @teststagename  
set @isDNP = (select (case when (TestUnitException = 'True') then 1 else 0 end) from @exceptionstable where name = @testname)

-- is in FA
set @inFA = case when (select COUNT (*) from TestRecords as tr where TestUnitID = @testunitid and tr.Status = 3)>0 then 1 else 0 end --status is FARaised

-- is in FA
set @inQuarantine = case when (select COUNT (*) from TestRecords as tr where TestUnitID = @testunitid and tr.Status = 9)>0 then 1 else 0 end --status is Quarantine

--test record status
set @testrecordstatus = (select tr.Status from TestRecords as tr where tr.ID = @trid)
--test OLD record status
set @OLDtestrecordstatus = (select tr.Status from TestRecords as tr where tr.ID = @OLDtrid)

--number of scans
set @numberoftests = (select COUNT (*) from Testrecordsxtrackinglogs as trXtl, DeviceTrackingLog as dtl where trXtl.TestRecordID = @trid and dtl.ID = trXtl.TrackingLogID)
--test valid for tracking location
set @TestIsValidForLocation = case when (select 1 from Tests as t, TrackingLocations as tl, trackinglocationtypes as tlt, TrackingLocationsForTests as tltfort 
where tlt.ID = tltfort.TrackingLocationtypeID and t.ID = tltfort.TestID and t.ID = @testID and tlt.ID = tl.TrackingLocationTypeID and tl.ID = @TLID) IS not null then 1 else 0 end
--get applicable test stages
select @ApplicableTestStages = @ApplicableTestStages + ','  + TestStageName from TestStages where ISNULL(TestStages.IsArchived, 0)=0 AND TestStages.JobID = (select ID from Jobs where jobname = @jobname) order by ProcessOrder
set @ApplicableTestStages = SUBSTRING(@ApplicableTestStages,2,Len(@ApplicableTestStages))
--get applicable tests
select @ApplicableTests = @ApplicableTests + ','  +  testname from Tests as t, TrackingLocationsForTests as tlft, TrackingLocationTypes as tlt , TrackingLocations as tl
where ISNULL(t.IsArchived, 0)=0 AND t.ID = tlft.TestID
and tlft.TrackingLocationtypeID = tlt.ID
and tlt.ID = tl.TrackingLocationTypeID
and tl.ID = @tlid
set @ApplicableTests = SUBSTRING(@ApplicableTests,2,Len(@ApplicableTests))

----------------------------
---  Tracking Log Params ---
----------------------------

declare @dtlID int, @inTime datetime, @outtime datetime, @inuser nvarchar(255),
 @outuser nvarchar(255), @lasttrackinglocationname nvarchar(400), @LastTrackingLocationID int
 
 select   top(1)	@dtlID=dtl.id,
 	@inTime =InTime, 
 	@outtime=OutTime,
	@inuser=InUser, 
	@outuser =OutUser,
	@lasttrackinglocationname=trackinglocationname , 
	@LastTrackingLocationID=tl.ID 
	FROM     DeviceTrackingLog as dtl, TrackingLocations as tl
	WHERE     (dtl.TestUnitID = @TestUnitID and tl.ID = dtl.TrackingLocationID)
	order by dtl.intime desc;
----------------------
--  RETURN DATA ------
----------------------
select   @dtlID as LastLogID,
	@testunitid as TestUnitID,
 	@inTime as intime, 
 	@outtime as outtime,
	@InUser as inuser, 
	@OutUser as outuser,
	@lastTrackingLocationName as lasttrackinglocationname, 
	@LastTrackingLocationID as LastTrackingLocationID,
	@batchstatus as BatchStatus,
	@currenttlname as CurrentTrackingLocationName,
	@tlCapacityRemaining as CapacityRemaining,
	@TLID as CurrentTrackingLocationID,
	@testunitcurrentteststage as testUnitCurrentTestStage,
	@testunitcurrenttest as TestUnitCurrentTest ,
	@teststageisvalid as TestStageValid ,
	@testisvalid as TestValid,
	@isDNP as IsDNP,
	@inFA as IsInFA,
	@TestType as testType,
	@trackinglocationCurrentTestName as TrackingLocationCurrentTestName,
	@testrecordstatus  as TestRecordStatus,
	@OLDtestrecordstatus as OldTestRecordStatus,
	@numberoftests as NumberOfTests,
    @productname as ProductGroup,
	@jobWILocation as JobWI,
	@tlWILocation as TLWI,
	@trid as testrecordid,
	@tlfunction as tlfunction,
	@jobname as jobname,
	@BSN as BSN,
	@TestIsValidForLocation as TestIsValidForTrackingLocation,
	@testIsTimed as TestIsTimed,
	@requiredTestTime as TestDuration,
	@totalTestTimeMinutes as TotaltestTimeInMinutes,
	@ApplicableTestStages as ApplicableTestStages,
	@ApplicableTests as ApplicableTests
	
	exec remispTrackingLocationsSelectForTest @testid, @tlid;
	 
		IF (@@ERROR != 0)
	BEGIN
		RETURN -3
	END
	ELSE
	BEGIN
		RETURN 0
	END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestsSelectSingleItemByName]'
GO
ALTER PROCEDURE [dbo].[remispTestsSelectSingleItemByName] @Name nvarchar(400)
AS
	SELECT t.Comment,t.ConcurrencyID,t.Duration,t.ID,t.LastUser,t.ResultBasedOntime,t.TestName,t.TestType,t.WILocation, t.IsArchived
	FROM Tests as t
	WHERE t.TestName = @name AND TestType=1
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestExceptionsInsertTestUnitException]'
GO
ALTER PROCEDURE [dbo].[remispTestExceptionsInsertTestUnitException]
/*	'===============================================================
	'   NAME:                	remispTestExceptionsInsertTestUnitException
	'   DATE CREATED:       	22 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Creates an item in a table: TestUnitTestExceptions
	'   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
	@QRANumber nvarchar(11),
	@BatchUnitNumber int,
	@TestName nvarchar(400) = null,
	@TestStageName nvarchar(400) = null,
	@LastUser nvarchar(255),
	@TestStageID int = null,
	@testunitid int = null,
	@ProductTypeID INT = NULL,
	@AccessoryGroupID INT = NULL,
	@TestID INT = NULL
AS		
	DECLARE @ReturnValue int	
	
	--get the test unit id
	if @testunitid is  null and (@QRANumber is not null and @BatchUnitNumber is not null)
	begin
		set @testUnitID = (select tu.Id from TestUnits as tu, Batches as b 
		where b.QRANumber = @QRANumber 
		AND tu.BatchID = b.ID AND tu.batchunitnumber = @Batchunitnumber)

		PRINT 'TestUnitID: ' + CONVERT(NVARCHAR, ISNULL(@testUnitID,''))
	end	
		
	--Get the test stage id
	if (@teststageid is null and @TestStageName is not null)
	begin
		set @TestStageID = (select ts.ID from TestStages as ts, TestUnits as tu,Jobs as j, Batches as b 
		where tu.ID=@testUnitID and b.ID=tu.BatchID and ts.TestStageName = @TestStageName and ts.JobID = j.ID and
		j.JobName = b.jobname)
		
		PRINT 'TestStageID: ' + CONVERT(NVARCHAR, ISNULL(@TestStageID,''))
	end 
	
	set @ReturnValue = (SELECT DISTINCT pvt.ID
	FROM vw_ExceptionsPivoted as pvt
		LEFT OUTER JOIN Tests t ON pvt.Test = t.ID
	where (testunitid = @testunitid)
	and 
	(
		TestStageID = @TestStageID 
		or
		(@TestStageID is null and TestStageID is null)
	)
	and 
	(
		(t.TestName = @testname AND @TestID IS NULL)
		or 
		(@TestName is null and TestName is null AND @TestID IS NULL)
		OR
		(t.ID = @TestID AND @TestID IS NOT NULL)
	)
	)
	
	IF (@ReturnValue IS NULL) -- if it doesnt already exist then add it
	BEGIN
		PRINT 'INSERTING'
		DECLARE @ID INT
		SELECT @ID = MAX(ID)+1 FROM TestExceptions
		PRINT @ID
		
		IF (@TestID IS NOT NULL)
		BEGIN
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 5, @TestID, @LastUser)
		END
		ELSE IF (@TestName IS NOT NULL)
		BEGIN
			PRINT 'Inserting TestName'
			DECLARE @tID INT
			IF ((SELECT COUNT(*) FROM Tests WHERE TestName=@TestName) = 1)
			BEGIN
				SELECT @tID = ID FROM Tests WHERE TestName=@TestName
				INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 5, @tID, @LastUser)
			END
			ELSE
			BEGIN
				IF (@TestStageID IS NOT NULL AND EXISTS (SELECT TestID FROM TestStages WHERE ID=@TestStageID AND TestID IS NOT NULL))
				BEGIN
					SET @tID = (SELECT TestID FROM TestStages WHERE ID=@TestStageID AND TestID IS NOT NULL)
					INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 5, @tID, @LastUser)
				END
				--ELSE
				--BEGIN
				--	INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 5, @TestName, @LastUser)
				--END
			END
		END

		IF (@TestStageID IS NOT NULL)
		BEGIN
			PRINT 'Inserting TestStageID'
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 4, @TestStageID, @LastUser)
		END
		
		IF (@TestUnitID IS NOT NULL)
		BEGIN
			PRINT 'Inserting TestUnitID'
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 3, @TestUnitID, @LastUser)
		END

		IF (@ProductTypeID IS NOT NULL AND @ProductTypeID > 0)
		BEGIN
			PRINT 'Inserting ProductType'
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 6, @ProductTypeID, @LastUser)
		END

		IF (@AccessoryGroupID IS NOT NULL AND @AccessoryGroupID > 0)
		BEGIN
			PRINT 'Inserting AccessoryGroupName'
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 7, @AccessoryGroupID, @LastUser)
		END

		SET @ReturnValue = @ID		
	ENd
		
	IF (@@ERROR != 0)
	BEGIN
		RETURN -1
	END
	ELSE
	BEGIN
		RETURN @returnvalue
	END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestExceptionsInsertProductGroupException]'
GO
ALTER PROCEDURE [dbo].[remispTestExceptionsInsertProductGroupException]
/*	'===============================================================
	'   NAME:                	remispTestExceptionsInsertProductGroupException
	'   DATE CREATED:       	22 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Creates an item in a table: TestUnitTestExceptions
	'   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
	@ReasonForRequest int = null,
	@TestName nvarchar(400) = null,
	@TestStageName nvarchar(400) = null,
	@JobName nvarchar(400)=null,
	@ProductID INT=null,
	@LastUser nvarchar(255),
	@ProductTypeID INT = NULL,
	@AccessoryGroupID INT = NULL,
	@TestStageID int = null,
	@TestID INT = null
AS		
	DECLARE @ReturnValue int
	declare @testUnitID int
	declare @ValidInputParams int = 1
	
	if (@teststageid is null and @TestStageName is not null)
	begin
		set @TestStageID = (select ts.id from TestStages as ts, Jobs as j where j.JobName = @JobName and ts.JobID = j.ID and ts.TestStageName = @TestStageName)
	end

	PRINT 'TestStageID: ' + CONVERT(NVARCHAR, ISNULL(@TestStageID, ''))
		
	--test if item exists in db already

	set @ReturnValue = (SELECT DISTINCT pvt.ID
	FROM vw_ExceptionsPivoted as pvt
		LEFT OUTER JOIN Tests t ON pvt.Test = t.ID
	where (ReasonForRequest = @ReasonForRequest)
		and (TestStageID = @TestStageID)
		and (testname = @testname OR t.ID = @TestID)
		and (ProductID = @ProductID))

	IF (@ReturnValue IS NULL) -- if it doesnt already exist then add it
	BEGIN
		PRINT 'INSERTING'
		DECLARE @ID INT
		SELECT @ID = MAX(ID)+1 FROM TestExceptions
		PRINT @ID

		IF (@TestID IS NOT NULL)
		BEGIN
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 5, @TestID, @LastUser)
		END
		ELSE IF (@TestName IS NOT NULL)
		BEGIN
			PRINT 'Inserting TEST'
			DECLARE @tID INT
			IF ((SELECT COUNT(*) FROM Tests WHERE TestName=@TestName) = 1)
			BEGIN
				SELECT @tID = ID FROM Tests WHERE TestName=@TestName
				INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 5, @tID, @LastUser)
			END
			ELSE
			BEGIN
				IF (@TestStageID IS NOT NULL AND EXISTS (SELECT TestID FROM TestStages WHERE ID=@TestStageID AND TestID IS NOT NULL))
				BEGIN
					SET @tID = (SELECT TestID FROM TestStages WHERE ID=@TestStageID AND TestID IS NOT NULL)
					INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 5, @tID, @LastUser)
				END
			END
		END

		IF (@TestStageID IS NOT NULL)
		BEGIN
			PRINT 'Inserting TestStage'
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 4, @TestStageID, @LastUser)
		END

		IF (@ReasonForRequest IS NOT NULL)
		BEGIN
			PRINT 'Inserting ReasonForRequest'
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 2, @ReasonForRequest, @LastUser)
		END

		IF (@ProductID > 0)
		BEGIN
			PRINT 'Inserting ProductID'
			DECLARE @LookupID INT
			SELECT @LookupID=LookupID FROM Lookups WHERE Type='Exceptions' AND [Values]='ProductID'
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, @LookupID, @ProductID, @LastUser)
		END

		IF (@ProductTypeID IS NOT NULL AND @ProductTypeID > 0)
		BEGIN
			PRINT 'Inserting ProductType'
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 6, @ProductTypeID, @LastUser)
		END

		IF (@AccessoryGroupID IS NOT NULL AND @AccessoryGroupID > 0)
		BEGIN
			PRINT 'Inserting AccessoryGroupName'
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 7, @AccessoryGroupID, @LastUser)
		END		

		SET @ReturnValue = @ID
	END
	
	IF (@@ERROR != 0)
	BEGIN
		RETURN -1
	END
	ELSE
	BEGIN
		RETURN @ReturnValue
	END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestExceptionsDeleteTestUnitException]'
GO
ALTER PROCEDURE [dbo].[remispTestExceptionsDeleteTestUnitException]
	@QRANumber nvarchar(11),
	@BatchUnitNumber int,
	@TestName nvarchar(400) = null,
	@TestStageName nvarchar(400) = null,
	@LastUser nvarchar(255),
	@TestUnitID INT = NULL,
	@TestStageID INT = NULL
AS
BEGIN
	DECLARE @TestID INT
	
	IF (@TestUnitID IS NULL)
		SET @TestUnitID = (SELECT ID FROM TestUnits WHERE BatchID = (SELECT ID FROM Batches WHERE QRANumber = @QRAnumber) and BatchUnitNumber = @BatchUnitNumber)
	
	IF (@TestName IS NOT NULL)
	BEGIN	
		SET @TestID = (SELECT ID FROM Tests WHERE TestName=@TestName)	
	END

	if (@teststageid is null and @TestStageName is not null)
	begin
		SET @TestStageID = (SELECT ts.ID 
						FROM TestStages ts
							INNER JOIN Jobs j ON j.ID = ts.JobID
							INNER JOIN Batches b ON b.JobName = j.JobName
							INNER JOIN TestUnits tu ON tu.BatchID = b.ID
						WHERE tu.ID=@TestUnitID AND ts.TestStageName = @TestStageName)
	END

	DECLARE @txID int = (SELECT ID 
						FROM vw_ExceptionsPivoted 
						WHERE TestUnitID = @TestUnitID 
							AND 
							(
								Test = @TestID
								OR
								(
									@TestID IS NULL AND Test IS NULL
								)
							)
							AND 
							(
								TestStageID = @TestStageID 
								OR
								(
									@TestStageId IS NULL AND TestStageID IS NULL
								)
							)
						)
	
	--set the deleting user
	UPDATE TestExceptions SET LastUser = @LastUser WHERE TestExceptions.ID = @txid
	
	--finally delete the item
	DELETE FROM TestExceptions WHERE TestExceptions.ID = @txid
	
	RETURN @txid
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestExceptionsDeleteProductGroupException]'
GO
ALTER PROCEDURE [dbo].[remispTestExceptionsDeleteProductGroupException]
/*	'===============================================================
	'   NAME:                	remispTestExceptionsDeleteProductGroupException
	'   DATE CREATED:       	22 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	deletes an item from table: TestUnitTestExceptions
	'   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
		@ReasonForRequest int = null,
		@TestName nvarchar(400) = null,
		@TestStageName nvarchar(400) = null,
		@JobName nvarchar(400) = null,
		@ProductID INT=null,
		@LastUser nvarchar(255),
	@TestStageID INT = NULL
AS
	declare @TestUnitID as int 
	
	if (@teststageid is null)
	begin
		if (@ProductID is not null and @teststagename is not null and @jobname is not null and @testUnitID is null)
		begin
			set @TestStageID = (select ts.id from TestStages as ts, Jobs as j where j.JobName = @JobName and ts.JobID = j.ID and ts.TestStageName = @TestStageName)
		end
	
		select @TestStageId AS TestStageID, @TestUnitID AS TestUnitID;
	END

	SELECT DISTINCT pvt.ID
	INTO #temp
	FROM vw_ExceptionsPivoted pvt
		INNER JOIN Tests t ON pvt.Test = t.ID
	where (ReasonForRequest = @ReasonForRequest or (@ReasonForRequest is null and ReasonForRequest is null))
		and testname=@TestName 
		and (teststageid =@TestStageID or (@TestStageId is null and TestStageID is null))
		and ProductID = @ProductID

	PRINT 'SET The User who is deleting'
	UPDATE TestExceptions
	SET LastUser=@LastUser
	WHERE TestExceptions.ID IN (SELECT ID FROM #temp)
	
	PRINT 'Delete Exception'
	delete from TestExceptions WHERE TestExceptions.ID IN (SELECT ID FROM #temp)

	DROP TABLE #temp
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[vw_GetTaskInfo]'
GO
ALTER VIEW [dbo].[vw_GetTaskInfo]
AS
SELECT qranumber, processorder, BatchID,
	   tsname, 
	   tname, 
	   testtype, 
	   teststagetype, 
	   resultbasedontime, 
	   testunitsfortest, 
	   (SELECT CASE WHEN specifictestduration IS NULL THEN generictestduration ELSE specifictestduration END) AS expectedDuration,
	   TestStageID, TestWI, TestID, IsArchived, RecordExists, TestIsArchived, TestRecordExists
FROM   
	(
		SELECT b.qranumber,b.ID AS BatchID,
		ts.processorder, ts.teststagename AS tsname, t.testname AS tname, t.testtype, ts.teststagetype, t.duration AS genericTestDuration, ts.ID AS TestStageID,t.ID AS TestID,
		t.WILocation As TestWI, ISNULL(ts.IsArchived, 0) AS IsArchived, ISNULL(t.IsArchived, 0) AS TestIsArchived, 
			t.resultbasedontime, 
			(
				SELECT bstd.duration 
				FROM   batchspecifictestdurations AS bstd 
				WHERE  bstd.testid = t.id 
					   AND bstd.batchid = b.id
			) AS specificTestDuration,
			(				
				SELECT Cast(tu.batchunitnumber AS VARCHAR(MAX)) + ', ' 
				FROM testunits AS tu 
				WHERE tu.batchid = b.id 
					AND 
					(
						NOT EXISTS 
						(
							SELECT DISTINCT 1
							FROM vw_ExceptionsPivoted as pvt
							where pvt.ID IN (SELECT ID FROM TestExceptions WHERE LookupID=3 AND Value = tu.ID) AND
							(
								(pvt.TestStageID IS NULL AND pvt.Test = t.ID ) 
								OR 
								(pvt.Test IS NULL AND pvt.TestStageID = ts.id) 
								OR 
								(pvt.TestStageID = ts.id AND pvt.Test = t.ID)
								OR
								(pvt.TestStageID IS NULL AND pvt.Test IS NULL)
							)
						)
					)
				FOR xml path ('')
			) AS TestUnitsForTest,
			(SELECT TOP 1 1
			FROM TestRecords tr
			WHERE tr.TestStageName=ts.TestStageName AND tr.TestUnitID IN (SELECT ID FROM TestUnits WHERE BatchID=b.ID)) AS RecordExists,
			(SELECT TOP 1 1
			FROM TestRecords tr
			WHERE tr.TestID=t.ID AND tr.TestUnitID IN (SELECT ID FROM TestUnits WHERE BatchID=b.ID)) AS TestRecordExists
		FROM TestStages ts
		INNER JOIN Jobs j ON ts.JobID=j.ID
		INNER JOIN Batches b on j.jobname = b.jobname 
		INNER JOIN Tests t ON ( ( ts.teststagetype = 2 AND ts.testid = t.id ) OR ts.teststagetype != 2 AND ts.teststagetype = t.testtype )
		INNER JOIN Products p ON b.ProductID=p.ID
		WHERE NOT EXISTS 
			(
				SELECT DISTINCT 1
				FROM vw_ExceptionsPivoted as pvt
				WHERE pvt.testunitid IS NULL AND pvt.Test = t.ID
					AND ( pvt.teststageid IS NULL OR ts.id = pvt.teststageid ) 
					AND ( 
							(pvt.ProductID = p.ID AND pvt.reasonforrequest IS NULL)
							OR 
							(pvt.ProductID = p.ID AND pvt.reasonforrequest = b.requestpurpose ) 
							OR
							(pvt.ProductID IS NULL AND b.requestpurpose IS NOT NULL AND pvt.reasonforrequest = b.requestpurpose)
							OR
							(pvt.ProductID IS NULL AND pvt.reasonforrequest IS NULL)
						) 
					AND
						(
							(pvt.AccessoryGroupID IS NULL)
							OR
							(pvt.AccessoryGroupID IS NOT NULL AND pvt.AccessoryGroupID = b.AccessoryGroupID)
						)
					AND
						(
							(pvt.ProductTypeID IS NULL)
							OR
							(pvt.ProductTypeID IS NOT NULL AND pvt.ProductTypeID = b.ProductTypeID)
						)
			)
	) AS unitData 
WHERE TestUnitsForTest IS NOT NULL AND 
	(
		(ISNULL(RecordExists,0) > 0 AND IsArchived = 1 AND ISNULL(TestRecordExists, 0) > 0 AND TestIsArchived = 1)
		OR
		(ISNULL(IsArchived, 0) = 0 AND ISNULL(TestIsArchived, 0) = 0)
		OR
		(ISNULL(RecordExists,0) > 0 AND IsArchived = 0 AND ISNULL(TestRecordExists, 0) > 0 AND TestIsArchived = 1)
	)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestsSelectSingleItem]'
GO
ALTER PROCEDURE [dbo].[remispTestsSelectSingleItem] @ID int
AS
	SELECT t.Comment,t.ConcurrencyID,t.Duration,t.ID,t.LastUser,t.ResultBasedOntime,t.TestName,t.TestType,t.WILocation, t.IsArchived
	FROM Tests as t
	WHERE t.ID = @ID
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestsSelectListByType]'
GO
ALTER PROCEDURE [dbo].[remispTestsSelectListByType] @TestType int, @IncludeArchived BIT = 0
AS
BEGIN
	SELECT t.Comment,t.ConcurrencyID,t.Duration,t.ID,t.LastUser,t.ResultBasedOntime,t.TestName,t.TestType,t.WILocation, dbo.remifnTestCanDelete(t.ID) AS CanDelete, t.IsArchived
	FROM Tests t
	WHERE TestType = @TestType 
		AND
		(
			(@IncludeArchived = 0 AND ISNULL(t.IsArchived, 0) = 0)
			OR
			(@IncludeArchived = 1)
		)
	ORDER BY TestName;
	
	SELECT t.id, tlt.id, tlt.TrackingLocationTypeName    
	FROM trackinglocationtypes as tlt, TrackingLocationsForTests as tlfort, Tests as t
	WHERE tlfort.testid = t.id and tlt.ID = tlfort.TrackingLocationtypeID
		AND t.TestType = @TestType
	ORDER BY tlt.TrackingLocationTypeName asc
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestsSelectListByTestStageID]'
GO
ALTER PROCEDURE [dbo].[remispTestsSelectListByTestStageID] @TestStageID int = -1
AS
	SELECT t.Comment,t.ConcurrencyID,t.Duration,t.ID,t.LastUser,t.ResultBasedOntime,t.TestName,t.TestType,t.WILocation, t.IsArchived
	FROM  Tests AS t, TestStages as ts
	WHERE ts.ID = @TestStageID
		and 
		((ts.TestStagetype = 2  and t.id = ts.TestID ) --if its an env teststage get the equivelant test
		or (ts.teststagetype = 1 and t.testtype = 1))--otherwise if its a para test stage get all the para tests
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestsInsertUpdateSingleItem]'
GO


ALTER PROCEDURE [dbo].[remispTestsInsertUpdateSingleItem]
	@TestName nvarchar(400), 
	@Duration real, 
	@TestType int,
	@WILocation nvarchar(800)=null,
	@Comment nvarchar(1000)=null,	
	@ID int OUTPUT,
	@LastUser nvarchar(255),
	@ResultBasedOnTime bit,
	@ConcurrencyID rowversion OUTPUT,
	@IsArchived BIT = 0	
AS
	DECLARE @ReturnValue int
	
	IF (@ID IS NULL) and (((select count (*) from Tests where TestName = @TestName)= 0) or @TestType != 1)-- New Item
	BEGIN
		INSERT INTO Tests (TestName, Duration, TestType, WILocation, Comment, lastUser, ResultBasedOntime, IsArchived)
		VALUES
		(
			@TestName, 
			@Duration, 
			@TestType, 
			@WILocation,
			@Comment,
			@lastUser,
			@ResultBasedOnTime,
			@IsArchived
		)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE -- Exisiting Item
	BEGIN
		UPDATE Tests SET
			TestName = @TestName, 
			Duration = @Duration, 
			TestType = @TestType, 
			WILocation = @WILocation,
			Comment = @Comment,
			lastUser = @LastUser,
			ResultBasedOntime = @ResultBasedOnTime,
			IsArchived = @IsArchived
		WHERE ID = @ID AND ConcurrencyID = @ConcurrencyID

		SELECT @ReturnValue = @ID
	END

	SET @ConcurrencyID = (SELECT ConcurrencyID FROM Tests WHERE ID = @ReturnValue)
	SET @ID = @ReturnValue
	
	IF (@@ERROR != 0)
	BEGIN
		RETURN -1
	END
	ELSE
	BEGIN
		RETURN 0
	END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[UserTraining]'
GO
ALTER TABLE [dbo].[UserTraining] ADD
[ConfirmDate] [datetime] NULL
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispGetUserTraining]'
GO
ALTER PROCEDURE [dbo].[remispGetUserTraining] @UserID INT
AS
BEGIN
	SELECT UserTraining.ID, UserID, DateAdded, Lookups.LookupID, Lookups.[Values] AS TrainingOption, 
		CASE WHEN ID IS NOT NULL THEN CONVERT(BIT,1) ELSE CONVERT(BIT, 0) END AS IsTrained,
		ll.[Values] As Level, ISNULL(UserTraining.LevelLookupID,0) AS LevelLookupID,
		ConfirmDate, CASE WHEN ConfirmDate IS NOT NULL THEN 1 ELSE 0 END AS IsConfirmed
	FROM Lookups
		LEFT OUTER JOIN UserTraining ON UserTraining.LookupID=Lookups.LookupID AND UserTraining.UserID=@UserID
		LEFT OUTER JOIN Lookups ll ON ll.LookupID=UserTraining.LevelLookupID AND ll.Type='Level'
	WHERE Lookups.Type='Training'
	ORDER BY Lookups.[Values]
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchDNPParametric]'
GO
ALTER PROCEDURE [dbo].[remispBatchDNPParametric] @QRANumber NVARCHAR(11), @LDAPLogin NVARCHAR(255), @UnitNumber INT
AS
	DECLARE @UnitID INT
	DECLARE @TestID INT
	DECLARE @ID INT

	IF (@UnitNumber = 0)
	BEGIN
		SET @UnitNumber = NULL
	END

	SELECT ID
	INTO #tests
	FROM Tests
	WHERE TestType=1 AND ID NOT IN (202, 1073, 1185)
	ORDER BY ID

	SELECT tu.ID
	INTO #units
	FROM TestUnits tu
		INNER JOIN Batches b ON tu.BatchID=b.ID
	WHERE b.QRANumber=@QRANumber AND ((@UnitNumber IS NULL) OR (@UnitNumber IS NOT NULL AND tu.BatchUnitNumber=@UnitNumber))
	ORDER BY tu.ID

	SELECT @TestID = MIN(ID) FROM #tests

	WHILE (@TestID IS NOT NULL)
	BEGIN
		SELECT @UnitID = MIN(ID) FROM #units
		PRINT @TestID
		
		WHILE (@UnitID IS NOT NULL)
		BEGIN
			SELECT @ID = MAX(ID)+1 FROM TestExceptions
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 3, @UnitID, @LDAPLogin)--TestUnit
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 5, @TestID, @LDAPLogin)--Test
			
			SELECT @UnitID = MIN(ID) FROM #units WHERE ID > @UnitID
		END

		SELECT @TestID = MIN(ID) FROM #tests WHERE ID>@TestID
	END

	DELETE FROM TestExceptions WHERE ID IN (SELECT MIN(ID)
	FROM vw_ExceptionsPivoted
	WHERE TestUnitID IN (SELECT ID FROM #units)
		AND TestStageID IS NULL
		AND Test IN (SELECT ID FROM #tests)
	GROUP BY Test, TestUnitID
	HAVING COUNT(*)>1)

	DROP TABLE #tests
	DROP TABLE #units
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispScanGetData]'
GO
ALTER PROCEDURE [dbo].[remispScanGetData]
	@qranumber nvarchar(11),
	@unitnumber int,
	@Hostname nvarchar(255)=  null,
	@selectedTrackingLocationID int = null,
	@selectedTestName nvarchar(300)=null,
	@selectedTestStageName nvarchar(300)=null,
	@trackingLocationName nvarchar(255) = null,
	@selectedTestStageID INT = NULL,
	@selectedTestID INT  = NULL
AS
declare @jobName nvarchar(400)
declare @jobID int
declare @testUnitID int
declare @BSN bigint
declare @selectedTLCapacityRemaining int
declare @currentTest nvarchar(300)
declare @currentTestStage nvarchar(300)
declare @currentTestRecordStatus int
declare @currentTestRecordID int
declare @currentTestID int
declare @currentTestRequiredTestTime float
declare @currentTestTotalTestTime float
declare @currentTestIsTimed bit
declare @currentTestType int
declare @batchStatus int
declare @inFA bit
declare @inQuarantine bit
declare @productGroup nvarchar(400)
declare @jobWILocation nvarchar(400)
declare @selectedTestWI nvarchar(400)
declare @ApplicableTestStages nvarchar(1000)=''
declare @ApplicableTests nvarchar(1000)=''
declare @selectedTestRequiredTestTime float
declare @selectedTestStageIsValid bit
declare @selectedTestIsValid bit
declare @selectedTestIsMarkedDoNotProcess bit
declare @selectedTestRecordStatus int
declare @selectedTestType int
declare @selectedTestIsValidForLocation bit
declare @selectedTestIsTimed bit
declare @selectedTestRecordID int
declare @selectedTestTotalTestTime float
declare @selectedTrackingLocationName nvarchar(400)
declare @selectedLocationNumberOfScans int
declare @selectedTrackinglocationCurrentTestName nvarchar(300)
declare @selectedTrackingLocationWILocation nvarchar(400)
declare @selectedTrackingLocationFunction int
declare @cprNumber nvarchar(500)
declare @hwrevision nvarchar(500)
declare @batchSpecificDuration float 
declare @exceptionsTable table(name nvarchar(300), TestUnitException nvarchar(50))
declare @currentDtlID int, @currentDtlInTime datetime, @currentDtlOutTime datetime, @currentDtlInUser nvarchar(255),
 @currentDtlOutUser nvarchar(255), @currentDtlTrackingLocationName nvarchar(400), @currentDtlTrackingLocationID int
declare @isBBX nvarchar(200)
declare @productID INT

--jobname, product group, job WI, jobID
select @jobName=b.jobname,@cprNumber =b.CPRNumber,@hwrevision = b.HWRevision, @productGroup=p.ProductGroupName,@jobWILocation=j.WILocation,@jobid=j.ID, @batchStatus = b.BatchStatus ,
@productID=p.ID
from Batches as b
	INNER JOIN jobs as j ON j.JobName = b.JobName
	INNER JOIN Products p ON p.ID=b.ProductID
where b.QRANumber = @qranumber

--*******************
---This section gets the IsBBX value as a bit
declare @IsBBXvaluetext nvarchar(200) = (select ValueText FROM ProductSettings as ps where ps.ProductID = @ProductID and KeyName = 'IsBBX')
declare @IsBBXDefaultvaluetext nvarchar(200) =(select top (1) DefaultValue FROM ProductSettings as ps where KeyName = 'IsBBX' and DefaultValue is not null)
set @isBBX = case when @IsBBXvaluetext is not null then @IsBBXvaluetext else @IsBBXDefaultvaluetext end;

--tracking location wi
select TOP 1 @selectedTrackingLocationID = tl.ID, @selectedTrackingLocationWILocation=tlt.WILocation,@selectedTrackingLocationName = TrackingLocationName,@selectedTrackingLocationFunction = tlt.TrackingLocationFunction 
from TrackingLocations as tl
	INNER JOIN TrackingLocationTypes as tlt ON tlt.ID = tl.TrackingLocationTypeID
	LEFT OUTER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
where (@selectedTrackingLocationID IS NULL AND tlh.HostName = @Hostname and @HostName is not null AND 
		((tl.TrackingLocationname= @trackingLocationName AND @trackingLocationName IS NOT NULL) OR @trackingLocationName IS NULL)
	  )
	OR
	(@selectedTrackingLocationID IS NOT NULL AND tl.ID = @selectedTrackingLocationID)


-- tracking location current test name
set @selectedTrackinglocationCurrentTestName = (SELECT top(1) tu.CurrentTestName as CurrentTestName
		                    FROM TestUnits AS tu, DeviceTrackingLog AS dtl 
		             where tu.ID = dtl.TestUnitID and tu.CurrentTestName is not null and dtl.TrackingLocationID = @selectedTrackingLocationID and (dtl.OutUser IS NULL))
--test unit id, bsncurrent test/test stage

(select @testUnitID=tu.id,@bsn = tu.BSN,@currentTest=tu.CurrentTestName,@currentTeststage=tu.CurrentTestStageName from testunits as tu, Batches as b 
	where tu.BatchID = b.ID and b.QRANumber = @qranumber and tu.BatchUnitNumber = @unitnumber)

--teststage id
if (@selectedTestStageID IS NULL)
begin
	select @selectedTestStageID = ts.id 
	from teststages as ts
	where ts.JobID = @jobID and ts.TestStageName = @selectedTestStageName
end

--selected test details
if (@selectedTestID IS NULL)
BEGIN
	SELECT  @selectedTestID=t.ID, @selectedTestIsTimed =t.resultbasedontime,@selectedTestType = t.TestType, @selectedTestWI = t.WILocation
	from Tests AS t, TestStages as ts
	WHERE ts.ID = @selectedTestStageID  
	and (
			(ts.TestStagetype = 2 and t.TestName=ts.teststagename and t.TestName = @selectedTestName and t.id = ts.TestID) --if its an env teststage get the equivelant test
			or (ts.teststagetype = 1 and t.testtype = 1 and t.TestName = @selectedTestName)--otherwise if its a para test stage get the para test
			or (ts.teststagetype = 3 and t.testtype = 3 and t.TestName = @selectedTestName) --or the incoming eval test
		)
END
--current test details

SELECT  @currentTestID=t.ID, @currentTestIsTimed =t.resultbasedontime,@currentTestType = t.TestType 
from Tests AS t, TestStages as ts 
WHERE ts.TestStageName = @currentTestStage
and ts.JobID = @jobid
and (
		(ts.TestStagetype = 2 and t.TestName=ts.teststagename and t.TestName = @currentTest and t.id = ts.TestID) --if its an env teststage get the equivelant test
		or (ts.teststagetype = 1 and t.testtype = 1 and t.TestName = @currentTest)--otherwise if its a para test stage get the para test
		or (ts.teststagetype = 3 and t.testtype = 3 and t.TestName = @currentTest) --or the incoming eval test
	)
--selected test record id

select @selectedTestRecordID = Tr.id, @selectedTestRecordStatus = tr.Status
from TestRecords as tr 
where tr.JobName = @jobName and tr.TestStageName = @selectedTestStageName and tr.TestName = @selectedTestName and tr.TestUnitID = @testUnitID

--OLD test record id

select @currentTestRecordID = Tr.id, @currentTestRecordStatus = tr.Status 
from TestRecords as tr
where tr.JobName = @jobName and tr.TestStageName = @currentTestStage and tr.TestName = @currentTest and tr.TestUnitID = @testUnitID

--time info. adjusted to select the selected test batch specific duration if applicable
set @batchSpecificDuration = (select Duration from BatchSpecificTestDurations, Batches where TestID = @selectedTestID and BatchID = Batches.ID and Batches.QRANumber = @qranumber)
set @selectedTestRequiredTestTime = case when @batchSpecificDuration is not null then @batchSpecificDuration else (select Tests.Duration from Tests where ID = @selectedTestID) end

--now select the currentTest test duration
set @batchSpecificDuration = (select Duration from BatchSpecificTestDurations, Batches where TestID = @currentTestID and BatchID = Batches.ID and Batches.QRANumber = @qranumber)
set @currentTestRequiredTestTime = case when @batchSpecificDuration is not null then @batchSpecificDuration else (select Tests.Duration from Tests where ID = @currentTestID) end

set @selectedTestTotalTestTime = (Select sum(datediff(MINUTE,dtl.intime,
(case when (dtl.OutTime IS null) then GETUTCDATE() else dtl.outtime  end ))) 
	 from Testrecordsxtrackinglogs as trXtl, DeviceTrackingLog as dtl 
	 where trXtl.TestRecordID = @selectedTestRecordID and dtl.ID = trXtl.TrackingLogID)
	 
set @currentTestTotalTestTime = (Select sum(datediff(MINUTE,dtl.intime,
(case when (dtl.OutTime IS null) then GETUTCDATE() else dtl.outtime  end ))) 
	 from Testrecordsxtrackinglogs as trXtl, DeviceTrackingLog as dtl 
	 where trXtl.TestRecordID = @currentTestRecordID and dtl.ID = trXtl.TrackingLogID)
	 
--tlcapacity
set @selectedTLCapacityRemaining = (select tlt.UnitCapacity - (SELECT COUNT(dtl.ID)--currentcount
		                    FROM  DeviceTrackingLog AS dtl
		                                          where 
		                                           dtl.TrackingLocationID = @selectedTrackingLocationID
		                                          and (dtl.OutUser IS NULL))
		                                          
		                                          from TrackingLocations as tl, TrackingLocationTypes as tlt
		                                          where tl.id = @selectedTrackingLocationID
		                                          and tlt.ID = tl.TrackingLocationTypeID)
--teststage is valid
set @selectedTestStageIsValid = (case when (@selectedTestStageID IS NULL) then 0 else 1 end)

--testisvalid
set @selectedTestIsValid = (case when (@selectedTestID IS NULL) then 0 else 1 end)

-- is dnp'd
insert @exceptionsTable exec remispTestExceptionsGetTestUnitTable @qranumber, @unitnumber, @selectedTestStageName  
set @selectedTestIsMarkedDoNotProcess = (select (case when (TestUnitException = 'True') then 1 else 0 end) from @exceptionstable where name = @selectedTestName)

-- is in FA
set @inFA = case when (select COUNT (*) from TestRecords as tr where TestUnitID = @testUnitID and (tr.Status = 3 or tr.Status = 10 or tr.Status = 11)) > 0 then 1 else 0 end --status is FARaised

-- is in Quarantine
set @inQuarantine = case when (select COUNT (*) from TestRecords as tr where TestUnitID = @testUnitID and tr.Status = 9)>0 then 1 else 0 end --status is Quarantine


--number of scans
set @selectedLocationNumberOfScans = (select COUNT (*) from Testrecordsxtrackinglogs as trXtl, DeviceTrackingLog as dtl where trXtl.TestRecordID = @selectedTestRecordID and dtl.ID = trXtl.TrackingLogID)
--test valid for tracking location
set @selectedTestIsValidForLocation = case when (select 1 from Tests as t, TrackingLocations as tl, trackinglocationtypes as tlt, TrackingLocationsForTests as tltfort 
where tlt.ID = tltfort.TrackingLocationtypeID and t.ID = tltfort.TestID and t.ID = @selectedTestID and tlt.ID = tl.TrackingLocationTypeID and tl.ID = @selectedTrackingLocationID) IS not null then 1 else 0 end
--get applicable test stages
select @ApplicableTestStages = @ApplicableTestStages + ','  + TestStageName from TestStages where ISNULL(TestStages.IsArchived, 0)=0 AND TestStages.JobID = @jobID order by ProcessOrder
set @ApplicableTestStages = SUBSTRING(@ApplicableTestStages,2,Len(@ApplicableTestStages))
--get applicable tests
select @ApplicableTests = @ApplicableTests + ','  +  testname from Tests as t, TrackingLocationsForTests as tlft, TrackingLocationTypes as tlt , TrackingLocations as tl
where ISNULL(t.IsArchived, 0)=0 AND t.ID = tlft.TestID
and tlft.TrackingLocationtypeID = tlt.ID
and tlt.ID = tl.TrackingLocationTypeID
and tl.ID = @selectedTrackingLocationID

set @ApplicableTests = SUBSTRING(@ApplicableTests,2,Len(@ApplicableTests))

----------------------------
---  Tracking Log Params ---
----------------------------
 
 select top(1) @currentDtlID=dtl.id,
 	@currentDtlInTime =InTime, 
 	@currentDtlOutTime=OutTime,
	@currentDtlInUser=InUser, 
	@currentDtlOutUser =OutUser,
	@currentDtlTrackingLocationName=trackinglocationname , 
	@currentDtlTrackingLocationID=tl.ID
	FROM DeviceTrackingLog as dtl, TrackingLocations as tl
	WHERE (dtl.TestUnitID = @testUnitID and tl.ID = dtl.TrackingLocationID)
	order by dtl.intime desc

----------------------
--  RETURN DATA ------
----------------------
select @currentDtlID as currentDtlID,
	@testUnitID as testunitID,
 	@currentDtlInTime as currentDtlInTime, 
 	@currentDtlOutTime as currentDtlOutTime,
	@currentDtlInUser as currentDtlInUser,
	@currentDtlOutUser as currentDtlOutUser,
	@currentDtlTrackingLocationName as currentDtlTrackingLocationName, 
	@currentDtlTrackingLocationID as currentDtlTrackingLocationID,		
	@currentTeststage as currentTestStage,
	@currentTest as currentTest,
	@currentTestRecordStatus as currentTestRecordStatus,
	@currentTestRecordID as currentTestRecordID,
	@currentTestRequiredTestTime as currentTestRequiredTestTime,
	@currentTestTotalTestTime as currentTestTotalTestTime,
	@currentTestIsTimed as currenttestIsTimed,
	@currentTestType as currenttestType,	
	@batchStatus as batchStatus,
	@inFA as inFA,	
    @productGroup as productGroup,
	@jobWILocation as jobWILocation,		
	@jobName as jobName,
	@BSN as bsn,	
	@isBBX as isBBX,	
	@selectedTLCapacityRemaining as selectedTLCapacityRemaining,
	@selectedTrackingLocationName as selectedTrackingLocationName,
	@selectedTrackingLocationID as selectedTrackingLocationID,
	@selectedTestStageIsValid as selectedTestStageIsValid,
	@selectedTestIsValid as selectedTestIsValid,
	@selectedTestIsMarkedDoNotProcess as selectedTestIsMarkedDoNotProcess,
	@selectedTestType as selectedTestType, 
	@selectedTrackinglocationCurrentTestName as selectedTrackinglocationCurrentTestName,
	@selectedTestRecordStatus as selectedTestRecordStatus,
	@selectedTrackingLocationWILocation as selectedTrackingLocationWILocation ,
	@selectedTrackingLocationFunction as selectedTrackingLocationFunction,
	@selectedTestRecordID as selectedTestRecordID,
	@selectedTestIsValidForLocation as selectedTestIsValidForLocation,
	@selectedTestIsTimed as selectedTestIsTimed,
	@selectedLocationNumberOfScans as selectedLocationNumberOfScans,	
	@selectedTestRequiredTestTime as selectedTestRequiredTestTime,
	@selectedTestTotalTestTime as selectedTestTotalTestTime,		
	@cprNumber as CPRNumber,
	@hwrevision as HWRevision,		
	@ApplicableTestStages as ApplicableTestStages, 
	@ApplicableTests as ApplicableTests,
	@selectedTestID as selectedTestID,
	@productID As ProductID,
	@selectedTestWI AS selectedTestWILocation
	
	exec remispTrackingLocationsSelectForTest @selectedTestID, @selectedTrackingLocationID
	 
IF (@@ERROR != 0)
	BEGIN
		RETURN -3
	END
	ELSE
	BEGIN
		RETURN 0
	END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering permissions on [dbo].[remispTestsSelectSingleItem]'
GO
GRANT EXECUTE ON  [dbo].[remispTestsSelectSingleItem] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispTestsSelectListByTestStageID]'
GO
GRANT EXECUTE ON  [dbo].[remispTestsSelectListByTestStageID] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispTestsInsertUpdateSingleItem]'
GO
GRANT EXECUTE ON  [dbo].[remispTestsInsertUpdateSingleItem] TO [remi]
GO
IF EXISTS (SELECT * FROM #tmpErrors) ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT>0 BEGIN
PRINT 'The database update succeeded'
rollback TRANSACTION
END
ELSE PRINT 'The database update failed'
GO
DROP TABLE #tmpErrors
GO