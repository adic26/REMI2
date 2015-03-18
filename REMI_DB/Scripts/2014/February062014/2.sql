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
	@TestStageID INT = NULL,
	@FunctionalType INT = NULL
AS
BEGIN
	DECLARE @JobID INT
	DECLARE @ReturnValue INT
	
	IF (@ID is null or @ID <=0 ) --no dupes allowed here!
	BEGIN
		SET @ID = (SELECT ID FROM TestRecords WITH(NOLOCK) WHERE TestStageName = @TestStageName AND JobName = @JobName AND testname=@TestName AND testunitid=@TestUnitID)
	END
	
	if (@TestID is null and @TestName is not null)
	begin
		SELECT @TestID=ID FROM Tests WITH(NOLOCK) WHERE TestName=@TestName
	END

	if (@TestStageID is null and @TestStageName is not null)
	begin
		SELECT @JobID=ID FROM Jobs WITH(NOLOCK) WHERE JobName=@JobName
		SELECT @TestStageID=ID FROM TestStages WITH(NOLOCK) WHERE JobID=@JobID AND TestStageName=@TestStageName
	END

	IF (@ID IS NULL) -- New Item
	BEGIN
		INSERT INTO TestRecords (TestUnitID, Status, FailDocNumber, TestStageName, JobName, TestName, RelabVersion, LastUser, Comment,
			ResultSource, FailDocRQID, TestID, TestStageID, FunctionalType)
		VALUES (@TestUnitID, @Status, @FailDocNumber, @TestStageName, @JobName, @TestName, @RelabVersion, @lastUser, @Comment,
			@ResultSource, @FailDocRQID, @TestID, @TestStageID, @FunctionalType)

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
			TestStageID=@TestStageID, FunctionalType=@FunctionalType
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
PRINT N'Altering [dbo].[remispTestRecordsSelectForBatch]'
GO
ALTER PROCEDURE [dbo].[remispTestRecordsSelectForBatch] @QRANumber nvarchar(11) = null
AS
BEGIN
	SELECT tr.FailDocRQID,tr.Comment,tr.ConcurrencyID,tr.FailDocNumber,tr.ID,tr.JobName,tr.ResultSource,tr.LastUser,tr.RelabVersion,tr.Status,tr.TestName,
		tr.TestStageName,tr.TestUnitID, b.QRANumber, tu.BatchUnitNumber,
	(
		Select sum(datediff(MINUTE,dtl.intime,(case when (dtl.OutTime IS null) then GETUTCDATE() else dtl.outtime  end ))) 
		from Testrecordsxtrackinglogs trXtl WITH(NOLOCK)
			INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON dtl.ID = trXtl.TrackingLogID
		where trXtl.TestRecordID = tr.id
	) as TotalTestTimeMinutes,
	(
		select COUNT (*)
		from Testrecordsxtrackinglogs as trXtl WITH(NOLOCK)
			INNER JOIN DeviceTrackingLog as dtl WITH(NOLOCK) ON dtl.ID = trXtl.TrackingLogID
		where trXtl.TestRecordID = tr.id
	) as NumberOfTests, tr.TestID, tr.TestStageID, tr.FunctionalType
	FROM TestRecords as tr WITH(NOLOCK)
		INNER JOIN testunits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
		INNER JOIN Batches b WITH(NOLOCK) ON b.id = tu.batchid
	WHERE b.QRANumber = @QRANumber
	ORDER BY tr.TestStageName, tr.TestName, tr.TestUnitID
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestRecordsSelectOne]'
GO
ALTER PROCEDURE [dbo].[remispTestRecordsSelectOne] @ID int= null
AS
BEGIN	
	SELECT tr.Comment,tr.ConcurrencyID,tr.FailDocNumber,tr.ID,tr.JobName,tr.LastUser,tr.ResultSource,tr.RelabVersion,tr.Status,tr.TestName,tr.TestStageName,tr.TestUnitID, b.QRANumber, tu.BatchUnitNumber
	,(Select sum(datediff(MINUTE,dtl.intime,(case when (dtl.OutTime IS null) then GETUTCDATE() else dtl.outtime  end ))) 
	 from Testrecordsxtrackinglogs as trXtl, DeviceTrackingLog as dtl where trXtl.TestRecordID = tr.id and dtl.ID = trXtl.TrackingLogID
	) as TotalTestTimeMinutes
	,(select COUNT (*) as NumberOfTests from Testrecordsxtrackinglogs as trXtl, DeviceTrackingLog as dtl where trXtl.TestRecordID = tr.id and dtl.ID = trXtl.TrackingLogID
	) as NumberOfTests, tr.TestID, tr.TestStageID, tr.FunctionalType
	FROM TestRecords tr WITH(NOLOCK)
		INNER JOIN testunits tu WITH(NOLOCK) ON tu.ID=tr.TestUnitID
		INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
	WHERE tr.ID = @id
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestRecordsSelectByStatus]'
GO
ALTER PROCEDURE [dbo].[remispTestRecordsSelectByStatus] @status int= null
AS
BEGIN
	SELECT tr.Comment,tr.ConcurrencyID,tr.FailDocNumber,tr.ID,tr.JobName,tr.ResultSource,tr.LastUser,tr.RelabVersion,tr.Status,tr.TestName,tr.TestStageName,tr.TestUnitID, b.QRANumber, tu.BatchUnitNumber
	,(Select sum(datediff(MINUTE,dtl.intime,(case when (dtl.OutTime IS null) then GETUTCDATE() else dtl.outtime  end ))) 
	 from Testrecordsxtrackinglogs as trXtl, DeviceTrackingLog as dtl where trXtl.TestRecordID = tr.id and dtl.ID = trXtl.TrackingLogID
	) as TotalTestTimeMinutes
	,(select COUNT (*) as NumberOfTests from Testrecordsxtrackinglogs as trXtl, DeviceTrackingLog as dtl where trXtl.TestRecordID = tr.id and dtl.ID = trXtl.TrackingLogID
	) as NumberOfTests, tr.TestID, tr.TestStageID, tr.FunctionalType
	FROM TestRecords as tr,  testunits as tu, Batches as b
	                    
	WHERE tr.Status = @status and  tu.batchid = b.id and tu.ID = tr.TestUnitID 
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Relab].[FunctionalMatrixByTestRecord]'
GO
ALTER PROCEDURE [Relab].[FunctionalMatrixByTestRecord] @TRID INT = NULL, @TestStageID INT, @TestID INT, @BatchID INT, @UnitIDs NVARCHAR(MAX) = NULL, @FunctionalType INT
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @TestUnitID INT
	DECLARE @rows VARCHAR(8000)
	DECLARE @sql VARCHAR(8000)
	DECLARE @LookupType NVARCHAR(20)
	CREATE Table #units(id int) 
	
	IF (@TRID IS NOT NULL)
	BEGIN
		SELECT @TestUnitID = TestUnitID FROM TestRecords WHERE ID=@TRID
		INSERT INTO #units VALUES (@TestUnitID)
	END
	ELSE
	BEGIN
		EXEC(@UnitIDs)
	END
	
	IF (@FunctionalType = 1)
		SET @LookupType = 'SFIFunctionalMatrix'
	ELSE IF (@FunctionalType = 2)
		SET @LookupType = 'MFIFunctionalMatrix'
	ELSE IF (@FunctionalType = 3)
		SET @LookupType = 'AccFunctionalMatrix'
	ELSE
		SET @LookupType = 'SFIFunctionalMatrix'
	
	SELECT @rows=  ISNULL(STUFF(
		(SELECT DISTINCT '],[' + l.[Values]
		FROM dbo.Lookups l
		WHERE Type=@LookupType
		ORDER BY '],[' +  l.[Values]
		FOR XML PATH('')), 1, 2, '') + ']','[na]')
	
	SET @sql = 'SELECT *
		FROM (
			SELECT l.[Values], tu.ID AS TestUnitID, tu.BatchUnitNumber, 
				CASE 
					WHEN r.ID IS NULL 
					THEN -1
					ELSE (
						SELECT PassFail 
						FROM Relab.ResultsMeasurements rm 
							LEFT OUTER JOIN Lookups lr ON lr.Type=''' + CONVERT(VARCHAR, @LookupType) + ''' AND rm.MeasurementTypeID=lr.LookupID
						WHERE rm.ResultID=r.ID AND lr.[values] = l.[values] AND rm.Archived = 0)
				END As Row
			FROM dbo.Lookups l
			INNER JOIN TestUnits tu ON tu.BatchID = ' + CONVERT(VARCHAR, @BatchID) + ' AND 
				(
					(' + CONVERT(VARCHAR, ISNULL(CONVERT(VARCHAR,@TestUnitID), 'NULL')) + ' IS NULL)
					OR
					(' + CONVERT(VARCHAR, ISNULL(CONVERT(VARCHAR,@TestUnitID), 'NULL')) + ' IS NOT NULL AND tu.ID=' + CONVERT(VARCHAR, ISNULL(CONVERT(VARCHAR,@TestUnitID), 'NULL')) + ')
				)
			INNER JOIN #units ON tu.ID=#units.ID
			LEFT OUTER JOIN Relab.Results r ON r.TestID = ' + CONVERT(VARCHAR, @TestID) + ' AND r.TestStageID = ' + CONVERT(VARCHAR, @TestStageID) + ' 
				AND r.TestUnitID = tu.ID
			WHERE l.Type=''' + CONVERT(VARCHAR, @LookupType) + '''
			) te 
			PIVOT (MAX(row) FOR [Values] IN (' + @rows + ')) AS pvt
			ORDER BY BatchUnitNumber'

	PRINT @sql
	EXEC(@sql)
	
	SET NOCOUNT OFF
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
	DECLARE @txID int
	
	If (@TestName = '')
		SET @TestName = NULL
	
	IF (@TestUnitID IS NULL)
		SET @TestUnitID = (SELECT ID FROM TestUnits WHERE BatchID = (SELECT ID FROM Batches WHERE QRANumber = @QRAnumber) and BatchUnitNumber = @BatchUnitNumber)
	
	if (@teststageid is null and @TestStageName is not null)
	begin
		SET @TestStageID = (SELECT ts.ID 
						FROM TestStages ts
							INNER JOIN Jobs j ON j.ID = ts.JobID
							INNER JOIN Batches b ON b.JobName = j.JobName
							INNER JOIN TestUnits tu ON tu.BatchID = b.ID
						WHERE tu.ID=@TestUnitID AND ts.TestStageName = @TestStageName)
	END
	
	select * from vw_ExceptionsPivoted where ID=1060448 
	print @teststageid
	
	IF (@TestName IS NOT NULL AND (SELECT COUNT(*) FROM Tests WHERE TestName=@TestName) = 1)
	BEGIN
		SET @TestID = (SELECT ID FROM Tests WHERE TestName=@TestName)

		SET @txID = (SELECT ID 
				FROM vw_ExceptionsPivoted 
				WHERE TestUnitID = @TestUnitID 
					AND 
					(
						(@TestID IS NOT NULL AND Test = @TestID)
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
	END
	ELSE IF (@TestName IS NOT NULL AND (SELECT COUNT(*) FROM Tests WHERE TestName=@TestName) > 1)
	BEGIN
		SELECT ID
		INTO #temp
		FROM vw_ExceptionsPivoted 
		WHERE TestUnitID = @TestUnitID 
			AND 
			(
				Test IN (SELECT ID FROM Tests WHERE TestName=@TestName)
			)
			AND 
			(
				TestStageID = @TestStageID 
				OR
				(
					@TestStageId IS NULL AND TestStageID IS NULL
				)
			)
		UPDATE TestExceptions SET LastUser = @LastUser WHERE TestExceptions.ID IN (SELECT ID FROM #temp)
		DELETE FROM TestExceptions WHERE TestExceptions.ID IN (SELECT ID FROM #temp)
		
		SET @txID = (SELECT TOP 1 ID FROM #temp)
		DROP TABLE #temp
	END
	ELSE IF (@TestStageName IS NOT NULL And @TestStageID IS NOT NULL)
	BEGIN
		SET @txID = (SELECT ID 
				FROM vw_ExceptionsPivoted 
				WHERE TestUnitID = @TestUnitID 
					AND 
					(
						@TestID IS NULL AND Test IS NULL
					)
					AND 
					(
						TestStageID = @TestStageID
					)
				)
		
		--set the deleting user
		UPDATE TestExceptions SET LastUser = @LastUser WHERE TestExceptions.ID = @txid
		
		--finally delete the item
		DELETE FROM TestExceptions WHERE TestExceptions.ID = @txid
	END
	ELSE
	BEGIN
		SET @txID = 0
	END
	
	RETURN @txid
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Relab].[remispResultsFileProcessing]'
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
		DECLARE @TestID INT
		DECLARE @TrackingLocationTypeName NVARCHAR(200)
		DECLARE @LookupTypeName NVARCHAR(100)
		DECLARE @FunctionalType INT

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
		
		SELECT @TestID = TestID FROM Relab.Results WHERE ID=@ResultID
		
		SELECT @TrackingLocationTypeName =tlt.TrackingLocationTypeName
		FROM Tests t
		INNER JOIN TrackingLocationsForTests tlft ON tlft.TestID=t.ID
		INNER JOIN TrackingLocationTypes tlt ON tlft.TrackingLocationtypeID=tlt.ID
		WHERE t.ID=@TestID
		
		PRINT '# Files To Process: ' + CONVERT(VARCHAR, @Val)
		PRINT 'XMLID: ' + CONVERT(VARCHAR, @ID)
		PRINT 'ResultID: ' + CONVERT(VARCHAR, @ResultID)
		PRINT 'TestID: ' + CONVERT(VARCHAR, @TestID)
		PRINT 'TrackingLocationTypeName: ' + CONVERT(VARCHAR, @TrackingLocationTypeName)

		SELECT @xmlPart = T.c.query('.') 
		FROM @xml.nodes('/TestResults/Header') T(c)
				
		select @EndDate = T.c.query('DateCompleted').value('.', 'nvarchar(max)'),
			@Duration = T.c.query('Duration').value('.', 'nvarchar(max)'),
			@StationName = T.c.query('StationName').value('.', 'nvarchar(400)'),
			@FunctionalType = T.c.query('FunctionalType').value('.', 'nvarchar(400)')
		FROM @xmlPart.nodes('/Header') T(c)

		SELECT @EndDate= STUFF(@EndDate, CHARINDEX('-',@EndDate,(charindex('-',@EndDate, (charindex('-',@EndDate)+1))+1)), 1, ' ')
		SELECT @EndDate= STUFF(@EndDate, CHARINDEX('-',@EndDate,(charindex('-',@EndDate, (charindex('-',@EndDate)+1))+1)), 1, ':')
		SELECT @EndDate= STUFF(@EndDate, CHARINDEX('-',@EndDate,(charindex('-',@EndDate, (charindex('-',@EndDate)+1))+1)), 1, ':')
				
		If (CHARINDEX('.', @Duration) > 0)
			SET @Duration = SUBSTRING(@Duration, 1, CHARINDEX('.', @Duration)-1)
		
		SET @StartDate=dateadd(s,-datediff(s,0,convert(DATETIME,@Duration)), CONVERT(DATETIME, @EndDate))
	
		IF (@TrackingLocationTypeName IS NOT NULL And @TrackingLocationTypeName = 'Functional Station')
		BEGIN
			IF (@FunctionalType = 1)
			BEGIN
				SET @LookupTypeName = 'SFIFunctionalMatrix'
			END
			ELSE IF (@FunctionalType = 2)
			BEGIN
				SET @LookupTypeName = 'MFIFunctionalMatrix'
			END
			ELSE IF (@FunctionalType = 3)
			BEGIN
				SET @LookupTypeName = 'AccFunctionalMatrix'
			END
			
			PRINT 'Test IS SFI/MFI/Acc type'
		END
		ELSE
		BEGIN
			SET @LookupTypeName = 'MeasurementType'
			
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
		END
		
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
				T.c.query('Comments').value('.', 'nvarchar(400)') AS [Comment],
				T.c.query('Description').value('.', 'nvarchar(800)') AS [Description]
			INTO #measurement
			FROM @xmlPart.nodes('/Measurement') T(c)
				LEFT OUTER JOIN Lookups l ON l.Type='UnitType' AND l.[Values]=LTRIM(RTRIM(CONVERT(VARCHAR(MAX), T.c.query('Units').value('.', 'nvarchar(max)'))))
				LEFT OUTER JOIN Lookups l2 ON l2.Type=@LookupTypeName AND l2.[Values]=LTRIM(RTRIM(CONVERT(VARCHAR(MAX), T.c.query('MeasurementName').value('.', 'nvarchar(max)'))))

			UPDATE #measurement
			SET Comment=''
			WHERE Comment='N/A'
						
			UPDATE #measurement
			SET Description=null
			WHERE Description='N/A' or Description='NA'

			IF (@VerNum = 1)
			BEGIN
				PRINT 'INSERT Version 1 Measurements'
				INSERT INTO Relab.ResultsMeasurements (ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, MeasurementUnitTypeID, PassFail, ReTestNum, Archived, XMLID, Comment, Description)
				SELECT @ResultID As ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, UnitTypeID, CONVERT(BIT, PassFail), 1, 0, @ID, Comment, Description
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
					INSERT INTO Relab.ResultsMeasurements (ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, MeasurementUnitTypeID, PassFail, ReTestNum, Archived, XMLID, Comment, Description)
					SELECT @ResultID As ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, UnitTypeID, CONVERT(BIT, PassFail), @ReTestNum, 0, @ID, Comment, Description
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
					INSERT INTO Relab.ResultsMeasurements (ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, MeasurementUnitTypeID, PassFail, ReTestNum, Archived, XMLID, Comment, Description)
					SELECT @ResultID As ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, UnitTypeID, CONVERT(BIT, PassFail), 1, 0, @ID, Comment, Description
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
	WHERE TestType=1 AND ID NOT IN (202, 1073, 1185, 1020, 1212, 1211, 1280)
		AND ISNULL(IsArchived, 0) = 0
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
PRINT N'Altering [Relab].[remispResultMeasurements]'
GO
ALTER PROCEDURE [Relab].[remispResultMeasurements] @ResultID INT, @OnlyFails INT = 0, @IncludeArchived INT = 0
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @FalseBit BIT
	DECLARE @ReTestNum INT
	CREATE TABLE #parameters (ResultMeasurementID INT)
	SELECT @ReTestNum= MAX(Relab.ResultsMeasurements.ReTestNum) FROM Relab.ResultsMeasurements WITH(NOLOCK) WHERE Relab.ResultsMeasurements.ResultID=@ResultID
	SET @FalseBit = CONVERT(BIT, 0)

	DECLARE @rows VARCHAR(8000)
	DECLARE @sql VARCHAR(8000)
	SELECT @rows=  ISNULL(STUFF(
		( 
		SELECT DISTINCT '],[' + rp.ParameterName
		FROM Relab.ResultsMeasurements rm WITH(NOLOCK)
			LEFT OUTER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON rm.ID=rp.ResultMeasurementID
		WHERE ResultID=@ResultID AND ((@IncludeArchived = 0 AND rm.Archived=@FalseBit) OR (@IncludeArchived=1)) AND ((@OnlyFails = 1 AND PassFail=@FalseBit) OR (@OnlyFails = 0))
		ORDER BY '],[' +  rp.ParameterName
		FOR XML PATH('')), 1, 2, '') + ']','[na]')

	SET @sql = 'ALTER TABLE #parameters ADD ' + convert(varchar(8000), replace(@rows, ']', '] NVARCHAR(250)'))
	EXEC (@sql)

	IF (@rows != '[na]')
	BEGIN
		EXEC ('INSERT INTO #parameters SELECT *
		FROM (
			SELECT rp.ResultMeasurementID, rp.ParameterName, rp.Value
			FROM Relab.ResultsMeasurements rm WITH(NOLOCK)
				LEFT OUTER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON rm.ID=rp.ResultMeasurementID
			WHERE ResultID=' + @ResultID + ' AND ((' + @IncludeArchived + ' = 0 AND rm.Archived=' + @FalseBit + ') OR (' + @IncludeArchived + '=1)) 
				AND ((' + @OnlyFails + ' = 1 AND PassFail=' + @FalseBit + ') OR (' + @OnlyFails + ' = 0))
			) te PIVOT (MAX(Value) FOR ParameterName IN (' + @rows + ')) AS pvt')
	END
	ELSE
	BEGIN
		EXEC ('ALTER TABLE #parameters DROP COLUMN na')
	END

	SELECT CASE WHEN rm.Archived = 1 THEN 
	(SELECT MIN(ID) FROM relab.ResultsMeasurements rm2 WHERE rm2.ResultID=rm.ResultID AND rm2.MeasurementTypeID=rm.MeasurementTypeID 
		and isnull(Relab.ResultsParametersComma(rm.ID),'') = isnull(Relab.ResultsParametersComma(rm2.ID),'') and rm2.Archived=0)
	
	ELSE rm.ID END AS ID, ISNULL(ISNULL(ISNULL(lt.[Values], ltsf.[Values]), ltmf.[Values]), ltacc.[Values]) As Measurement, LowerLimit AS [Lower Limit], UpperLimit AS [Upper Limit], MeasurementValue AS Result, lu.[Values] As Unit, 
		CASE WHEN PassFail=1 THEN 'Pass' ELSE 'Fail' END AS [Pass/Fail],
		rm.MeasurementTypeID, rm.ReTestNum AS [Test Num], rm.Archived, rm.XMLID, 
		@ReTestNum AS MaxVersion, rm.Comment, ISNULL(rmf.[File], 0) AS [Image], 
		ISNULL(UPPER(SUBSTRING(rmf.ContentType,2,LEN(rmf.ContentType))), 'PNG') AS ContentType, rm.Description, 
		ISNULL((SELECT TOP 1 1 FROM Relab.ResultsMeasurementsAudit rma WHERE rma.ResultMeasurementID=rm.ID AND rma.PassFail <> rm.PassFail ORDER BY DateEntered DESC), 0) As WasChanged,
		p.*
	FROM Relab.ResultsMeasurements rm WITH(NOLOCK)
		LEFT OUTER JOIN Lookups lu WITH(NOLOCK) ON lu.Type='UnitType' AND lu.LookupID=rm.MeasurementUnitTypeID
		LEFT OUTER JOIN Lookups lt WITH(NOLOCK) ON lt.Type='MeasurementType' AND lt.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Lookups ltsf WITH(NOLOCK) ON ltsf.Type='SFIFunctionalMatrix' AND ltsf.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Lookups ltmf WITH(NOLOCK) ON ltmf.Type='MFIFunctionalMatrix' AND ltmf.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Lookups ltacc WITH(NOLOCK) ON ltacc.Type='AccFunctionalMatrix' AND ltacc.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Relab.ResultsMeasurementsFiles rmf WITH(NOLOCK) ON rmf.ResultMeasurementID=rm.ID
		LEFT OUTER JOIN #parameters p WITH(NOLOCK) ON p.ResultMeasurementID=rm.ID
	WHERE rm.ResultID=@ResultID AND ((@IncludeArchived = 0 AND rm.Archived=@FalseBit) OR (@IncludeArchived=1)) AND ((@OnlyFails = 1 AND PassFail=@FalseBit) OR (@OnlyFails = 0))
	ORDER BY CASE WHEN rm.Archived = 1 THEN 
	(SELECT MIN(ID) FROM relab.ResultsMeasurements rm2 WHERE rm2.ResultID=rm.ResultID AND rm2.MeasurementTypeID=rm.MeasurementTypeID 
		and isnull(Relab.ResultsParametersComma(rm.ID),'') = isnull(Relab.ResultsParametersComma(rm2.ID),'') and rm2.Archived=0)
	ELSE rm.ID END, rm.ReTestNum

	DROP TABLE #parameters
	SET NOCOUNT OFF
END
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
	@trackingLocationName nvarchar(255) = null
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
declare @selectedTestStageID int
declare @selectedTestID int
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
declare @accessoryTypeID INT
declare @productTypeID INT
declare @accessoryType NVARCHAR(150)
declare @productType NVARCHAR(150)
Declare @NoBSN BIT

--jobname, product group, job WI, jobID
select @jobName=b.jobname,@cprNumber =b.CPRNumber,@hwrevision = b.HWRevision, @productGroup=p.ProductGroupName,@jobWILocation=j.WILocation,@jobid=j.ID, @batchStatus = b.BatchStatus ,
@productID=p.ID, @NoBSN=j.NoBSN, @productTypeID=b.ProductTypeID, @accessoryTypeID=b.AccessoryGroupID
from Batches as b
	INNER JOIN jobs as j ON j.JobName = b.JobName
	INNER JOIN Products p ON p.ID=b.ProductID
where b.QRANumber = @qranumber

SELECT @productType=[values] FROM Lookups WHERE LookupID=@productTypeID
SELECT @accessoryType=[values] FROM Lookups WHERE LookupID=@accessoryTypeID

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

select @selectedTestStageID = ts.id 
from teststages as ts
where ts.JobID = @jobID and ts.TestStageName = @selectedTestStageName

--selected test details

SELECT  @selectedTestID=t.ID, @selectedTestIsTimed =t.resultbasedontime,@selectedTestType = t.TestType, @selectedTestWI = t.WILocation
from Tests AS t, TestStages as ts
WHERE ts.ID = @selectedTestStageID  
and (
		(ts.TestStagetype = 2 and t.TestName=ts.teststagename and t.TestName = @selectedTestName and t.id = ts.TestID) --if its an env teststage get the equivelant test
		or (ts.teststagetype = 1 and t.testtype = 1 and t.TestName = @selectedTestName)--otherwise if its a para test stage get the para test
		or (ts.teststagetype = 3 and t.testtype = 3 and t.TestName = @selectedTestName) --or the incoming eval test
	)
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
	@selectedTestWI AS selectedTestWILocation, @NoBSN AS NoBSN, @productType AS ProductType, @productTypeID AS ProductTypeID, @accessoryType AS AccessoryType, @accessoryTypeID AS AccessoryTypeID
	
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
ALTER PROCEDURE remispGetEstimatedTSTime @BatchID INT, @TestStageName NVARCHAR(400), @JobName NVARCHAR(400), @TSTimeLeft REAL OUTPUT, @JobTimeLeft REAL OUTPUT,
	@TestStageID INT = NULL, @JobID INT = NULL, @ReturnTestStageGrid INT = 0
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @TestUnitID INT
	DECLARE @BatchUnitNumber INT
	DECLARE @ProcessOrder INT
	DECLARE @TaskID INT
	DECLARE @resultbasedontime INT
	DECLARE @TotalTestTimeMinutes REAL
	DECLARE @Status INT
	DECLARE @BatchStatus INT
	DECLARE @UnitTotalTime REAL
	DECLARE @expectedDuration REAL
	DECLARE @StressingTimeOverage REAL -- How much stressing time to minus from job remaining time
	DECLARE @TestType INT
	DECLARE @TSID INT
	DECLARE @TID INT
	SET @TSTimeLeft = 0
	SET @JobTimeLeft = 0
	SET @StressingTimeOverage = 0

	IF (@JobID IS NULL OR @JobID = 0)
		SELECT @JobID = ID FROM Jobs WHERE JobName=@JobName

	IF (@TestStageID IS NULL OR @TestStageID = 0)
		SELECT @TestStageID = ID FROM TestStages WHERE TestStageName=@TestStageName AND JobID=@JobID

	SELECT ID AS TestUnitID
	INTO #tempUnits
	FROM TestUnits WITH(NOLOCK)
	WHERE BatchID=@BatchID
	ORDER BY TestUnitID
	
	SELECT @BatchStatus = BatchStatus FROM Batches WHERE ID=@BatchID

	CREATE TABLE #Tasks (ID INT IDENTITY(1, 1), tname NVARCHAR(400), resultbasedontime INT, expectedDuration REAL, processorder INT, tsname NVARCHAR(400), testtype INT, TestID INT, TestStageID INT)
	CREATE TABLE #Stressing (TestStageID INT, NumUnits INT, StressingTime REAL)
	CREATE TABLE #TestStagesTimes (TestStageID INT, ProcessOrder INT, TimeLeft REAL)

	IF (@BatchStatus = 5)
	BEGIN
		INSERT INTO #Tasks (tname, resultbasedontime,expectedDuration, processorder, tsname, TestType, TestID, TestStageID)
		SELECT tname, resultbasedontime,expectedDuration, processorder, tsname, TestType, TestID, TestStageID
		FROM vw_GetTaskInfoCompleted WITH(NOLOCK)
		WHERE BatchID=@BatchID AND testtype IN (1,2)
		ORDER BY processorder
	END
	ELSE
	BEGIN
		INSERT INTO #Tasks (tname, resultbasedontime,expectedDuration, processorder, tsname, TestType, TestID, TestStageID)
		SELECT tname, resultbasedontime,expectedDuration, processorder, tsname, TestType, TestID, TestStageID
		FROM vw_GetTaskInfo WITH(NOLOCK)
		WHERE BatchID=@BatchID AND testtype IN (1,2)
		ORDER BY processorder
	END
	
	DELETE FROM #Tasks WHERE processorder < 0
	
	SELECT @TestUnitID =MIN(TestUnitID) FROM #tempUnits

	WHILE (@TestUnitID IS NOT NULL)
	BEGIN
		SET @UnitTotalTime = 0

		SELECT @TaskID = MIN(ID) FROM #Tasks
			
		WHILE (@TaskID IS NOT NULL)
		BEGIN
			SELECT @resultbasedontime=resultbasedontime,@expectedDuration=expectedDuration, @ProcessOrder=processorder, @TestType = TestType, @TSID = TestStageID, @TID = TestID
			FROM #Tasks 
			WHERE ID = @TaskID

			--Test has not been done so add expected duration to overall unit time.
			IF NOT EXISTS (SELECT TOP 1 1 FROM TestRecords WITH(NOLOCK) WHERE TestStageID = @TSID AND TestUnitID=@TestUnitID AND TestID=@TID)
				BEGIN
					IF (@TSID = @TestStageID)
					BEGIN
						SET @TSTimeLeft += @expectedDuration
					END
					If (@TestType = 2)
					BEGIN
						IF EXISTS (SELECT 1 FROM #Stressing WHERE TestStageID=@TSID)
						BEGIN
							UPDATE #Stressing
							SET NumUnits +=1, StressingTime += @expectedDuration
							WHERE TestStageID=@TSID
						END
						ELSE
						BEGIN
							INSERT INTO #Stressing VALUES (@TSID, 1, @expectedDuration)
						END
					END
					ELSE
					BEGIN
						SET @UnitTotalTime += @expectedDuration
					END
					
					IF EXISTS (SELECT 1 FROM #TestStagesTimes WHERE TestStageID=@TSID)
					BEGIN
						UPDATE #TestStagesTimes
						SET TimeLeft += @expectedDuration
						WHERE TestStageID=@TSID
					END
					ELSE
					BEGIN
						INSERT INTO #TestStagesTimes VALUES (@TSID, @ProcessOrder, @expectedDuration)
					END					
				END
			ELSE --Test Record exists
				BEGIN
					--Get Status of test record and how long it has currently been running
					select @Status = Status, @TotalTestTimeMinutes = 
						(
							Select sum(datediff(MINUTE,dtl.intime,(case when (dtl.OutTime IS null) then GETUTCDATE() else dtl.outtime  end ))) 
							from Testrecordsxtrackinglogs as trXtl WITH(NOLOCK)
								INNER JOIN DeviceTrackingLog as dtl WITH(NOLOCK) ON dtl.ID = trXtl.TrackingLogID
							where trXtl.TestRecordID = TestRecords.id
						)
					FROM TestRecords WITH(NOLOCK)
					WHERE TestStageID = @TSID AND TestUnitID=@TestUnitID AND TestID=@TID

					If (@Status IN (0, 8, 12)) -- 0: NoSet, 8: In Progress, 12: TestingSuspended
					BEGIN
						IF (@resultbasedontime = 1)
							BEGIN
								--PRINT 'Result Based On Time: ' + CONVERT(VARCHAR, @Status) + ' = ' + CONVERT(VARCHAR, @TotalTestTimeMinutes) + ' = ' + CONVERT(VARCHAR, @expectedDuration)

								--Test isn't done and the total test time in minutes divided by 60 = hrs <= expected duration
   								IF ((@TotalTestTimeMinutes/60) <= @expectedDuration)--Test isn't done
								BEGIN
									If (@TestType = 2)
									BEGIN										
										IF EXISTS (SELECT 1 FROM #Stressing WHERE TestStageID=@TSID)
										BEGIN
											UPDATE #Stressing
											SET NumUnits +=1, StressingTime += (@expectedDuration - (@TotalTestTimeMinutes/60))
											WHERE TestStageID=@TSID
										END
										ELSE
										BEGIN
											INSERT INTO #Stressing VALUES (@TSID, 1, (@expectedDuration - (@TotalTestTimeMinutes/60)))
										END
									END
									ELSE
									BEGIN
										--Add time by taking expected hrs and minusing total test time hours
										SET @UnitTotalTime += (@expectedDuration - (@TotalTestTimeMinutes/60))
									END
									
									IF (@TSID = @TestStageID)
									BEGIN
										SET @TSTimeLeft += (@expectedDuration - (@TotalTestTimeMinutes/60))
									END
					
									IF EXISTS (SELECT 1 FROM #TestStagesTimes WHERE TestStageID=@TSID)
									BEGIN
										UPDATE #TestStagesTimes
										SET TimeLeft += (@expectedDuration - (@TotalTestTimeMinutes/60))
										WHERE TestStageID=@TSID
									END
									ELSE
									BEGIN
										INSERT INTO #TestStagesTimes VALUES (@TSID, @ProcessOrder, (@expectedDuration - (@TotalTestTimeMinutes/60)))
									END
								END
							END
						ELSE
							BEGIN
								If (@TestType = 2)
								BEGIN
									IF EXISTS (SELECT 1 FROM #Stressing WHERE TestStageID=@TSID)
									BEGIN
										UPDATE #Stressing
										SET NumUnits +=1, StressingTime += @expectedDuration
										WHERE TestStageID=@TSID
									END
									ELSE
									BEGIN
										INSERT INTO #Stressing VALUES (@TSID, 1, @expectedDuration)
									END
								END
								ELSE
								BEGIN								
									--PRINT 'Result Not Based On Time'
									SET @UnitTotalTime += @expectedDuration
								END
								IF (@TSID = @TestStageID)
								BEGIN
									SET @TSTimeLeft += @expectedDuration
								END
					
								IF EXISTS (SELECT 1 FROM #TestStagesTimes WHERE TestStageID=@TSID)
								BEGIN
									UPDATE #TestStagesTimes
									SET TimeLeft += @expectedDuration
									WHERE TestStageID=@TSID
								END
								ELSE
								BEGIN
									INSERT INTO #TestStagesTimes VALUES (@TSID, @ProcessOrder, @expectedDuration)
								END
							END
					END
				END
			SELECT @TaskID =MIN(ID) FROM #Tasks WHERE ID > @TaskID
		END

		SET @JobTimeLeft += @UnitTotalTime
		
		SELECT @TestUnitID = MIN(TestUnitID) FROM #tempUnits WHERE TestUnitID > @TestUnitID
	END

	IF ((SELECT COUNT(*) FROM #Stressing) > 0)
	BEGIN
		SELECT @StressingTimeOverage = SUM(StressingTime/NumUnits) FROM #Stressing

		IF EXISTS (SELECT 1 FROM #Stressing WHERE TestStageID=@TestStageID)
			SET @TSTimeLeft = @TSTimeLeft / ISNULL((SELECT NumUnits FROM #Stressing WHERE TestStageID = @TestStageID),0) --If currently at a stressing stage
	END
	
	UPDATE tst
	SET tst.TimeLeft = (TimeLeft / NumUnits)
	FROM #TestStagesTimes tst
		INNER JOIN #Stressing s ON tst.TestStageID=s.TestStageID
		
	SET @JobTimeLeft += @StressingTimeOverage

	--PRINT CONVERT(CHAR(10),DATEADD(SECOND, CAST(@JobTimeLeft * 3600 AS INT), 0),108)
	PRINT @JobTimeLeft
	--PRINT CONVERT(CHAR(10),DATEADD(SECOND, CAST(@TSTimeLeft * 3600 AS INT), 0),108)
	PRINT @TSTimeLeft
	
	IF (@ReturnTestStageGrid = 1)
	BEGIN
		SELECT tst.TimeLeft, ts.TestStageName, tst.TestStageID
		FROM #TestStagesTimes tst
			INNER JOIN TestStages ts ON ts.ID=tst.TestStageID
		ORDER BY tst.ProcessOrder
	END

	DROP TABLE #Tasks
	DROP TABLE #tempUnits
	DROP TABLE #Stressing
	DROP TABLE #TestStagesTimes
	SET NOCOUNT OFF
END
GO
GRANT EXECUTE ON remispGetEstimatedTSTime TO Remi
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
IF EXISTS (SELECT * FROM #tmpErrors) ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT>0 BEGIN
PRINT 'The database update succeeded'
commit TRANSACTION
END
ELSE PRINT 'The database update failed'
GO
DROP TABLE #tmpErrors
GO