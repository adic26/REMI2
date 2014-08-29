/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        CI0000001593275.REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 7/8/2013 3:33:27 PM

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
ALTER TABLE TestStages ADD IsArchived BIT DEFAULT(0) NULL
GO
ALTER TABLE TestStagesAudit ADD IsArchived BIT NULL
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[testStagesAuditDelete]
   ON  [dbo].[TestStages]
    for  delete
AS 
BEGIN
 SET NOCOUNT ON;
 
  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here
	
insert into testStagesaudit (
	TeststageId, 
	TestStageName, 
	TestStageType,
	JobID, 
	Comment,
	testid,
	UserName,
	ProcessOrder,
	IsArchived,
	Action)
	Select 
	Id, 
	TestStageName, 
	TestStageType,
	JobID, 
	Comment, 
	testid,
	LastUser,
	ProcessOrder,
	IsArchived,
'D' from deleted

END
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[testStagesAuditInsertUpdate]
   ON  [dbo].[TestStages]
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
   select TestStageName, TestStageType, testid, JobID, Comment, ProcessOrder, IsArchived from Inserted
   except
   select TestStageName, TestStageType, testid, JobID, Comment, ProcessOrder, IsArchived from Deleted
) a

if ((@count) >0)
begin
	insert into testStagesaudit (
		TeststageId, 
		TestStageName, 
		TestStageType,
		testid,
		JobID, 
		Comment,
		UserName,
		ProcessOrder,
		IsArchived,
		Action)
		Select 
		Id, 
		TestStageName, 
		TestStageType,
		testid,
		JobID, 
		Comment, 
		LastUser,
		ProcessOrder,IsArchived,
	@action from inserted
END
END
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

where t.ID = tlft.TestID
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
	   TestStageID, TestWI, TestID, IsArchived, RecordExists
FROM   
	(
		SELECT b.qranumber,b.ID AS BatchID,
		ts.processorder, ts.teststagename AS tsname, t.testname AS tname, t.testtype, ts.teststagetype, t.duration AS genericTestDuration, ts.ID AS TestStageID,t.ID AS TestID,
		t.WILocation As TestWI, ISNULL(ts.IsArchived, 0) AS IsArchived, 
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
							)
						)
					)
				FOR xml path ('')
			) AS TestUnitsForTest,
			(SELECT TOP 1 1
			FROM TestRecords tr
			WHERE tr.TestStageName=ts.TestStageName AND tr.TestUnitID IN (SELECT ID FROM TestUnits WHERE BatchID=b.ID)) AS RecordExists
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
		(ISNULL(RecordExists,0) > 0 AND IsArchived = 1)
		OR
		(ISNULL(IsArchived, 0) = 0)
	)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[remifnTestStageCanDelete]'
GO
CREATE FUNCTION dbo.remifnTestStageCanDelete (@TestStageID INT)
RETURNS BIT
AS
BEGIN
	DECLARE @Exists BIT
	DECLARE @TestStageName NVARCHAR(400)
	SELECT @TestStageName = TestStageName FROM TestStages WHERE ID=@TestStageID
	
	SELECT @Exists = (SELECT DISTINCT 0
		FROM Batches
		WHERE LTRIM(RTRIM(TestStageName))=@TestStageName
		UNION
		SELECT DISTINCT 0
		FROM TestRecords
		WHERE LTRIM(RTRIM(TestStageName))=@TestStageName
		UNION
		SELECT DISTINCT 0
		FROM Relab.Results
		WHERE LTRIM(RTRIM(TestStageID))=@TestStageID)
	
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
	WHERE (ts.TestStageType = 1 or ts.TestStageType=3)
	ORDER BY ts.TestStageName
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestStagesSelectSingleItem]'
GO
ALTER PROCEDURE [dbo].[remispTestStagesSelectSingleItem] @ID int = null, @Name nvarchar(400) = null, @JobName nvarchar(400) = null
AS
BEGIN
	--check that at least one param is set
	if (@ID is null and @Name is not null and @JobName is not null) or (@ID is not null and @Name is null) 
	begin
		SELECT ts.Comment,ts.ConcurrencyID,ts.ID,ts.processorder,ts.JobID,ts.LastUser,ts.TestID,ts.TestStageName,ts.TestStageType,  j.jobname, ISNULL(ts.IsArchived,0) AS IsArchived
		FROM TestStages as ts, Jobs as j
		WHERE ts.JobID = j.id and (ts.ID = @ID or @ID is null) and (ts.TestStageName = @Name and j.jobname = @JobName or @Name is null)
		
	end
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestStagesSelectList]'
GO
ALTER PROCEDURE [dbo].[remispTestStagesSelectList]
	@JobName nvarchar(400) = null,
	@TestStageType int = null
AS
	BEGIN
		if @JobName is not null
		begin
			SELECT ts.Comment,ts.ConcurrencyID,ts.ID,ts.processorder, ts.JobID,ts.LastUser,ts.TestID,ts.TestStageName,ts.TestStageType, j.jobname, 
				ISNULL(ts.IsArchived, 0) AS IsArchived, dbo.remifnTestStageCanDelete(ts.ID) AS CanDelete
			FROM teststages as ts,jobs as j
			where ((ts.jobid = j.id and j.Jobname = @Jobname) or @jobname is null)
			order by ProcessOrder
		end
		else
		begin
			SELECT ts.Comment,ts.ConcurrencyID,ts.ID,ts.processorder,ts.JobID,ts.LastUser,ts.TestID,ts.TestStageName,ts.TestStageType,j.jobname, 
				ISNULL(ts.IsArchived, 0) AS IsArchived, dbo.remifnTestStageCanDelete(ts.ID) AS CanDelete
			FROM teststages as ts, Jobs as j
			where (ts.jobid = j.id and (ts.TestStageType = @TestStageType or @TestStageType is null))
			order by ProcessOrder
		end
	END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestStagesInsertUpdateSingleItem]'
GO
ALTER PROCEDURE [dbo].[remispTestStagesInsertUpdateSingleItem]
/*	'===============================================================
	'   NAME:                	remispTestStagesInsertUpdateSingleItem
	'   DATE CREATED:       	20 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Creates or updates an item in a table: TestStages      
	'   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
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
	begin transaction AddTestStage
	declare @jobID int
	set @jobID = (select ID from Jobs where JobName = @jobname)
	
	if @jobID is null and @JobName is not null --the job was not added to the db yet so add it to get an id.
	begin
		execute remispJobsInsertUpdateSingleItem null, @jobname,null,null,@lastuser,null
	end
	--try again
	set @jobID = (select ID from Jobs where JobName = @jobname)
	DECLARE @ReturnValue int

	IF (@ID IS NULL) -- New Item
	BEGIN
		INSERT INTO TestStages
		(
			TestStageName, 
			TestStageType,
			JobID,
			TestID,
			LastUser,
			Comment,
			ProcessOrder,
			IsArchived
		)
		VALUES
		(
			@TestStageName, 
			@TestStageType,
			@JobID,
			@TestID,
			@LastUser,
			@Comment,
			@ProcessOrder,
			@IsArchived
		)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE -- Exisiting Item
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
		WHERE 
			ID = @ID
			AND ConcurrencyID = @ConcurrencyID

		SELECT @ReturnValue = @ID
	END

	SET @ConcurrencyID = (SELECT ConcurrencyID FROM TestStages WHERE ID = @ReturnValue)
	SET @ID = @ReturnValue
	commit transaction AddTestStage
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

SELECT  @selectedTestID=t.ID, @selectedTestIsTimed =t.resultbasedontime,@selectedTestType = t.TestType 
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
	@productID As ProductID
	
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
PRINT N'Altering permissions on [dbo].[remifnTestStageCanDelete]'
GO
GRANT EXECUTE ON  [dbo].[remifnTestStageCanDelete] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispTestStagesSelectListOfNames]'
GO
GRANT EXECUTE ON  [dbo].[remispTestStagesSelectListOfNames] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispTestStagesSelectSingleItem]'
GO
GRANT EXECUTE ON  [dbo].[remispTestStagesSelectSingleItem] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispTestStagesSelectList]'
GO
GRANT EXECUTE ON  [dbo].[remispTestStagesSelectList] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispTestStagesInsertUpdateSingleItem]'
GO
GRANT EXECUTE ON  [dbo].[remispTestStagesInsertUpdateSingleItem] TO [remi]
GO
create PROCEDURE [dbo].[remispTrackingTypesTests]
AS
BEGIN
	DECLARE @rows VARCHAR(8000)
	DECLARE @query VARCHAR(4000)
	SELECT @rows=  ISNULL(STUFF(
	( 
	SELECT DISTINCT '],[' + tlt.TrackingLocationTypeName
	FROM  dbo.TrackingLocationTypes tlt
	ORDER BY '],[' +  tlt.TrackingLocationTypeName
	FOR XML PATH('')), 1, 2, '') + ']','[na]')


	SET @query = '
		SELECT *
		FROM
		(
			SELECT CASE WHEN tlft.ID IS NOT NULL THEN 1 ELSE NULL END As Row, t.TestName, tlt.TrackingLocationTypeName, t.testtype
			FROM dbo.TrackingLocationTypes tlt
				LEFT OUTER JOIN dbo.TrackingLocationsForTests tlft ON tlft.TrackingLocationtypeID = tlt.ID
				INNER JOIN dbo.Tests t ON t.ID=tlft.TestID
			WHERE t.TestName IS NOT NULL
		)r
		PIVOT 
		(
			MAX(row) 
			FOR TrackingLocationTypeName 
				IN ('+@rows+')
		) AS pvt
		ORDER BY TestType ASC, TestName'
	EXECUTE (@query)
END
GO
GRANT EXECUTE ON remispTrackingTypesTests TO REMI
GO
CREATE PROCEDURE [dbo].[remispAddRemoveTypeToTest] @TestName NVARCHAR(256), @TrackingType NVARCHAR(256)
AS
BEGIN
	DECLARE @TestID INT
	DECLARE @TrackingTypeID INT

	SELECT @TestID = ID FROM Tests WHERE TestName=@TestName
	SELECT @TrackingTypeID = ID FROM TrackingLocationTypes WHERE TrackingLocationTypeName=@TrackingType

	IF EXISTS (SELECT 1 FROM TrackingLocationsForTests WHERE TestID=@TestID AND TrackingLocationtypeID=@TrackingTypeID)
		BEGIN
			DELETE FROM TrackingLocationsForTests WHERE TestID=@TestID AND TrackingLocationtypeID=@TrackingTypeID
		END
	ELSE
		BEGIN
			INSERT INTO TrackingLocationsForTests (TestID, TrackingLocationtypeID) VALUES (@TestID, @TrackingTypeID)
		END
END
GO
GRANT EXECUTE ON remispAddRemoveTypeToTest TO REMI
GO
ALTER PROCEDURE [dbo].[remispTrackingLocationTypesSelectList] @Function as int = null
AS
BEGIN	
	SELECT tlt.Comment,tlt.ConcurrencyID,tlt.ID,tlt.LastUser,tlt.TrackingLocationFunction,tlt.TrackingLocationTypeName,tlt.UnitCapacity,tlt.WILocation,
		ISNULL((SELECT TOP 1 0 FROM TrackingLocations tl WHERE tl.TrackingLocationTypeID=tlt.ID), 1) AS CanDelete
	FROM TrackingLocationTypes as tlt
	WHERE (tlt.TrackingLocationFunction = @function or @function is null)
	ORDER BY TrackingLocationTypeName ASC
END
GO
GRANT EXECUTE ON remispTrackingLocationTypesSelectList TO REMI
GO
ALTER PROCEDURE [dbo].[remispTestsSelectListByType] @TestType int
AS
BEGIN
	SELECT t.Comment,t.ConcurrencyID,t.Duration,t.ID,t.LastUser,t.ResultBasedOntime,t.TestName,t.TestType,t.WILocation, dbo.remifnTestCanDelete(t.ID) AS CanDelete
	FROM Tests t
	WHERE TestType = @TestType ORDER BY TestName;
	
	SELECT t.id, tlt.id, tlt.TrackingLocationTypeName    
	FROM trackinglocationtypes as tlt, TrackingLocationsForTests as tlfort, Tests as t
	WHERE tlfort.testid = t.id and tlt.ID = tlfort.TrackingLocationtypeID
		AND t.TestType = @TestType
	ORDER BY tlt.TrackingLocationTypeName asc
END
GO
GRANT EXECUTE ON remispTestsSelectListByType TO REMI
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION dbo.remifnTestCanDelete (@TestID INT)
RETURNS BIT
AS
BEGIN
	DECLARE @Exists BIT
	DECLARE @TestName NVARCHAR(400)
	SELECT @TestName = TestName FROM Tests WHERE ID=@TestID
	
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
		WHERE TestName=@TestName)
	
	RETURN ISNULL(@Exists, 1)
END
GO
GRANT EXECUTE ON remifnTestStageCanDelete TO Remi
GO

ALTER PROCEDURE Relab.remispResultsGraph @MeasurementTypeID INT, @batchIDs NVARCHAR(MAX), @UnitIDs NVARCHAR(MAX), @TestID INT, @ParameterName NVARCHAR(255)=NULL, @ParameterValue NVARCHAR(250)=NULL, @ShowUpperLowerLimits INT = 1, @Xaxis INT, @PlotValue INT
AS
BEGIN
	DECLARE @LoopValue NVARCHAR(500)
	DECLARE @ID INT
	DECLARE @query VARCHAR(MAX)
	DECLARE @query2 VARCHAR(MAX)
	CREATE TABLE #batches (id INT)
	CREATE TABLE #units (id INT)
	CREATE TABLE #Graph (RowID INT, YAxis NVARCHAR(500), XAxis NVARCHAR(500), LoopValue NVARCHAR(500), LowerLimit NVARCHAR(255), UpperLimit NVARCHAR(255))
	EXEC (@batchIDs)
	EXEC (@UnitIDs)
	SET @query = ''	
	SET @query2 = ''
	
	/*@Xaxis
	Units: 0
	Stages: 1
	Parameter: 2
	*/
	/*@PlotValue
	Units: 0
	Stages: 1
	*/
	
	IF (@Xaxis=0)
	BEGIN
		SET @query = 'INSERT INTO #Graph SELECT ROW_NUMBER() OVER (ORDER BY rm.MeasurementValue) AS RowID, rm.MeasurementValue AS YAxis, 
		CASE WHEN '''+ ISNULL(@ParameterName,'')+''' = '''' THEN CONVERT(VARCHAR,tu.BatchUnitNumber) WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN CONVERT(VARCHAR,tu.BatchUnitNumber) ELSE CONVERT(VARCHAR,tu.BatchUnitNumber) +'': '' + Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' = '''' THEN ''V'' ELSE ''N'' END) END AS XAxis, 
		ts.TestStageName AS LoopValue, rm.LowerLimit, rm.UpperLimit '		
	END
	ELSE IF (@Xaxis=1)
	BEGIN
		SET @query = 'INSERT INTO #Graph SELECT ROW_NUMBER() OVER (ORDER BY rm.MeasurementValue) AS RowID, rm.MeasurementValue AS YAxis, 
		CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN CONVERT(VARCHAR,ts.TestStageName) ELSE CONVERT(VARCHAR,ts.TestStageName) +'': '' + Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' = '''' THEN ''V'' ELSE ''N'' END) END AS XAxis, 
		tu.BatchUnitNumber AS LoopValue, rm.LowerLimit, rm.UpperLimit '		
	END
	ELSE IF (@Xaxis=2 AND @PlotValue = 1)
	BEGIN
		SET @query = 'INSERT INTO #Graph SELECT ROW_NUMBER() OVER (ORDER BY rm.MeasurementValue) AS RowID, rm.MeasurementValue AS YAxis,
		CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN ''V'' ELSE ''N'' END) ELSE Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN ''V'' ELSE ''N'' END) +'': '' + Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' = '''' THEN ''V'' ELSE ''N'' END) END AS XAxis, 
		ts.TestStageName AS LoopValue, rm.LowerLimit, rm.UpperLimit '
	END
	ELSE IF (@Xaxis=2 AND @PlotValue = 0)
	BEGIN
		SET @query = 'INSERT INTO #Graph SELECT ROW_NUMBER() OVER (ORDER BY rm.MeasurementValue) AS RowID, rm.MeasurementValue AS YAxis, Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN ''V'' ELSE ''N'' END) AS XAxis, tu.BatchUnitNumber AS LoopValue, rm.LowerLimit, rm.UpperLimit '
	END
	
	SET @query += 'FROM Relab.Results r WITH(NOLOCK)
		INNER JOIN TestUnits tu WITH(NOLOCK) ON r.TestUnitID=tu.ID
		INNER JOIN Relab.ResultsMeasurements rm WITH(NOLOCK) ON r.ID=rm.ResultID
		INNER JOIN #batches b WITH(NOLOCK) ON tu.batchID=b.ID
		INNER JOIN #units u WITH(NOLOCK) ON u.id=tu.BatchUnitNumber
		INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
		LEFT OUTER JOIN Relab.ResultsParameters p ON p.ResultMeasurementID=rm.ID
	WHERE rm.MeasurementTypeID='+CONVERT(VARCHAR,@MeasurementTypeID)+' AND r.TestID='+CONVERT(VARCHAR,@TestID)+' AND MeasurementValue IS NOT NULL '
	
	IF (@Xaxis=2)
		BEGIN
			IF (@ParameterName IS NOT NULL)
				SET @query2 = ' AND (Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN '''+ ISNULL(@ParameterName,'')+''' <> '''' THEN ''N'' ELSE ''V'' END)='''+ ISNULL(@ParameterName,'')+''') '
			
			IF (@ParameterValue IS NOT NULL)
				SET @query2 = ' AND (Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN ''V'' ELSE ''N'' END)='''+ ISNULL(@ParameterValue,'')+''') '
		END
	ELSE
		BEGIN
			IF (@ParameterName IS NOT NULL)
				SET @query2 = ' AND (Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN '''+ ISNULL(@ParameterName,'')+''' <> '''' THEN ''N'' ELSE ''V'' END)='''+ ISNULL(@ParameterName,'')+''') '
			IF (@ParameterValue IS NOT NULL)
				SET @query2 = ' AND (Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN ''V'' ELSE ''N'' END)='''+ ISNULL(@ParameterValue,'')+''') '
		END

	SET @query2 += ' AND ISNULL(rm.Archived,0)=0 ORDER BY LoopValue'
	
	print @query
	print @query2
	
	EXEC(@query + @query2)
	
	UPDATE #Graph SET YAxis=1 WHERE YAxis IN ('True','Pass')
	UPDATE #Graph SET YAxis=0 WHERE YAxis IN ('Fail','False')
		
	select UpperLimit, LowerLimit, COUNT(*) as va
	into #GraphLimits
	FROM #Graph
	GROUP BY UpperLimit, LowerLimit
	
	IF (@@ROWCOUNT = 1)
	BEGIN
		IF (@ShowUpperLowerLimits = 1)
		BEGIN
			SELECT DISTINCT ROUND(Lowerlimit, 3) AS YAxis, XAxis, (LoopValue + ' Lower Specification Limit') AS LoopValue 
			FROM #Graph
			WHERE LowerLimit IS NOT NULL AND ISNUMERIC(LowerLimit)=1 AND LoopValue = (SELECT MIN(LoopValue) FROM #Graph)
			
			SELECT DISTINCT ROUND(Upperlimit, 3) AS YAxis, XAxis, (LoopValue + ' Upper Specification Limit') AS LoopValue 
			FROM #Graph
			WHERE LowerLimit IS NOT NULL AND ISNUMERIC(LowerLimit)=1 AND LoopValue = (SELECT MIN(LoopValue) FROM #Graph)
		END	
	END
	
	DECLARE select_cursor CURSOR FOR SELECT DISTINCT LoopValue FROM #Graph
	OPEN select_cursor

	FETCH NEXT FROM select_cursor INTO @LoopValue

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT DISTINCT ROUND(YAxis, 3) AS YAxis, XAxis, LoopValue, LowerLimit, UpperLimit FROM #Graph WHERE LoopValue=@LoopValue AND ISNUMERIC(YAxis)=1
		FETCH NEXT FROM select_cursor INTO @LoopValue
	END
	
	CLOSE select_cursor
	DEALLOCATE select_cursor
	
	DROP TABLE #Graph
	DROP TABLE #batches
	DROP TABLE #units
	DROP TABLE #GraphLimits
END
GO
GRANT EXECUTE ON Relab.remispResultsGraph TO REMI
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