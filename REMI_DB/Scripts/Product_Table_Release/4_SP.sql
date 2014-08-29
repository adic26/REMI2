/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        ci0000001593275\SQLDeveloper.REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 3/18/2013 10:09:01 AM

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
	@TestStageName nvarchar(400) = null
AS
	declare @pgName nvarchar(800)
	declare @testunitid int
	declare @TestStageType int
	declare @TestStageID int
		
	--get the test unit id
	if @QRANumber is not null and @BatchUnitNumber is not null
	begin
		set @testUnitID = (select tu.Id from TestUnits as tu, Batches as b where b.QRANumber = @QRANumber AND tu.BatchID = b.ID AND tu.batchunitnumber = @Batchunitnumber)
		PRINT 'TestUnitID: ' + CONVERT(NVARCHAR, ISNULL(@testUnitID,''))
	end
		
	--get the product group name for the test unit's batch
	set @pgName= (select p.ProductGroupname from Batches as b, TestUnits as tu, products p where b.id = tu.BatchID and tu.ID= @testunitid and p.id=b.productID)
	PRINT 'pgName: ' + CONVERT(NVARCHAR, ISNULL(@pgName,''))

	--Get the test stage id
	set @TestStageID = (select ts.ID from Teststages as ts,jobs as j, Batches as b, TestUnits as tu
	where ts.TestStageName = @TestStageName and ts.JobID = j.id 
		and j.jobname = b.jobname 
		and tu.ID = @testunitid
		and b.ID = tu.BatchID)

	PRINT 'TestStageID: ' + CONVERT(NVARCHAR, ISNULL(@TestStageID,''))

	--set up the required tables
	declare @testUnitExemptions table (exTestName nvarchar(255))

	insert into @testunitexemptions
	SELECT DISTINCT TestName
	FROM vw_ExceptionsPivoted as pvt
		INNER JOIN Tests t ON (pvt.Test = t.ID OR pvt.Test = t.TestName)
	where (
			(pvt.TestUnitID = @TestUnitID and pvt.ProductGroupName is null) 
			or 
			(pvt.TestUnitID is null and pvt.ProductGroupName = @pgName)
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
select @ApplicableTestStages = @ApplicableTestStages + ', '  + TestStageName from TestStages where TestStages.JobID = (select ID from Jobs where jobname = @jobname) order by ProcessOrder
set @ApplicableTestStages = SUBSTRING(@ApplicableTestStages,3,Len(@ApplicableTestStages))
--get applicable tests
select @ApplicableTests = @ApplicableTests + ', '  +  testname from Tests as t, TrackingLocationsForTests as tlft, TrackingLocationTypes as tlt , TrackingLocations as tl

where t.ID = tlft.TestID
and tlft.TrackingLocationtypeID = tlt.ID
and tlt.ID = tl.TrackingLocationTypeID
and tl.ID = @tlid
set @ApplicableTests = SUBSTRING(@ApplicableTests,3,Len(@ApplicableTests))

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
PRINT N'Altering [dbo].[remispGetProductConfiguration]'
GO
ALTER PROCEDURE [dbo].[remispGetProductConfiguration] @TestID INT, @productID INT
AS
BEGIN
	SELECT pc.ID, pcParent.NodeName As ParentName, pc.ParentId AS ParentID, pc.ViewOrder, pc.NodeName,
		ISNULL((
			(SELECT ISNULL(ProductConfiguration.NodeName, '')
			FROM ProductConfiguration
				LEFT OUTER JOIN ProductConfiguration pc2 ON ProductConfiguration.ID = pc2.ParentId
			WHERE pc2.ID = pc.ParentID)
			+ '/' + 
			ISNULL(pcParent.NodeName, '')
		), CASE WHEN pc.ParentId IS NOT NULL THEN pcParent.NodeName ELSE NULL END) As ParentScheme
	FROM ProductConfiguration pc
		LEFT OUTER JOIN ProductConfiguration pcParent ON pc.ParentId=pcParent.ID
	WHERE pc.TestID=@TestID AND pc.productID=@productID
	ORDER BY pc.ViewOrder
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispSaveProductConfiguration]'
GO
ALTER PROCEDURE [dbo].[remispSaveProductConfiguration] @productID INT, @parentID INT, @ViewOrder INT, @NodeName NVARCHAR(200), @TestID INT, @productGroupNameID INT, @LastUser NVARCHAR(255)
AS
BEGIN
	If ((@productID IS NULL OR @productID = 0 OR NOT EXISTS (SELECT 1 FROM ProductConfiguration WHERE ID=@productID)) AND @NodeName IS NOT NULL AND LTRIM(RTRIM(@NodeName)) <> '')
	BEGIN
		INSERT INTO ProductConfiguration (ParentId, ViewOrder, NodeName, TestID, ProductID, LastUser)
		VALUES (CASE WHEN @parentID = 0 THEN NULL ELSE @parentID END, @ViewOrder, @NodeName, @TestID, @productGroupNameID, @LastUser)
		
		SET @productID = SCOPE_IDENTITY()
	END
	ELSE IF (@productID > 0)
	BEGIN
		UPDATE ProductConfiguration
		SET ParentId=CASE WHEN @parentID = 0 THEN NULL ELSE @parentID END, ViewOrder=@ViewOrder, NodeName=@NodeName, LastUser=@LastUser
		WHERE ID=@productID
	END
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesSelectActiveBatchesForProductGroup]'
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectActiveBatchesForProductGroup]
/*	'===============================================================
	'   NAME:                	remispBatchesSelectActiveBatchesForProductGroup
	'   DATE CREATED:       	12 May 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves data from table: Batches based on search criteria
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/
	@ProductID INT = null,
	@AccessoryGroupName nvarchar(800) = null,
	@StartRowIndex int = null,
	@MaximumRows int = null,
	@RecordCount int = null OUTPUT,
	@GetAllBatches int = 0
AS
	IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (SELECT COUNT(*) FROM Batches WHERE 		
		(Batches.BatchStatus NOT IN(5,7) or @GetAllBatches =1)
		AND productID = @ProductID
		and (AccessoryGroupName = @AccessoryGroupName or @AccessoryGroupName is null))
		RETURN
	END
	
	SELECT BatchesRows.row,BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,BatchesRows.JobName,
		BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,BatchesRows.ProductType,batchesrows.AccessoryGroupName,batchesrows.productid, BatchesRows.QRANumber,BatchesRows.RequestPurpose,
		BatchesRows.TestCenterLocation,BatchesRows.TestStageName, BatchesRows.RFBands, BatchesRows.TestStageCompletionStatus,
		testUnitCount,
		(CASE WHEN BatchesRows.WILocation IS NULL THEN NULL ELSE BatchesRows.WILocation END) AS jobWILocation,
		(testunitcount -
			(select COUNT(*) 
			from TestUnits as tu
			INNER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
		) as HasUnitsToReturnToRequestor,
		(select AssignedTo 
		from TaskAssignments as ta
			--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
			INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
			--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
			INNER JOIN Jobs j ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
		where ta.BatchID = BatchesRows.ID and ta.Active=1  ) as ActiveTaskAssignee, CONVERT(BIT,0) AS HasBatchSpecificExceptions
	FROM     
		(
			SELECT ROW_NUMBER() OVER (ORDER BY b.ID) AS Row, 
				b.BatchStatus,b.Comment,(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
				b.ConcurrencyID,b.ID,b.TestStageCompletionStatus,b.JobName,
				b.LastUser,b.Priority,p.ProductGroupName,b.QRANumber,b.RequestPurpose,b.ProductType,b.AccessoryGroupName,p.ID As ProductID,
				b.TestCenterLocation,b.TestStageName,
				(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount, j.WILocation
			FROM Batches as b 
				inner join Products p on b.ProductID=p.id
				LEFT OUTER JOIN Jobs j ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
			WHERE (b.BatchStatus NOT IN(5,7) or @GetAllBatches =1) AND p.ID = @ProductID and (AccessoryGroupName = @AccessoryGroupName or @AccessoryGroupName is null)
		) AS BatchesRows
	WHERE (Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) OR @startRowIndex is null OR @maximumRows is null
	RETURN
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispProductGroupConfiguration]'
GO
ALTER PROCEDURE [dbo].[remispProductGroupConfiguration] @productID INT, @TestID INT AS
BEGIN
	DECLARE @rows VARCHAR(8000)
	DECLARE @query VARCHAR(4000)
	DECLARE @id INT
	CREATE TABLE #results (idkey [int] IDENTITY(1,1),  NodeName varchar(150), ID int, ParentID int, Example varchar(800))
	CREATE TABLE #results2 (idkey [int] IDENTITY(1,1),  NodeName varchar(150), ID int, ParentID int, Example varchar(800))

	IF NOT EXISTS (SELECT 1 FROM ProductConfiguration WHERE ProductID=@productID AND TestID=@TestID)
	BEGIN
		SELECT TOP 1 @productID = ProductID
		FROM ProductConfiguration
		WHERE TestID=@TestID
	END

	SELECT @rows=  STUFF(
	( 
	SELECT DISTINCT '],[' + l.[Values] 
	FROM    ProductConfiguration pc
	inner join ProductConfigValues val on pc.ID = val.ProductConfigID
	inner join Lookups l on val.LookupID=l.LookupID
	where TestID=@TestID and ProductID=@productID
	ORDER BY '],[' +  l.[Values]
	FOR XML PATH('')), 1, 2, '') + ']'

	SET @query = '
	select NodeName, ID, ParentID, 
	(
		SELECT pvt.* FROM
		(
			SELECT  l.[Values], val.Value
			FROM ProductConfiguration pc
			inner join ProductConfigValues val on pc.ID=val.ProductConfigID
			inner join Lookups l on val.LookupID=l.LookupID
			where TestID=''' + CONVERT(varchar,@TestID) + ''' and ProductID=''' + CONVERT(varchar,@productID) + ''' and productconfiguration.ID=pc.ID
		)t
		PIVOT (max(Value) FOR t.[Values]
		IN ('+@rows+')) AS pvt
		for xml Path('''')
	) as example

	from productconfiguration
	where TestID=''' + CONVERT(varchar,@TestID) + ''' and ProductID=''' + CONVERT(varchar,@productID) + '''
	ORDER BY ViewOrder'

	INSERT INTO #results
		EXECUTE (@query)	

	SELECT @id= MIN(idkey) FROM #results WHERE ParentID IS NOT NULL

	IF EXISTS (SELECT idkey FROM #results WHERE ParentID IS NULL)
		INSERT INTO #results2 SELECT NodeName, ID, ParentID, Example FROM #results WHERE ParentID IS NULL

	WHILE (@id is not null)
	BEGIN
		IF EXISTS (SELECT idkey FROM #results WHERE idkey=@id)
			INSERT INTO #results2 SELECT NodeName, ID, ParentID, Example FROM #results WHERE idkey=@id

	--	SELECT * FROM #results where id=@id
		SELECT @id= MIN(idkey) FROM #results WHERE idkey > @id AND ParentID IS NOT NULL
	END

	SELECT * FROM #results2

	DROP TABLE #results
	DROP TABLE #results2
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesSelectChamberBatches]'
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectChamberBatches]
/*	'===============================================================
	'   NAME:                	remispBatchesSelectDailyList
	'   DATE CREATED:       	20 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retreives the batches in chamber
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/

	@StartRowIndex int = -1,
	@MaximumRows int = -1,
	@TestCentreLocation nvarchar(200) =null,
	@RecordCount int = NULL OUTPUT,
	@sortExpression varchar(100) = null,
	@direction varchar(100) = 'asc'
	AS
SELECT BatchesRows.Row, BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,
	BatchesRows.JobName,BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,batchesrows.ProductType,batchesrows.AccessoryGroupName,
	batchesrows.ProductID,batchesrows.QRANumber,
	BatchesRows.RequestPurpose,BatchesRows.TestCenterLocation,BatchesRows.TestStageName, 
	batchesrows.RFBands, batchesrows.TestStageCompletionStatus,testunitcount,
	(CASE WHEN batchesrows.WILocation IS NULL THEN NULL ELSE batchesrows.WILocation END) AS jobWILocation,
	(testUnitCount -
		(select COUNT(*) 
			  from TestUnits as tu
			  INNER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			  where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
	) as HasUnitsToReturnToRequestor,
	(select AssignedTo 
	from TaskAssignments as ta
		--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
		INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
		--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
		INNER JOIN Jobs j ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
	where ta.BatchID = BatchesRows.ID and ta.Active=1  ) as ActiveTaskAssignee, CONVERT(BIT,0) AS HasBatchSpecificExceptions
	FROM     
	(
		SELECT ROW_NUMBER() OVER 
			(ORDER BY 
				case when @sortExpression='qra' and @direction='asc' then qranumber end,
				case when @sortExpression='qra' and @direction='desc' then qranumber end desc,
				case when @sortExpression='teststage' and @direction='asc' then b.teststagename end,
				case when @sortExpression='teststage' and @direction='desc' then b.teststagename end desc,
				case when @sortExpression='purpose' and @direction='asc' then requestpurpose end,
				case when @sortExpression='purpose' and @direction='desc' then requestpurpose end desc,
				case when @sortExpression='job' and @direction='asc' then jobname end,
				case when @sortExpression='job' and @direction='desc' then jobname end desc,
				case when @sortExpression='productgroup' and @direction='asc' then productgroupname end asc,
				case when @sortExpression='productgroup' and @direction='desc' then productgroupname end desc,
				case when @sortExpression='priority' and @direction='asc' then Priority end asc,
				case when @sortExpression='priority' and @direction='desc' then Priority end desc,
				case when @sortExpression='batchstatus' and @direction='asc' then batchstatus end,
				case when @sortExpression='batchstatus' and @direction='desc' then batchstatus end desc,
				case when @sortExpression is null then Priority end desc
			) AS Row, 
			ID, 
			QRANumber, 
			Comment,
			RequestPurpose, 
			Priority,
			TestStageName, 
			BatchStatus, 
			ProductGroupName, 
			ProductType,
			AccessoryGroupName,
			ProductID,
			JobName, 
			TestCenterLocation,
			LastUser, 
			ConcurrencyID,
			b.RFBands,
			b.TestStageCompletionStatus,
			(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
			b.WILocation
		FROM 
		(
			SELECT DISTINCT b.ID, 
				b.QRANumber, 
				b.Comment,
				b.RequestPurpose, 
				b.Priority,
				b.TestStageName, 
				b.BatchStatus, 
				p.ProductGroupName, 
				b.ProductType,
				b.AccessoryGroupName,
				p.ID As ProductID,
				b.JobName, 
				b.LastUser, 
				b.TestCenterLocation,
				b.ConcurrencyID,
				(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
				b.TestStageCompletionStatus, j.WILocation
			FROM Batches AS b 
				LEFT OUTER JOIN Jobs as j on b.jobname = j.JobName 
				inner join TestStages as ts on j.ID = ts.JobID
				inner join Tests as t on ts.TestID = t.ID
				inner join DeviceTrackingLog AS dtl 
				INNER JOIN TrackingLocations AS tl ON dtl.TrackingLocationID = tl.ID
				INNER JOIN TrackingLocationTypes as tlt on tl.TrackingLocationTypeID = tlt.id 
				inner join TestUnits AS tu ON dtl.TestUnitID = tu.ID on tu.CurrentTestName = t.TestName and b.id = tu.batchid  --batches where there's a tracking log
				INNER JOIN Products p ON b.ProductID=p.id   
			WHERE (b.TestCenterLocation = @TestCentreLocation or @TestCentreLocation is null) and j.TechnicalOperationsTest = 1 and j.MechanicalTest=0 and  tlt.TrackingLocationFunction= 4  and t.ResultBasedOntime = 1 AND dtl.OutTime IS NULL AND dtl.OutUser IS NULL
		)as b
	) as batchesrows
 	WHERE ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) OR @startRowIndex = -1 OR @maximumRows = -1) 
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispGetSimilarTestConfiguration]'
GO
ALTER PROCEDURE [dbo].[remispGetSimilarTestConfiguration] @productID INT, @TestID INT
AS
BEGIN
	SELECT pc.ProductID AS ID, p.ProductGroupName
	FROM ProductConfiguration pc
		INNER JOIN Products p on pc.ProductID = p.ID
	WHERE pc.TestID=@TestID AND pc.ProductID <> @productID
	GROUP BY pc.ProductID, p.ProductGroupName
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesSelectBatchesForReport]'
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectBatchesForReport]
/*	'===============================================================
	'   NAME:                	remispBatchesSelectBatchesForReport
	'   DATE CREATED:       	12 Jul 2011
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retreives the batches where batch is having a report written
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/

	@StartRowIndex int = -1,
	@MaximumRows int = -1,
	@TestCentreLocation nvarchar(200) =null,
	@RecordCount int = NULL OUTPUT,
	@sortExpression varchar(100) = null,
	@direction varchar(100) = 'asc'
	AS
SELECT BatchesRows.Row, BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,
	BatchesRows.JobName,BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,batchesrows.ProductType,batchesrows.AccessoryGroupName,
	batchesrows.ProductID,batchesrows.QRANumber,
	BatchesRows.RequestPurpose,BatchesRows.TestCenterLocation,BatchesRows.TestStageName, 
	batchesrows.RFBands, batchesrows.TestStageCompletionStatus, testunitcount,
	(CASE WHEN BatchesRows.WILocation IS NULL THEN NULL ELSE BatchesRows.WILocation END) AS jobWILocation,
	(
		testunitcount -
		(select COUNT(*) 
		from TestUnits as tu
			INNER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
		where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
	) as HasUnitsToReturnToRequestor,
	(select AssignedTo 
	from TaskAssignments as ta
		--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
		INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
		--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
		INNER JOIN Jobs j ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
	where ta.BatchID = BatchesRows.ID and ta.Active=1  ) as ActiveTaskAssignee, CONVERT(BIT,0) AS HasBatchSpecificExceptions
	FROM     
		(
			SELECT ROW_NUMBER() OVER 
			(
				ORDER BY 
					case when @sortExpression='qra' and @direction='asc' then qranumber end,
					case when @sortExpression='qra' and @direction='desc' then qranumber end desc,
					case when @sortExpression='teststage' and @direction='asc' then b.teststagename end,
					case when @sortExpression='teststage' and @direction='desc' then b.teststagename end desc,
					case when @sortExpression='purpose' and @direction='asc' then requestpurpose end,
					case when @sortExpression='purpose' and @direction='desc' then requestpurpose end desc,
					case when @sortExpression='job' and @direction='asc' then jobname end,
					case when @sortExpression='job' and @direction='desc' then jobname end desc,
					case when @sortExpression='productgroup' and @direction='asc' then productgroupname end asc,
					case when @sortExpression='productgroup' and @direction='desc' then productgroupname end desc,
					case when @sortExpression='priority' and @direction='asc' then Priority end asc,
					case when @sortExpression='priority' and @direction='desc' then Priority end desc,
					case when @sortExpression='batchstatus' and @direction='asc' then batchstatus end,
					case when @sortExpression='batchstatus' and @direction='desc' then batchstatus end desc,
					case when @sortExpression is null then Priority end desc		
			) AS Row, 
			ID, 
			QRANumber, 
			Comment,
			RequestPurpose, 
			Priority,
			TestStageName, 
			BatchStatus, 
			ProductGroupName, 
			productType,
			AccessoryGroupName,
			ProductID,
			JobName, 
			TestCenterLocation,
			LastUser, 
			ConcurrencyID,
			b.RFBands,
			b.TestStageCompletionStatus ,
			b.WILocation,
			(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount
			FROM
				(
					SELECT DISTINCT b.ID, 
						b.QRANumber, 
						b.Comment,
						b.RequestPurpose, 
						b.Priority,
						b.TestStageName, 
						b.BatchStatus, 
						p.ProductGroupName, 
						b.ProductType,
						b.AccessoryGroupName,
						p.ID As ProductID,
						b.JobName, 
						b.LastUser, 
						b.TestCenterLocation,
						b.ConcurrencyID,
						(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
						b.TestStageCompletionStatus,
						j.WILocation
					FROM Batches AS b
						inner join Products p on p.ID=b.ProductID
						LEFT OUTER JOIN Jobs j ON j.JobName = b.JobName
					WHERE (b.TestCenterLocation = @TestCentreLocation or @TestCentreLocation is null) and (b.TestStageName = 'Report') and (b.BatchStatus != 5)
				)as b
		) as batchesrows
 	WHERE (
 			(Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) 
			OR @startRowIndex = -1 OR @maximumRows = -1
		  )
	order by QRANumber desc
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestExceptionsGetBatchExceptions]'
GO
ALTER procedure [dbo].[remispTestExceptionsGetBatchExceptions] @qraNumber nvarchar(11) = null
AS
--get any for the product
select distinct pvt.id, null as batchunitnumber, pvt.ReasonForRequest,pvt.ProductGroupName,b.JobName, ts.teststagename
, t.TestName, (SELECT TOP 1 LastUser FROM TestExceptions WHERE ID=pvt.ID) AS LastUser,
(SELECT TOP 1 ConcurrencyID FROM TestExceptions WHERE ID=pvt.ID) AS ConcurrencyID,
pvt.TestStageID, pvt.TestUnitID, pvt.ProductType, pvt.AccessoryGroupName, p.ID AS ProductID
FROM vw_ExceptionsPivoted as pvt
	LEFT OUTER JOIN Tests t ON (pvt.Test = t.ID OR pvt.Test = t.TestName)
	LEFT OUTER JOIN Products p ON p.ProductGroupName=pvt.ProductGroupName
	, Batches as b, teststages as ts, Jobs as j
where b.QRANumber = @qranumber 
	and (ts.JobID = j.ID or j.ID is null)
	and (b.JobName = j.JobName or j.JobName is null)
	and pvt.TestUnitID is null
	and (ts.id = pvt.teststageid or pvt.TestStageID is null)
	and 
	(
		(pvt.ProductGroupName = p.ProductGroupName and pvt.ReasonForRequest is null) 
		or 
		(pvt.ProductGroupName = p.ProductGroupName and pvt.ReasonForRequest = b.RequestPurpose)
		or
		(pvt.ProductGroupName is null and pvt.ReasonForRequest = b.RequestPurpose)
		or
		(pvt.ProductGroupName is null and pvt.ReasonForRequest is null)
	)
	AND
	(
		(pvt.AccessoryGroupName IS NULL)
		OR
		(pvt.AccessoryGroupName IS NOT NULL AND pvt.AccessoryGroupName = b.AccessoryGroupName)
	)
	AND
	(
		(pvt.ProductType IS NULL)
		OR
		(pvt.ProductType IS NOT NULL AND pvt.ProductType = b.ProductType)
	)

union all

--then get any for the test units.
select distinct pvt.id, tu.BatchUnitNumber, pvt.ReasonForRequest,pvt.ProductGroupName,b.JobName, 
(select teststagename from teststages where teststages.id =pvt.TestStageid) as teststagename, t.testname,
(SELECT TOP 1 LastUser FROM TestExceptions WHERE ID=pvt.ID) AS LastUser,
(SELECT TOP 1 ConcurrencyID FROM TestExceptions WHERE ID=pvt.ID) AS ConcurrencyID
, pvt.TestStageID, pvt.TestUnitID, pvt.ProductType, pvt.AccessoryGroupName, p.ID AS ProductID
FROM vw_ExceptionsPivoted as pvt
	LEFT OUTER JOIN Tests t ON (pvt.Test = t.ID OR pvt.Test = t.TestName)
	LEFT OUTER JOIN Products p ON p.ProductGroupName=pvt.ProductGroupName
, Batches as b, testunits tu 
where b.QRANumber = @qranumber and tu.batchid = b.id and pvt.TestUnitID = tu.id
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispDeviceTrackingLogSelectListByProductDate]'
GO
ALTER PROCEDURE [dbo].[remispDeviceTrackingLogSelectListByProductDate]
/*	'===============================================================
	'   NAME:                	remispDeviceTrackingLogSelectListByProductDate
	'   DATE CREATED:       	1 Nov 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves paged data from table: DeviceTrackingLog OR the number of records in the table
	'   IN:         TestUnitID Optional: RecordCount         
	'   OUT: 		List Of: ID, TestUnitId, TrackingLocationId, InTime, OutTime, InUser, OutUser, ConcurrencyID              
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/
	@ProductID INT, @Date as datetime = '05/22/1983'
AS
	SELECT dtl.ID,
		TestUnitId, 
		TrackingLocationId, 
		InTime, 
		OutTime, 
		InUser, 
		OutUser,
		dtl.ConcurrencyID,
		tu.BatchUnitNumber,
		b.QRANumber, 
		tl.TrackingLocationName
	FROM Batches as b
		INNER JOIN TestUnits tu ON tu.BatchID = b.id
		LEFT OUTER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID
		LEFT OUTER JOIN TrackingLocations as tl ON tl.ID = dtl.TrackingLocationID
	WHERE b.ProductID = @ProductID and (dtl.InTime > @Date) 
	order by  dtl.intime desc
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispSaveProductConfigurationDetails]'
GO
ALTER PROCEDURE [dbo].[remispSaveProductConfigurationDetails] @productID INT, @configID INT, @lookupID INT, @lookupValue NVARCHAR(200), @TestID INT, @productGroupNameID INT, @LastUser NVARCHAR(255)
AS
BEGIN	
	If ((@configID IS NULL OR @configID = 0 OR NOT EXISTS (SELECT 1 FROM ProductConfigValues WHERE ID=@configID)) AND @lookupValue IS NOT NULL AND LTRIM(RTRIM(@lookupValue)) <> '' AND @LookupID IS NOT NULL AND @LookupID > 0 AND EXISTS(SELECT 1 FROM ProductConfiguration WHERE ID=@productID))
	BEGIN
		INSERT INTO ProductConfigValues (Value, LookupID, ProductConfigID, LastUser)
		VALUES (@lookupValue, @LookupID, @productID, @LastUser)
	END
	ELSE IF (@configID > 0)
	BEGIN
		UPDATE ProductConfigValues
		SET Value=@lookupValue, LookupID=@LookupID, LastUser=@LastUser, ProductConfigID=@productID
		WHERE ID=@configID
	END
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispCopyTestConfiguration]'
GO
ALTER PROCEDURE [dbo].[remispCopyTestConfiguration] @ProductID INT, @TestID INT, @copyFromProductID INT, @LastUser NVARCHAR(255)
AS
BEGIN
	BEGIN TRANSACTION
	
	DECLARE @FromCount INT
	DECLARE @ToCount INT
	DECLARE @max INT
	SET @max = (SELECT MAX(ID) +1 FROM ProductConfiguration)
	
	SELECT @FromCount = COUNT(*) FROM ProductConfiguration WHERE TestID=@TestID AND ProductID=@copyFromProductID
	
	SELECT tempID=IDENTITY (int, 1, 1), CONVERT(int,ID) As ID, ParentId, ViewOrder, NodeName, @TestID AS TestID, @ProductID AS ProductID, @LastUser AS LastUser, 0 AS newproID, NULL AS newParentID
	INTO #ProductConfiguration
	FROM ProductConfiguration
	WHERE TestID=@TestID AND ProductID=@copyFromProductID
	
	UPDATE #ProductConfiguration SET newproID=@max+tempid
	
	UPDATE #ProductConfiguration 
	SET #ProductConfiguration.newParentID = pc2.newproID
	FROM #ProductConfiguration
		LEFT OUTER JOIN #ProductConfiguration pc2 ON #ProductConfiguration.ParentID=pc2.ID
		
	SET Identity_Insert ProductConfiguration ON
	
	INSERT INTO ProductConfiguration (ID, ParentId, ViewOrder, NodeName, TestID, ProductID, LastUser)
	SELECT newproID, newParentId, ViewOrder, NodeName, TestID, ProductID, LastUser
	FROM #ProductConfiguration
	
	SET Identity_Insert ProductConfiguration OFF
	
	SELECT @ToCount = COUNT(*) FROM ProductConfiguration WHERE TestID=@TestID AND ProductID=@ProductID

	IF (@FromCount = @ToCount)
	BEGIN
		SELECT @FromCount = COUNT(*) FROM ProductConfiguration pc INNER JOIN ProductConfigValues pcv ON pc.ID=pcv.ProductConfigID WHERE TestID=@TestID AND ProductID=@copyFromProductID
	
		INSERT INTO ProductConfigValues (Value, LookupID, ProductConfigID, LastUser)
		SELECT Value, LookupID, #ProductConfiguration.newproID AS ProductConfigID, @LastUser AS LastUser
		FROM ProductConfigValues
			INNER JOIN ProductConfiguration ON ProductConfigValues.ProductConfigID=ProductConfiguration.ID
			INNER JOIN #ProductConfiguration ON ProductConfiguration.ID=#ProductConfiguration.ID	
			
		SELECT @ToCount = COUNT(*) FROM ProductConfiguration pc INNER JOIN ProductConfigValues pcv ON pc.ID=pcv.ProductConfigID WHERE TestID=@TestID AND ProductID=@ProductID
		
		IF (@FromCount <> @ToCount)
		BEGIN
			GOTO HANDLE_ERROR
		END
		GOTO HANDLE_SUCESS
	END
	ELSE
	BEGIN
		GOTO HANDLE_ERROR
	END
	
	HANDLE_SUCESS:
		IF @@TRANCOUNT > 0
			COMMIT TRANSACTION
			RETURN	
	
	HANDLE_ERROR:
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION
			RETURN	
    
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesSelectListAtTrackingLocation]'
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectListAtTrackingLocation]
/*	'===============================================================
	'   NAME:                	remispBatchesSelectListAtTrackingLocation
	'   DATE CREATED:       	20 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves paged data from table: Batches
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/


	@TrackingLocationID int,
	@StartRowIndex int = -1,
	@MaximumRows int = -1,
	@RecordCount int = NULL OUTPUT,
	@sortExpression varchar(100) = null,
	@direction varchar(100) = 'asc'
	AS
	
IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (select  COUNT(*) from (select DISTINCT b.id	FROM  Batches AS b INNER JOIN
                      DeviceTrackingLog AS dtl INNER JOIN
                      TrackingLocations AS tl ON dtl.TrackingLocationID = tl.ID INNER JOIN
                      TestUnits AS tu ON dtl.TestUnitID = tu.ID ON b.id = tu.BatchID --batches where there's a tracking log
                      
				WHERE  tl.id = @TrackingLocationID AND dtl.OutTime IS NULL AND dtl.OutUser IS NULL)as records)  --and the tracking log has not been 'scanned' out
		RETURN
	END
SELECT
						 BatchesRows.Row, BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,
				 BatchesRows.JobName,BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,BatchesRows.QRANumber,
				 BatchesRows.RequestPurpose,BatchesRows.TestCenterLocation,BatchesRows.TestStageName,batchesrows.ProductType, batchesrows.AccessoryGroupName,Batchesrows.ProductID,
				 batchesrows.RFBands, batchesrows.TestStageCompletionStatus,testunitcount,
				 (testunitcount -
			   (select COUNT(*) 
			  from TestUnits as tu
			  INNER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			  where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
			  ) as HasUnitsToReturnToRequestor,
(CASE WHEN BatchesRows.WILocation IS NULL THEN NULL ELSE BatchesRows.WILocation END) AS jobWILocation,
	 (select AssignedTo 
	from TaskAssignments as ta
		--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
		INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
		--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
		INNER JOIN Jobs j ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
	where ta.BatchID = BatchesRows.ID and ta.Active=1  ) as ActiveTaskAssignee, CONVERT(BIT,0) AS HasBatchSpecificExceptions
	FROM     
		(SELECT ROW_NUMBER() OVER (ORDER BY 
case when @sortExpression='qra' and @direction='asc' then qranumber end,
case when @sortExpression='qra' and @direction='desc' then qranumber end desc,
case when @sortExpression='teststage' and @direction='asc' then b.teststagename end,
case when @sortExpression='teststage' and @direction='desc' then b.teststagename end desc,
case when @sortExpression='purpose' and @direction='asc' then requestpurpose end,
case when @sortExpression='purpose' and @direction='desc' then requestpurpose end desc,
case when @sortExpression='job' and @direction='asc' then jobname end,
case when @sortExpression='job' and @direction='desc' then jobname end desc,
case when @sortExpression='productgroup' and @direction='asc' then productgroupname end asc,
case when @sortExpression='productgroup' and @direction='desc' then productgroupname end desc,
case when @sortExpression='priority' and @direction='asc' then Priority end asc,
case when @sortExpression='priority' and @direction='desc' then Priority end desc,
case when @sortExpression='batchstatus' and @direction='asc' then batchstatus end,
case when @sortExpression='batchstatus' and @direction='desc' then batchstatus end desc,
case when @sortExpression is null then Priority end desc
		) AS Row, 
		           ID, 
                      QRANumber, 
                      Comment,
                      RequestPurpose, 
                      Priority,
                      TestStageName, 
                      BatchStatus, 
                      ProductGroupName, 
					  ProductType,
					  AccessoryGroupName,
					  ProductID,
                      JobName, 
                      TestCenterLocation,
                      LastUser, 
                      ConcurrencyID,
                      b.RFBands,
                      b.TestStageCompletionStatus,
				 (select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
				 b.WILocation
                      from
				(SELECT DISTINCT 
                      b.ID, 
                      b.QRANumber, 
                      b.Comment,
                      b.RequestPurpose, 
                      b.Priority,
                      b.TestStageName, 
                      b.BatchStatus, 
                      p.ProductGroupName, 
					  b.ProductType,
					  b.AccessoryGroupName,
					  p.ID As ProductID,
                      b.JobName, 
                      b.LastUser, 
                      b.TestCenterLocation,
                      b.ConcurrencyID,
                      (case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
                      b.TestStageCompletionStatus,
                      j.WILocation
FROM Batches AS b 
                      INNER JOIN DeviceTrackingLog AS dtl 
                      INNER JOIN TrackingLocations AS tl ON dtl.TrackingLocationID = tl.ID 
                      INNER JOIN TestUnits AS tu ON dtl.TestUnitID = tu.ID ON b.id = tu.batchid --batches where there's a tracking log
                      inner join Products p on p.ID=b.ProductID
					  LEFT OUTER JOIN Jobs j ON j.JobName = b.JobName
WHERE     tl.id = @TrackingLocationId AND dtl.OutTime IS NULL AND dtl.OutUser IS NULL)as b) as batchesrows
	WHERE
	 ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) 
			OR @startRowIndex = -1 OR @maximumRows = -1) 
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesSelectDailyListQRAListOnly]'
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectDailyListQRAListOnly]
	@StartRowIndex int = -1,
	@MaximumRows int = -1,
	@RecordCount int = NULL OUTPUT,
	@ProductID INT = null,
	@sortExpression varchar(100) = null,
	@GetBatchesAtEnvStages int = 1,
	@direction varchar(100) = 'desc',
	@TestCenterLocation as nvarchar(255)= null,
	@GetOperationsTests as bit = 0,
	@GetTechnicalOperationsTests as bit = 1,
	@TestStageCompletion as int	 = null
AS

IF (@RecordCount IS NOT NULL)
BEGIN
	SET @RecordCount = (select COUNT(*) from (SELECT distinct b.* FROM Batches as b, TestStages as ts, TestUnits as tu, Jobs as j, Products p where 
	( ts.TestStageName = b.TestStageName) 
	and tu.BatchID = b.id
	and ts.JobID = j.id
	and j.JobName = b.JobName
	and ((j.OperationsTest = @getoperationstests and @GetOperationsTests = 1)
	or (j.TechnicalOperationsTest = @GetTechnicalOperationsTests and @GetTechnicalOperationsTests = 1 ))
	and ((b.batchstatus=2 or b.BatchStatus = 4) and (ts.TestStageType =  @GetBatchesAtEnvStages))
	and (@ProductID is null or p.ID = @ProductID)
	and ((@TestStageCompletion is null or b.TestStageCompletionStatus = @TestStageCompletion)
	or  (@TestStageCompletion = 2 and (b.TestStageCompletionStatus = 2 or b.TestStageCompletionStatus = 3)))
	and (@TestCenterLocation is null or TestCenterLocation = @TestCenterLocation)) as batchcount)
	RETURN
END

SELECT BatchesRows.QRANumber
FROM (
		SELECT ROW_NUMBER() OVER 
		(
			ORDER BY 
				case when @sortExpression='qra' and @direction='asc' then qranumber end,
				case when @sortExpression='qra' and @direction='desc' then qranumber end desc,
				case when @sortExpression='teststage' and @direction='asc' then b.teststagename end,
				case when @sortExpression='teststage' and @direction='desc' then b.teststagename end desc,
				case when @sortExpression='purpose' and @direction='asc' then requestpurpose end,
				case when @sortExpression='purpose' and @direction='desc' then requestpurpose end desc,
				case when @sortExpression='job' and @direction='asc' then jobname end,
				case when @sortExpression='job' and @direction='desc' then jobname end desc,
				case when @sortExpression='productgroup' and @direction='asc' then b.productgroupname end asc,
				case when @sortExpression='productgroup' and @direction='desc' then b.productgroupname end desc,
				case when @sortExpression='priority' and @direction='asc' then Priority end asc,
				case when @sortExpression='priority' and @direction='desc' then Priority end desc,
				case when @sortExpression='batchstatus' and @direction='asc' then batchstatus end,
				case when @sortExpression='batchstatus' and @direction='desc' then batchstatus end desc,
				case when @sortExpression='testcenter' and @direction='asc' then testcenterlocation end,
				case when @sortExpression='testcenter' and @direction='desc' then testcenterlocation end desc,
				case when @sortExpression is null then (cast(priority as varchar(10)) + qranumber) end desc
		) AS Row, 
		b.ID,
		b.QRANumber, 
		b.Priority, 
		b.TestStageName,
		b.BatchStatus, 
		b.ProductGroupName,
		b.ProductType,
		b.AccessoryGroupName,
		b.ProductID,
		b.Jobname,
		b.LastUser,
		b.ConcurrencyID,
		b.Comment,
		b.TestCenterLocation,
		b.RequestPurpose,
		(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = b.ProductGroupName)  end) as rfBands,
		b.TestStageCompletionStatus,
		(select COUNT (*) from TestUnits as tu where tu.id = b.ID) as testunitcount
		FROM 
		(
			select distinct b.*, p.ProductGroupName
			from Batches as b
				INNER JOIN TestStages as ts ON (ts.TestStageName = b.TestStageName)
				INNER JOIN TestUnits as tu ON (tu.BatchID = b.ID)
				INNER JOIN Products p ON p.ID=b.productID
				LEFT OUTER JOIN Jobs j ON (j.JobName = b.JobName)
			WHERE ts.JobID = j.ID and (b.batchstatus=2) and (ts.TestStageType =  @GetBatchesAtEnvStages) and (@ProductID is null or p.ID = @ProductID)
					and
					(
						(j.OperationsTest = @getoperationstests and @GetOperationsTests = 1)
						or 
						(j.TechnicalOperationsTest = @GetTechnicalOperationsTests and @GetTechnicalOperationsTests = 1 )
					)			
				and
				(
					(@TestStageCompletion is null or b.TestStageCompletionStatus = @TestStageCompletion)
					or
					(@TestStageCompletion = 2 and (b.TestStageCompletionStatus = 2 or b.TestStageCompletionStatus = 3))
				)
				and (@TestCenterLocation is null or TestCenterLocation = @TestCenterLocation)
		) as b
	) AS BatchesRows 
WHERE (
		(Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) 
		OR @startRowIndex = -1 OR @maximumRows = -1
	  ) order by row
GO
GRANT EXECUTE ON remispBatchesSelectDailyListQRAListOnly TO Remi
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispEnvironmentalReport]'
GO
ALTER procedure [dbo].[remispEnvironmentalReport]
	@startDate datetime,
	@enddate datetime,
	@reportBasedOn int = 1,
	@testLocationName NVARCHAR(400)
AS
SET NOCOUNT ON

IF (@testLocationName = 'All Test Centers')
BEGIN
	SET @testLocationName = NULL
END

DECLARE @TrueBit BIT
SET @TrueBit = CONVERT(BIT, 1)

SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Completed Testing], p.ProductGroupName 
FROM Batches b WITH(NOLOCK)
	INNER JOIN TestUnits tu ON b.ID = tu.BatchID
	INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus = 8 and ba.inserttime between @startdate and @enddate
	INNER JOIN BatchesAudit ba2 WITH(NOLOCK) ON b.ID = ba2.BatchID AND ba2.BatchStatus <> 8 and ba2.inserttime between @startdate and @enddate
	INNER JOIN Products p ON p.ID=b.ProductID
WHERE (b.TestCenterLocation = @testLocationName or @testLocationName is null) 
GROUP BY p.productgroupname
ORDER BY p.productgroupname

SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# in Chamber], p.productgroupname 
FROM DeviceTrackingLog dtl WITH(NOLOCK)
	INNER JOIN TestUnits tu WITH(NOLOCK) ON dtl.TestUnitID = tu.ID
	INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
	INNER JOIN TrackingLocations tl WITH(NOLOCK) ON dtl.TrackingLocationID = tl.id
	INNER JOIN TrackingLocationTypes tlt WITH(NOLOCK) ON tl.TrackingLocationTypeID = tlt.ID AND tlt.TrackingLocationFunction = 4 --4 means chamber type device (environmentstressing)
	INNER JOIN Products p ON p.ID=b.ProductID
WHERE dtl.InTime BETWEEN @startdate AND @enddate
	and (b.TestCenterLocation = @testLocationName or @testLocationName is null) 
GROUP BY p.productgroupname
ORDER BY p.productgroupname

SELECT count(tr.ID) as [# Units in FA], p.productgroupname 
FROM (
		SELECT tra.TestRecordId 
		FROM TestRecordsaudit tra WITH(NOLOCK)
		WHERE tra.Action IN ('I','U') AND tra.Status IN (3, 4) and tra.InsertTime BETWEEN @startdate AND @enddate--FQRaised and FARequired
		GROUP BY TestRecordId
	) as xer
	INNER JOIN TestRecords tr WITH(NOLOCK) ON tr.ID= xer.TestRecordId
	INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
	INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
	INNER JOIN Products p ON p.ID=b.ProductID
WHERE (b.TestCenterLocation = @testLocationName or @testLocationName is null) 
GROUP BY ProductGroupName
ORDER BY p.productgroupname

SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Worked On Parametric], p.productgroupname
FROM Batches b WITH(NOLOCK)
	INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
	INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
	INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
	INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
	INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.TechnicalOperationsTest = @TrueBit
	INNER JOIN Products p ON p.ID=b.ProductID
WHERE ba.inserttime between @startdate and @enddate and (b.TestCenterLocation = @testLocationName or @testLocationName is null) 
GROUP BY p.productgroupname
ORDER BY p.productgroupname

SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Completed Parametric], p.productgroupname
FROM Batches b WITH(NOLOCK)
	INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus IN (5, 8)--Complete or TestingComplete
	INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
	INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
	INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
	INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.TechnicalOperationsTest = @TrueBit
	INNER JOIN Products p ON p.ID=b.ProductID
WHERE ba.inserttime between @startdate and @enddate and (b.TestCenterLocation = @testLocationName or @testLocationName is null) 
GROUP BY p.productgroupname
ORDER BY p.productgroupname

SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Worked On Drop/Tumble], p.productgroupname
FROM Batches b WITH(NOLOCK)
	INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
	INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
	INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = @TrueBit
	INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
	INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
	INNER JOIN Products p ON p.ID=b.ProductID
WHERE ba.inserttime between @startdate and @enddate
	and (b.TestCenterLocation = @testLocationName or @testLocationName is null) 
GROUP BY p.productgroupname
ORDER BY p.productgroupname

SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Completed Drop/Tumble], p.productgroupname
FROM Batches b WITH(NOLOCK)
	INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus IN (5, 8)--Complete or TestingComplete
	INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
	INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = @TrueBit
	INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
	INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
	INNER JOIN Products p ON p.ID=b.ProductID
WHERE ba.inserttime between @startdate and @enddate
	and (b.TestCenterLocation = @testLocationName or @testLocationName is null) 
GROUP BY p.productgroupname
ORDER BY p.productgroupname

SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Worked On Accessories], p.productgroupname
FROM Batches b WITH(NOLOCK)
	INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
	INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
	INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
	INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
	INNER JOIN Products p ON p.ID=b.ProductID
WHERE ba.inserttime between @startdate and @enddate AND ba.ProductType = 'Accessory'
	and (b.TestCenterLocation = @testLocationName or @testLocationName is null) 
GROUP BY p.productgroupname
ORDER BY p.productgroupname

SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Worked On Component], p.productgroupname
FROM Batches b WITH(NOLOCK)
	INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
	INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
	INNER JOIN Products p ON p.ID=b.ProductID
WHERE ba.inserttime between @startdate and @enddate AND ba.ProductType = 'Component'
	and (b.TestCenterLocation = @testLocationName or @testLocationName is null) 
GROUP BY p.productgroupname
ORDER BY p.productgroupname

SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Worked On Handheld], p.productgroupname
FROM Batches b WITH(NOLOCK)
	INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
	INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
	INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
	INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
	INNER JOIN Products p ON p.ID=b.ProductID
WHERE ba.inserttime between @startdate and @enddate	AND ba.ProductType = 'Handheld'
	and (b.TestCenterLocation = @testLocationName or @testLocationName is null) 
GROUP BY p.productgroupname
ORDER BY p.productgroupname

SET NOCOUNT OFF
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestExceptionsGetProductExceptions]'
GO
ALTER procedure [dbo].[remispTestExceptionsGetProductExceptions]
	@productid INT = null,
	@recordCount  int  = null output,
	@startrowindex int = -1,
	@maximumrows int = -1
AS
DECLARE @ProductGroupName NVARCHAR(800)
SELECT @ProductGroupName = ProductGroupName FROM Products WHERE ID=@productid

IF (@RecordCount IS NOT NULL)
	BEGIN
		SELECT @RecordCount = COUNT(pvt.ID)
		FROM vw_ExceptionsPivoted as pvt
		where [TestUnitID] IS NULL AND (([ProductGroupName]=@ProductGroupName) OR (@ProductGroupName = 'All Records' AND pvt.ProductGroupName IS NULL))
return
end

--get any exceptions for the product
select *
from 
(
	select ROW_NUMBER() over (order by pvt.ProductGroupName desc)as row,
	pvt.ID,
	null as batchunitnumber, 
	pvt.[ReasonForRequest], pvt.ProductGroupName,
	(select jobname from jobs,TestStages where teststages.id =pvt.TestStageid and Jobs.ID = TestStages.jobid) as jobname, 
	(select teststagename from teststages where teststages.id =pvt.TestStageid) as teststagename, 
	t.TestName,pvt.TestStageID, pvt.TestUnitID,-- pvt.LastUser, pvt.concurrencyid
	(select top 1 LastUser from TestExceptions WHERE ID=pvt.ID) AS LastUser,
	(select top 1 ConcurrencyID from TestExceptions WHERE ID=pvt.ID) AS ConcurrencyID,
	pvt.ProductType, pvt.AccessoryGroupName, p.ID As ProductID
	FROM vw_ExceptionsPivoted as pvt
		LEFT OUTER JOIN Tests t ON (pvt.Test = t.ID OR pvt.Test = t.TestName)
		INNER JOIN Products p ON p.ProductGroupName=pvt.ProductGroupName
	WHERE pvt.TestUnitID IS NULL AND
			((pvt.[ProductGroupName]=@ProductGroupName) OR (@ProductGroupName = 'All Records' AND pvt.ProductGroupName IS NULL))) as exceptionResults
where ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) 
			OR @startRowIndex = -1 OR @maximumRows = -1)
ORDER BY TestName
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispProductSettingsInsertUpdateSingleItem]'
GO
ALTER PROCEDURE [dbo].[remispProductSettingsInsertUpdateSingleItem]
/*	'===============================================================
	'   NAME:                	remispProductSettingsInsertUpdateSingleItem
	'   DATE CREATED:       	4 Nov 2011
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Creates or updates an item in a table: Jobs
	'							Deletes the item if the value text is null
    '   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
	@ProductID INT,
	@KeyName nvarchar(MAX),
	@ValueText nvarchar(MAX) = null,
	@DefaultValue nvarchar(MAX),
	@LastUser nvarchar(255)	
AS
	DECLARE @ReturnValue int
	declare @ID int
	
	set @ID = (select ID from ProductSettings as ps  where ps.KeyName = @KeyName and productid=@ProductID)
	
	IF (@ID IS NULL and @ValueText is not null) -- New Item
	BEGIN
		INSERT INTO ProductSettings
		(
			Productid, 
			KeyName,
			ValueText,
			LastUser,
			DefaultValue
		)
		VALUES
		(
			@ProductID, 
			@KeyName,
			@ValueText,
			@LastUser,
			@DefaultValue
		)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE -- Exisiting Item
	BEGIN
		if @ValueText is null
			begin
				delete from ProductSettings where ID = @id;
			end
		else
			begin	
				if (select defaultvalue from ProductSettings where ID = @ID) != @DefaultValue
				begin
					--update the defaultvalues for any entries
					update ProductSettings set ValueText = @DefaultValue where ValueText = DefaultValue and KeyName = @KeyName;
					update ProductSettings set DefaultValue = @DefaultValue where KeyName = @KeyName;
				end
		
				--and update everything else
				UPDATE ProductSettings SET
					productid = @ProductID, 
					LastUser = @LastUser,
					KeyName = @KeyName,
					ValueText = @ValueText
				WHERE ID = @ID
			END
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
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispProductSettingsSelectListForProduct]'
GO
ALTER PROCEDURE [dbo].[remispProductSettingsSelectListForProduct]
/*	'===============================================================
'   NAME:                	remispProductSettingsSelectList
'   DATE CREATED:       	4 Nov 2011
'   CREATED BY:          	Darragh O'Riordan
'   FUNCTION:            	Retrieves data from table: ProductSettings 
'   VERSION: 1           
'   COMMENTS:            
'   MODIFIED ON:         
'   MODIFIED BY:         
'   REASON MODIFICATION: 
	'===============================================================*/
	@productID INT		
AS 
select keyVals.keyname,
	case when keyVals.valueText is not null then keyVals.valueText 
	else keyVals.defaultValue 
	end as valuetext, 
	keyVals.defaultvalue
from
	(
		select distinct ps1.keyName as keyname, ps2.ValueText, ps1.DefaultValue
		FROM ProductSettings as ps1
			left outer join ProductSettings as ps2 on ps1.KeyName = ps2.KeyName and ps2.ProductID = @productID
	) as keyVals
order by keyname 
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispProductSettingsSelectSingleValue]'
GO
ALTER PROCEDURE [dbo].[remispProductSettingsSelectSingleValue]
/*	'===============================================================
'   NAME:                	remispProductSettingsSelectSingleValue
'   DATE CREATED:       	4 Nov 2011
'   CREATED BY:          	Darragh O'Riordan
'   FUNCTION:            	Retrieves data from table: ProductSettings 
'   VERSION: 1           
'   COMMENTS:            
'   MODIFIED ON:         
'   MODIFIED BY:         
'   REASON MODIFICATION: 
	'===============================================================*/
	@ProductID INT,
	@keyname as nvarchar(MAX)
AS
declare @valueText nvarchar(MAX);
declare @defaultValue nvarchar(MAX);
	
set @valuetext = (select ValueText FROM ProductSettings as ps where ps.ProductID = @ProductID and KeyName = @keyname)
set @defaultValue =(select top (1) DefaultValue FROM ProductSettings as ps where KeyName = @keyname and DefaultValue is not null)
select case when @valueText is not null then @valueText else @defaultValue end as [ValueText];
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesSelectDailyList]'
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectDailyList]
	@StartRowIndex int = -1,
	@MaximumRows int = -1,
	@RecordCount int = NULL OUTPUT,
	@ProductID INT = null,
	@sortExpression varchar(100) = null,
	@GetBatchesAtEnvStages int = 1,
	@direction varchar(100) = 'desc',
	@TestCenterLocation as nvarchar(255)= null,
	@GetOperationsTests as bit = 0,
	@GetTechnicalOperationsTests as bit = 1,
	@TestStageCompletion as int = null
AS


	IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (select COUNT(*) from (SELECT distinct b.* FROM Batches as b, TestStages as ts, TestUnits as tu, Jobs as j, Products p where 
			( ts.TestStageName = b.TestStageName) 
			and tu.BatchID = b.id
			and ts.JobID = j.id
			and j.JobName = b.JobName
			and ((j.OperationsTest = @getoperationstests and @GetOperationsTests = 1)
			or (j.TechnicalOperationsTest = @GetTechnicalOperationsTests and @GetTechnicalOperationsTests = 1 ))
			and ((b.batchstatus=2 or b.BatchStatus = 4) and (ts.TestStageType =  @GetBatchesAtEnvStages))
			and (@ProductID is null or p.ID = @ProductID)
			and ((@TestStageCompletion is null or b.TestStageCompletionStatus = @TestStageCompletion)
			or  (@TestStageCompletion = 2 and (b.TestStageCompletionStatus = 2 or b.TestStageCompletionStatus = 3)))
			and (@TestCenterLocation is null or TestCenterLocation = @TestCenterLocation)) as batchcount)
		RETURN
	END
	
	SELECT BatchesRows.Row, BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,
		BatchesRows.JobName,BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,batchesrows.ProductType,batchesrows.AccessoryGroupName, BatchesRows.ProductID ,BatchesRows.QRANumber,
		BatchesRows.RequestPurpose,BatchesRows.TestCenterLocation,BatchesRows.TestStageName, BatchesRows.RFBands, BatchesRows.TestStageCompletionStatus,
		(select count(*) from testunits where testunits.batchid = BatchesRows.id) as testUnitCount,
		(CASE WHEN BatchesRows.WILocation IS NULL THEN NULL ELSE BatchesRows.WILocation END) AS jobWILocation,
		testunitcount,(testunitcount -
						(select COUNT(*) 
						from TestUnits as tu
						INNER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
						where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
					   ) as HasUnitsToReturnToRequestor,
		(select AssignedTo 
		from TaskAssignments as ta
		--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
		INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
		--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
		INNER JOIN Jobs j ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
		where ta.BatchID = BatchesRows.ID and ta.Active=1  ) as ActiveTaskAssignee
	FROM
		(
			SELECT ROW_NUMBER() OVER 
			(
				ORDER BY 
				case when @sortExpression='qra' and @direction='asc' then qranumber end,
				case when @sortExpression='qra' and @direction='desc' then qranumber end desc,
				case when @sortExpression='teststage' and @direction='asc' then b.teststagename end,
				case when @sortExpression='teststage' and @direction='desc' then b.teststagename end desc,
				case when @sortExpression='purpose' and @direction='asc' then requestpurpose end,
				case when @sortExpression='purpose' and @direction='desc' then requestpurpose end desc,
				case when @sortExpression='job' and @direction='asc' then jobname end,
				case when @sortExpression='job' and @direction='desc' then jobname end desc,
				case when @sortExpression='productgroup' and @direction='asc' then productgroupname end asc,
				case when @sortExpression='productgroup' and @direction='desc' then productgroupname end desc,
				case when @sortExpression='priority' and @direction='asc' then Priority end asc,
				case when @sortExpression='priority' and @direction='desc' then Priority end desc,
				case when @sortExpression='batchstatus' and @direction='asc' then batchstatus end,
				case when @sortExpression='batchstatus' and @direction='desc' then batchstatus end desc,
				case when @sortExpression='testcenter' and @direction='asc' then testcenterlocation end,
				case when @sortExpression='testcenter' and @direction='desc' then testcenterlocation end desc,
				case when @sortExpression is null then (cast(priority as varchar(10)) + qranumber) end desc
			) AS Row, 
			b.ID,
			b.QRANumber, 
			b.Priority, 
			b.TestStageName,
			b.BatchStatus, 
			b.ProductGroupName,
			b.ProductType,
			b.AccessoryGroupName,
			b.ProductID As ProductID,
			b.Jobname,
			b.LastUser,
			b.ConcurrencyID,
			b.Comment,
			b.TestCenterLocation,
			b.RequestPurpose,
			b.WILocation,
			(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = b.ProductGroupName)  end) as rfBands,
			b.TestStageCompletionStatus,
			(select COUNT (*) from TestUnits as tu where tu.id = b.ID) as testunitcount
			FROM
			(
				select distinct b.* ,p.ProductGroupName,j.WILocation
				from Batches as b--, TestStages as ts, TestUnits as tu, Jobs j--, Products p
					LEFT OUTER join TestStages ts ON ts.TestStageName = b.TestStageName and ts.TestStageType =  @GetBatchesAtEnvStages
					LEFT OUTER join TestUnits tu ON tu.BatchID = b.ID
					LEFT OUTER JOIN Products p ON p.ID = b.ProductID
					LEFT OUTER join Jobs j ON j.JobName =b.JobName and ts.JobID = j.ID
				WHERE --(ts.TestStageName = b.TestStageName) and (tu.BatchID = b.ID)	and (j.JobName =b.JobName )
				(
					(j.OperationsTest = @getoperationstests and @GetOperationsTests = 1)
					or
					(j.TechnicalOperationsTest = @GetTechnicalOperationsTests and @GetTechnicalOperationsTests = 1)
				)
				--and ts.JobID = j.ID
				--modified above to stop recieved batches (status=4) appearing in daily list				
				--and (ts.TestStageType =  @GetBatchesAtEnvStages)
				and 
				(b.batchstatus=2)
				and (@ProductID is null or p.ID = @ProductID)
				and 
				(
					(@TestStageCompletion is null or b.TestStageCompletionStatus = @TestStageCompletion)
					or
					(@TestStageCompletion = 2 and (b.TestStageCompletionStatus = 2 or b.TestStageCompletionStatus = 3))
				)
				and (@TestCenterLocation is null or TestCenterLocation = @TestCenterLocation)
			) as b
		) AS BatchesRows 
	--LEFT OUTER JOIN Jobs j ON j.JobName = BatchesRows.JobName
	WHERE
		(
			(Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) 
			OR 
			@startRowIndex = -1 OR @maximumRows = -1
		) order by row		
GO
GRANT EXECUTE ON remispBatchesSelectDailyList TO Remi	
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispProductSettingsDeleteSetting]'
GO
ALTER PROCEDURE [dbo].[remispProductSettingsDeleteSetting]
/*	'===============================================================
'   NAME:                	remispProductSettingsDeleteSetting
'   DATE CREATED:       	4 Nov 2011
'   CREATED BY:          	Darragh O'Riordan
'   FUNCTION:            	Deletes an entry from table: ProductSettings 
'   VERSION: 1           
'   COMMENTS:            
'   MODIFIED ON:         
'   MODIFIED BY:         
'   REASON MODIFICATION: 
	'===============================================================*/
	@ProductID INT,
	@keyname as nvarchar(MAX),
	@userName as nvarchar(255)
AS 
	
declare @id int =(select ProductSettings.id from ProductSettings where ProductID = @ProductID and KeyName = @keyname)

if (@id is not null)
begin
	update ProductSettings set LastUser = @userName where ID = @id;
	Delete FROM ProductSettings where ID = @id;
end
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesSearchList]'
GO
ALTER PROCEDURE [dbo].[remispBatchesSearchList]
/*	'===============================================================
	'   NAME:                	remispBatchesSearchList
	'   DATE CREATED:       	12 May 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves data from table: Batches based on search criteria
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/
	@ID int = Null,
	@Status int = null,
	@QRANumber nvarchar(11) = null,
	@ProductGroupName varchar(800) = null,
	@StartRowIndex int = null,
	@MaximumRows int = null,
	@RecordCount int = null OUTPUT
AS
	IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (SELECT COUNT(*) FROM Batches inner join Products p on p.ID=Batches.ProductID WHERE 		
		(Batches.ID = @ID or @ID is null) AND
		(BatchStatus = @Status or @Status is null) AND
		(QRANumber LIKE '%' + @QRANumber + '%' OR @QRANumber IS NULL)
		AND (p.ProductGroupName = @ProductGroupName OR @ProductGroupName IS NULL))
		RETURN
	END
	
	SELECT BatchesRows.row,BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,BatchesRows.JobName,
		BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,batchesrows.ProductType,batchesrows.AccessoryGroupName,batchesrows.ProductID, BatchesRows.QRANumber,BatchesRows.RequestPurpose,
		BatchesRows.TestCenterLocation,BatchesRows.TestStageName,BatchesRows.RFBands, BatchesRows.TestStageCompletionStatus, testUnitCount, 
		(CASE WHEN BatchesRows.WILocation IS NULL THEN NULL ELSE BatchesRows.WILocation END) AS jobWILocation,
		(testunitcount -
			(select COUNT(*) 
			from TestUnits as tu
			INNER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
		) as HasUnitsToReturnToRequestor,
		(select AssignedTo 
		from TaskAssignments as ta
			--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
			INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
			--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
			INNER JOIN Jobs j ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
		where ta.BatchID = BatchesRows.ID and ta.Active=1) as ActiveTaskAssignee,
		CONVERT(BIT,0) AS HasBatchSpecificExceptions
	FROM     
		(
			SELECT ROW_NUMBER() OVER (ORDER BY b.ID) AS Row, 
				b.BatchStatus,b.Comment,(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
				b.teststagecompletionstatus,b.ConcurrencyID,b.ID,b.JobName,b.LastUser,b.Priority,b.ProductType,b.AccessoryGroupName,p.ID As ProductID,
				p.ProductGroupName,b.QRANumber,b.RequestPurpose,b.TestCenterLocation,b.TestStageName,j.WILocation,
				(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount
			FROM Batches as b
				inner join Products p on b.ProductID=p.id 
				LEFT OUTER JOIN Jobs j ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
			WHERE (b.ID = @ID or @ID is null) AND (BatchStatus = @Status or @Status is null) 
				AND (QRANumber LIKE '%' + @QRANumber + '%' OR @QRANumber IS NULL)
				AND (p.ProductGroupName = @ProductGroupName OR @ProductGroupName IS NULL)
		)AS BatchesRows		
	WHERE (Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) OR @startRowIndex is null OR @maximumRows is null
	RETURN
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesInsertUpdateSingleItem]'
GO
ALTER PROCEDURE [dbo].[remispBatchesInsertUpdateSingleItem]
/*	'===============================================================
	'   NAME:                	remispBatchesInsertUpdateSingleItem
	'   DATE CREATED:       	9 April 2009
	'   CREATED BY:          	Darragh O Riordan
	'   FUNCTION:            	Creates or updates an item in a table: BatchTestStageSchedules
	'===============================================================*/
	@ID int OUTPUT,
	@QRANumber nvarchar(11),
	@Priority int, 
	@BatchStatus int, 
	@JobName nvarchar(400),
	@TestStageName nvarchar(255)=null,
	@ProductGroupName nvarchar(800),
	@ProductType nvarchar(800),
	@AccessoryGroupName nvarchar(800) = null,
	@Comment nvarchar(1000) = null,
	@TestCenterLocation nvarchar(400),
	@RequestPurpose int,
	@LastUser nvarchar(255),
	@ConcurrencyID rowversion OUTPUT,
	@rfBands nvarchar(400) = null,
	@testStageCompletionStatus int = null,
	@requestor nvarchar(500) = null,
	@unitsToBeReturnedToRequestor bit = null,
	@expectedSampleSize int = null,
	@relabJobID int = null,
	@reportApprovedDate datetime = null,
	@reportRequiredBy datetime = null,
	@rqID int = null,
	@partName nvarchar(500) = null,
	@assemblyNumber nvarchar(500) = null,
	@assemblyRevision nvarchar(500) = null,
	@trsStatus nvarchar(500) = null,
	@cprNumber nvarchar(500) = null,
	@hwRevision nvarchar(500) = null,
	@pmNotes nvarchar(500) = null
	AS
	DECLARE @ProductID INT
	DECLARE @ReturnValue int
	
	IF NOT EXISTS (SELECT 1 FROM Products WHERE LTRIM(RTRIM(ProductGroupName))= LTRIM(RTRIM(@ProductGroupName)))
	BEGIn
		INSERT INTO Products (ProductGroupName) Values (LTRIM(RTRIM(@ProductGroupName)))
	END 

	SELECT @ProductID = ID FROM Products WHERE LTRIM(RTRIM(ProductGroupName))= LTRIM(RTRIM(@ProductGroupName))
	
	--set the rfbands from the productgroup if they are not given
	if @rfBands is null
	set @rfbands = (select RFBands from RFBands where RFBands.ProductGroupName = @ProductGroupName)
	
	IF (@ID IS NULL)
	BEGIN
		INSERT INTO Batches(
		QRANumber, 
		Priority, 
		BatchStatus, 
		JobName,
		TestStageName,
		--ProductGroupName, 
		ProductType,
		AccessoryGroupName,
		TestCenterLocation,
		RequestPurpose,
		Comment,
		LastUser,
		rfbands,
		TestStageCompletionStatus,
		Requestor,
		unitsToBeReturnedToRequestor,
		expectedSampleSize,
		relabJobID,
		reportApprovedDate,
		reportRequiredBy,
		rqID,
		partName,
		assemblyNumber,
		assemblyRevision,
		trsStatus,
		cprNumber,
		hwRevision,
		pmNotes,
		ProductID ) 
		VALUES 
		(@QRANumber, 
		@Priority, 
		@BatchStatus, 
		@JobName,
		@TestStageName,
		--@ProductGroupName, 
		@ProductType,
		@AccessoryGroupName,
		@TestCenterLocation,
		@RequestPurpose,
		@Comment,
		@LastUser,
		@rfBands,
		@testStageCompletionStatus,
		@Requestor,
		@unitsToBeReturnedToRequestor,
		@expectedSampleSize,
		@relabJobID,
		@reportApprovedDate,
		@reportRequiredBy,
		@rqID,
		@partName,
		@assemblyNumber,
		@assemblyRevision,
		@trsStatus,
		@cprNumber,
		@hwRevision,
		@pmNotes,
		@ProductID )

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE -- Exisiting Item
	BEGIN
		UPDATE Batches SET 
		QRANumber = @QRANumber, 
		Priority = @Priority, 
		Jobname = @Jobname, 
		TestStagename = @TestStagename, 
		BatchStatus = @BatchStatus, 
		--ProductGroupName = @ProductGroupName, 
		ProductType = @ProductType,
		AccessoryGroupName = @AccessoryGroupName,
		TestCenterLocation=@TestCenterLocation,
		RequestPurpose=@RequestPurpose,
		Comment = @Comment, 
		LastUser = @LastUser,
		rfbands = @rfBands,
		Requestor = @Requestor,
		TestStageCompletionStatus = @testStageCompletionStatus,
		unitsToBeReturnedToRequestor=@unitsToBeReturnedToRequestor,
		expectedSampleSize=@expectedSampleSize,
		relabJobID=@relabJobID,
		reportApprovedDate=@reportApprovedDate,
		reportRequiredBy=@reportRequiredBy,
		rqID=@rqID,
		partName=@partName,
		assemblyNumber=@assemblyNumber,
		assemblyRevision=@assemblyRevision,
		trsStatus=@trsStatus,
		cprNumber=@cprNumber,
		hwRevision=@hwRevision,
		pmNotes=@pmNotes ,
		ProductID=@ProductID
		WHERE (ID = @ID) AND (ConcurrencyID = @ConcurrencyID)

		SELECT @ReturnValue = @ID
	END

	SET @ConcurrencyID = (SELECT ConcurrencyID FROM Batches WHERE ID = @ReturnValue)
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
PRINT N'Altering [dbo].[remispTestExceptionsGetBatchOnlyExceptions]'
GO
ALTER procedure [dbo].[remispTestExceptionsGetBatchOnlyExceptions] @qraNumber nvarchar(11) = null
AS
(select distinct pvt.id, null as batchunitnumber, pvt.ReasonForRequest,pvt.ProductGroupName,b.JobName, ts.teststagename
, t.testname, (SELECT TOP 1 LastUser FROM TestExceptions WHERE ID=pvt.ID) AS LastUser,
(SELECT TOP 1 ConcurrencyID FROM TestExceptions WHERE ID=pvt.ID) AS ConcurrencyID, pvt.TestStageID, pvt.TestUnitID ,
pvt.ProductType, pvt.AccessoryGroupName, p.ID AS ProductID
FROM vw_ExceptionsPivoted as pvt
	LEFT OUTER JOIN Tests t ON (pvt.Test = t.ID OR pvt.Test = t.TestName)
	LEFT OUTER JOIN Products p ON p.ProductGroupName=pvt.ProductGroupName
	, Batches as b, teststages as ts, Jobs as j 
where b.QRANumber = @qranumber 
and pvt.TestUnitID is null
and (ts.id = pvt.teststageid or pvt.TestStageID is null)
and (ts.JobID = j.ID or j.ID is null)
and (b.JobName = j.JobName or j.JobName is null)
and (
(pvt.ProductGroupName is null and pvt.ReasonForRequest = b.RequestPurpose)
or 
(pvt.ProductGroupName is null and pvt.ReasonForRequest is null)))

union all

--get any for the test units.
(select distinct pvt.id, tu.BatchUnitNumber, pvt.ReasonForRequest, pvt.ProductGroupName,b.JobName, 
(select teststagename from teststages where teststages.id =pvt.TestStageid) as teststagename, t.testname,
(SELECT TOP 1 LastUser FROM TestExceptions WHERE ID=pvt.ID) AS LastUser,
(SELECT TOP 1 ConcurrencyID FROM TestExceptions WHERE ID=pvt.ID) AS ConcurrencyID, 
pvt.TestStageID, pvt.TestUnitID,pvt.ProductType, pvt.AccessoryGroupName, p.ID AS ProductID
FROM vw_ExceptionsPivoted as pvt
	LEFT OUTER JOIN Tests t ON (pvt.Test = t.ID OR pvt.Test = t.TestName)
	LEFT OUTER JOIN Products p ON p.ProductGroupName=pvt.ProductGroupName
	, Batches as b, testunits tu
where b.QRANumber = @qranumber and tu.batchid = b.id and pvt.TestUnitID = tu.id)
order by TestName
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestExceptionsGetProductGroupTable]'
GO
ALTER PROCEDURE [dbo].[remispTestExceptionsGetProductGroupTable]
/*	'===============================================================
'   NAME:                	remispTestExceptionsGetProductGroupTable
'   DATE CREATED:       	09 Oct 2009
'   CREATED BY:          	Darragh O'Riordan
'   FUNCTION:            	Retrieves a list of test names / boolean
'   VERSION: 1           
'   COMMENTS:            
'   MODIFIED ON:         
'   MODIFIED BY:         
'   REASON MODIFICATION: 
'===============================================================*/
	@ProductID INT
AS
	declare @testUnitExemptions table (exTestName nvarchar(255), ExceptionID int)
	DECLARE @ProductGroupName NVARCHAR(800)
	SELECT @ProductGroupName = ProductGroupName FROM Products WHERE ID=@ProductID
	
	insert into @testunitexemptions
	SELECT TestName, pvt.ID
	FROM vw_ExceptionsPivoted as pvt
		INNER JOIN Tests t ON (pvt.Test = t.ID OR pvt.Test = t.TestName)
	where [ProductGroupName]=@ProductGroupName AND [TestStageID] IS NULL AND [Test] IS NOT NULL
	
	SELECT TestName AS Name, (CASE WHEN (SELECT TOP 1 ExceptionID FROM @testUnitExemptions WHERE exTestName = t.TestName) IS NOT NULL THEN 'True' ELSE 'False' END ) AS TestUnitException
	FROM Tests t
	WHERE t.TestType = 1
	ORDER BY TestName
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesGetActiveBatches]'
GO
ALTER PROCEDURE [dbo].[remispBatchesGetActiveBatches]
/*	'===============================================================
	'   NAME:                	remispBatchesGetActiveBatches
	'   DATE CREATED:       	10 Jun 2010
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves active batches from table: Batches 
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION:	remove hardcode string comparison and moved to ID
	'===============================================================*/
	@StartRowIndex int = null,
	@MaximumRows int = null,
	@RecordCount int = null OUTPUT
AS
	IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (SELECT COUNT(*) FROM Batches WHERE BatchStatus NOT IN(5,7))	
		RETURN
	END
	
	SELECT BatchesRows.row,BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,BatchesRows.JobName,
		BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,BatchesRows.QRANumber,BatchesRows.RequestPurpose,batchesrows.ProductType, batchesrows.AccessoryGroupName,
		batchesrows.ProductID,
		BatchesRows.TestCenterLocation,BatchesRows.TestStageName,BatchesRows.RFBands, BatchesRows.TestStageCompletionStatus, 
		batchesrows.testUnitCount,
		(CASE WHEN BatchesRows.WILocation IS NULL THEN NULL ELSE BatchesRows.WILocation END) AS jobWILocation,
		(
			testunitcount -
			(select COUNT(*) 
			from TestUnits as tu
				INNER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
		) as HasUnitsToReturnToRequestor,
		(
			select AssignedTo 
			from TaskAssignments as ta
				--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
				INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
				--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
				INNER JOIN Jobs j ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
			where ta.BatchID = BatchesRows.ID and ta.Active=1
		) as ActiveTaskAssignee,
		CONVERT(BIT, 0) AS HasBatchSpecificExceptions
	FROM     
		(
			SELECT ROW_NUMBER() OVER (ORDER BY b.ID) AS Row, 
			b.BatchStatus,b.Comment,(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
			b.teststagecompletionstatus,b.ConcurrencyID,b.ID,b.JobName,b.LastUser,b.Priority,p.ProductGroupName,b.ProductType,b.AccessoryGroupName,p.ID as ProductID,b.QRANumber,
			b.RequestPurpose,b.TestCenterLocation,b.TestStageName, j.WILocation,
			(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount
			FROM Batches as b
				inner join Products p on p.ID=b.ProductID
				LEFT OUTER JOIN Jobs j ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs
			WHERE BatchStatus NOT IN(5,7)
		) AS BatchesRows
	WHERE (Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) OR @startRowIndex is null OR @maximumRows is null
	ORDER BY BatchesRows.QRANumber
	RETURN
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesSelectByQRANumber]'
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectByQRANumber]
/*	'===============================================================
	'   NAME:                	remispBatchesSelectByQRANumber
	'   DATE CREATED:       	15 jun 2010
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves data from table: Batches based on qranumber
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION:	More efficient
	'===============================================================*/

	@QRANumber nvarchar(11) = null,
	@RecordCount int = null OUTPUT
AS
	IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (SELECT COUNT(*) FROM Batches WHERE 		
		
		QRANumber = @QRANumber)
		
		RETURN
	END
	declare @batchid int = (select id from Batches where QRANumber = @QRANumber);
	declare @testunitcount int = (select count(*) from testunits as tu where tu.batchid = @batchid)
	
	SELECT BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,BatchesRows.JobName,
BatchesRows.LastUser,BatchesRows.Priority,p.ProductGroupName,BatchesRows.QRANumber,BatchesRows.RequestPurpose,batchesrows.ProductType,batchesrows.AccessoryGroupName,
batchesrows.ProductID,
BatchesRows.TestCenterLocation,BatchesRows.TestStageName,
(case when batchesrows.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
BatchesRows.TestStageCompletionStatus, @testunitcount as testUnitCount,
(CASE WHEN j.WILocation IS NULL THEN NULL ELSE j.WILocation END) AS jobWILocation,
	(@testunitcount -
			  -- TrackingLocations was only used because we were testing based on string comparison and this isn't needed anymore because we are basing on ID which DeviceTrackingLog can be used.
              (select COUNT(*) 
			  from TestUnits as tu
			  INNER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			  where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
	) as HasUnitsToReturnToRequestor,	 
	(select AssignedTo 
	from TaskAssignments as ta
		--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
		INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
		--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
		INNER JOIN Jobs j ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
	where ta.BatchID = BatchesRows.ID and ta.Active=1  ) as ActiveTaskAssignee
	,BatchesRows.CPRNumber, BatchesRows.ProductType,
	(
		SELECT TOP 1 CONVERT(BIT, 1) FROM TestExceptions WHERE LookupID=3 AND Value IN (SELECT ID FROM TestUnits WHERE BatchID=BatchesRows.ID)
    ) AS HasBatchSpecificExceptions
	from Batches as BatchesRows
		LEFT OUTER JOIN Jobs j ON j.JobName = BatchesRows.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
		INNER JOIN Products p ON BatchesRows.productID=p.ID
	WHERE QRANumber = @QRANumber

select bc.DateAdded, bc.ID, bc.[Text], bc.LastUser from BatchComments as bc where BatchID = @batchid and Active = 1 order by DateAdded desc;
	RETURN
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesSelectInMechanicalTestBatches]'
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectInMechanicalTestBatches]
/*	'===============================================================
	'   NAME:                	remispBatchesSelectInMechanicalTestBatches
	'   DATE CREATED:       	08 Aug 2010
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retreives the batches in mechanical tests
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/
	@StartRowIndex int = -1,
	@MaximumRows int = -1,
	@TestCentreLocation nvarchar(200) =null,
	@RecordCount int = NULL OUTPUT,
	@sortExpression varchar(100) = null,
	@direction varchar(100) = 'asc'
AS
SELECT
						 BatchesRows.Row, BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,
				 BatchesRows.JobName,BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,BatchesRows.QRANumber,
				 BatchesRows.RequestPurpose,BatchesRows.TestCenterLocation,BatchesRows.TestStageName, BatchesRows.ProductType,batchesrows.AccessoryGroupName,batchesrows.ProductID,
				 batchesrows.RFBands, batchesrows.TestStageCompletionStatus,testunitcount, 
				(testunitcount -
				   (select COUNT(*) 
				  from TestUnits as tu
				  INNER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
				  where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
			  ) as HasUnitsToReturnToRequestor,
   (CASE WHEN batchesrows.WILocation IS NULL THEN NULL ELSE batchesrows.WILocation END) AS jobWILocation,
	 (select AssignedTo 
	from TaskAssignments as ta
		--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
		INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
		--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
		INNER JOIN Jobs j ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
	where ta.BatchID = BatchesRows.ID and ta.Active=1  ) as ActiveTaskAssignee, CONVERT(BIT,0) AS HasBatchSpecificExceptions
	FROM     
		(SELECT ROW_NUMBER() OVER (ORDER BY 
case when @sortExpression='qra' and @direction='asc' then qranumber end,
case when @sortExpression='qra' and @direction='desc' then qranumber end desc,
case when @sortExpression='teststage' and @direction='asc' then b.teststagename end,
case when @sortExpression='teststage' and @direction='desc' then b.teststagename end desc,
case when @sortExpression='purpose' and @direction='asc' then requestpurpose end,
case when @sortExpression='purpose' and @direction='desc' then requestpurpose end desc,
case when @sortExpression='job' and @direction='asc' then jobname end,
case when @sortExpression='job' and @direction='desc' then jobname end desc,
case when @sortExpression='productgroup' and @direction='asc' then productgroupname end asc,
case when @sortExpression='productgroup' and @direction='desc' then productgroupname end desc,
case when @sortExpression='priority' and @direction='asc' then Priority end asc,
case when @sortExpression='priority' and @direction='desc' then Priority end desc,
case when @sortExpression='batchstatus' and @direction='asc' then batchstatus end,
case when @sortExpression='batchstatus' and @direction='desc' then batchstatus end desc,
case when @sortExpression is null then Priority end desc
	
		
		) AS Row, 
		           ID, 
                      QRANumber, 
                      Comment,
                      RequestPurpose, 
                      Priority,
                      TestStageName, 
                      BatchStatus, 
                      ProductGroupName, 
					  ProductType,
					  AccessoryGroupName,
					  ProductID,
                      JobName, 
                      TestCenterLocation,
                      LastUser, 
                      ConcurrencyID,
                      b.RFBands,
                      b.TestStageCompletionStatus,
				 (select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
				 b.WILocation
                      from
(SELECT DISTINCT 
                      b.ID, 
                      b.QRANumber, 
                      b.Comment,
                      b.RequestPurpose, 
                      b.Priority,
                      b.TestStageName, 
                      b.BatchStatus, 
                      p.ProductGroupName, 
					  b.ProductType,
					  b.AccessoryGroupName,
					  p.ID As ProductID,
                      b.JobName, 
                      b.LastUser, 
                      b.TestCenterLocation,
                      b.ConcurrencyID,
                      (case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
                      b.TestStageCompletionStatus,
                      j.WILocation
FROM Batches AS b LEFT OUTER JOIN Jobs j ON j.JobName = b.JobName inner join
                      DeviceTrackingLog AS dtl INNER JOIN
                      TrackingLocations AS tl ON dtl.TrackingLocationID = tl.ID INNER JOIN
                   TrackingLocationTypes as tlt on tl.TrackingLocationTypeID = tlt.id inner join
                      TestUnits AS tu ON dtl.TestUnitID = tu.ID ON b.id = tu.batchid --batches where there's a tracking log
                      inner join Products p on p.ID=b.ProductID
WHERE   (b.TestCenterLocation = @TestCentreLocation or @TestCentreLocation is null) and j.TechnicalOperationsTest = 1 and j.MechanicalTest=1 and  tlt.TrackingLocationFunction= 4  AND dtl.OutTime IS NULL AND dtl.OutUser IS NULL)as b) as batchesrows
WHERE ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) OR @startRowIndex = -1 OR @maximumRows = -1) 
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesSelectTestingCompleteBatches]'
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectTestingCompleteBatches]
	@StartRowIndex int = -1,
	@MaximumRows int = -1,
	@TestCentreLocation nvarchar(200) =null,
	@RecordCount int = NULL OUTPUT,
	@sortExpression varchar(100) = null,
	@direction varchar(100) = 'desc'
AS
DECLARE @comments NVARCHAR(max) 
SELECT BatchesRows.Row, BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,
	BatchesRows.JobName,BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,BatchesRows.QRANumber,
	BatchesRows.RequestPurpose,BatchesRows.TestCenterLocation,BatchesRows.TestStageName, batchesrows.RFBands, 
	batchesrows.TestStageCompletionStatus,batchesrows.testUnitCount,BatchesRows.ProductType,batchesrows.AccessoryGroupName,BatchesRows.ProductID,
	batchesrows.HasUnitsToReturnToRequestor,
	batchesrows.jobWILocation
	,(select AssignedTo 
	from TaskAssignments as ta
		--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
		INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
		--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
		INNER JOIN Jobs j ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
	where ta.BatchID = BatchesRows.ID and ta.Active=1  ) as ActiveTaskAssignee,
	(select  bc.Text + '####' from BatchComments as bc 
	where bc.BatchID = batchesrows.ID and bc.Active = 1 for xml path('')) as BatchCommentsConcat, CONVERT(BIT,0) AS HasBatchSpecificExceptions
FROM
	(
		SELECT ROW_NUMBER() OVER 
			(
				ORDER BY 
				case when @sortExpression='qranumber' and @direction='asc' then qranumber end,
				case when @sortExpression='qranumber' and @direction='desc' then qranumber end desc,
				case when @sortExpression='teststage' and @direction='asc' then b.teststagename end,
				case when @sortExpression='teststage' and @direction='desc' then b.teststagename end desc,
				case when @sortExpression='purpose' and @direction='asc' then requestpurpose end,
				case when @sortExpression='purpose' and @direction='desc' then requestpurpose end desc,
				case when @sortExpression='job' and @direction='asc' then jobname end,
				case when @sortExpression='job' and @direction='desc' then jobname end desc,
				case when @sortExpression='productgroup' and @direction='asc' then productgroupname end asc,
				case when @sortExpression='productgroup' and @direction='desc' then productgroupname end desc,
				case when @sortExpression='priority' and @direction='asc' then Priority end asc,
				case when @sortExpression='priority' and @direction='desc' then Priority end desc,
				case when @sortExpression='batchstatus' and @direction='asc' then batchstatus end,
				case when @sortExpression='batchstatus' and @direction='desc' then batchstatus end desc,
				case when @sortExpression='HasUnitsToReturnToRequestor' and @direction='asc' then HasUnitsToReturnToRequestor end,
				case when @sortExpression='HasUnitsToReturnToRequestor' and @direction='desc' then HasUnitsToReturnToRequestor end desc,
				case when @sortExpression='jobwilocation' and @direction='asc' then jobWILocation end,
				case when @sortExpression='jobwilocation' and @direction='desc' then jobWILocation end desc,
				case when @sortExpression='testunitcount' and @direction='asc' then testUnitCount end,
				case when @sortExpression='testunitcount' and @direction='desc' then testUnitCount end desc,
				case when @sortExpression='comments' and @direction='asc' then comment end,
				case when @sortExpression='comments' and @direction='desc' then comment end desc,
				case when @sortExpression='testcenterlocation' and @direction='asc' then TestCenterLocation end,
				case when @sortExpression='testcenterlocation' and @direction='desc' then TestCenterLocation end desc,
				case when @sortExpression is null then qranumber end desc
			) AS Row, 
			ID, 
			QRANumber, 
			Comment,
			RequestPurpose, 
			Priority,
			TestStageName, 
			BatchStatus, 
			ProductGroupName, 
			ProductType,
			AccessoryGroupName,
			ProductID,
			JobName, 
			TestCenterLocation,
			LastUser, 
			ConcurrencyID,
			b.RFBands,
			b.TestStageCompletionStatus,
			b.testUnitCount,
			b.HasUnitsToReturnToRequestor,
			b.jobWILocation
		from
			(
				SELECT DISTINCT 
				b.ID, 
				b.QRANumber, 
				b.Comment,
				b.RequestPurpose, 
				b.Priority,
				b.TestStageName, 
				b.BatchStatus, 
				p.ProductGroupName, 
				p.ID As ProductID,
				b.ProductType,
				b.AccessoryGroupName,
				b.JobName, 
				b.LastUser, 
				b.TestCenterLocation,
				b.ConcurrencyID,
				(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
				b.TestStageCompletionStatus,
				(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
				(select Jobs.WILocation from Jobs where Jobs.JobName = b.jobname) as jobWILocation,
				(
					(select COUNT(*) from TestUnits as tu where tu.batchid = b.ID) -
					(
						select COUNT(*) 
						from TestUnits as tu, DeviceTrackingLog as dtl, TrackingLocations as tl 
						where dtl.TrackingLocationID = tl.ID and tu.BatchID = b.ID 
							and tl.ID = 81 and dtl.OutTime IS null and dtl.TestUnitID = tu.ID
					)
				) as HasUnitsToReturnToRequestor
				FROM Batches AS b
					INNER JOIN Products p ON b.ProductID=p.ID	
				WHERE (b.TestCenterLocation = @TestCentreLocation or @TestCentreLocation is null) and b.BatchStatus = 8
			)as b
	) as batchesrows
WHERE ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) 
OR @startRowIndex = -1 OR @maximumRows = -1) order by Row

GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesSelectHeldBatches]'
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectHeldBatches]
/*	'===============================================================
	'   NAME:                	remispBatchesSelectHeldBatches
	'   DATE CREATED:       	22 Sep 2010
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retreives the batches where status is held or quarantined
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/

	@StartRowIndex int = -1,
	@MaximumRows int = -1,
	@TestCentreLocation nvarchar(200) =null,
	@RecordCount int = NULL OUTPUT,
	@sortExpression varchar(100) = null,
	@direction varchar(100) = 'asc'
	AS
SELECT
						 BatchesRows.Row, BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,
				 BatchesRows.JobName,BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,BatchesRows.QRANumber,
				 BatchesRows.RequestPurpose,BatchesRows.TestCenterLocation,BatchesRows.TestStageName,batchesrows.ProductType, batchesrows.AccessoryGroupName,batchesrows.productID,
				 batchesrows.RFBands, batchesrows.TestStageCompletionStatus, testunitcount,
	(CASE WHEN batchesrows.WILocation IS NULL THEN NULL ELSE batchesrows.WILocation END) AS jobWILocation,			
(testunitcount -
		(select COUNT(*) 
		from TestUnits as tu
		INNER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
		where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
	) as HasUnitsToReturnToRequestor,
	(select AssignedTo 
	from TaskAssignments as ta
		--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
		INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
		--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
		INNER JOIN Jobs j ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
	where ta.BatchID = BatchesRows.ID and ta.Active=1  ) as ActiveTaskAssignee, CONVERT(BIT,0) AS HasBatchSpecificExceptions

	FROM     
		(SELECT ROW_NUMBER() OVER (ORDER BY 
case when @sortExpression='qra' and @direction='asc' then qranumber end,
case when @sortExpression='qra' and @direction='desc' then qranumber end desc,
case when @sortExpression='teststage' and @direction='asc' then b.teststagename end,
case when @sortExpression='teststage' and @direction='desc' then b.teststagename end desc,
case when @sortExpression='purpose' and @direction='asc' then requestpurpose end,
case when @sortExpression='purpose' and @direction='desc' then requestpurpose end desc,
case when @sortExpression='job' and @direction='asc' then jobname end,
case when @sortExpression='job' and @direction='desc' then jobname end desc,
case when @sortExpression='productgroup' and @direction='asc' then productgroupname end asc,
case when @sortExpression='productgroup' and @direction='desc' then productgroupname end desc,
case when @sortExpression='priority' and @direction='asc' then Priority end asc,
case when @sortExpression='priority' and @direction='desc' then Priority end desc,
case when @sortExpression='batchstatus' and @direction='asc' then batchstatus end,
case when @sortExpression='batchstatus' and @direction='desc' then batchstatus end desc,
case when @sortExpression is null then Priority end desc
		) AS Row, 
		           ID, 
                      QRANumber, 
                      Comment,
                      RequestPurpose, 
                      Priority,
                      TestStageName, 
                      BatchStatus, 
                      ProductGroupName, 
					  ProductType,
					  AccessoryGroupName,
					  productID,
                      JobName, 
                      TestCenterLocation,
                      LastUser, 
                      ConcurrencyID,
                      b.RFBands,
                      b.TestStageCompletionStatus ,
                      (select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
                      b.WILocation
                      from
(SELECT DISTINCT 
                      b.ID, 
                      b.QRANumber, 
                      b.Comment,
                      b.RequestPurpose, 
                      b.Priority,
                      b.TestStageName, 
                      b.BatchStatus, 
                      p.ProductGroupName,
					  b.ProductType, 
					  b.AccessoryGroupName,
					  p.ID As productID,
                      b.JobName, 
                      b.LastUser, 
                      b.TestCenterLocation,
                      b.ConcurrencyID,
                      (case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
                      b.TestStageCompletionStatus,
                      j.WILocation                      
FROM         Batches AS b
	 inner join Products p on b.ProductID=p.id
	 LEFT OUTER JOIN Jobs j ON j.JobName = b.JobName
WHERE   (b.TestCenterLocation = @TestCentreLocation or @TestCentreLocation is null) and (b.BatchStatus = 1 or b.BatchStatus = 3) )as b) as batchesrows
 	WHERE
	 ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) 
			OR @startRowIndex = -1 OR @maximumRows = -1) order by QRANumber desc

GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesSelectBackToRequestorBatches]'
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectBackToRequestorBatches]
/*	'===============================================================
	'   NAME:                	remispBatchesSelectBackToRequestorBatches
	'   DATE CREATED:       	07 Oct 2010
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retreives the batches where testing is complete and the batch is due to go back tot he requestor but has not been sent.
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/

	@StartRowIndex int = -1,
	@MaximumRows int = -1,
	@TestCentreLocation nvarchar(200) =null,
	@RecordCount int = NULL OUTPUT,
	@sortExpression varchar(100) = null,
	@direction varchar(100) = 'asc'
AS
SELECT BatchesRows.Row, BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,
	BatchesRows.JobName,BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,BatchesRows.QRANumber,
	BatchesRows.RequestPurpose,BatchesRows.TestCenterLocation,BatchesRows.TestStageName,batchesrows.ProductType, batchesrows.AccessoryGroupName,
	batchesrows.RFBands, batchesrows.TestStageCompletionStatus, testUnitCount,jobwilocation, 
	(
		testunitcount -
		(select COUNT(*) 
		from TestUnits as tu
			INNER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
		where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
	) as HasUnitsToReturnToRequestor,
	(select AssignedTo 
	from TaskAssignments as ta
		--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
		INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
		--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
		INNER JOIN Jobs j ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
	where ta.BatchID = BatchesRows.ID and ta.Active=1  ) as ActiveTaskAssignee
FROM     
(
	SELECT ROW_NUMBER() OVER 
		(
			ORDER BY 
				case when @sortExpression='qra' and @direction='asc' then qranumber end,
				case when @sortExpression='qra' and @direction='desc' then qranumber end desc,
				case when @sortExpression='teststage' and @direction='asc' then b.teststagename end,
				case when @sortExpression='teststage' and @direction='desc' then b.teststagename end desc,
				case when @sortExpression='purpose' and @direction='asc' then requestpurpose end,
				case when @sortExpression='purpose' and @direction='desc' then requestpurpose end desc,
				case when @sortExpression='job' and @direction='asc' then jobname end,
				case when @sortExpression='job' and @direction='desc' then jobname end desc,
				case when @sortExpression='productgroup' and @direction='asc' then productgroupname end asc,
				case when @sortExpression='productgroup' and @direction='desc' then productgroupname end desc,
				case when @sortExpression='priority' and @direction='asc' then Priority end asc,
				case when @sortExpression='priority' and @direction='desc' then Priority end desc,
				case when @sortExpression='batchstatus' and @direction='asc' then batchstatus end,
				case when @sortExpression='batchstatus' and @direction='desc' then batchstatus end desc,
				case when @sortExpression is null then Priority end desc
		) AS Row, 
		ID, 
		QRANumber, 
		Comment,
		RequestPurpose, 
		Priority,
		TestStageName, 
		BatchStatus, 
		ProductGroupName, 
		ProductType,
		AccessoryGroupName,
		JobName, 
		TestCenterLocation,
		LastUser, 
		ConcurrencyID,
		b.RFBands,
		b.TestStageCompletionStatus,
		(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
		(select Jobs.WILocation from Jobs where Jobs.JobName = b.jobname) as jobWILocation
	FROM
	(
		SELECT DISTINCT b.ID, 
			b.QRANumber, 
			b.Comment,
			b.RequestPurpose, 
			b.Priority,
			b.TestStageName, 
			b.BatchStatus, 
			p.ProductGroupName, 
			b.ProductType,
			b.AccessoryGroupName,
			b.JobName, 
			b.LastUser, 
			b.TestCenterLocation,
			b.ConcurrencyID,
			(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
			b.TestStageCompletionStatus
		FROM Batches AS b 
			INNER JOIN DeviceTrackingLog AS dtl
			INNER JOIN TrackingLocations AS tl ON dtl.TrackingLocationID = tl.ID
			INNER JOIN TestUnits AS tu ON dtl.TestUnitID = tu.ID ON b.id = tu.batchid --batches where there's a tracking log
			inner join Products p on p.ID=b.ProductID
		WHERE (tl.id != 81 AND dtl.OutTime IS NULL AND dtl.OutUser IS NULL) and b.BatchStatus = 8
	)as b
) as batchesrows	
WHERE ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) OR @startRowIndex = -1 OR @maximumRows = -1) 
order by QRANumber desc
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispInventoryReport]'
GO
ALTER procedure [dbo].[remispInventoryReport]
	@StartDate datetime,
	@EndDate datetime,
	@FilterBasedOnQraNumber bit,
	@geographicallocation nvarchar(500)
AS
declare @startYear int = Right(year( @StartDate), 2);
declare @endYear int = Right(year( @EndDate), 2);
declare @AverageTestUnitsPerBatch int = -1

declare @TotalBatches int = (select COUNT(*) from BatchesAudit  where 
 BatchesAudit.InsertTime >= @StartDate and BatchesAudit.InsertTime <= @EndDate and BatchesAudit.Action = 'I' 
 and (@FilterBasedOnQraNumber = 0 or (Convert(int , SUBSTRING(BatchesAudit.QRANumber, 5, 2)) >= @startYear
 and Convert(int , SUBSTRING(BatchesAudit.QRANumber, 5, 2)) <= @endYear))
 and (@geographicallocation = 'All Test Centers' or BatchesAudit.TestCenterLocation = @geographicallocation)
 );

declare @TotalTestUnits int =(select COUNT(*) as TotalTestUnits from TestUnitsAudit, batchesaudit  where 
 TestUnitsAudit.InsertTime >= @StartDate and TestUnitsAudit.InsertTime <= @EndDate and TestUnitsAudit.Action = 'I' 
 and BatchesAudit.InsertTime >= @StartDate and BatchesAudit.InsertTime <= @EndDate and BatchesAudit.Action = 'I' 
 and (@FilterBasedOnQraNumber = 0 or (Convert(int , SUBSTRING(batchesaudit.QRANumber, 5, 2)) >= @startYear
 and Convert(int , SUBSTRING(batchesaudit.QRANumber, 5, 2)) <= @endYear))
and TestUnitsAudit.BatchID = Batchesaudit.batchID 
and (@geographicallocation = 'All Test Centers' or batchesaudit.TestCenterLocation = @geographicallocation)
);

if @TotalBatches != 0
begin
 set @AverageTestUnitsPerBatch = @totaltestunits / @totalbatches;
end

select @TotalBatches as TotalBatches, @TotalTestUnits as TotalTestUnits, @AverageTestUnitsPerBatch as AverageUnitsPerBatch;

select products.ProductGroupName as ProductGroup, COUNT( distinct BatchesAudit.id) as TotalBatches,
COUNT(TestUnits.ID) as TotalTestUnits 
from BatchesAudit,testunits , Products 
where Products.ID=BatchesAudit.ProductID and 
BatchesAudit.InsertTime >= @StartDate and BatchesAudit.InsertTime <= @EndDate and BatchesAudit.Action = 'I' 
and (@FilterBasedOnQraNumber = 0 or (Convert(int , SUBSTRING(BatchesAudit.QRANumber, 5, 2)) >= @startYear
and Convert(int , SUBSTRING(BatchesAudit.QRANumber, 5, 2)) <= @endYear)) 
and (BatchesAudit.TestCenterLocation = @geographicallocation or @geographicallocation = 'All Test Centers')
and BatchesAudit.BatchID = TestUnits.BatchID 
group by productgroupname;
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispCountUnitsInLocation]'
GO
ALTER procedure [dbo].[remispCountUnitsInLocation]
@startDate datetime,
@endDate datetime,
@geoGraphicalLocation nvarchar(200),
@FilterBasedOnQraNumber bit,
@productGroupName nvarchar(500)
AS
declare @startYear int = Right(year( @StartDate), 2);
declare @endYear int = Right(year( @EndDate), 2);

select tl.TrackingLocationName, count(tu.id) as CountedUnits 
from TestUnits as tu, trackinglocations as tl, DeviceTrackingLog as dtl, Batches as b,Products p 
where tu.ID = dtl.TestUnitID and dtl.TrackingLocationID = tl.ID and dtl.OutUser is null and tu.BatchID = b.id
and dtl.InTime > @StartDate and dtl.InTime < @EndDate 
and (@FilterBasedOnQraNumber = 0 or (Convert(int , SUBSTRING(b.QRANumber, 5, 2)) >= @startYear
and Convert(int , SUBSTRING(b.QRANumber, 5, 2)) <= @endYear))
and (p.ProductGroupName = @productGroupName or @productGroupName = 'All Products')
and (b.TestCenterLocation = @geoGraphicalLocation or @geoGraphicalLocation ='All Test Centers') and p.ID=b.ProductID
group by TrackingLocationName 
union all
select 'Total', count(tu.id) as CountedUnits 
from TestUnits as tu, trackinglocations as tl, DeviceTrackingLog as dtl, Batches as b, Products p 
where tu.ID = dtl.TestUnitID and dtl.TrackingLocationID = tl.ID and dtl.OutUser is null and tu.BatchID = b.id
and dtl.InTime > @StartDate and dtl.InTime < @EndDate 
and (@FilterBasedOnQraNumber = 0 or (Convert(int , SUBSTRING(b.QRANumber, 5, 2)) >= @startYear
and Convert(int , SUBSTRING(b.QRANumber, 5, 2)) <= @endYear))
and (p.ProductGroupName = @productGroupName or @productGroupName = 'All Products')
and (b.TestCenterLocation  = @geoGraphicalLocation or @geoGraphicalLocation ='All Test Centers')
and p.ID=b.ProductID
order by TrackingLocationName asc
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesGetActiveBatchesByRequestor]'
GO
ALTER PROCEDURE [dbo].[remispBatchesGetActiveBatchesByRequestor]
/*	'===============================================================
	'   NAME:                	remispBatchesGetActiveBatchesByRequestor
	'   DATE CREATED:       	28 Feb 2011
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves active batches by requestor
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/
	@StartRowIndex int = null,
	@MaximumRows int = null,
	@RecordCount int = null OUTPUT,
	@Requestor nvarchar(500) = null
AS
	IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (SELECT COUNT(*) FROM Batches WHERE BatchStatus NOT IN(5,7) and Requestor = @Requestor	)	
		RETURN
	END

	SELECT BatchesRows.row,BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,BatchesRows.JobName,
		BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,batchesrows.ProductType,batchesrows.AccessoryGroupName, batchesrows.ProductID,
		BatchesRows.QRANumber,BatchesRows.RequestPurpose,
		BatchesRows.TestCenterLocation,BatchesRows.TestStageName,BatchesRows.RFBands, BatchesRows.TestStageCompletionStatus, 
		batchesrows.testUnitCount,
		(CASE WHEN batchesrows.WILocation IS NULL THEN NULL ELSE batchesrows.WILocation END) AS jobWILocation,
		(
			testunitcount -
			(select COUNT(*) 
			from TestUnits as tu
				INNER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
		) as HasUnitsToReturnToRequestor,
		(
			select AssignedTo 
			from TaskAssignments as ta
				--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
				INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
				--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
				INNER JOIN Jobs j ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
			where ta.BatchID = BatchesRows.ID and ta.Active=1
		) as ActiveTaskAssignee,
		CONVERT(BIT,0) AS HasBatchSpecificExceptions
	FROM     
		(
			SELECT ROW_NUMBER() OVER (ORDER BY b.ID) AS Row, 
				b.BatchStatus,b.Comment,(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
				b.teststagecompletionstatus,b.ConcurrencyID,b.ID,b.JobName,b.LastUser,b.Priority,p.ProductGroupName,b.ProductType, b.AccessoryGroupName,p.ID As ProductID,b.QRANumber,
				b.RequestPurpose,b.TestCenterLocation,b.TestStageName, j.WILocation,
				(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount
			FROM Batches as b
				inner join Products p on p.ID=b.ProductID
				LEFT OUTER JOIN Jobs j ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
			WHERE BatchStatus NOT IN(5,7) and Requestor = @Requestor
		) AS BatchesRows
WHERE (Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) OR @startRowIndex is null OR @maximumRows is null
order by BatchesRows.QRANumber
RETURN
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
select @ApplicableTestStages = @ApplicableTestStages + ', '  + TestStageName from TestStages where TestStages.JobID = @jobID order by ProcessOrder
set @ApplicableTestStages = SUBSTRING(@ApplicableTestStages,3,Len(@ApplicableTestStages))
--get applicable tests
select @ApplicableTests = @ApplicableTests + ', '  +  testname from Tests as t, TrackingLocationsForTests as tlft, TrackingLocationTypes as tlt , TrackingLocations as tl
where t.ID = tlft.TestID
and tlft.TrackingLocationtypeID = tlt.ID
and tlt.ID = tl.TrackingLocationTypeID
and tl.ID = @selectedTrackingLocationID

set @ApplicableTests = SUBSTRING(@ApplicableTests,3,Len(@ApplicableTests))

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
PRINT N'Altering [dbo].[remispProductManagersDeleteSingleItem]'
GO
ALTER PROCEDURE [dbo].[remispProductManagersDeleteSingleItem]
/*	'===============================================================
	'   NAME:                	remispProductManagersDeleteSingleItem
	'   DATE CREATED:       	11 Sept 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Deletes an item from table: UsersXProductGroups
	'   IN:        UserID of user, ProductGroupID of productGroup          
	'   OUT: 		Nothing         
	'   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
	@UserToRemove nvarchar(255),
	@ProductID INT,
	@UserName nvarchar(255)
AS
	update productmanagers 
	set lastuser = @username
	FROM productManagers
		INNER JOIN Products p ON ProductManagers.ProductID=p.ID
	WHERE p.ID = @ProductID and Username = @UserToRemove

	delete productmanagers
	from productmanagers
		INNER JOIN Products p ON ProductManagers.ProductID=p.ID
	WHERE p.ID = @ProductID and Username = @UserToRemove
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesActiveSelectByJob]'
GO
ALTER PROCEDURE [dbo].[remispBatchesActiveSelectByJob]
	@JobName NVARCHAR(400),
	@StartRowIndex int = -1,
	@MaximumRows int = -1,
	@RecordCount int = NULL OUTPUT,
	@sortExpression varchar(100) = null,
	@direction varchar(100) = 'asc'
AS
	IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (select  COUNT(*) 
							from 
							(
								select DISTINCT b.id
								FROM  Batches AS b 
								INNER JOIN DeviceTrackingLog AS dtl
								INNER JOIN TestUnits AS tu ON dtl.TestUnitID = tu.ID ON b.id = tu.BatchID --batches where there's a tracking log                      
								WHERE  b.BatchStatus NOT IN (5,8) AND b.Jobname=@JobName AND dtl.OutTime IS NULL AND dtl.OutUser IS NULL
							)as records)  --and the tracking log has not been 'scanned' out
		RETURN
	END
	SELECT BatchesRows.Row, BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,
		BatchesRows.JobName,BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,BatchesRows.QRANumber,
		BatchesRows.RequestPurpose,BatchesRows.TestCenterLocation,BatchesRows.TestStageName,batchesrows.ProductType, batchesrows.AccessoryGroupName,batchesrows.ProductID,
		batchesrows.RFBands, batchesrows.TestStageCompletionStatus,testunitcount,
		(
			testunitcount -
			(select COUNT(*) 
			from TestUnits as tu
				INNER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
		) as HasUnitsToReturnToRequestor,
		(CASE WHEN BatchesRows.WILocation IS NULL THEN NULL ELSE BatchesRows.WILocation END) AS jobWILocation,
		(
			select AssignedTo 
			from TaskAssignments as ta
				--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
				INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
				--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
				INNER JOIN Jobs j ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
			where ta.BatchID = BatchesRows.ID and ta.Active=1
		) as ActiveTaskAssignee, CONVERT(BIT,0) AS HasBatchSpecificExceptions
	FROM     
	(
		SELECT ROW_NUMBER() OVER 
			(ORDER BY 
				case when @sortExpression='qra' and @direction='asc' then qranumber end,
				case when @sortExpression='qra' and @direction='desc' then qranumber end desc,
				case when @sortExpression='teststage' and @direction='asc' then b.teststagename end,
				case when @sortExpression='teststage' and @direction='desc' then b.teststagename end desc,
				case when @sortExpression='purpose' and @direction='asc' then requestpurpose end,
				case when @sortExpression='purpose' and @direction='desc' then requestpurpose end desc,
				case when @sortExpression='job' and @direction='asc' then jobname end,
				case when @sortExpression='job' and @direction='desc' then jobname end desc,
				case when @sortExpression='productgroup' and @direction='asc' then productgroupname end asc,
				case when @sortExpression='productgroup' and @direction='desc' then productgroupname end desc,
				case when @sortExpression='priority' and @direction='asc' then Priority end asc,
				case when @sortExpression='priority' and @direction='desc' then Priority end desc,
				case when @sortExpression='batchstatus' and @direction='asc' then batchstatus end,
				case when @sortExpression='batchstatus' and @direction='desc' then batchstatus end desc,
				case when @sortExpression is null then Priority end desc		
			) AS Row, 
			ID, 
			QRANumber, 
			Comment,
			RequestPurpose, 
			Priority,
			TestStageName, 
			BatchStatus, 
			ProductGroupName, 
			ProductType,
			AccessoryGroupName,
			ProductID,
			JobName, 
			TestCenterLocation,
			LastUser, 
			ConcurrencyID,
			b.RFBands,
			b.TestStageCompletionStatus,
			(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
			b.WILocation
		FROM
		(
			SELECT DISTINCT b.ID, 
				b.QRANumber, 
				b.Comment,
				b.RequestPurpose, 
				b.Priority,
				b.TestStageName, 
				b.BatchStatus, 
				p.ProductGroupName, 
				b.ProductType,
				b.AccessoryGroupName,
				p.ID as ProductID,
				b.JobName, 
				b.LastUser, 
				b.TestCenterLocation,
				b.ConcurrencyID,
				(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
				b.TestStageCompletionStatus,
				j.WILocation
			FROM Batches AS b 
				INNER JOIN DeviceTrackingLog AS dtl 
				INNER JOIN TestUnits AS tu ON dtl.TestUnitID = tu.ID ON b.id = tu.batchid --batches where there's a tracking log
				inner join Products p on p.ID=b.ProductID
				LEFT OUTER JOIN Jobs j ON j.JobName = b.JobName
			WHERE b.BatchStatus NOT IN (5,8) AND b.Jobname=@JobName AND dtl.OutTime IS NULL AND dtl.OutUser IS NULL
		)as b
	) as batchesrows 	
	WHERE ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) OR @startRowIndex = -1 OR @maximumRows = -1) 
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispProductManagersAssignUser]'
GO
ALTER PROCEDURE [dbo].[remispProductManagersAssignUser]
/*	'===============================================================
	'   NAME:                	remispProductManagersAssignUser
	'   DATE CREATED:       	11 Sept 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Creates or updates an item in a table: product managers
	'   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
	@ProductID INT,
	@Username nvarchar(255),
	@LastUser nvarchar(255)	
AS
	DECLARE @ReturnValue int
	Declare @ID int

	SET @ID = (Select ID from Productmanagers where productID = @ProductID and UserName = @username)

	IF (@ID IS NULL) -- New Item
	BEGIN
		INSERT INTO Productmanagers (ProductID, Username, Lastuser)
		VALUES (@ProductID, @Username, @LastUser)

		SELECT @ReturnValue = SCOPE_IDENTITY()
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
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispProductManagersSelectList]'
GO
ALTER PROCEDURE [dbo].[remispProductManagersSelectList]
/*	'===============================================================
'   NAME:                	remispProductManagersSelectList
'   DATE CREATED:       	11 Sept 2009
'   CREATED BY:          	Darragh O'Riordan
'   FUNCTION:            	Retrieves  data from table: UsersXProductGroups OR the number of records in the table
'   IN:         Optional: RecordCount         
'   OUT: 		List Of:ProductGroup        
'   VERSION: 1           
'   COMMENTS:            
'   MODIFIED ON:         
'   MODIFIED BY:         
'   REASON MODIFICATION: 
'===============================================================*/
	@RecordCount int = NULL OUTPUT,
	@Username nvarchar(255)	
AS
	IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (SELECT COUNT(*) FROM  productmanagers AS uxpg	WHERE  uxpg.Username = @Username)
		RETURN
	END

	SELECT p.ProductGroupName, p.ID  
	FROM productmanagers AS uxpg
		INNER JOIN Products p ON p.ID=uxpg.ProductID
	WHERE uxpg.Username = @Username  order by p.ProductGroupName
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesByProductView]'
GO
ALTER PROCEDURE [dbo].[remispBatchesByProductView]
/*	'===============================================================
	'   NAME:                	remispBatchesByProductView
	'   DATE CREATED:       	19 April 2011
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retreives  batches given a  product
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/
	@ProductGroupName nvarchar(800) =null,
	@AccessoryGroupName nvarchar(800) =null,
	@TestCentreLocation nvarchar(200) = null
AS
select results.*, (ExpectedDuration - CurrentTestTime) as RemainingHours, DATEADD(HOUR,(ExpectedDuration - CurrentTestTime),GETUTCDATE()) as CanBeRemovedAt 
from 
(
	SELECT b.QRANumber as QRANumber, 
		tu.BatchUnitNumber,
		tu.AssignedTo,
		tl.TrackingLocationName,
		b.JobName,
		b.AccessoryGroupName,
		p.ProductGroupName,
		b.ProductType,
		b.TestStageName,
		dtl.InTime,
		tr.id as TestRecordID ,                     
		case when (select Duration from BatchSpecificTestDurations 
		where TestID = t.id and BatchID = b.ID) is not null then 
		(select Duration from BatchSpecificTestDurations  
		where TestID = t.id and BatchID = b.ID) else t.Duration end as ExpectedDuration,
		(Select sum(datediff(Minute,dtl.intime,
		(case when (dtl.OutTime IS null) then GETUTCDATE() else dtl.outtime  end )) / 60.0)
		 from Testrecordsxtrackinglogs as trXtl, DeviceTrackingLog as dtl 
		 where trXtl.TestRecordID = tr.ID and dtl.ID = trXtl.TrackingLogID) as CurrentTestTime
	FROM Batches AS b 
		INNER JOIN Jobs as j on b.jobname = j.JobName 
		inner join TestStages as ts on j.ID = ts.JobID
		inner join tests as t on ((ts.TestStagetype = 2 and t.id = ts.TestID )or (ts.teststagetype != 2 and t.testtype = ts.TestStageType)) 
		inner join DeviceTrackingLog AS dtl
		INNER JOIN TrackingLocations AS tl ON dtl.TrackingLocationID = tl.ID
		INNER JOIN TrackingLocationTypes as tlt on tl.TrackingLocationTypeID = tlt.id 
		inner join TestUnits AS tu ON dtl.TestUnitID = tu.ID on tu.CurrentTestName = t.TestName and b.id = tu.batchid 
		inner join testrecords as tr on tr.TestUnitID = tu.id and tr.TestName = t.TestName and tr.TestStageName = t.TestName
		inner join Products p on p.ID=b.ProductID    
	WHERE (b.TestCenterLocation = @TestCentreLocation or @TestCentreLocation is null) and  (b.AccessoryGroupName = @AccessoryGroupName or @AccessoryGroupName is null) 
		and (b.BatchStatus = 2) --in progress batches
) as results
order by RemainingHours asc
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchGetViewBatch]'
GO
ALTER PROCEDURE [dbo].[remispBatchGetViewBatch] 
/*  '=============================================================== 
  '   NAME:                  remispBatchGetViewBatch 
  '   DATE CREATED:         29 April 2011 
  '   CREATED BY:            Darragh O'Riordan 
  '   FUNCTION:              Retrieves the data required to display a single batch
   '   VERSION: 1            
  '   COMMENTS:             
  '   MODIFIED ON:          
  '   MODIFIED BY:          
  '   REASON MODIFICATION:  
    '===============================================================*/ 
@qranumber nvarchar(11) AS 

--select basic batch info 
EXEC Remispbatchesselectbyqranumber @QraNumber; 

--select the process for this batch 
SELECT processorder, 
       tsname, 
       tname, 
       testtype, 
       teststagetype, 
       resultbasedontime, 
       testunitsfortest, 
       (SELECT CASE WHEN specifictestduration IS NULL THEN generictestduration ELSE specifictestduration END) AS expectedDuration,
	   TestStageID
FROM   
	(
		SELECT 
		ts.processorder, ts.teststagename AS tsname, t.testname AS tname, t.testtype, ts.teststagetype, t.duration AS genericTestDuration, ts.ID AS TestStageID,
			t.resultbasedontime, 
            (
				SELECT bstd.duration 
                FROM   batchspecifictestdurations AS bstd 
                WHERE  bstd.testid = t.id 
                       AND bstd.batchid = b.id
            ) AS specificTestDuration, 
			(
				SELECT assignedto 
				FROM taskassignments AS ta, 
				teststages AS ts, 
				jobs AS j 
				WHERE ta.batchid = b.id AND ta.taskid = ts.id AND ta.active = 1 AND j.jobname = b.jobname AND ts.jobid = j.id 
					AND ts.teststagename = b.teststagename
			) AS ActiveTaskAssignee, 
			(				
				SELECT Cast(tu.batchunitnumber AS VARCHAR(max)) + ', ' 
				FROM testunits AS tu 
				WHERE tu.batchid = b.id 
					AND 
					(
						NOT EXISTS 
						(
							SELECT DISTINCT 1
							FROM vw_ExceptionsPivoted as pvt
							where pvt.ID IN (SELECT ID FROM TestExceptions WHERE LookupID=3 AND Value = CONVERT(VARCHAR, tu.ID)) AND
							(
								(pvt.TestStageID IS NULL AND CONVERT(int,pvt.Test) = t.ID ) 
								OR 
								(pvt.Test IS NULL AND CONVERT(int,pvt.TestStageID) = ts.id) 
								OR 
								(pvt.TestStageID = ts.id AND pvt.Test = t.ID)
							)
						)
					)
				FOR xml path ('')
            ) AS TestUnitsForTest 
		FROM TestStages ts
		INNER JOIN Jobs j ON ts.JobID=j.ID
		INNER JOIN Batches b on j.jobname = b.jobname 
		INNER JOIN Tests t ON ( ( ts.teststagetype = 2 AND ts.testid = t.id ) OR ts.teststagetype != 2 AND ts.teststagetype = t.testtype )
		INNER JOIN Products p ON b.ProductID=p.ID
        WHERE  b.qranumber = @qranumber 
			AND NOT EXISTS 
			(SELECT DISTINCT 1
				FROM vw_ExceptionsPivoted as pvt
				WHERE pvt.testunitid IS NULL AND pvt.Test = t.ID
					AND ( pvt.teststageid IS NULL OR ts.id = pvt.teststageid ) 
					AND ( 
							( p.productgroupname IS NOT NULL AND pvt.productgroupname = p.productgroupname AND pvt.reasonforrequest IS NULL)
							OR 
							(p.productgroupname IS NOT NULL AND pvt.productgroupname = p.productgroupname AND pvt.reasonforrequest = b.requestpurpose ) 
							OR
							(pvt.productgroupname IS NULL AND b.requestpurpose IS NOT NULL AND pvt.reasonforrequest = b.requestpurpose)
							OR
							(pvt.productgroupname IS NULL AND pvt.reasonforrequest IS NULL)
						) 
						AND
						(
							(pvt.AccessoryGroupName IS NULL)
							OR
							(pvt.AccessoryGroupName IS NOT NULL AND pvt.AccessoryGroupName = b.AccessoryGroupName)
						)
						AND
						(
							(pvt.ProductType IS NULL)
							OR
							(pvt.ProductType IS NOT NULL AND pvt.ProductType = b.ProductType)
						)
					)
	) AS unitData 
WHERE  testunitsfortest IS NOT NULL 
ORDER  BY ProcessOrder

--get records and testunits 
EXEC Remisptestrecordsselectforbatch @qranumber;

EXEC Remisptestunitssearchfor @qranumber;  
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering permissions on [dbo].[remispGetFastScanData]'
GO
GRANT EXECUTE ON  [dbo].[remispGetFastScanData] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispTrackingLocationsSelectForTest]'
GO
GRANT EXECUTE ON  [dbo].[remispTrackingLocationsSelectForTest] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispDeviceTrackingLogSelectListByProductDate]'
GO
GRANT EXECUTE ON  [dbo].[remispDeviceTrackingLogSelectListByProductDate] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispSaveProductConfigurationDetails]'
GO
GRANT EXECUTE ON  [dbo].[remispSaveProductConfigurationDetails] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispBatchesSelectDailyList]'
GO
GRANT EXECUTE ON  [dbo].[remispBatchesSelectDailyList] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispBatchesSearchList]'
GO
GRANT EXECUTE ON  [dbo].[remispBatchesSearchList] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispBatchesInsertUpdateSingleItem]'
GO
GRANT EXECUTE ON  [dbo].[remispBatchesInsertUpdateSingleItem] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispTestExceptionsGetTestUnitTable]'
GO
GRANT EXECUTE ON  [dbo].[remispTestExceptionsGetTestUnitTable] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispTestExceptionsGetProductGroupTable]'
GO
GRANT EXECUTE ON  [dbo].[remispTestExceptionsGetProductGroupTable] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispBatchesSelectBackToRequestorBatches]'
GO
GRANT EXECUTE ON  [dbo].[remispBatchesSelectBackToRequestorBatches] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispProductManagersDeleteSingleItem]'
GO
GRANT EXECUTE ON  [dbo].[remispProductManagersDeleteSingleItem] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispProductManagersAssignUser]'
GO
GRANT EXECUTE ON  [dbo].[remispProductManagersAssignUser] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispProductManagersSelectList]'
GO
GRANT EXECUTE ON  [dbo].[remispProductManagersSelectList] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispBatchesByProductView]'
GO
GRANT EXECUTE ON  [dbo].[remispBatchesByProductView] TO [remi]
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