/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        (local).REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 9/12/2014 12:13:34 PM

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
PRINT N'Dropping constraints from [dbo].[Batches]'
GO
ALTER TABLE [dbo].[Batches] DROP CONSTRAINT [DF__Batches__Order__7874C3FF]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[Batches]'
GO
ALTER TABLE [dbo].[Batches] ADD
[OrientationID] [int] NULL
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[JobOrientation]'
GO
CREATE TABLE [dbo].[JobOrientation]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[JobID] [int] NOT NULL,
[ProductTypeID] [int] NOT NULL,
[NumUnits] [int] NOT NULL,
[NumDrops] [int] NOT NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_JobOrientation_CreatedDate] DEFAULT (getutcdate()),
[Description] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[IsActive] [bit] NOT NULL CONSTRAINT [DF_JobOrientation_IsActive] DEFAULT ((1)),
[Definition] [xml] NOT NULL,
[Name] [nvarchar] (150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating primary key [PK_JobOrientation] on [dbo].[JobOrientation]'
GO
ALTER TABLE [dbo].[JobOrientation] ADD CONSTRAINT [PK_JobOrientation] PRIMARY KEY CLUSTERED  ([ID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[remispJobOrientationSave]'
GO
CREATE PROCEDURE [dbo].[remispJobOrientationSave] @ID INT = 0, @Name NVARCHAR(150), @JobID INT, @ProductTypeID INT, @Description NVARCHAR(250), @IsActive BIT, @Definition NTEXT = NULL
AS
BEGIN
	IF (@ID = 0)
	BEGIN
		DECLARE @XML XML
		DECLARE @NumUnits INT
		DECLARE @NumDrops INT
		SELECT @XML = CONVERT(XML, @Definition)
		
		SELECT @NumUnits=MAX(T.c.value('(@Unit)[1]', 'int')), @NumDrops =MAX(T.c.value('(@Drop)[1]', 'int'))
		FROM @XML.nodes('/Orientations/Orientation') as T(c)

		IF (@NumUnits IS NULL)
		BEGIN
			SET @NumUnits = 0
		END
		
		IF (@NumDrops IS NULL)
		BEGIN
			SET @NumDrops = 0
		END
				
		INSERT INTO JobOrientation (JobID, ProductTypeID, NumUnits, NumDrops, Description, IsActive, Definition, Name)
		VALUES (@JobID, @ProductTypeID, @NumUnits, @NumDrops, @Description, @IsActive, @XML, @Name)
	END
	ELSE
	BEGIN
		UPDATE JobOrientation
		SET IsActive = @IsActive, Name = @Name, Description=@Description, ProductTypeID=@ProductTypeID
		WHERE ID=@ID
	END
END
GO
GRANT EXECUTE ON [dbo].[remispJobOrientationSave] TO REMI
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[remispGetJobOrientations]'
GO
CREATE PROCEDURE [dbo].[remispGetJobOrientations] @JobID INT
AS
BEGIN
	SELECT jo.ID, jo.Name, jo.ProductTypeID, l.[Values] AS ProductType, jo.NumUnits, jo.NumDrops,
		jo.Description, jo.CreatedDate, jo.IsActive, jo.Definition
	FROM JobOrientation jo
		INNER JOIN Lookups l ON l.LookupID=jo.ProductTypeID AND l.[Type]='ProductType'
	WHERE jo.JobID=@JobID
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[remispGetOrientation]'
GO
CREATE PROCEDURE [dbo].[remispGetOrientation] @ID INT
AS
BEGIN
	SELECT jo.ID, jo.Name, jo.ProductTypeID, l.[Values] AS ProductType, jo.NumUnits, jo.NumDrops,
		jo.Description, jo.CreatedDate, jo.IsActive, jo.Definition, jo.JobID
	FROM JobOrientation jo
		INNER JOIN Lookups l ON l.LookupID=jo.ProductTypeID AND l.[Type]='ProductType'
	WHERE jo.ID = @ID
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesSelectByQRANumber]'
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectByQRANumber]
	@QRANumber nvarchar(11) = null,
	@RecordCount int = null OUTPUT
AS
	IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (SELECT COUNT(*) FROM Batches WITH(NOLOCK) WHERE QRANumber = @QRANumber)
		RETURN
	END

	declare @batchid int
	DECLARE @TestStageID INT
	DECLARE @JobID INT
	declare @jobname nvarchar(400)
	declare @teststagename nvarchar(400)
	select @batchid = id, @teststagename=TestStageName, @jobname = JobName from Batches WITH(NOLOCK) where QRANumber = @QRANumber
	declare @testunitcount int = (select count(*) from testunits as tu WITH(NOLOCK) where tu.batchid = @batchid)
	SELECT @JobID = ID FROM Jobs WHERE JobName=@jobname
	SELECT @TestStageID = ID FROM TestStages ts WHERE JobID=@JobID AND TestStageName = @teststagename

	DECLARE @TSTimeLeft REAL
	DECLARE @JobTimeLeft REAL
	EXEC remispGetEstimatedTSTime @batchid,@teststagename,@jobname, @TSTimeLeft OUTPUT, @JobTimeLeft OUTPUT, @TestStageID, @JobID
	
	SELECT BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,BatchesRows.JobName,
	BatchesRows.LastUser,BatchesRows.Priority AS PriorityID,p.ProductGroupName,BatchesRows.QRANumber,BatchesRows.RequestPurpose As RequestPurposeID,batchesrows.ProductTypeID,batchesrows.AccessoryGroupID,
	batchesrows.ProductID,BatchesRows.TestCenterLocationID,
	l3.[Values] AS TestCenterLocation,BatchesRows.TestStageName,
	BatchesRows.TestStageCompletionStatus, @testunitcount as testUnitCount,
	(CASE WHEN j.WILocation IS NULL THEN NULL ELSE j.WILocation END) AS jobWILocation,@TSTimeLeft AS EstTSCompletionTime,@JobTimeLeft AS EstJobCompletionTime, 
	(@testunitcount -
			  -- TrackingLocations was only used because we were testing based on string comparison and this isn't needed anymore because we are basing on ID which DeviceTrackingLog can be used.
              (select COUNT(*) 
			  from TestUnits as tu WITH(NOLOCK)
			  INNER JOIN DeviceTrackingLog as dtl WITH(NOLOCK) ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			  where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
	) as HasUnitsToReturnToRequestor,
	ISNULL(
			(SELECT AssignedTo 
			FROM TaskAssignments ta WITH(NOLOCK)
				--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
				INNER JOIN TestStages ts WITH(NOLOCK) ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName AND ts.JobID = j.ID
			WHERE ta.BatchID = BatchesRows.ID and ta.Active=1), 
			(SELECT AssignedTo 
			FROM TaskAssignments ta WITH(NOLOCK)
			WHERE ta.Active=1 AND ISNULL(ta.taskID,0) = 0 AND ta.BatchID = BatchesRows.ID)
		) as ActiveTaskAssignee,
	BatchesRows.CPRNumber, l.[Values] AS ProductType, l2.[Values] As AccessoryGroupName,
	(
		SELECT TOP 1 CONVERT(BIT, 1) FROM TestExceptions WITH(NOLOCK) WHERE LookupID=3 AND Value IN (SELECT ID FROM TestUnits WITH(NOLOCK) WHERE BatchID=BatchesRows.ID)
    ) AS HasBatchSpecificExceptions,BatchesRows.RQID As ReqID, AssemblyNumber, AssemblyRevision, HWRevision, PartName, ReportRequiredBy, ReportApprovedDate,
	IsMQual, j.ID AS JobID, ExecutiveSummary, MechanicalTools, l4.[Values] AS RequestPurpose, l5.[Values] AS Priority, BatchesRows.OrientationID
	from Batches as BatchesRows WITH(NOLOCK)
		LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = BatchesRows.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
		INNER JOIN Products p WITH(NOLOCK) ON BatchesRows.productID=p.ID
		LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND BatchesRows.ProductTypeID=l.LookupID  
		LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.Type='AccessoryType' AND BatchesRows.AccessoryGroupID=l2.LookupID  
		LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.Type='TestCenter' AND BatchesRows.TestCenterLocationID=l3.LookupID  
		LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON l4.Type='RequestPurpose' AND BatchesRows.RequestPurpose=l4.LookupID  
		LEFT OUTER JOIN Lookups l5 WITH(NOLOCK) ON l5.Type='Priority' AND BatchesRows.Priority=l5.LookupID
	WHERE QRANumber = @QRANumber

select bc.DateAdded, bc.ID, bc.[Text], bc.LastUser from BatchComments as bc WITH(NOLOCK) where BatchID = @batchid and Active = 1 order by DateAdded desc;
	RETURN
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
		 ISNULL(CONVERT(NVARCHAR, rm.DegradationVal), 'N/A') AS [Degradation], x.VerNum, p.*
	FROM Relab.ResultsMeasurements rm WITH(NOLOCK)
		LEFT OUTER JOIN Lookups lu WITH(NOLOCK) ON lu.Type='UnitType' AND lu.LookupID=rm.MeasurementUnitTypeID
		LEFT OUTER JOIN Lookups lt WITH(NOLOCK) ON lt.Type='MeasurementType' AND lt.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Lookups ltsf WITH(NOLOCK) ON ltsf.Type='SFIFunctionalMatrix' AND ltsf.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Lookups ltmf WITH(NOLOCK) ON ltmf.Type='MFIFunctionalMatrix' AND ltmf.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Lookups ltacc WITH(NOLOCK) ON ltacc.Type='AccFunctionalMatrix' AND ltacc.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Relab.ResultsMeasurementsFiles rmf WITH(NOLOCK) ON rmf.ResultMeasurementID=rm.ID
		LEFT OUTER JOIN #parameters p WITH(NOLOCK) ON p.ResultMeasurementID=rm.ID
		LEFT OUTER JOIN Relab.ResultsXML x ON x.ID = rm.XMLID
	WHERE rm.ResultID=@ResultID AND ((@IncludeArchived = 0 AND rm.Archived=@FalseBit) OR (@IncludeArchived=1)) AND ((@OnlyFails = 1 AND PassFail=@FalseBit) OR (@OnlyFails = 0))
	ORDER BY CASE WHEN rm.Archived = 1 THEN 
	(SELECT MIN(ID) FROM relab.ResultsMeasurements rm2 WHERE rm2.ResultID=rm.ResultID AND rm2.MeasurementTypeID=rm.MeasurementTypeID 
		and isnull(Relab.ResultsParametersComma(rm.ID),'') = isnull(Relab.ResultsParametersComma(rm2.ID),'') and rm2.Archived=0)
	ELSE rm.ID END, rm.ReTestNum

	DROP TABLE #parameters
	SET NOCOUNT OFF
END
GO
CREATE PROCEDURE [dbo].remispGetStagesNeedingCompletionByUnit @RequestNumber NVARCHAR(11), @BatchUnitNumber INT = NULL
AS
BEGIN
	DECLARE @UnitID INT
	
	SELECT tu.ID, tu.BatchUnitNumber
	INTO #units
	FROM TestUnits tu
		INNER JOIN Batches b ON tu.BatchID=b.ID
	WHERE b.QRANumber=@RequestNumber AND ((@BatchUnitNumber IS NULL) OR (@BatchUnitNumber IS NOT NULL AND tu.BatchUnitNumber=@BatchUnitNumber))
	ORDER BY tu.ID

	SELECT @UnitID = MIN(ID) FROM #units
		
	WHILE (@UnitID IS NOT NULL)
	BEGIN
		PRINT @UnitID
		SELECT @BatchUnitNumber = BatchUnitNumber FROM #units WHERE ID=@UnitID

		SELECT ROW_NUMBER() OVER (ORDER BY tsk.ProcessOrder) AS Row, tsk.TestStageID, @BatchUnitNumber AS BatchUnitNumber, tsk.teststagetype, tsk.tsname AS TestStageName
		FROM vw_GetTaskInfo tsk 
		WHERE qranumber=@RequestNumber AND tsk.testunitsfortest LIKE '%' + CONVERT(NVARCHAR, @BatchUnitNumber) + '%' AND tsk.teststagetype IN (2,1) AND tsk.TestStageID NOT IN (SELECT ISNULL(tr.TestStageID,0)
		FROM TestRecords tr
			INNER JOIN TestUnits tu ON tu.ID=tr.TestUnitID
			INNER JOIN Batches b ON b.ID=tu.BatchID
		WHERE tu.ID=@UnitID AND b.QRANumber=tsk.qranumber AND tr.Status IN (1,2,3,4,6,7))
		ORDER BY tsk.processorder
		
		SELECT @UnitID = MIN(ID) FROM #units WHERE ID > @UnitID
	END
	
	DROP TABLE #units
END
GO
ALTER PROCEDURE [dbo].[remispTestSelectApplicableTrackingLocationTypes] @TestID int
AS
BEGIN
	SELECT tlt.*   
	FROM trackinglocationtypes as tlt, TrackingLocationsForTests as tlfort
	WHERE tlfort.testid = @testid and tlt.ID = tlfort.TrackingLocationtypeID
	ORDER BY tlt.TrackingLocationTypeName asc
END
GO
GRANT EXECUTE ON remispTestSelectApplicableTrackingLocationTypes TO Remi
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding constraints to [dbo].[Batches]'
GO
ALTER TABLE [dbo].[Batches] ADD CONSTRAINT [DF_Batches_Order] DEFAULT ((0)) FOR [Order]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding foreign keys to [dbo].[Batches]'
GO
ALTER TABLE [dbo].[Batches] ADD CONSTRAINT [FK_Batches_JobOrientation] FOREIGN KEY ([OrientationID]) REFERENCES [dbo].[JobOrientation] ([ID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding foreign keys to [dbo].[JobOrientation]'
GO
ALTER TABLE [dbo].[JobOrientation] ADD CONSTRAINT [FK_JobOrientation_Jobs] FOREIGN KEY ([JobID]) REFERENCES [dbo].[Jobs] ([ID])
ALTER TABLE [dbo].[JobOrientation] ADD CONSTRAINT [FK_JobOrientation_Lookups] FOREIGN KEY ([ProductTypeID]) REFERENCES [dbo].[Lookups] ([LookupID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering permissions on [dbo].[remispJobOrientationSave]'
GO
GRANT EXECUTE ON  [dbo].[remispJobOrientationSave] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispGetJobOrientations]'
GO
GRANT EXECUTE ON  [dbo].[remispGetJobOrientations] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispGetOrientation]'
GO
GRANT EXECUTE ON  [dbo].[remispGetOrientation] TO [remi]
GO
GRANT EXECUTE ON  [dbo].[remispGetStagesNeedingCompletionByUnit] TO [remi]
GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_JobOrientation_JID_PID_Name] ON [dbo].JobOrientation 
(
	JobID ASC,
	ProductTypeID ASC,
	Name ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
ALTER PROCEDURE [dbo].[remispTrackingLocationTypesInsertUpdateSingleItem] @ID int OUTPUT, @TrackingLocationTypeName nvarchar (100), @WILocation nvarchar(800)=null,
	@UnitCapacity int, @Comment nvarchar(1000) = null, @TrackingLocationTypeFunction int, @LastUser nvarchar(255), @ConcurrencyID rowversion OUTPUT
AS
BEGIN
	DECLARE @ReturnValue int

	IF (@ID IS NULL AND NOT EXISTS (SELECT 1 FROM TrackingLocationTypes WHERE TrackingLocationTypeName=@TrackingLocationTypeName)) -- New Item
	BEGIN
		INSERT INTO TrackingLocationTypes (TrackingLocationTypeName, TrackingLocationFunction, Comment,WILocation,UnitCapacity,LastUser)
		VALUES (@TrackingLocationTypeName, @TrackingLocationTypeFunction, @Comment, @WILocation, @UnitCapacity, @LastUser)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE IF (@ConcurrencyID IS NOT NULL) -- Exisiting Item
	BEGIN
		UPDATE TrackingLocationTypes
		SET TrackingLocationTypeName = @TrackingLocationTypeName, TrackingLocationFunction = @TrackingLocationTypeFunction,
			Comment  =@Comment, WILocation = @WILocation, UnitCapacity = @UnitCapacity, LastUser = @LastUser
		WHERE ID = @ID AND ConcurrencyID = @ConcurrencyID

		SELECT @ReturnValue = @ID
	END

	SET @ConcurrencyID = (SELECT ConcurrencyID FROM TrackingLocationTypes WHERE ID = @ReturnValue)
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
GRANT EXECUTE ON [dbo].[remispTrackingLocationTypesInsertUpdateSingleItem] TO REMI
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
		VALUES (@TestStageName, @TestStageType, @JobID, @TestID, @LastUser, @Comment, @ProcessOrder, @IsArchived)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE IF (@ConcurrencyID IS NOT NULL) -- Exisiting Item
	BEGIN
		UPDATE TestStages SET
			TestStageName = @TestStageName, 
			TestStageType = @TestStageType,
			JobID = @JobID,
			TestID=@TestID,
			LastUser = @LastUser,
			Comment = @Comment,
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
ALTER PROCEDURE [dbo].[remispUsersInsertUpdateSingleItem]
	@ID int OUTPUT,
	@LDAPLogin nvarchar(255),
	@BadgeNumber int=null,
	@TestCentreID INT = null,
	@LastUser nvarchar(255),
	@ConcurrencyID rowversion OUTPUT,
	@IsActive INT = 1,
	@ByPassProduct INT = 0,
	@DefaultPage NVARCHAR(255)
AS
	DECLARE @ReturnValue int

	IF (@ID IS NULL AND NOT EXISTS (SELECT 1 FROM Users WHERE LDAPLogin=@LDAPLogin)) -- New Item
	BEGIN
		INSERT INTO Users (LDAPLogin, BadgeNumber, TestCentreID, LastUser, IsActive, DefaultPage, ByPassProduct)
		VALUES (@LDAPLogin, @BadgeNumber, @TestCentreID, @LastUser, @IsActive, @DefaultPage, @ByPassProduct)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE IF(@ConcurrencyID IS NOT NULL) -- Exisiting Item
	BEGIN
		UPDATE Users SET
			LDAPLogin = @LDAPLogin,
			BadgeNumber=@BadgeNumber,
			TestCentreID = @TestCentreID,
			lastuser=@LastUser,
			IsActive=@IsActive,
			DefaultPage = @DefaultPage,
			ByPassProduct = @ByPassProduct
		WHERE ID = @ID AND ConcurrencyID = @ConcurrencyID

		SELECT @ReturnValue = @ID
	END

	SET @ConcurrencyID = (SELECT ConcurrencyID FROM Users WHERE ID = @ReturnValue)
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

