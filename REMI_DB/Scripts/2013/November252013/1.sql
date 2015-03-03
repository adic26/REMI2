begin tran
go
insert into Tests (TestName, Duration, TestType, WILocation,Comment,LastUser,ResultBasedOntime,IsArchived) values ('Status', 0,5,null,null,'ogaudreault',0,0)
go

update batches
set batchstatus=8
where batchstatus=9
Go
ALTER PROCEDURE [dbo].[remispBatchesSearch]
	@ByPassProductCheck INT = 0,
	@ExecutingUserID int,
	@Status int = null,
	@Priority int = null,
	@UserID int = null,
	@TrackingLocationID int = null,
	@TestStageID int = null,
	@TestID int = null,
	@ProductTypeID int = null,
	@ProductID int = null,
	@AccessoryGroupID int = null,
	@GeoLocationID INT = null,
	@JobName nvarchar(400) = null,
	@RequestReason int = null,
	@StartRowIndex int = null,
	@MaximumRows int = null,
	@BatchStart DateTime = NULL,
	@BatchEnd DateTime = NULL,
	@TestStage NVARCHAR(400) = NULL,
	@TestStageType INT = NULL,
	@excludedTestStageType INT = NULL,
	@ExcludedStatus INT = NULL,
    @TrackingLocationFunction INT = NULL,
	@NotInTrackingLocationFunction INT  = NULL	
AS
	DECLARE @TestName NVARCHAR(400)
	DECLARE @TestStageName NVARCHAR(400)
	
	SELECT @TestName = TestName FROM Tests WITH(NOLOCK) WHERE ID=@TestID 
	SELECT @TestStageName = TestStageName FROM TestStages WITH(NOLOCK) WHERE ID=@TestStageID
	CREATE TABLE #ExTestStageType (ID INT)
	CREATE TABLE #ExBatchStatus (ID INT)
	
	IF (@TestStageName IS NOT NULL)
		SET @TestStage = NULL
	
	IF convert(VARCHAR,(@excludedTestStageType & 1) / 1) = 1
	BEGIN
		INSERT INTO #ExTestStageType VALUES (1)
	END
	IF convert(VARCHAR,(@excludedTestStageType & 2) / 2) = 1
	BEGIN
		INSERT INTO #ExTestStageType VALUES (2)
	END
	IF convert(VARCHAR,(@excludedTestStageType & 4) / 4) = 1
	BEGIN
		INSERT INTO #ExTestStageType VALUES (3)
	END
	IF convert(VARCHAR,(@excludedTestStageType & 8) / 8) = 1
	BEGIN
		INSERT INTO #ExTestStageType VALUES (4)
	END
	IF convert(VARCHAR,(@excludedTestStageType & 16) / 16) = 1
	BEGIN
		INSERT INTO #ExTestStageType VALUES (5)
	END
		
	IF convert(VARCHAR,(@ExcludedStatus & 1) / 1) = 1
	BEGIN
		INSERT INTO #ExBatchStatus VALUES (1)
	END
	IF convert(VARCHAR,(@ExcludedStatus & 2) / 2) = 1
	BEGIN
		INSERT INTO #ExBatchStatus VALUES (2)
	END
	IF convert(VARCHAR,(@ExcludedStatus & 4) / 4) = 1
	BEGIN
		INSERT INTO #ExBatchStatus VALUES (3)
	END
	IF convert(VARCHAR,(@ExcludedStatus & 8) / 8) = 1
	BEGIN
		INSERT INTO #ExBatchStatus VALUES (4)
	END
	IF convert(VARCHAR,(@ExcludedStatus & 16) / 16) = 1
	BEGIN
		INSERT INTO #ExBatchStatus VALUES (5)
	END
	IF convert(VARCHAR,(@ExcludedStatus & 32) / 32) = 1
	BEGIN
		INSERT INTO #ExBatchStatus VALUES (6)
	END
	IF convert(VARCHAR,(@ExcludedStatus & 64) / 64) = 1
	BEGIN
		INSERT INTO #ExBatchStatus VALUES (7)
	END
	IF convert(VARCHAR,(@ExcludedStatus & 128) / 128) = 1
	BEGIN
		INSERT INTO #ExBatchStatus VALUES (8)
	END
		
	SELECT TOP 100 BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,BatchesRows.JobName,
		BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroup As ProductGroupName,batchesrows.ProductType,batchesrows.AccessoryGroupName,batchesrows.ProductID, 
		BatchesRows.QRANumber,BatchesRows.RequestPurpose, BatchesRows.TestCenterLocationID,BatchesRows.TestStageName, BatchesRows.TestStageCompletionStatus, testUnitCount, 
		(CASE WHEN BatchesRows.WILocation IS NULL THEN NULL ELSE BatchesRows.WILocation END) AS jobWILocation, batchesrows.RQID AS ReqID,
		(testunitcount -
			(select COUNT(*) 
			from TestUnits as tu WITH(NOLOCK)
			INNER JOIN DeviceTrackingLog as dtl WITH(NOLOCK) ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
		) as HasUnitsToReturnToRequestor,
		(select AssignedTo 
		from TaskAssignments as ta WITH(NOLOCK)
			--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
			INNER JOIN TestStages ts WITH(NOLOCK) ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
			--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
			INNER JOIN Jobs j WITH(NOLOCK) ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
		where ta.BatchID = BatchesRows.ID and ta.Active=1) as ActiveTaskAssignee,
		CONVERT(BIT,0) AS HasBatchSpecificExceptions, batchesrows.ProductTypeID,batchesrows.AccessoryGroupID, BatchesRows.CurrentTest, BatchesRows.CPRNumber, BatchesRows.RelabJobID, 
		BatchesRows.TestCenterLocation, AssemblyNumber, AssemblyRevision, HWRevision, PartName, ReportRequiredBy, ReportApprovedDate, IsMQual, JobID
	FROM     
		(
			SELECT DISTINCT b.BatchStatus,b.Comment, b.teststagecompletionstatus,b.ConcurrencyID,b.ID,b.JobName,b.LastUser,b.Priority,b.ProductTypeID,b.AccessoryGroupID,p.ID As ProductID,
				p.ProductGroupName As ProductGroup,b.QRANumber,b.RequestPurpose,b.TestCenterLocationID,b.TestStageName,j.WILocation,
				(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
				l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, l3.[Values] As TestCenterLocation,
				(
					SELECT top(1) tu.CurrentTestName as CurrentTestName 
					FROM TestUnits AS tu, DeviceTrackingLog AS dtl 
					where tu.ID = dtl.TestUnitID 
					and tu.CurrentTestName is not null
					and (dtl.OutUser IS NULL) AND tu.BatchID=b.ID
				) As CurrentTest, b.CPRNumber,b.RelabJobID, b.RQID, b.AssemblyNumber, b.AssemblyRevision,b.HWRevision, b.PartName, b.ReportRequiredBy, 
				b.ReportApprovedDate, b.IsMQual, j.ID AS JobID
			FROM Batches as b WITH(NOLOCK)
				inner join Products p WITH(NOLOCK) on b.ProductID=p.id 
				LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
				LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID  
				LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.Type='TestCenter' AND b.TestCenterLocationID=l3.LookupID
				INNER JOIN TestStages ts WITH(NOLOCK) ON ts.TestStageName=b.TestStageName
			WHERE ((BatchStatus NOT IN (SELECT ID FROM #ExBatchStatus) OR @ExcludedStatus IS NULL) AND (BatchStatus = @Status OR @Status IS NULL))
				AND (p.ID = @ProductID OR @ProductID IS NULL)
				AND (b.Priority = @Priority OR @Priority IS NULL)
				AND (b.ProductTypeID = @ProductTypeID OR @ProductTypeID IS NULL)
				AND (b.AccessoryGroupID = @AccessoryGroupID OR @AccessoryGroupID IS NULL)
				AND (b.TestCenterLocationID = @GeoLocationID OR @GeoLocationID IS NULL)
				AND (b.JobName = @JobName OR @JobName IS NULL)
				AND (b.RequestPurpose = @RequestReason OR @RequestReason IS NULL)
				AND 
				(
					(@TestStage IS NULL AND (b.TestStageName = @TestStageName OR @TestStageName IS NULL))
					OR
					(b.TestStageName = @TestStage AND @TestStageName IS NULL)
				)
				AND ((ts.TestStageType NOT IN (SELECT ID FROM #ExTestStageType) OR @excludedTestStageType IS NULL) AND (ts.TestStageType = @TestStageType OR @TestStageType IS NULL))
				AND
				(
					(
						SELECT top(1) tu.CurrentTestName as CurrentTestName 
						FROM TestUnits AS tu WITH(NOLOCK), DeviceTrackingLog AS dtl WITH(NOLOCK)
						where tu.ID = dtl.TestUnitID 
						and tu.CurrentTestName is not null
						and (dtl.OutUser IS NULL) AND tu.BatchID=b.ID
					) = @TestName 
					OR 
					@TestName IS NULL
				)
				AND
				(
					(
						SELECT top 1 u.id 
						FROM TestUnits as tu WITH(NOLOCK), devicetrackinglog as dtl WITH(NOLOCK), TrackingLocations as tl WITH(NOLOCK), Users u WITH(NOLOCK)
						WHERE tl.ID = dtl.TrackingLocationID and tu.id  = dtl.testunitid and tu.batchid = b.id and  inuser = u.LDAPLogin and outuser is null
					) = @UserID
					OR
					@UserID IS NULL
				)
				AND
				(
					@TrackingLocationID IS NULL
					OR
					(
						b.ID IN (select DISTINCT tu.BatchID
						from TrackingLocations tl WITH(NOLOCK)
						inner join devicetrackinglog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID AND dtl.OutTime IS NULL
						inner join TestUnits tu WITH(NOLOCK) on tu.ID=dtl.TestUnitID
						where TrackingLocationTypeID=@TrackingLocationID)
					)
				)
				AND
				(
					@TrackingLocationFunction IS NULL
					OR
					(
						b.ID IN (select DISTINCT tu.BatchID
						from TrackingLocations tl WITH(NOLOCK)
						inner join devicetrackinglog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID AND dtl.OutTime IS NULL
						inner join TestUnits tu WITH(NOLOCK) on tu.ID=dtl.TestUnitID
						INNER JOIN TrackingLocationTypes tlt WITH(NOLOCK) ON tlt.ID = tl.TrackingLocationTypeID
						where tlt.TrackingLocationFunction=@TrackingLocationFunction)
					)
				)
				AND
				(
					@NotInTrackingLocationFunction IS NULL
					OR
					(
						b.ID IN (select DISTINCT tu.BatchID
						from TrackingLocations tl WITH(NOLOCK)
						inner join devicetrackinglog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID AND dtl.OutTime IS NULL
						inner join TestUnits tu WITH(NOLOCK) on tu.ID=dtl.TestUnitID
						INNER JOIN TrackingLocationTypes tlt WITH(NOLOCK) ON tlt.ID = tl.TrackingLocationTypeID
						where tlt.TrackingLocationFunction NOT IN (@NotInTrackingLocationFunction))
					)
				)
				AND 
				(
					(@BatchStart IS NULL AND @BatchEnd IS NULL)
					OR
					(b.ID IN (Select distinct batchid FROM BatchesAudit WITH(NOLOCK) WHERE InsertTime BETWEEN @BatchStart AND @BatchEnd))
				)
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@ExecutingUserID)))
		)AS BatchesRows		
	ORDER BY BatchesRows.QRANumber DESC
	
	DROP TABLE #ExTestStageType
	DROP TABLE #ExBatchStatus
	RETURN
GO
GRANT EXECUTE ON remispBatchesSearch TO Remi
GO
alter table Relab.ResultsMeasurements add Description NVARCHAR(800)
go
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
		DECLARE @LookupTypeName NVARCHAR(100)

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
		
		PRINT '# Files To Process: ' + CONVERT(VARCHAR, @Val)
		PRINT 'XMLID: ' + CONVERT(VARCHAR, @ID)
		PRINT 'ResultID: ' + CONVERT(VARCHAR, @ResultID)
		PRINT 'TestID: ' + CONVERT(VARCHAR, @TestID)

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
	
		IF (@TestID = 1185 OR @TestID = 202)
		BEGIN
			IF (@TestID = 1185)
			BEGIN
				SET @LookupTypeName = 'SFIFunctionalMatrix'
			END
			
			IF (@TestID = 202)
			BEGIN
				SET @LookupTypeName = 'MFIFunctionalMatrix'
			END			
			
			PRINT 'Test IS SFI Functional Or Functional Test'
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
PRINT N'Altering [Relab].[remispResultsSummaryExport]'
GO
ALTER PROCEDURE [Relab].[remispResultsSummaryExport] @BatchID INT, @ResultID INT = NULL
AS
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #parameters (ResultMeasurementID INT)

	DECLARE @rows VARCHAR(8000)
	DECLARE @sql VARCHAR(8000)
	SELECT @rows=  ISNULL(STUFF(
		( 
		SELECT DISTINCT '],[' + rp.ParameterName
		FROM Relab.Results r WITH(NOLOCK)
			INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
			INNER JOIN Tests t WITH(NOLOCK) ON r.TestID=t.ID
			INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID=r.TestUnitID
			INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID
			INNER JOIN Relab.ResultsMeasurements m WITH(NOLOCK) ON m.ResultID=r.ID
			LEFT OUTER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON m.ID=rp.ResultMeasurementID
		WHERE b.ID=@BatchID AND (@ResultID IS NULL OR (@ResultID IS NOT NULL AND r.ID=@ResultID))
		ORDER BY '],[' +  rp.ParameterName
		FOR XML PATH('')), 1, 2, '') + ']','[na]')

	SET @sql = 'ALTER TABLE #parameters ADD ' + convert(varchar(8000), replace(@rows, ']', '] NVARCHAR(250)'))
	EXEC (@sql)

	IF (@rows != '[na]')
	BEGIN
		SET @sql = 'INSERT INTO #parameters SELECT *
		FROM (
			SELECT rp.ResultMeasurementID, rp.ParameterName, rp.Value
			FROM Relab.Results r WITH(NOLOCK)
				INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
				INNER JOIN Tests t WITH(NOLOCK) ON r.TestID=t.ID
				INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID=r.TestUnitID
				INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID
				INNER JOIN Relab.ResultsMeasurements m WITH(NOLOCK) ON m.ResultID=r.ID
				LEFT OUTER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON m.ID=rp.ResultMeasurementID
			WHERE b.ID=' + CONVERT(VARCHAR, @BatchID) + ' AND (' + CASE WHEN convert(varchar,@ResultID) IS NULL THEN 'NULL' ELSE convert(varchar,@ResultID) END + ' IS NULL OR (' + CASE WHEN convert(varchar,@ResultID) IS NULL THEN 'NULL' ELSE convert(varchar,@ResultID) END + ' IS NOT NULL AND r.ID=' + CASE WHEN @ResultID IS NOT NULL THEN CONVERT(VARCHAR, @ResultID) ELSE 'NULL' END + '))
			) te PIVOT (MAX(Value) FOR ParameterName IN (' + @rows + ')) AS pvt'
		EXEC (@sql)
	END
	ELSE
	BEGIN
		EXEC ('ALTER TABLE #parameters DROP COLUMN na')
	END

	SELECT b.QRANumber, tu.BatchUnitNumber As Unit, tu.BSN, ts.TestStageName AS TestStage, t.TestName, 
		lm.[Values] AS MeasurementType, m.LowerLimit, m.UpperLimit, m.MeasurementValue AS Result, lu.[Values] AS Units,
		CASE WHEN m.PassFail=1 THEN 'Pass' ELSE 'Fail' END AS PassFail, --Relab.ResultsParametersComma(m.ID) AS Parameters, 
		m.ReTestNum, m.Archived, m.Comment, rxml.VerNum AS XMLVersion, rxml.StartDate, rxml.EndDate, rxml.StationName, m.Description, p.*
	FROM Relab.Results r WITH(NOLOCK)
		INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
		INNER JOIN Tests t WITH(NOLOCK) ON r.TestID=t.ID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID=r.TestUnitID
		INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID
		INNER JOIN Relab.ResultsMeasurements m WITH(NOLOCK) ON m.ResultID=r.ID
		LEFT OUTER JOIN Lookups lm WITH(NOLOCK) ON m.MeasurementTypeID=lm.LookupID
		LEFT OUTER JOIN Lookups lu WITH(NOLOCK) ON m.MeasurementUnitTypeID=lu.LookupID
		LEFT OUTER JOIN Relab.ResultsXML rxml WITH(NOLOCK) ON rxml.ID=m.XMLID
		LEFT OUTER JOIN #parameters p WITH(NOLOCK) ON p.ResultMeasurementID=m.ID
	WHERE b.ID=@BatchID AND (@ResultID IS NULL OR (@ResultID IS NOT NULL AND r.ID=@ResultID))
	ORDER BY tu.BatchUnitNumber, ts.TestStageName, TestName
	
	SET NOCOUNT OFF
END
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
	
	SELECT rm.ID, ISNULL(ISNULL(lt.[Values], ltsf.[Values]), ltmf.[Values]) As Measurement, LowerLimit AS [Lower Limit], UpperLimit AS [Upper Limit], MeasurementValue AS Result, lu.[Values] As Unit, 
		CASE WHEN PassFail=1 THEN 'Pass' ELSE 'Fail' END AS [Pass/Fail],
		rm.MeasurementTypeID, rm.ReTestNum AS [Test Num], rm.Archived, rm.XMLID, 
		@ReTestNum AS MaxVersion, rm.Comment, ISNULL(rmf.[File], 0) AS [Image], 
		ISNULL(UPPER(SUBSTRING(rmf.ContentType,2,LEN(rmf.ContentType))), 'PNG') AS ContentType, rm.Description, p.*
	FROM Relab.ResultsMeasurements rm WITH(NOLOCK)
		LEFT OUTER JOIN Lookups lu WITH(NOLOCK) ON lu.Type='UnitType' AND lu.LookupID=rm.MeasurementUnitTypeID
		LEFT OUTER JOIN Lookups lt WITH(NOLOCK) ON lt.Type='MeasurementType' AND lt.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Lookups ltsf WITH(NOLOCK) ON ltsf.Type='SFIFunctionalMatrix' AND ltsf.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Lookups ltmf WITH(NOLOCK) ON ltmf.Type='MFIFunctionalMatrix' AND ltmf.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Relab.ResultsMeasurementsFiles rmf WITH(NOLOCK) ON rmf.ResultMeasurementID=rm.ID
		LEFT OUTER JOIN #parameters p WITH(NOLOCK) ON p.ResultMeasurementID=rm.ID
	WHERE ResultID=@ResultID AND ((@IncludeArchived = 0 AND rm.Archived=@FalseBit) OR (@IncludeArchived=1)) AND ((@OnlyFails = 1 AND PassFail=@FalseBit) OR (@OnlyFails = 0))
	ORDER BY CASE WHEN @IncludeArchived = 1 THEN ISNULL(ISNULL(lt.[Values], ltsf.[Values]), ltmf.[Values]) ELSE CONVERT(VARCHAR, rm.ID) END, rm.ReTestNum ASC

	DROP TABLE #parameters
	SET NOCOUNT OFF
END
GO
rollback tran