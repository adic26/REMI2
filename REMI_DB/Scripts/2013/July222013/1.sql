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
PRINT N'Altering [dbo].[TestRecords]'
GO
ALTER TABLE [dbo].[TestRecords] ADD
[TestID] [int] NULL,
[TestStageID] [int] NULL
GO
ALTER TABLE Relab.ResultsMeasurements DROP COLUMN [File]
GO
ALTER TABLE [dbo].[TestRecordsAudit] ADD
[TestID] [int] NULL,
[TestStageID] [int] NULL
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating index [IX_TestRecords_TestStage] on [dbo].[TestRecords]'
GO
CREATE NONCLUSTERED INDEX [IX_TestRecords_TestStage] ON [dbo].[TestRecords] ([TestStageID]) INCLUDE ([TestID], [TestUnitID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
CREATE NONCLUSTERED INDEX [IX_TestRecords_TestID] ON TestRecords
(
	[TestID] ASC
)
INCLUDE ( [ID],
[TestStageID],
[TestUnitID]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[TestRecordsAuditInsertUpdate]
   ON  [dbo].[TestRecords]
    after insert, update
AS 
BEGIN
SET NOCOUNT ON;
 
Declare @action char(1)
DECLARE @count INT
  
--check if this is an insert or an update

If Exists(Select * From Inserted) and Exists(Select * From Deleted) --Update, both tables referenced
begin
	Set @action= 'U'
end
else
begin
	If Exists(Select * From Inserted) --insert, only one table referenced
	Begin
		Set @action= 'I'
	end
	if not Exists(Select * From Inserted) and not Exists(Select * From Deleted)--nothing changed, get out of here
	Begin
		RETURN
	end
end

--Only inserts records into the Audit table if the row was either updated or inserted and values actually changed.
select @count= count(*) from
(
   select TestUnitID, TestName, TestStageName, JobName, Status, FailDocNumber, RelabVersion, Comment, resultsource, TestID, TestStageID from Inserted
   except
   select TestUnitID, TestName, TestStageName, JobName, Status, FailDocNumber, RelabVersion, Comment, resultsource, TestID, TestStageID from Deleted
) a

if ((@count) >0)
begin
	insert into TestRecordsaudit (
		TestRecordId, 
		TestUnitID,
		TestName, 
		TestStageName,
		JobName,
		Status, 
		FailDocNumber,
		RelabVersion,
		Comment,
		UserName,
		resultsource,
		action, TestID, TestStageID)
		Select 
		Id, 
		TestUnitID,
		TestName, 
		TestStageName,
		JobName,
		Status, 
		FailDocNumber,
		RelabVersion,
		Comment, 
		LastUser,
		resultsource,
	@action, TestID, TestStageID from inserted
END

END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[TestRecordsAuditDelete]
   ON  [dbo].[TestRecords]
    for  delete
AS 
BEGIN
 SET NOCOUNT ON;
 
  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here
	
insert into TestRecordsaudit (
	TestRecordId, 
	TestUnitID,
	TestName, 
	TestStageName,
	JobName,
	Status, 
	FailDocNumber,
	RelabVersion,
	Comment,
	UserName,
	ResultSource,
	Action, TestID, TestStageID)
	Select 
	Id, 
	TestUnitID,
	TestName, 
	TestStageName,
	JobName,
	Status, 
	FailDocNumber,
	RelabVersion,
	Comment, 
	LastUser,
	ResultSource,
'D', TestID, TestStageID from deleted

END
GO
ALTER TABLE [Relab].[ResultsMeasurements]  WITH CHECK ADD  CONSTRAINT [FK_ResultsMeasurements_ResultsXML_XMLID] FOREIGN KEY([XMLID])
REFERENCES [relab].[ResultsXML] ([ID])
GO
ALTER TABLE [Relab].[ResultsMeasurements] CHECK CONSTRAINT [FK_ResultsMeasurements_ResultsXML_XMLID]
GO
CREATE PRIMARY XML INDEX [ResultLossIndex] ON [Relab].[ResultsXML] 
(
	[LossFile]
)WITH (PAD_INDEX  = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
GO
CREATE TABLE [Relab].[ResultsMeasurementsFiles](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ResultMeasurementID] [int] NULL,
	[File] [varbinary](max) NOT NULL,
	[ContentType] [nvarchar](50) NOT NULL,
	[FileName] [nvarchar](200) NOT NULL,
 CONSTRAINT [PK_ResultsMeasurementsFiles] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [Relab].[ResultsMeasurementsFiles]  WITH CHECK ADD  CONSTRAINT [FK_ResultsMeasurementsFiles_ResultsMeasurements] FOREIGN KEY([ResultMeasurementID])
REFERENCES [Relab].[ResultsMeasurements] ([ID])
GO

ALTER TABLE [Relab].[ResultsMeasurementsFiles] CHECK CONSTRAINT [FK_ResultsMeasurementsFiles_ResultsMeasurements]
GO


IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
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
	@LastUser nvarchar(255)
AS
BEGIN
	DECLARE @TestStageID INT
	DECLARE @TestID INT
	DECLARE @JobID INT
	DECLARE @ReturnValue INT
	
	IF (@ID is null or @ID <=0 ) --no dupes allowed here!
	BEGIN
		SET @ID = (SELECT ID FROM TestRecords WHERE TestStageName = @TestStageName AND JobName = @JobName AND testname=@TestName AND testunitid=@TestUnitID)
	END
	
	SELECT @TestID=ID FROM Tests WHERE TestName=@TestName
	SELECT @JobID=ID FROM Jobs WHERE JobName=@JobName
	SELECT @TestStageID=ID FROM TestStages WHERE JobID=@JobID AND TestStageName=@TestStageName
	
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
PRINT N'Altering [dbo].[remispTestRecordsSelectForBatch]'
GO
ALTER PROCEDURE [dbo].[remispTestRecordsSelectForBatch] @QRANumber nvarchar(11) = null
AS
BEGIN
	SELECT tr.FailDocRQID,tr.Comment,tr.ConcurrencyID,tr.FailDocNumber,tr.ID,tr.JobName,tr.ResultSource,tr.LastUser,tr.RelabVersion,tr.Status,tr.TestName,
		tr.TestStageName,tr.TestUnitID, b.QRANumber, tu.BatchUnitNumber,
	(
		Select sum(datediff(MINUTE,dtl.intime,(case when (dtl.OutTime IS null) then GETUTCDATE() else dtl.outtime  end ))) 
		from Testrecordsxtrackinglogs trXtl
			INNER JOIN DeviceTrackingLog dtl ON dtl.ID = trXtl.TrackingLogID
		where trXtl.TestRecordID = tr.id
	) as TotalTestTimeMinutes,
	(
		select COUNT (*)
		from Testrecordsxtrackinglogs as trXtl
			INNER JOIN DeviceTrackingLog as dtl ON dtl.ID = trXtl.TrackingLogID
		where trXtl.TestRecordID = tr.id
	) as NumberOfTests, tr.TestID, tr.TestStageID
	FROM TestRecords as tr
		INNER JOIN testunits tu ON tu.ID = tr.TestUnitID
		INNER JOIN Batches b ON b.id = tu.batchid
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
	SELECT    tr.Comment,tr.ConcurrencyID,tr.FailDocNumber,tr.ID,tr.JobName,tr.LastUser,tr.ResultSource,tr.RelabVersion,tr.Status,tr.TestName,tr.TestStageName,tr.TestUnitID, b.QRANumber, tu.BatchUnitNumber
	,(Select sum(datediff(MINUTE,dtl.intime,(case when (dtl.OutTime IS null) then GETUTCDATE() else dtl.outtime  end ))) 
	 from Testrecordsxtrackinglogs as trXtl, DeviceTrackingLog as dtl where trXtl.TestRecordID = tr.id and dtl.ID = trXtl.TrackingLogID
	) as TotalTestTimeMinutes
	,(select COUNT (*) as NumberOfTests from Testrecordsxtrackinglogs as trXtl, DeviceTrackingLog as dtl where trXtl.TestRecordID = tr.id and dtl.ID = trXtl.TrackingLogID
	) as NumberOfTests, tr.TestID, tr.TestStageID
	FROM TestRecords as tr,  testunits as tu, Batches as b
	                    
	WHERE tr.ID = @id and  tu.batchid = b.id and tu.ID = tr.TestUnitID 
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
	) as NumberOfTests, tr.TestID, tr.TestStageID
	FROM TestRecords as tr,  testunits as tu, Batches as b
	                    
	WHERE tr.Status = @status and  tu.batchid = b.id and tu.ID = tr.TestUnitID 
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remifnTestStageCanDelete]'
GO
ALTER FUNCTION dbo.remifnTestStageCanDelete (@TestStageID INT)
RETURNS BIT
AS
BEGIN
	DECLARE @Exists BIT
	
	SELECT @Exists = (SELECT DISTINCT 0
		FROM TestRecords
		WHERE TestStageID=@TestStageID
		UNION
		SELECT DISTINCT 0
		FROM Relab.Results
		WHERE TestStageID=@TestStageID)
	
	RETURN ISNULL(@Exists, 1)
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remifnTestCanDelete]'
GO
ALTER FUNCTION dbo.remifnTestCanDelete (@TestID INT)
RETURNS BIT
AS
BEGIN
	DECLARE @Exists BIT
	
	SELECT @Exists = (SELECT DISTINCT 0
		FROM ProductConfiguration
		WHERE TestID=@TestID
		UNION
		SELECT DISTINCT 0
		FROM BatchSpecificTestDurations
		WHERE TestID=@TestID
		UNION
		SELECT DISTINCT 0
		FROM Relab.Results
		WHERE TestID=@TestID
		UNION
		SELECT DISTINCT 0
		FROM ProductConfigurationUpload
		WHERE TestID=@TestID
		UNION
		SELECT DISTINCT 0
		FROM TestRecords
		WHERE TestID=@TestID)
	
	RETURN ISNULL(@Exists, 1)
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestStagesSelectListOfNames]'
GO
ALTER PROCEDURE [dbo].[remispTestStagesSelectListOfNames]
AS
BEGIN
	SELECT DISTINCT ts.TestStageName as Name, ISNULL(ts.IsArchived, 0) AS IsArchived, dbo.remifnTestStageCanDelete(ts.ID) AS CanDelete
	FROM teststages as ts
	WHERE ts.TestStageType IN (1, 3)
	ORDER BY ts.TestStageName
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding foreign keys to [dbo].[TestRecords]'
GO
ALTER TABLE [dbo].[TestRecords] ADD CONSTRAINT [FK_TestRecords_Tests] FOREIGN KEY ([TestID]) REFERENCES [dbo].[Tests] ([ID])
ALTER TABLE [dbo].[TestRecords] ADD CONSTRAINT [FK_TestRecords_TestStages] FOREIGN KEY ([TestStageID]) REFERENCES [dbo].[TestStages] ([ID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering permissions on [dbo].[remispTestRecordsInsertUpdateSingleItem]'
GO
GRANT EXECUTE ON  [dbo].[remispTestRecordsInsertUpdateSingleItem] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispTestRecordsSelectOne]'
GO
GRANT EXECUTE ON  [dbo].[remispTestRecordsSelectOne] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispTestRecordsSelectByStatus]'
GO
GRANT EXECUTE ON  [dbo].[remispTestRecordsSelectByStatus] TO [remi]
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
where t.ID = tlft.TestID
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
GRANT EXECUTE ON remispScanGetData TO REMI
GO
ALTER PROCEDURE [Relab].[remispResultMeasurements] @ResultID INT, @OnlyFails INT = 0, @IncludeArchived INT = 0
AS
BEGIN
	SET NOCOUNT ON
	SELECT rm.ID, lt.[Values] As MeasurementType, LowerLimit, UpperLimit, MeasurementValue, lu.[Values] As UnitType, 
		CASE WHEN PassFail=1 THEN 'Pass' ELSE 'Fail' END AS PassFail,
		Relab.ResultsParametersComma(rm.ID) AS [Parameters], rm.MeasurementTypeID, rm.ReTestNum, rm.Archived, rm.XMLID, 
		(SELECT MAX(VerNum) FROM Relab.ResultsXML WHERE ResultID=rm.ResultID) AS MaxVersion, rm.Comment,
		ISNULL(rmf.[File], 0) AS [Image], 
		ISNULL(UPPER(SUBSTRING(rmf.ContentType,2,LEN(rmf.ContentType))), 'PNG') AS ContentType
	FROM Relab.ResultsMeasurements rm WITH(NOLOCK)
		LEFT OUTER JOIN Lookups lu WITH(NOLOCK) ON lu.Type='UnitType' AND lu.LookupID=rm.MeasurementUnitTypeID
		LEFT OUTER JOIN Lookups lt WITH(NOLOCK) ON lt.Type='MeasurementType' AND lt.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN ResultsMeasurementsFiles rmf ON rmf.ResultMeasurementID=rm.ID
	WHERE ResultID=@ResultID AND ((@IncludeArchived = 0 AND rm.Archived=0) OR (@IncludeArchived=1)) AND ((@OnlyFails = 1 AND PassFail=0) OR (@OnlyFails = 0))
	ORDER BY lt.[Values],Relab.ResultsParametersComma(rm.ID), rm.ReTestNum ASC
	SET NOCOUNT OFF
END
GO
GRANT EXECUTE ON [Relab].[remispResultMeasurements] TO Remi
GO
CREATE PROCEDURE Relab.remispResultsMeasurementFileUpload @File VARBINARY(MAX), @ContentType NVARCHAR(50), @FileName NVARCHAR(200)
AS
BEGIN
	IF (DATALENGTH(@File) > 0)
	BEGIN
		INSERT INTO Relab.ResultsMeasurementsFiles ( ResultMeasurementID, [File], ContentType, FileName)
		VALUES (NULL, @File, @ContentType, @FileName)
	END
END
GO
GRANT EXECUTE ON Relab.remispResultsMeasurementFileUpload TO REMI
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

		IF ((SELECT COUNT(*) FROM Relab.ResultsXML x INNER JOIN Relab.Results r ON r.ID=x.ResultID WHERE r.TestID <> 1099 AND ISNULL(IsProcessed,0)=0)=0)
		BEGIN
			GOTO HANDLE_SUCCESS
			RETURN
		END
		
		SET NOCOUNT ON
		
		SELECT @Val = COUNT(*) FROM Relab.ResultsXML x INNER JOIN Relab.Results r ON r.ID=x.ResultID WHERE r.TestID <> 1099 AND ISNULL(isProcessed,0)=0
		
		SELECT TOP 1 @ID=x.ID, @xml = x.ResultXML, @VerNum = x.VerNum, @ResultID = x.ResultID
		FROM Relab.ResultsXML x
			INNER JOIN Relab.Results r ON r.ID=x.ResultID
		WHERE r.TestID <> 1099 AND ISNULL(IsProcessed,0)=0
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
				[Relab].[ResultsXMLParametersComma] ((select T.c.query('.') from @xmlPart.nodes('/Measurement/Parameters') T(c))) AS Parameters
			INTO #measurement
			FROM @xmlPart.nodes('/Measurement') T(c)
				LEFT OUTER JOIN Lookups l ON l.Type='UnitType' AND l.[Values]=LTRIM(RTRIM(CONVERT(VARCHAR(MAX), T.c.query('Units').value('.', 'nvarchar(max)'))))
				LEFT OUTER JOIN Lookups l2 ON l2.Type='MeasurementType' AND l2.[Values]=LTRIM(RTRIM(CONVERT(VARCHAR(MAX), T.c.query('MeasurementName').value('.', 'nvarchar(max)'))))

			IF (@VerNum = 1)
			BEGIN
				PRINT 'INSERT Version 1 Measurements'
				INSERT INTO Relab.ResultsMeasurements (ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, MeasurementUnitTypeID, PassFail, ReTestNum, Archived, XMLID)
				SELECT @ResultID As ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, UnitTypeID, CONVERT(BIT, PassFail), 1, 0, @ID
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
						WHERE LTRIM(RTRIM(FileName))=@FileName AND ResultMeasurementID IS NULL
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
				SELECT @MeasurementTypeID=MeasurementTypeID, @Parameters=ISNULL(Parameters, ''), @MeasuredValue=MeasurementValue FROM #measurement
				
				SELECT @OldMeasuredValue = MeasurementValue , @ReTestNum = reTestNum+1
				FROM Relab.ResultsMeasurements 
				WHERE ResultID=@ResultID AND MeasurementTypeID=@MeasurementTypeID AND ISNULL(Relab.ResultsParametersComma(ID),'') = ISNULL(@Parameters,'') AND Archived=0

				IF (@OldMeasuredValue IS NOT NULL AND @OldMeasuredValue <> @MeasuredValue)
				--That result has that measurement type and exact parameters but measured value is different
				BEGIN
					PRINT 'INSERT ReTest Measurements'
					INSERT INTO Relab.ResultsMeasurements (ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, MeasurementUnitTypeID, PassFail, ReTestNum, Archived, XMLID)
					SELECT @ResultID As ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, UnitTypeID, CONVERT(BIT, PassFail), @ReTestNum, 0, @ID
					FROM #measurement
					
					DECLARE @ResultMeasurementID2 INT
					SET @ResultMeasurementID2 = @@IDENTITY
					
					SELECT @FileName = LTRIM(RTRIM([FileName]))
					FROM #measurement
				
					IF (@FileName IS NOT NULL AND @FileName <> '')
						BEGIN
							UPDATE Relab.ResultsMeasurementsFiles 
							SET ResultMeasurementID=@ResultMeasurementID 
							WHERE LTRIM(RTRIM(FileName))=@FileName AND ResultMeasurementID IS NULL
						END

					IF (@Parameters <> '')
					BEGIN
						PRINT 'INSERT ReTest Parameters'
						INSERT INTO Relab.ResultsParameters (ResultMeasurementID, ParameterName, Value)
						SELECT @ResultMeasurementID2 AS ResultMeasurementID, T.c.value('@ParameterName','nvarchar(max)') AS ParameterName, T.c.query('.').value('.', 'nvarchar(max)') AS Value
						FROM @xmlPart.nodes('/Measurement/Parameters/Parameter') T(c)
						
						UPDATE Relab.ResultsMeasurements 
						SET Archived=1 
						WHERE ResultID=@ResultID AND Archived=0 AND MeasurementTypeID=@MeasurementTypeID AND ISNULL(Relab.ResultsParametersComma(ID),'') = ISNULL(@Parameters,'') AND ReTestNum < @ReTestNum
					END
				END
				ELSE IF (@OldMeasuredValue IS NOT NULL AND @OldMeasuredValue = @MeasuredValue)
				--That measurement already exists in the current active measurements
				BEGIN
					SET @ReTestNum = 0
				END
				ELSE
				--That result does not have that measurement type and exact parameters
				BEGIN
					PRINT 'INSERT New Measurements'
					INSERT INTO Relab.ResultsMeasurements (ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, MeasurementUnitTypeID, PassFail, ReTestNum, Archived, XMLID)
					SELECT @ResultID As ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, UnitTypeID, CONVERT(BIT, PassFail), 1, 0, @ID
					FROM #measurement

					DECLARE @ResultMeasurementID3 INT
					SET @ResultMeasurementID3 = @@IDENTITY
					
					SELECT @FileName = LTRIM(RTRIM([FileName]))
					FROM #measurement
				
					IF (@FileName IS NOT NULL AND @FileName <> '')
						BEGIN
							UPDATE Relab.ResultsMeasurementsFiles 
							SET ResultMeasurementID=@ResultMeasurementID 
							WHERE LTRIM(RTRIM(FileName))=@FileName AND ResultMeasurementID IS NULL
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