begin tran
go
ALTER PROCEDURE [dbo].[remispBatchesSearch]
	@ByPassProductCheck INT = 0,
	@ExecutingUserID int,
	@Status int = null,
	@Priority int = null,
	@UserID int = null,
	@TrackingLocationTypeID int = null,
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
	@NotInTrackingLocationFunction INT  = NULL,
	@Revision NVARCHAR(10) = NULL,
	@DepartmentID INT = NULL,
	@OnlyHasResults INT = NULL,
	@JobID INT = 0,
	@TrackingLocationID INT = NULL,
	@Requestor NVARCHAR(255) = NULL
AS
	--SET FMTONLY OFF --Used when importing into the entity framework
	DECLARE @TestName NVARCHAR(400)
	DECLARE @TestStageName NVARCHAR(400)
	DECLARE @HasBatchSpecificExceptions BIT
	SET @HasBatchSpecificExceptions = CONVERT(BIT, 0)
	
	IF (@TestID IS NOT NULL)
	BEGIN
		SELECT @TestName = TestName FROM Tests WITH(NOLOCK) WHERE ID=@TestID 
	END
	
	IF (@TestStageID IS NOT NULL)
	BEGIN
		SELECT @TestStageName = TestStageName FROM TestStages WITH(NOLOCK) WHERE ID=@TestStageID
	END
	
	CREATE TABLE #ExTestStageType (ID INT)
	CREATE TABLE #ExBatchStatus (ID INT)
	
	IF (@TestStageName IS NOT NULL)
		SET @TestStage = NULL
	
	IF (@excludedTestStageType IS NOT NULL)
	BEGIN
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
	END
		
	IF (@ExcludedStatus IS NOT NULL)
	BEGIN
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
	END
	
	SELECT TOP 100 BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,BatchesRows.JobName,
		BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroup As ProductGroupName,batchesrows.ProductType,batchesrows.AccessoryGroupName,batchesrows.ProductID, 
		BatchesRows.QRANumber,BatchesRows.RequestPurposeID, BatchesRows.TestCenterLocationID,BatchesRows.TestStageName, BatchesRows.TestStageCompletionStatus, testUnitCount, 
		(CASE WHEN BatchesRows.WILocation IS NULL THEN NULL ELSE BatchesRows.WILocation END) AS jobWILocation, batchesrows.RQID AS ReqID,
		(testunitcount -
			(select COUNT(*) 
			from TestUnits as tu WITH(NOLOCK)
			INNER JOIN DeviceTrackingLog as dtl WITH(NOLOCK) ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
		) as HasUnitsToReturnToRequestor,
		ISNULL(
			(SELECT AssignedTo 
			FROM TaskAssignments ta WITH(NOLOCK)
				--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
				INNER JOIN TestStages ts WITH(NOLOCK) ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
				--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
				INNER JOIN Jobs j WITH(NOLOCK) ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
			WHERE ta.BatchID = BatchesRows.ID and ta.Active=1), 
			(SELECT AssignedTo 
			FROM TaskAssignments ta WITH(NOLOCK)
			WHERE ta.Active=1 AND ISNULL(ta.taskID,0) = 0 AND ta.BatchID = BatchesRows.ID)
		) as ActiveTaskAssignee,
		@HasBatchSpecificExceptions AS HasBatchSpecificExceptions, batchesrows.ProductTypeID,batchesrows.AccessoryGroupID, BatchesRows.CPRNumber, BatchesRows.RelabJobID, 
		BatchesRows.TestCenterLocation, AssemblyNumber, AssemblyRevision, HWRevision, PartName, ReportRequiredBy, ReportApprovedDate, IsMQual, JobID, DateCreated, ContinueOnFailures,
		MechanicalTools, BatchesRows.RequestPurpose, BatchesRows.PriorityID, DepartmentID, Department, Requestor, BatchesRows.TestStageID,
		BatchesRows.OrientationID
	FROM     
		(
			SELECT DISTINCT b.BatchStatus,b.Comment, b.teststagecompletionstatus,b.ConcurrencyID,b.ID,b.JobName,b.LastUser,b.Priority AS PriorityID,b.ProductTypeID,
				b.AccessoryGroupID,b.ProductID As ProductID,p.[Values] As ProductGroup,b.QRANumber,b.RequestPurpose As RequestPurposeID,b.TestCenterLocationID,b.TestStageName,
				j.WILocation,(select count(*) from testunits WITH(NOLOCK) where testunits.batchid = b.id) as testUnitCount,
				l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, l3.[Values] As TestCenterLocation,
				b.CPRNumber,b.RelabJobID, b.RQID, b.AssemblyNumber, b.AssemblyRevision,b.HWRevision, b.PartName, b.ReportRequiredBy, 
				b.ReportApprovedDate, b.IsMQual, j.ID AS JobID, b.DateCreated, j.ContinueOnFailures, MechanicalTools, l4.[Values] As RequestPurpose, l5.[Values] As Priority, 
				ISNULL(b.[Order], 100) As PriorityOrder, b.DepartmentID, l6.[Values] AS Department, b.Requestor, ts.ID AS TestStageID,
				b.OrientationID
			FROM Batches as b WITH(NOLOCK)
				INNER JOIN Lookups p WITH(NOLOCK) ON p.LookupID=b.ProductID
				LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
				LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON b.AccessoryGroupID=l2.LookupID  
				LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON b.TestCenterLocationID=l3.LookupID
				INNER JOIN TestStages ts WITH(NOLOCK) ON ts.TestStageName=b.TestStageName AND ts.JobID=j.ID
				LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON b.RequestPurpose=l4.LookupID
				LEFT OUTER JOIN Lookups l5 WITH(NOLOCK) ON b.Priority=l5.LookupID
				LEFT OUTER JOIN Lookups l6 WITH(NOLOCK) ON b.DepartmentID=l6.LookupID
			WHERE
				(
					(ISNULL(@ExcludedStatus, 0) > 0 AND BatchStatus NOT IN (SELECT ID FROM #ExBatchStatus WITH(NOLOCK)))
					OR
					(ISNULL(@ExcludedStatus, 0) = 0)
				)
				AND
				(
					(ISNULL(@Status, 0) > 0 AND BatchStatus = @Status)
					OR
					(ISNULL(@Status, 0) = 0)
				)
				AND 
				(
					(ISNULL(@ProductID, 0) > 0 AND p.LookupID = @ProductID)
					OR 
					ISNULL(@ProductID, 0) = 0
				)
				AND 
				(
					(ISNULL(@Priority, 0) > 0 AND b.Priority = @Priority)
					OR 
					ISNULL(@Priority, 0) = 0
				)
				AND 
				(
					(ISNULL(@ProductTypeID, 0) > 0 AND b.ProductTypeID = @ProductTypeID)
					OR 
					ISNULL(@ProductTypeID, 0) = 0
				)
				AND 
				(
					(ISNULL(@AccessoryGroupID, 0) > 0 AND b.AccessoryGroupID = @AccessoryGroupID)
					OR 
					ISNULL(@AccessoryGroupID, 0) = 0
				)
				AND 
				(
					(ISNULL(@GeoLocationID, 0) > 0 AND b.TestCenterLocationID = @GeoLocationID)
					OR 
					ISNULL(@GeoLocationID, 0) = 0
				)
				AND 
				(
					(ISNULL(@DepartmentID, 0) > 0 AND b.DepartmentID = @DepartmentID)
					OR 
					ISNULL(@DepartmentID, 0) = 0
				)
				AND 
				(
					(ISNULL(@RequestReason, 0) > 0 AND b.RequestPurpose = @RequestReason)
					OR 
					ISNULL(@RequestReason, 0) = 0
				)
				AND 
				(
					(@Revision IS NOT NULL AND b.MechanicalTools = @Revision)
					OR 
					@Revision IS NULL
				)
				AND 
				(
					(@Requestor IS NOT NULL AND b.Requestor = @Requestor)
					OR 
					@Requestor IS NULL
				)
				AND 
				(
					(ISNULL(@JobID, 0) > 0 AND j.ID=@JobID)
					OR
					(ISNULL(@JobID, 0) = 0 AND @JobName IS NOT NULL AND b.JobName = @JobName)
					OR
					(@JobName IS NULL AND ISNULL(@JobID, 0) = 0)
				)
				AND 
				(
					(@TestStageName IS NOT NULL AND @TestStage IS NULL AND b.TestStageName = @TestStageName)
					OR
					(@TestStage IS NOT NULL AND b.TestStageName = @TestStage AND @TestStageName IS NULL)
					OR
					(@TestStageName IS NULL AND @TestStage IS NULL)
				)
				AND
				(
					(ISNULL(@excludedTestStageType, 0) > 0 AND ts.TestStageType NOT IN (SELECT ID FROM #ExTestStageType))
					OR
					(ISNULL(@excludedTestStageType, 0) = 0)
				)
				AND
				(
					(ISNULL(@TestStageType, 0) > 0 AND ts.TestStageType = @TestStageType)
					OR
					(ISNULL(@TestStageType, 0) = 0)
				)
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.LookupID IN (SELECT ud.LookupID FROM UserDetails ud WITH(NOLOCK) WHERE UserID=@ExecutingUserID)))
				AND 
				(
					(@BatchStart IS NULL AND @BatchEnd IS NULL)
					OR
					(@BatchStart IS NOT NULL AND @BatchEnd IS NOT NULL AND b.ID IN (Select distinct batchid FROM BatchesAudit WITH(NOLOCK) WHERE InsertTime BETWEEN @BatchStart AND @BatchEnd))
				)
				AND
				(
					(ISNULL(@OnlyHasResults, 0) = 0)
					OR
					(@OnlyHasResults = 1 AND EXISTS(SELECT TOP 1 1 FROM TestUnits tu WITH(NOLOCK) INNER JOIN Relab.Results r WITH(NOLOCK) ON r.TestUnitID=tu.ID WHERE tu.BatchID=b.ID))
				)
				AND
				(
					(@TestName IS NOT NULL AND (
						SELECT top(1) tu.CurrentTestName as CurrentTestName 
						FROM TestUnits AS tu WITH(NOLOCK), DeviceTrackingLog AS dtl WITH(NOLOCK)
						where tu.ID = dtl.TestUnitID 
						and tu.CurrentTestName is not null
						and (dtl.OutUser IS NULL) AND tu.BatchID=b.ID
					) = @TestName)
					OR 
					(@TestName IS NULL)
				)
				AND
				(
					(@UserID IS NOT NULL AND (
						SELECT top 1 u.id 
						FROM TestUnits as tu WITH(NOLOCK), devicetrackinglog as dtl WITH(NOLOCK), TrackingLocations as tl WITH(NOLOCK), Users u WITH(NOLOCK)
						WHERE tl.ID = dtl.TrackingLocationID and tu.id  = dtl.testunitid and tu.batchid = b.id and  inuser = u.LDAPLogin and outuser is null
					) = @UserID)
					OR
					(@UserID IS NULL)
				)
				AND
				(
					(ISNULL(@TrackingLocationFunction, 0) = 0)
					OR
					(ISNULL(@TrackingLocationFunction, 0) > 0 AND (
						b.ID IN (select DISTINCT tu.BatchID
						FROM TrackingLocations tl WITH(NOLOCK)
							INNER JOIN devicetrackinglog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID AND dtl.OutTime IS NULL
							INNER JOIN TestUnits tu WITH(NOLOCK) on tu.ID=dtl.TestUnitID
							INNER JOIN TrackingLocationTypes tlt WITH(NOLOCK) ON tlt.ID = tl.TrackingLocationTypeID
						where tlt.TrackingLocationFunction=@TrackingLocationFunction)
					))
				)
				AND
				(
					(ISNULL(@TrackingLocationTypeID, 0) = 0)
					OR
					(ISNULL(@TrackingLocationTypeID, 0) > 0 AND (
						b.ID IN (SELECT DISTINCT tu.BatchID
						FROM TrackingLocations tl WITH(NOLOCK)
							INNER JOIN devicetrackinglog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID --AND dtl.OutTime IS NULL
								AND dtl.InTime BETWEEN @BatchStart AND @BatchEnd
							INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID=dtl.TestUnitID
						WHERE TrackingLocationTypeID=@TrackingLocationTypeID)
					))
				)
				AND
				(
					(ISNULL(@TrackingLocationID, 0) = 0)
					OR
					(ISNULL(@TrackingLocationID, 0) > 0 AND (
						b.ID IN (SELECT DISTINCT tu.BatchID
						FROM TrackingLocations tl WITH(NOLOCK)
							INNER JOIN devicetrackinglog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID AND dtl.OutTime IS NULL
							INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID=dtl.TestUnitID
						WHERE tl.ID=@TrackingLocationID)
					))
				)
				AND
				(
					(ISNULL(@NotInTrackingLocationFunction, 0) = 0)
					OR
					(ISNULL(@NotInTrackingLocationFunction, 0) > 0 AND (
						b.ID IN (select DISTINCT tu.BatchID
						FROM TrackingLocations tl WITH(NOLOCK)
							INNER JOIN devicetrackinglog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID AND dtl.OutTime IS NULL
							INNER JOIN TestUnits tu WITH(NOLOCK) on tu.ID=dtl.TestUnitID
							INNER JOIN TrackingLocationTypes tlt WITH(NOLOCK) ON tlt.ID = tl.TrackingLocationTypeID
						where tlt.TrackingLocationFunction NOT IN (@NotInTrackingLocationFunction))
					))
				)
		)AS BatchesRows		
	ORDER BY BatchesRows.PriorityOrder ASC, BatchesRows.QRANumber DESC
	
	DROP TABLE #ExTestStageType
	DROP TABLE #ExBatchStatus
	RETURN
GO
GRANT EXECUTE ON remispBatchesSearch TO Remi
GO
ALTER PROCEDURE [dbo].[remispBatchGetViewBatch] @RequestNumber nvarchar(11)
AS
--DECLARE @BatchID INT
--SELECT @BatchID=ID FROM Batches WITH(NOLOCK) WHERE QRANumber=@qranumber

EXEC Remispbatchesselectbyqranumber @RequestNumber; 

--EXEC remispBatchGetTaskInfo @BatchID; 

--EXEC Remisptestrecordsselectforbatch @qranumber;

--EXEC Remisptestunitssearchfor @qranumber;  

GO
GRANT EXECUTE ON remispBatchGetViewBatch TO Remi
GO
DROP PROCEDURE remispBatchesSelectListAtTrackingLocation
GO
ALTER procedure [dbo].[remispInventoryReport]
	@StartDate datetime,
	@EndDate datetime,
	@FilterBasedOnQraNumber bit,
	@geographicallocation INT = NULL
AS

IF @geographicallocation = 0
	SET @geographicallocation = NULL

declare @startYear int = Right(year( @StartDate), 2);
declare @endYear int = Right(year( @EndDate), 2);
declare @AverageTestUnitsPerBatch int = -1

declare @TotalBatches int = (select COUNT(*) from BatchesAudit  where 
 BatchesAudit.InsertTime >= @StartDate and BatchesAudit.InsertTime <= @EndDate and BatchesAudit.Action = 'I' 
 and (@FilterBasedOnQraNumber = 0 or (Convert(int , SUBSTRING(BatchesAudit.QRANumber, 5, 2)) >= @startYear
 and Convert(int , SUBSTRING(BatchesAudit.QRANumber, 5, 2)) <= @endYear))
 and (@geographicallocation IS NULL or BatchesAudit.TestCenterLocationID = @geographicallocation)
 );

declare @TotalTestUnits int =(select COUNT(*) as TotalTestUnits from TestUnitsAudit, batchesaudit  where 
 TestUnitsAudit.InsertTime >= @StartDate and TestUnitsAudit.InsertTime <= @EndDate and TestUnitsAudit.Action = 'I' 
 and BatchesAudit.InsertTime >= @StartDate and BatchesAudit.InsertTime <= @EndDate and BatchesAudit.Action = 'I' 
 and (@FilterBasedOnQraNumber = 0 or (Convert(int , SUBSTRING(batchesaudit.QRANumber, 5, 2)) >= @startYear
 and Convert(int , SUBSTRING(batchesaudit.QRANumber, 5, 2)) <= @endYear))
and TestUnitsAudit.BatchID = Batchesaudit.batchID 
and (@geographicallocation IS NULL or batchesaudit.TestCenterLocationID = @geographicallocation)
);

if @TotalBatches != 0
begin
 set @AverageTestUnitsPerBatch = @totaltestunits / @totalbatches;
end

select @TotalBatches as TotalBatches, @TotalTestUnits as TotalTestUnits, @AverageTestUnitsPerBatch as AverageUnitsPerBatch;

select lp.[Values] as ProductGroup, COUNT( distinct BatchesAudit.id) as TotalBatches,
COUNT(tu.ID) as TotalTestUnits 
from BatchesAudit
	INNER JOIN TestUnits tu ON tu.BatchID=BatchesAudit.BatchID
	INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=BatchesAudit.ProductID
where BatchesAudit.InsertTime >= @StartDate and BatchesAudit.InsertTime <= @EndDate and BatchesAudit.Action = 'I' 
and (@FilterBasedOnQraNumber = 0 or (Convert(int , SUBSTRING(BatchesAudit.QRANumber, 5, 2)) >= @startYear
and Convert(int , SUBSTRING(BatchesAudit.QRANumber, 5, 2)) <= @endYear)) 
and (BatchesAudit.TestCenterLocationID = @geographicallocation or @geographicallocation IS NULL)
and BatchesAudit.BatchID = tu.BatchID 
group by lp.[Values];
GO
GRANT EXECUTE ON remispInventoryReport TO Remi
GO
ALTER PROCEDURE Relab.remispResultVersions  @TestID INT, @BatchID INT, @UnitNumber INT = 0, @TestStageID INT = 0
AS
BEGIN
	SELECT tu.BatchUnitNumber, ts.TestStageName As TestStage, rxml.ResultXML, rxml.StationName, rxml.StartDate, rxml.EndDate, ISNULL(rxml.lossFile,'') AS lossFile, 
		CASE WHEN rxml.isProcessed = 1 THEN 'Yes' ELSE 'No' END As Processed, rxml.VerNum, 
		ISNULL(rxml.ProductXML, '') AS ProductXML, ISNULL(rxml.StationXML, '') AS StationXML, ISNULL(rxml.SequenceXML, '') AS SequenceXML,
		ISNULL(rxml.TestXML, '') AS TestXML, CASE WHEN rxml.ErrorOccured = 1 THEN 'Yes' ELSE 'No' END As ErrorOccured
	FROM Relab.Results r WITH(NOLOCK)
		INNER JOIN TestUnits tu WITH(NOLOCK) ON r.TestUnitID=tu.ID
		INNER JOIN Relab.ResultsXML rxml WITH(NOLOCK) ON r.ID=rxml.ResultID
		INNER JOIN TestStages ts WITH(NOLOCK) ON ts.ID=r.TestStageID
	WHERE r.TestID=@TestID AND tu.BatchID=@BatchID
		AND (@UnitNumber = 0 OR tu.BatchUnitNumber=@UnitNumber)
		AND (@TestStageID = 0 OR ts.ID=@TestStageID)
END
GO
GRANT EXECUTE ON [Relab].[remispResultVersions] TO Remi
GO
ALTER PROCEDURE [dbo].[remispTestStagesInsertUpdateSingleItem]
	@ID int OUTPUT,
	@TestStageName nvarchar(400), 
	@TestStageType int,
	@JobName  nvarchar(400),
	@Comment  nvarchar(1000)=null,
	@TestID int = null,
	@LastUser  nvarchar(255),
	@ConcurrencyID rowversion OUTPUT,
	@ProcessOrder int = 0,
	@IsArchived BIT = 0
AS
	BEGIN TRANSACTION AddTestStage
	
	DECLARE @jobID int
	DECLARE @ReturnValue int
	
	SET @jobID = (SELECT ID FROM Jobs WHERE JobName = @jobname)
	
	if @jobID is null and @JobName is not null --the job was not added to the db yet so add it to get an id.
	begin
		execute remispJobsInsertUpdateSingleItem null, @jobname,null,null,@lastuser,null
	end
	
	SET @jobID = (select ID from Jobs where JobName = @jobname)

	IF (@ID IS NULL AND NOT EXISTS (SELECT 1 FROM TestStages WHERE JobID=@jobID AND TestStageName=@TestStageName)) -- New Item
	BEGIN
		INSERT INTO TestStages (TestStageName, TestStageType, JobID, TestID, LastUser, Comment, ProcessOrder, IsArchived)
		VALUES (LTRIM(RTRIM(@TestStageName)), @TestStageType, @JobID, @TestID, @LastUser, LTRIM(RTRIM(@Comment)), @ProcessOrder, @IsArchived)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE IF (@ConcurrencyID IS NOT NULL) -- Exisiting Item
	BEGIN
		UPDATE TestStages SET
			TestStageName = LTRIM(RTRIM(@TestStageName)), 
			TestStageType = @TestStageType,
			JobID = @JobID,
			TestID=@TestID,
			LastUser = @LastUser,
			Comment = LTRIM(RTRIM(@Comment)),
			ProcessOrder = @ProcessOrder,
			IsArchived = @IsArchived
		WHERE ID = @ID AND ConcurrencyID = @ConcurrencyID

		SELECT @ReturnValue = @ID
	END

	SET @ConcurrencyID = (SELECT ConcurrencyID FROM TestStages WHERE ID = @ReturnValue)
	SET @ID = @ReturnValue
	
	COMMIT TRANSACTION AddTestStage
	
	IF (@@ERROR != 0)
	BEGIN
		RETURN -1
	END
	ELSE
	BEGIN
		RETURN 0
	END
GO
GRANT EXECUTE On remispTestStagesInsertUpdateSingleItem TO REMI
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
	@IsArchived BIT = 0,
	@Owner NVARCHAR(255) = NULL,
	@Trainee NVARCHAR(255) = NULL,
	@DegradationVal DECIMAL(10,3)
AS
	DECLARE @ReturnValue int
	
	IF (@ID IS NULL) and (((select count (*) from Tests where TestName = @TestName)= 0) or @TestType != 1)-- New Item
	BEGIN
		INSERT INTO Tests (TestName, Duration, TestType, WILocation, Comment, lastUser, ResultBasedOntime, IsArchived, [Owner], Trainee, DegradationVal)
		VALUES (LTRIM(RTRIM(@TestName)), @Duration, @TestType, @WILocation, LTRIM(RTRIM(@Comment)), @lastUser, @ResultBasedOnTime, @IsArchived, @Owner, @Trainee, @DegradationVal)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE -- Exisiting Item
	BEGIN
		UPDATE Tests SET
			TestName = LTRIM(RTRIM(@TestName)), 
			Duration = @Duration, 
			TestType = @TestType, 
			WILocation = @WILocation,
			Comment = LTRIM(RTRIM(@Comment)),
			lastUser = @LastUser,
			ResultBasedOntime = @ResultBasedOnTime,
			IsArchived = @IsArchived,
			[Owner]=@Owner, Trainee=@Trainee, DegradationVal = @DegradationVal
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
GRANT EXECUTE ON remispTestsInsertUpdateSingleItem TO REMI
GO
ALTER PROCEDURE [dbo].[remispProductSettingsInsertUpdateSingleItem]
	@lookupid INT,
	@KeyName nvarchar(MAX),
	@ValueText nvarchar(MAX) = null,
	@DefaultValue nvarchar(MAX),
	@LastUser nvarchar(255)	
AS
	DECLARE @ReturnValue int
	declare @ID int
	
	set @ID = (select ID from ProductSettings as ps  where ps.KeyName = @KeyName and lookupid=@lookupid)

	IF (@ID IS NULL) -- New Item
	BEGIN
		INSERT INTO ProductSettings (lookupid, KeyName, ValueText, LastUser, DefaultValue)
		VALUES (@lookupid, LTRIM(RTRIM(@KeyName)), LTRIM(RTRIM(@ValueText)), @LastUser, LTRIM(RTRIM(@DefaultValue)))

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE -- Exisiting Item
	BEGIN	
		if (select defaultvalue from ProductSettings where ID = @ID) != @DefaultValue
		begin
			--update the defaultvalues for any entries
			update ProductSettings set ValueText = LTRIM(RTRIM(@DefaultValue)) where ValueText = DefaultValue and KeyName = @KeyName;
			update ProductSettings set DefaultValue = LTRIM(RTRIM(@DefaultValue)) where KeyName = @KeyName;
		end
		
		--and update everything else
		UPDATE ProductSettings SET
			lookupid = @lookupid, 
			LastUser = @LastUser,
			KeyName = LTRIM(RTRIM(@KeyName)),
			ValueText = LTRIM(RTRIM(ISNULL(@ValueText, '')))
		WHERE ID = @ID
		SELECT @ReturnValue = @ID
	END
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
GRANT EXECUTE ON remispProductSettingsInsertUpdateSingleItem TO Remi
go
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
		SET @ID = (SELECT ID FROM TestRecords WITH(NOLOCK) WHERE TestStageName = LTRIM(RTRIM(@TestStageName)) AND JobName = LTRIM(RTRIM(@JobName)) AND testname=LTRIM(RTRIM(@TestName)) AND testunitid=@TestUnitID)
	END
	
	if (@TestID is null and @TestName is not null)
	begin
		SELECT @TestID=ID FROM Tests WITH(NOLOCK) WHERE TestName=LTRIM(RTRIM(@TestName))
	END

	if (@TestStageID is null and @TestStageName is not null)
	begin
		SELECT @JobID=ID FROM Jobs WITH(NOLOCK) WHERE JobName=LTRIM(RTRIM(@JobName))
		SELECT @TestStageID=ID FROM TestStages WITH(NOLOCK) WHERE JobID=@JobID AND TestStageName=LTRIM(RTRIM(@TestStageName))
	END

	IF (@ID IS NULL) -- New Item
	BEGIN
		INSERT INTO TestRecords (TestUnitID, Status, FailDocNumber, TestStageName, JobName, TestName, RelabVersion, LastUser, Comment,
			ResultSource, FailDocRQID, TestID, TestStageID, FunctionalType)
		VALUES (@TestUnitID, @Status, @FailDocNumber, LTRIM(RTRIM(@TestStageName)), LTRIM(RTRIM(@JobName)), LTRIM(RTRIM(@TestName)), @RelabVersion, @lastUser, LTRIM(RTRIM(@Comment)),
			@ResultSource, @FailDocRQID, @TestID, @TestStageID, @FunctionalType)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE -- Exisiting Item
	BEGIN
		UPDATE TestRecords 
		SET TestUnitID = @TestUnitID, 
			Status = @Status, 
			FailDocNumber = @FailDocNumber,
			TestStageName = LTRIM(RTRIM(@TestStageName)),
			JobName = LTRIM(RTRIM(@JobName)),
			TestName = LTRIM(RTRIM(@TestName)),
			RelabVersion = @RelabVersion,
			lastuser = @LastUser,
			Comment = LTRIM(RTRIM(@Comment)),
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
GRANT EXECUTE ON remispTestRecordsInsertUpdateSingleItem TO Remi
GO
ALTER PROCEDURE [dbo].[remispJobsInsertUpdateSingleItem]
/*	'===============================================================
	'   NAME:                	remispJobsInsertUpdateSingleItem
	'   DATE CREATED:       	20 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Creates or updates an item in a table: Jobs
    '   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
	@ID int OUTPUT,
	@JobName nvarchar(400),
	@WILocation nvarchar(400)=null,
	@Comment nvarchar(1000)=null,
	@LastUser nvarchar(255),
	@ConcurrencyID rowversion OUTPUT,
	@OperationsTest bit = 0,
	@TechOperationsTest bit = 0,
	@MechanicalTest bit = 0,
	@ProcedureLocation nvarchar(400)=null,
	@IsActive bit = 0, @NoBSN BIT = 0, @ContinueOnFailures BIT = 0
	AS

	DECLARE @ReturnValue int
	
	set @ID = (select ID from Jobs WITH(NOLOCK) where jobs.JobName=LTRIM(RTRIM(@JobName)))
	
	IF (@ID IS NULL) -- New Item
	BEGIN
		INSERT INTO Jobs(JobName, WILocation, Comment, LastUser, OperationsTest, TechnicalOperationsTest, MechanicalTest, ProcedureLocation, IsActive, NoBSN, ContinueOnFailures)
		VALUES(LTRIM(RTRIM(@JobName)), @WILocation, LTRIM(RTRIM(@Comment)), @LastUser, @OperationsTest, @TechOperationsTest, @MechanicalTest, @ProcedureLocation, @IsActive, @NoBSN, @ContinueOnFailures)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE -- Exisiting Item
	BEGIN
		UPDATE Jobs SET
			JobName = LTRIM(RTRIM(@JobName)), 
			LastUser = @LastUser,
			Comment = LTRIM(RTRIM(@Comment)),
			WILocation = @WILocation,
			OperationsTest = @OperationsTest,
			TechnicalOperationsTest = @TechOperationsTest,
			MechanicalTest = @MechanicalTest,
			ProcedureLocation = @ProcedureLocation,
			IsActive = @IsActive,
			NoBSN = @NoBSN,
			ContinueOnFailures = @ContinueOnFailures
		WHERE ID = @ID

		SELECT @ReturnValue = @ID
	END

	SET @ConcurrencyID = (SELECT ConcurrencyID FROM Jobs WITH(NOLOCK) WHERE ID = @ReturnValue)
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
GRANT EXECUTE ON remispJobsInsertUpdateSingleItem TO REMI
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
	@LocationStatus INT
AS
	DECLARE @ReturnValue int
	DECLARE @AlreadyExists as integer 

	IF (@ID IS NULL) -- New Item
	BEGIN
		IF (@ID IS NULL) -- New Item
		BEGIN
			set @AlreadyExists = (select ID from TrackingLocations 
			where TrackingLocationName = LTRIM(RTRIM(@trackingLocationName)) and TestCenterLocationID = @GeoLocationID)

			if (@AlreadyExists is not null) 
				return -1
			end

			PRINT 'INSERTING'

			INSERT INTO TrackingLocations (TrackingLocationName, TestCenterLocationID, TrackingLocationTypeID, LastUser, Comment, Decommissioned, IsMultiDeviceZone, Status)
			VALUES (LTRIM(RTRIM(@TrackingLocationname)), @GeoLocationID, @TrackingLocationtypeID, @LastUser, LTRIM(RTRIM(@Comment)), @Decommissioned, @IsMultiDeviceZone, @LocationStatus)
			
			SELECT @ReturnValue = SCOPE_IDENTITY()

			INSERT INTO TrackingLocationsHosts (TrackingLocationID, HostName, LastUser, [Status]) 
			VALUES (@ReturnValue, LTRIM(RTRIM(@HostName)), @LastUser, @Status)
		END
		ELSE -- Exisiting Item
		BEGIN
			PRINT 'UDPATING TrackingLocations'
		
			UPDATE TrackingLocations 
			SET TrackingLocationName=LTRIM(RTRIM(@TrackingLocationName)) ,
				TestCenterLocationID=@GeoLocationID, 
				TrackingLocationTypeID=@TrackingLocationtypeID,
				LastUser = @LastUser,
				Comment = LTRIM(RTRIM(@Comment)),
				Decommissioned = @Decommissioned,
				IsMultiDeviceZone = @IsMultiDeviceZone,
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
ALTER PROCEDURE [dbo].[remispUsersInsertUpdateSingleItem]
	@ID int OUTPUT,
	@LDAPLogin nvarchar(255),
	@BadgeNumber int=null,
	@LastUser nvarchar(255),
	@ConcurrencyID rowversion OUTPUT,
	@IsActive INT = 1,
	@ByPassProduct INT = 0,
	@DefaultPage NVARCHAR(255)
AS
	DECLARE @ReturnValue int

	IF (@ID IS NULL AND NOT EXISTS (SELECT 1 FROM Users WITH(NOLOCK) WHERE LDAPLogin=@LDAPLogin)) -- New Item
	BEGIN
		INSERT INTO Users (LDAPLogin, BadgeNumber, LastUser, IsActive, DefaultPage, ByPassProduct)
		VALUES (LTRIM(RTRIM(@LDAPLogin)), @BadgeNumber, @LastUser, @IsActive, @DefaultPage, @ByPassProduct)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE IF(@ConcurrencyID IS NOT NULL) -- Exisiting Item
	BEGIN
		UPDATE Users SET
			LDAPLogin = LTRIM(RTRIM(@LDAPLogin)),
			BadgeNumber=@BadgeNumber,
			lastuser=@LastUser,
			IsActive=@IsActive,
			DefaultPage = @DefaultPage,
			ByPassProduct = @ByPassProduct
		WHERE ID = @ID AND ConcurrencyID = @ConcurrencyID

		SELECT @ReturnValue = @ID
	END

	SET @ConcurrencyID = (SELECT ConcurrencyID FROM Users WITH(NOLOCK) WHERE ID = @ReturnValue)
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
GRANT EXECUTE ON remispUsersInsertUpdateSingleItem TO Remi
GO
ALTER PROCEDURE [Relab].[remispResultsFileProcessing]
AS
BEGIN
	BEGIN TRANSACTION

	DECLARE @ID INT
	DECLARE @idoc INT
	DECLARE @RowID INT
	DECLARE @InfoRowID INT
	DECLARE @MaxID INT
	DECLARE @VerNum INT
	DECLARE @ResultID INT
	DECLARE @UnitID INT
	DECLARE @Val INT
	DECLARE @JobID INT
	DECLARE @FunctionalType INT
	DECLARE @UnitTypeLookupTypeID INT
	DECLARE @MeasurementTypeLookupTypeID INT
	DECLARE @TestStageID INT
	DECLARE @BaselineID INT
	DECLARE @TestID INT
	DECLARE @xml XML
	DECLARE @xmlPart XML
	DECLARE @LookupTypeName NVARCHAR(100)
	DECLARE @LookupTypeNameID INT
	DECLARE @TrackingLocationTypeName NVARCHAR(200)
	DECLARE @TestStageName NVARCHAR(400)
	DECLARE @DegradationVal DECIMAL(10,3)
	SET @ID = NULL
	DECLARE @FileID INT
	DECLARE @File NVARCHAR(200)
	CREATE TABLE #files (ID INT IDENTITY(1,1), [FileName] NVARCHAR(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS)

	BEGIN TRY
		IF ((SELECT COUNT(*) FROM Relab.ResultsXML x WHERE ISNULL(ErrorOccured, 0) = 0 AND ISNULL(IsProcessed,0)=0)=0)
		BEGIN
			PRINT 'No Files To Process'
			GOTO HANDLE_SUCCESS
			RETURN
		END
		ELSE
		BEGIN
			SET NOCOUNT ON

			SELECT @MeasurementTypeLookupTypeID=LookupTypeID FROM LookupType WHERE Name='MeasurementType'
			SELECT @UnitTypeLookupTypeID=LookupTypeID FROM LookupType WHERE Name='UnitType'
			
			SELECT @Val = COUNT(*) FROM Relab.ResultsXML x WHERE ISNULL(isProcessed,0)=0 AND ISNULL(ErrorOccured, 0) = 0
			
			SELECT TOP 1 @ID=x.ID, @xml = x.ResultXML, @VerNum = x.VerNum, @ResultID = x.ResultID
			FROM Relab.ResultsXML x
			WHERE ISNULL(IsProcessed,0)=0 AND ISNULL(ErrorOccured, 0) = 0
			ORDER BY ResultID, VerNum ASC
			
			SELECT @TestID = r.TestID , @TestStageName = ts.TestStageName, @UnitID = r.TestUnitID, @TestStageID  = r.TestStageID, @JobID = ts.JobID
			FROM Relab.Results r
				INNER JOIN TestStages ts ON r.TestStageID=ts.ID
			WHERE r.ID=@ResultID
			
			SELECT @BaselineID = ts.ID
			FROM TestStages ts
			WHERE JobID=@JobID AND LTRIM(RTRIM(LOWER(ts.TestStageName)))='baseline'
			
			SELECT @TrackingLocationTypeName =tlt.TrackingLocationTypeName, @DegradationVal = t.DegradationVal
			FROM Tests t
				INNER JOIN TrackingLocationsForTests tlft ON tlft.TestID=t.ID
				INNER JOIN TrackingLocationTypes tlt ON tlft.TrackingLocationtypeID=tlt.ID
			WHERE t.ID=@TestID
			
			PRINT '# Files To Process: ' + CONVERT(VARCHAR, @Val)
			PRINT 'XMLID: ' + CONVERT(VARCHAR, @ID)
			PRINT 'ResultID: ' + CONVERT(VARCHAR, @ResultID)
			PRINT 'TestID: ' + CONVERT(VARCHAR, @TestID)
			PRINT 'UnitID: ' + CONVERT(VARCHAR, @UnitID)
			PRINT 'JobID: ' + CONVERT(VARCHAR, @JobID)
			PRINT 'TestStageID: ' + CONVERT(VARCHAR, @TestStageID)
			PRINT 'TestStageName: ' + CONVERT(VARCHAR, @TestStageName)
			PRINT 'TrackingLocationTypeName: ' + CONVERT(VARCHAR, @TrackingLocationTypeName)
			PRINT 'DegradationVal: ' + CONVERT(VARCHAR, ISNULL(@DegradationVal,0.0))
			PRINT 'BaselineID: ' + CONVERT(VARCHAR, @BaselineID)

			SELECT @xmlPart = T.c.query('.') 
			FROM @xml.nodes('/TestResults/Header') T(c)
					
			select @FunctionalType = T.c.query('FunctionalType').value('.', 'nvarchar(400)')
			FROM @xmlPart.nodes('/Header') T(c)

			IF (@TrackingLocationTypeName IS NOT NULL And @TrackingLocationTypeName = 'Functional Station' AND @FunctionalType <> 0)
			BEGIN
				PRINT @FunctionalType
				IF (@FunctionalType = 0)
				BEGIN
					SET @LookupTypeName = 'MeasurementType'
				END
				ELSE IF (@FunctionalType = 1)
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
				
				PRINT 'Test IS ' + @LookupTypeName
			END
			ELSE
			BEGIN
				SET @LookupTypeName = 'MeasurementType'
				
				PRINT 'INSERT Lookups UnitType'
				SELECT DISTINCT (1) AS LookupID, T.c.query('Units').value('.', 'nvarchar(max)') AS UnitType, 1 AS Active
				INTO #LookupsUnitType
				FROM @xml.nodes('/TestResults/Measurements/Measurement') T(c)
				WHERE LTRIM(RTRIM(CONVERT(VARCHAR(MAX), T.c.query('Units').value('.', 'nvarchar(max)')))) NOT IN ( (SELECT [Values] FROM Lookups WHERE LookupTypeID=@UnitTypeLookupTypeID)) 
					AND CONVERT(VARCHAR(MAX), T.c.query('Units').value('.', 'nvarchar(max)')) NOT IN ('N/A')
				
				SELECT @MaxID = MAX(LookupID)+1 FROM Lookups
				
				INSERT INTO Lookups (LookupID, LookupTypeID,[Values], IsActive)
				SELECT (ROW_NUMBER() OVER (ORDER BY LookupID)) + @MaxID AS LookupID, @UnitTypeLookupTypeID AS LookupTypeID, UnitType AS [Values], Active
				FROM #LookupsUnitType
				
				DROP TABLE #LookupsUnitType
			
				PRINT 'INSERT Lookups MeasurementType'
				SELECT DISTINCT (1) AS LookupID, T.c.query('MeasurementName').value('.', 'nvarchar(max)') AS MeasurementType, 1 AS Active
				INTO #LookupsMeasurementType
				FROM @xml.nodes('/TestResults/Measurements/Measurement') T(c)
				WHERE LTRIM(RTRIM(CONVERT(VARCHAR(MAX), T.c.query('MeasurementName').value('.', 'nvarchar(max)')))) NOT IN ( (SELECT [Values] FROM Lookups WHERE LookupTypeID=@MeasurementTypeLookupTypeID)) 
					AND CONVERT(VARCHAR(MAX), T.c.query('MeasurementName').value('.', 'nvarchar(max)')) NOT IN ('N/A')
				
				SELECT @MaxID = MAX(LookupID)+1 FROM Lookups
				
				INSERT INTO Lookups (LookupID, LookupTypeID, [Values], IsActive)
				SELECT (ROW_NUMBER() OVER (ORDER BY LookupID)) + @MaxID AS LookupID, @MeasurementTypeLookupTypeID AS LookupTypeID, MeasurementType AS [Values], Active
				FROM #LookupsMeasurementType
			
				DROP TABLE #LookupsMeasurementType
			END
			
			PRINT 'Load Information into temp table'
			SELECT  ROW_NUMBER() OVER (ORDER BY T.c) AS RowID, T.c.query('.') AS value 
			INTO #temp3
			FROM @xml.nodes('/TestResults/Information/Info') T(c)
			
			SELECT @InfoRowID = MIN(RowID) FROM #temp3
			DECLARE @Version NVARCHAR(50)
			DECLARE @ProductConfigCommon NVARCHAR(50)
			DECLARE @SequenceConfigCommon NVARCHAR(50)
			DECLARE @StationConfigCommon NVARCHAR(50)
			DECLARE @TestConfigCommon NVARCHAR(50)
			DECLARE @Mode NVARCHAR(50)
			DECLARE @ConfigXML XML
			SET @ConfigXML = NULL

			SELECT @Mode=T.c.query('Value').value('.', 'nvarchar(max)')
			FROM @xml.nodes('/TestResults/Information/Info') T(c)
			WHERE T.c.query('Name').value('.', 'nvarchar(max)') = 'OperatingMode'
			
			SELECT @Version=T.c.query('Value').value('.', 'nvarchar(max)')
			FROM @xml.nodes('/TestResults/Information/Info') T(c)
			WHERE T.c.query('Name').value('.', 'nvarchar(max)') = 'Test System Version'
			
			IF (@Version IS NOT NULL)
			BEGIN
				SELECT @Version = pvt.[1] + '.' + pvt.[2]
				FROM  
					(
						SELECT RowID, s as val
							FROM dbo.Split('.',@Version)
					) a
					PIVOT (
							MAX(val) 
							FOR RowID IN ([1],[2],[3],[4])
							) as pvt
			END
			
			WHILE (@InfoRowID IS NOT NULL)
			BEGIN
				SELECT @xmlPart  = value FROM #temp3 WHERE RowID=@InfoRowID	
				SET @ConfigXML = NULL

				SELECT T.c.query('Name').value('.', 'nvarchar(max)') AS Name, T.c.query('Value').value('.', 'nvarchar(max)') AS Value
				INTO #information
				FROM @xmlPart.nodes('/Info') T(c)
					
				IF EXISTS (SELECT 1 FROM #information WHERE Name='ProductConfigCommon')
				BEGIN
					SET @ConfigXML = NULL
					SELECT @ProductConfigCommon=Value FROM #information WHERE Name='ProductConfigCommon'

					SELECT @ConfigXML = (SELECT T.c.query('.') FROM c.Definition.nodes('/ArrayOfProductConfig/ProductConfig') T(c) WHERE T.c.value('@Name', 'varchar(MAX)') = @ProductConfigCommon)
					FROM dbo.Configurations c 
						INNER JOIN Lookups lct ON lct.LookupID=c.ConfigTypeID
						INNER JOIN Lookups lm ON lm.LookupID=c.ModeID
					WHERE lct.[Values] = 'ProductConfigCommon' AND c.[Version]=@Version AND lm.[Values] = @Mode
					
					IF (@ConfigXML IS NOT NULL)
					BEGIN
						UPDATE x
						SET x.ProductXML = @ConfigXML
						FROM Relab.ResultsXML x
						WHERE ID=@ID
					END
				END
					
				IF EXISTS (SELECT 1 FROM #information WHERE Name='SequenceConfigCommon')
				BEGIN
					SET @ConfigXML = NULL
					SELECT @SequenceConfigCommon=Value FROM #information WHERE Name='SequenceConfigCommon'
					
					SELECT @ConfigXML = (SELECT T.c.query('.') FROM c.Definition.nodes('/ArrayOfSequenceConfigCommon/SequenceConfigCommon') T(c) WHERE T.c.value('@Name', 'varchar(MAX)') = @SequenceConfigCommon)
					FROM dbo.Configurations c 
						INNER JOIN Lookups lct ON lct.LookupID=c.ConfigTypeID
						INNER JOIN Lookups lm ON lm.LookupID=c.ModeID
					WHERE lct.[Values] = 'SequenceConfigCommon' AND c.[Version]=@Version AND lm.[Values] = @Mode
					
					IF (@ConfigXML IS NOT NULL)
					BEGIN
						UPDATE x
						SET x.SequenceXML = @ConfigXML
						FROM Relab.ResultsXML x
						WHERE ID=@ID
					END
				END
				
				IF EXISTS (SELECT 1 FROM #information WHERE Name='StationConfigCommon')
				BEGIN
					SET @ConfigXML = NULL
					SELECT @StationConfigCommon=Value FROM #information WHERE Name='StationConfigCommon'

					SELECT @ConfigXML = (SELECT T.c.query('.') FROM c.Definition.nodes('/ArrayOfStationConfig/StationConfig') T(c) WHERE T.c.value('@Name', 'varchar(MAX)') = @StationConfigCommon)
					FROM dbo.Configurations c 
						INNER JOIN Lookups lct ON lct.LookupID=c.ConfigTypeID
						INNER JOIN Lookups lm ON lm.LookupID=c.ModeID
					WHERE lct.[Values] = 'StationConfigCommon' AND c.[Version]=@Version AND lm.[Values] = @Mode
					
					IF (@ConfigXML IS NOT NULL)
					BEGIN
						UPDATE x
						SET x.StationXML = @ConfigXML
						FROM Relab.ResultsXML x
						WHERE ID=@ID
					END
				END
				
				IF EXISTS (SELECT 1 FROM #information WHERE Name='TestConfigCommon')
				BEGIN
					SET @ConfigXML = NULL
					SELECT @TestConfigCommon=Value FROM #information WHERE Name='TestConfigCommon'
					
					SELECT @ConfigXML = (SELECT T.c.query('.') FROM c.Definition.nodes('/ArrayOfTestConfig/TestConfig') T(c) WHERE T.c.value('@Name', 'varchar(MAX)') = @TestConfigCommon)
					FROM dbo.Configurations c 
						INNER JOIN Lookups lct ON lct.LookupID=c.ConfigTypeID
						INNER JOIN Lookups lm ON lm.LookupID=c.ModeID
					WHERE lct.[Values] = 'TestConfigCommon' AND c.[Version]=@Version AND lm.[Values] = @Mode
					
					IF (@ConfigXML IS NOT NULL)
					BEGIN
						UPDATE x
						SET x.TestXML = (SELECT x.TestXML, @ConfigXML FOR XML PATH('TestConfigs'))
						FROM Relab.ResultsXML x
						WHERE ID=@ID
					END
				END			
				
				UPDATE ri
				SET IsArchived=1
				FROM Relab.ResultsInformation ri
					INNER JOIN Relab.ResultsXML rxml ON ri.XMLID=rxml.ID
					INNER JOIN #information i ON i.Name = ri.Name
				WHERE rxml.VerNum < @VerNum AND ISNULL(ri.IsArchived,0)=0 AND rxml.ResultID=@ResultID
					
				PRINT 'INSERT Version ' + CONVERT(NVARCHAR, @VerNum) + ' Information'
				INSERT INTO Relab.ResultsInformation(XMLID, Name, Value, IsArchived)
				SELECT @ID AS XMLID, Name, Value, 0
				FROM #information

				SELECT @InfoRowID = MIN(RowID) FROM #temp3 WHERE RowID > @InfoRowID
				
				DROP TABLE #information
			END

			PRINT 'Load Informational Measurements into temp table'
			SELECT  ROW_NUMBER() OVER (ORDER BY T.c) AS RowID, T.c.query('.') AS value 
			INTO #temp4
			FROM @xml.nodes('/TestResults/Measurements/Measurement') T(c)
			WHERE LOWER(T.c.query('MeasurementName').value('.', 'nvarchar(max)')) IN
				('apx software version','id power supply 2','id power supply 1','id bt tester','tester sw version',
				'start','start utc','end','end utc', 'os','osversion','os version', 'cameraid','hwserialnumber','hardware id','hardwareid',
				'build','apx hardware model')
				
			SELECT @InfoRowID = MIN(RowID) FROM #temp4
			
			WHILE (@InfoRowID IS NOT NULL)
			BEGIN
				SELECT @xmlPart  = value FROM #temp4 WHERE RowID=@InfoRowID	
				
				SELECT T.c.query('MeasurementName').value('.', 'nvarchar(max)') AS Name, T.c.query('MeasuredValue').value('.', 'nvarchar(max)') AS Value
				INTO #information2
				FROM @xmlPart.nodes('/Info') T(c)
				
				UPDATE ri
				SET IsArchived=1
				FROM Relab.ResultsInformation ri
					INNER JOIN Relab.ResultsXML rxml ON ri.XMLID=rxml.ID
					INNER JOIN #information2 i ON i.Name = ri.Name
				WHERE rxml.VerNum < @VerNum AND ISNULL(ri.IsArchived,0)=0 AND rxml.ResultID=@ResultID
					
				PRINT 'INSERT Version ' + CONVERT(NVARCHAR, @VerNum) + ' Information'
				INSERT INTO Relab.ResultsInformation(XMLID, Name, Value, IsArchived)
				SELECT @ID AS XMLID, Name, Value, 0
				FROM #information2

				SELECT @InfoRowID = MIN(RowID) FROM #temp4 WHERE RowID > @InfoRowID
				
				DROP TABLE #information2
			END
			
			PRINT 'Load Measurements into temp table'
			SELECT  ROW_NUMBER() OVER (ORDER BY T.c) AS RowID, T.c.query('.') AS value 
			INTO #temp2
			FROM @xml.nodes('/TestResults/Measurements/Measurement') T(c)
			WHERE LOWER(T.c.query('MeasurementName').value('.', 'nvarchar(max)')) NOT IN
				('apx software version','id power supply 2','id power supply 1','id bt tester','tester sw version',
				'start','start utc','end','end utc', 'os','osversion','os version', 'cameraid','hwserialnumber','hardware id',
				'build','apx hardware model', 'cableloss')

			SELECT @RowID = MIN(RowID) FROM #temp2

			SELECT @LookupTypeNameID=LookupTypeID FROM LookupType WHERE Name=@LookupTypeName
			
			WHILE (@RowID IS NOT NULL)
			BEGIN
				DECLARE @FileName NVARCHAR(200)
				SET @FileName = NULL

				SELECT @xmlPart  = value FROM #temp2 WHERE RowID=@RowID

				SELECT CASE WHEN l2.LookupID IS NULL THEN l3.LookupID ELSE l2.LookupID END AS MeasurementTypeID,
					T.c.query('LowerLimit').value('.', 'nvarchar(max)') AS LowerLimit,
					T.c.query('UpperLimit').value('.', 'nvarchar(max)') AS UpperLimit,
					T.c.query('MeasuredValue').value('.', 'nvarchar(max)') AS MeasurementValue,
					(CASE WHEN T.c.query('PassFail').value('.', 'nvarchar(max)') = 'Pass' THEN 1 WHEN T.c.query('PassFail').value('.', 'nvarchar(max)') = 'Fail' Then 0 ELSE -1 END) AS PassFail,
					l.LookupID AS UnitTypeID,
					T.c.query('FileName').value('.', 'nvarchar(max)') AS [FileName], 
					[Relab].[ResultsXMLParametersComma] ((select T.c.query('.') from @xmlPart.nodes('/Measurement/Parameters') T(c))) AS Parameters,
					T.c.query('Comments').value('.', 'nvarchar(1000)') AS [Comment],
					T.c.query('Description').value('.', 'nvarchar(800)') AS [Description],
					CAST(NULL AS DECIMAL(10,3)) AS DegradationVal
				INTO #measurement
				FROM @xmlPart.nodes('/Measurement') T(c)
					LEFT OUTER JOIN Lookups l ON l.LookupTypeID=@UnitTypeLookupTypeID AND l.[Values]=LTRIM(RTRIM(CONVERT(VARCHAR(MAX), T.c.query('Units').value('.', 'nvarchar(max)'))))
					LEFT OUTER JOIN Lookups l2 ON l2.LookupTypeID=@LookupTypeNameID AND l2.[Values]=LTRIM(RTRIM(CONVERT(VARCHAR(MAX), T.c.query('MeasurementName').value('.', 'nvarchar(max)'))))
					LEFT OUTER JOIN Lookups l3 ON l3.LookupTypeID=@MeasurementTypeLookupTypeID AND l3.[Values]=LTRIM(RTRIM(CONVERT(VARCHAR(MAX), T.c.query('MeasurementName').value('.', 'nvarchar(max)'))))

				UPDATE #measurement
				SET Comment=''
				WHERE Comment='N/A'

				UPDATE #measurement
				SET Description=null
				WHERE Description='N/A' or Description='NA'
				
				DELETE FROM #files

				IF (LTRIM(RTRIM(LOWER(@TestStageName))) NOT IN ('baseline', 'analysis') AND LTRIM(RTRIM(LOWER(@TestStageName))) NOT LIKE '%Calibra%' AND EXISTS(SELECT 1 FROM #measurement WHERE PassFail = -1))
				BEGIN
					DECLARE @BaselineResultID INT
					DECLARE @BaseRowID INT
					
					SELECT @BaselineResultID = r.ID
					FROM Relab.Results r
					WHERE r.TestUnitID=@UnitID AND r.TestID=@TestID AND r.TestStageID=@BaselineID

					PRINT 'BaselineResultID: ' + CONVERT(VARCHAR, @BaselineResultID)
					
					SELECT ROW_NUMBER() OVER (ORDER BY rm.ID) AS RowID, rm.MeasurementTypeID AS BaselineMeasurementTypeID, rm.MeasurementValue AS BaselineMeasurementValue, 
						LTRIM(RTRIM(ISNULL(Relab.ResultsParametersComma(rm.ID),''))) AS BaselineParameters,
						m.MeasurementTypeID, m.MeasurementValue, LTRIM(RTRIM(ISNULL(m.Parameters,''))) AS Parameters
					INTO #MeasurementCompare
					FROM Relab.ResultsMeasurements rm
						INNER JOIN #measurement m ON rm.MeasurementTypeID=m.MeasurementTypeID AND LTRIM(RTRIM(ISNULL(Relab.ResultsParametersComma(rm.ID),''))) = LTRIM(RTRIM(ISNULL(m.Parameters,'')))
					WHERE rm.ResultID=@BaselineResultID AND ISNULL(rm.Archived, 0) = 0 AND m.PassFail=-1

					SELECT @BaseRowID = MIN(RowID) FROM #MeasurementCompare
					
					WHILE (@BaseRowID IS NOT NULL)
					BEGIN
						DECLARE @BParmaeters NVARCHAR(MAX)
						DECLARE @BMeasurementTypeID INT
						DECLARE @temp TABLE (val DECIMAL(10,3))
						DECLARE @bv DECIMAL(10,3)
						DECLARE @v DECIMAL(10,3)
						DECLARE @result DECIMAL(10,3)
						DECLARE @bPassFail BIT
						SET @result = 0.0
						SET @v = 0.0
						SET @bv = 0.0
						
						SELECT @BMeasurementTypeID = MeasurementTypeID, @bv = CONVERT(DECIMAL(10,3), BaselineMeasurementValue), @v = CONVERT(DECIMAL(10,3), MeasurementValue), 
							@BParmaeters = Parameters
						FROM #MeasurementCompare 
						WHERE RowID=@BaseRowID

						PRINT 'Baseline Value: ' + CONVERT(VARCHAR, @bv)     
						PRINT 'Current Value: ' + CONVERT(VARCHAR, @v)
						PRINT 'BMeasurementTypeID: ' + CONVERT(VARCHAR, @BMeasurementTypeID)
						
						INSERT INTO @temp VALUES (@bv)
						INSERT INTO @temp VALUES (@v)
						
						SELECT @result = STDEV(val) FROM @temp
						
						PRINT 'STDEV Result: ' + CONVERT(VARCHAR, @result)
						
						UPDATE #measurement
						SET PassFail = (CASE WHEN (@result > @DegradationVal) THEN 0 ELSE 1 END),
							DegradationVal = @result
						WHERE MeasurementTypeID = @BMeasurementTypeID AND LTRIM(RTRIM(ISNULL(Parameters,'')))=LTRIM(RTRIM(ISNULL(@BParmaeters,'')))
						
						SELECT @BaseRowID = MIN(RowID) FROM #MeasurementCompare WHERE RowID > @BaseRowID
						DELETE FROM @temp
					END

					DROP TABLE #MeasurementCompare
				END
				
				IF (@VerNum = 1)
				BEGIN
					PRINT 'INSERT Version 1 Measurements'
					INSERT INTO Relab.ResultsMeasurements (ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, MeasurementUnitTypeID, PassFail, ReTestNum, Archived, XMLID, Comment, Description, DegradationVal)
					SELECT @ResultID As ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, UnitTypeID, CONVERT(BIT, PassFail), 1, 0, @ID, Comment, Description, DegradationVal AS DegradationVal
					FROM #measurement

					DECLARE @ResultMeasurementID INT
					SET @ResultMeasurementID = @@IDENTITY
					
					PRINT 'INSERT Version 1 Parameters'
					INSERT INTO Relab.ResultsParameters (ResultMeasurementID, ParameterName, Value)
					SELECT @ResultMeasurementID AS ResultMeasurementID, T.c.value('@ParameterName','nvarchar(max)') AS ParameterName, T.c.query('.').value('.', 'nvarchar(max)') AS Value
					FROM @xmlPart.nodes('/Measurement/Parameters/Parameter') T(c)

					PRINT 'Build #Files Table'
					SELECT @FileName = LTRIM(RTRIM(ISNULL([FileName],''))) FROM #measurement
					
					INSERT INTO #files ([FileName])
					SELECT T.c.query('.').value('.', 'nvarchar(max)') AS [FileName]
					FROM @xmlPart.nodes('/Measurement/Files/FileName') T(c)
					WHERE LOWER(T.c.query('.').value('.', 'nvarchar(max)')) <> 'n/a'

					IF (LTRIM(RTRIM(ISNULL(@FileName, ''))) <> '' AND LOWER(@FileName) <> 'n/a')
					BEGIN
						INSERT INTO #files (FileName) VALUES (LTRIM(RTRIM(@FileName)))
					END
					
					SET @FileID = NULL
					SET @File = NULL
					SELECT @FileID = MIN(ID) FROM #files
					
					WHILE (@FileID IS NOT NULL)
					BEGIN
						SELECT @File = [FileName] FROM #files where ID=@FileID
						PRINT 'INSERT Files'
						UPDATE TOP(1) Relab.ResultsMeasurementsFiles 
						SET ResultMeasurementID=@ResultMeasurementID
						FROM Relab.ResultsMeasurementsFiles 
						WHERE ResultMeasurementID IS NULL AND
							LOWER(LTRIM(RTRIM(@File))) = LOWER(LTRIM(RTRIM(Relab.ResultsMeasurementsFiles.FileName)))
							
						SELECT @FileID = MIN(ID) FROM #files WHERE ID > @FileID
					END
										
					IF NOT EXISTS ((SELECT 1 FROM Relab.ResultsMeasurementsFiles 
									INNER JOIN #files f ON LOWER(LTRIM(RTRIM(f.[FileName]))) = LOWER(LTRIM(RTRIM(Relab.ResultsMeasurementsFiles.FileName)))
								WHERE ResultMeasurementID = @ResultMeasurementID)) AND (SELECT COUNT(*) FROM #files) > 0
					BEGIN

						PRINT 'Files Didnt Insert Correctly Rolling Back'
						GOTO HANDLE_ERROR
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
						INSERT INTO Relab.ResultsMeasurements (ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, MeasurementUnitTypeID, PassFail, ReTestNum, Archived, XMLID, Comment, Description, DegradationVal)
						SELECT @ResultID As ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, UnitTypeID, CONVERT(BIT, PassFail), @ReTestNum, 0, @ID, Comment, Description, DegradationVal AS DegradationVal
						FROM #measurement
						
						DECLARE @ResultMeasurementID2 INT
						SET @ResultMeasurementID2 = @@IDENTITY
						
						PRINT 'Build #Files Table'
						SELECT @FileName = LTRIM(RTRIM(ISNULL([FileName], ''))) FROM #measurement

						INSERT INTO #files ([FileName])
						SELECT T.c.query('.').value('.', 'nvarchar(max)') AS [FileName]
						FROM @xmlPart.nodes('/Measurement/Files/FileName') T(c)
						WHERE LOWER(T.c.query('.').value('.', 'nvarchar(max)')) <> 'n/a'
						
						IF (LTRIM(RTRIM(ISNULL(@FileName, ''))) <> '' AND LOWER(@FileName) <> 'n/a')
						BEGIN
							INSERT INTO #files (FileName) VALUES (LTRIM(RTRIM(@FileName)))
						END
						
						SET @FileID = NULL
						SET @File = NULL
						SELECT @FileID = MIN(ID) FROM #files
						
						WHILE (@FileID IS NOT NULL)
						BEGIN
							SELECT @File = [FileName] FROM #files where ID=@FileID
							PRINT 'INSERT Files'
							UPDATE TOP(1) Relab.ResultsMeasurementsFiles 
							SET ResultMeasurementID=@ResultMeasurementID2
							FROM Relab.ResultsMeasurementsFiles 
							WHERE ResultMeasurementID IS NULL AND
								LOWER(LTRIM(RTRIM(@File))) = LOWER(LTRIM(RTRIM(Relab.ResultsMeasurementsFiles.[FileName])))
								
							SELECT @FileID = MIN(ID) FROM #files WHERE ID > @FileID
						END
						
						IF NOT EXISTS ((SELECT 1 FROM Relab.ResultsMeasurementsFiles 
									INNER JOIN #files f ON LOWER(LTRIM(RTRIM(f.[FileName]))) = LOWER(LTRIM(RTRIM(Relab.ResultsMeasurementsFiles.[FileName])))
								WHERE ResultMeasurementID = @ResultMeasurementID2)) AND (SELECT COUNT(*) FROM #files) > 0
						BEGIN
							PRINT 'Files Didnt Insert Correctly Rolling Back'
							GOTO HANDLE_ERROR
						END
						
						IF (LTRIM(RTRIM(@Parameters)) <> '')
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
						INSERT INTO Relab.ResultsMeasurements (ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, MeasurementUnitTypeID, PassFail, ReTestNum, Archived, XMLID, Comment, Description, DegradationVal)
						SELECT @ResultID As ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, UnitTypeID, CONVERT(BIT, PassFail), 1, 0, @ID, Comment, Description, DegradationVal AS DegradationVal
						FROM #measurement

						DECLARE @ResultMeasurementID3 INT
						SET @ResultMeasurementID3 = @@IDENTITY
						
						PRINT 'Build #Files Table'
						SELECT @FileName = LTRIM(RTRIM([FileName])) FROM #measurement
						
						INSERT INTO #files ([FileName])
						SELECT T.c.query('.').value('.', 'nvarchar(max)') AS [FileName]
						FROM @xmlPart.nodes('/Measurement/Files/FileName') T(c)
						WHERE LOWER(T.c.query('.').value('.', 'nvarchar(max)')) <> 'n/a'
						
						IF (LTRIM(RTRIM(ISNULL(@FileName, ''))) <> '' AND LOWER(@FileName) <> 'n/a')
						BEGIN
							INSERT INTO #files (FileName) VALUES (LTRIM(RTRIM(@FileName)))
						END
						
						SET @FileID = NULL
						SET @File = NULL
						SELECT @FileID = MIN(ID) FROM #files
						
						WHILE (@FileID IS NOT NULL)
						BEGIN
							SELECT @File = [FileName] FROM #files where ID=@FileID
							PRINT 'INSERT Files'
							UPDATE TOP(1) Relab.ResultsMeasurementsFiles 
							SET ResultMeasurementID=@ResultMeasurementID3
							FROM Relab.ResultsMeasurementsFiles 
							WHERE ResultMeasurementID IS NULL AND
								LOWER(LTRIM(RTRIM(@File))) = LOWER(LTRIM(RTRIM(Relab.ResultsMeasurementsFiles.[FileName])))
								
							SELECT @FileID = MIN(ID) FROM #files WHERE ID > @FileID
						END
										
						IF NOT EXISTS ((SELECT 1 FROM Relab.ResultsMeasurementsFiles 
									INNER JOIN #files f ON LOWER(LTRIM(RTRIM(f.[FileName]))) = LOWER(LTRIM(RTRIM(Relab.ResultsMeasurementsFiles.FileName)))
								WHERE ResultMeasurementID = @ResultMeasurementID3)) AND (SELECT COUNT(*) FROM #files) > 0
						BEGIN
							PRINT 'Files Didnt Insert Correctly Rolling Back'
							GOTO HANDLE_ERROR
						END
					
						IF (LTRIM(RTRIM(@Parameters)) <> '')
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
			
			DROP TABLE #files
			
			PRINT 'Update Result To Be Processed'
			UPDATE Relab.ResultsXML SET IsProcessed=1 WHERE ID=@ID
			
			UPDATE Relab.Results
			SET PassFail=CASE WHEN (SELECT COUNT(*) FROM Relab.ResultsMeasurements WHERE ResultID=@ResultID AND Archived=0 AND PassFail=0) > 0 THEN 0 ELSE 1 END
			WHERE ID=@ResultID
		
			DROP TABLE #temp2
			SET NOCOUNT OFF

			GOTO HANDLE_SUCCESS
		END
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
			
			IF (@ID IS NOT NULL AND @ID > 0)
			BEGIN
				UPDATE Relab.ResultsXML SET ErrorOccured=1 WHERE ID=@ID
			END
		END
		RETURN
END
GO
GRANT EXECUTE ON Relab.remispResultsFileProcessing TO REMI
GO
rollback tran