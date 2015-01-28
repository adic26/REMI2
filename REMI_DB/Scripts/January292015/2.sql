/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        (local).REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 1/27/2015 5:15:17 PM

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

select @jobname=jobname, @productname=lp.[Values] from Batches inner join Products p on p.ID=Batches.ProductID 
				INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID where Batches.QRANumber = @qranumber

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
select @ApplicableTestStages = @ApplicableTestStages + ','  + TestStageName from TestStages where ISNULL(TestStages.IsArchived, 0)=0 AND testStages.TestStageType NOT IN (4,5, 0) AND TestStages.JobID = @jobID order by ProcessOrder


--get applicable tests
SELECT test.TestName, test.ProcessOrder
INTO #tests
FROM (
SELECT t.TestName, ts.ProcessOrder
FROM Tests t
INNER JOIN TrackingLocationsForTests tlft ON t.ID = tlft.TestID
INNER JOIN TrackingLocationTypes tlt ON tlt.ID = tlft.TrackingLocationtypeID
INNER JOIN TrackingLocations tl ON tl.TrackingLocationTypeID = tlt.ID
INNER JOIN TestStages ts ON ts.TestID = t.ID AND ts.JobID=@jobID AND t.TestType NOT IN (1, 3)
WHERE ISNULL(t.IsArchived, 0)=0 AND tl.ID = @tlid
UNION
SELECT t2.TestName, 0 AS ProcessOrder
FROM Tests t2
INNER JOIN TrackingLocationsForTests tlft ON t2.ID = tlft.TestID
INNER JOIN TrackingLocationTypes tlt ON tlt.ID = tlft.TrackingLocationtypeID
INNER JOIN TrackingLocations tl ON tl.TrackingLocationTypeID = tlt.ID
WHERE ISNULL(t2.IsArchived, 0)=0 AND tl.ID = @tlid AND t2.TestType IN (1, 3)
) test
ORDER BY test.ProcessOrder

SELECT @ApplicableTests = @ApplicableTests + ','  + TestName FROM #tests
DROP TABLE #tests

set @ApplicableTests = SUBSTRING(@ApplicableTests,2,Len(@ApplicableTests))
set @ApplicableTestStages = SUBSTRING(@ApplicableTestStages,2,Len(@ApplicableTestStages))

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
	@TestCentreLocation Int =null,
	@RecordCount int = NULL OUTPUT,
	@sortExpression varchar(100) = null,
	@direction varchar(100) = 'asc',
	@ByPassProductCheck INT = 0,
	@UserID int
	AS
SELECT BatchesRows.Row, BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,
	BatchesRows.JobName,BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,batchesrows.ProductType,batchesrows.AccessoryGroupName,
	batchesrows.ProductID,batchesrows.QRANumber,
	BatchesRows.RequestPurpose,BatchesRows.TestCenterLocation,BatchesRows.TestStageName, 
	batchesrows.TestStageCompletionStatus,testunitcount,
	(CASE WHEN batchesrows.WILocation IS NULL THEN NULL ELSE batchesrows.WILocation END) AS jobWILocation,
	(testUnitCount -
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
		) as ActiveTaskAssignee, CONVERT(BIT,0) AS HasBatchSpecificExceptions,
	batchesrows.ProductTypeID,batchesrows.AccessoryGroupID,batchesrows.RQID As ReqID, batchesrows.TestCenterLocationID,
	AssemblyNumber, AssemblyRevision, HWRevision, PartName, ReportRequiredBy, ReportApprovedDate, IsMQual, JobID, MechanicalTools, BatchesRows.RequestPurposeID,
	BatchesRows.PriorityID, DepartmentID, Department, Requestor
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
			ProductTypeID,
			AccessoryGroupID,
			ProductID,
			JobName, 
			TestCenterLocationID,
			TestCenterLocation,
			LastUser, 
			ConcurrencyID,
			b.TestStageCompletionStatus,
			(select count(*) from testunits WITH(NOLOCK) where testunits.batchid = b.id) as testUnitCount,
			b.WILocation,b.RQID, b.AssemblyNumber, b.AssemblyRevision,b.HWRevision, b.PartName, b.ReportRequiredBy, b.ReportApprovedDate, b.IsMQual, JobID, MechanicalTools,
			RequestPurposeID, PriorityID, DepartmentID, Department, Requestor
		FROM 
		(
			SELECT DISTINCT b.ID, 
				b.QRANumber, 
				b.Comment,
				b.RequestPurpose As RequestPurposeID, 
				b.Priority AS PriorityID,
				b.TestStageName, 
				b.BatchStatus, 
				lp.[Values] AS ProductGroupName, 
				b.ProductTypeID,
				b.AccessoryGroupID,
				l.[Values] AS ProductType,
				l2.[Values] As AccessoryGroupName,
				p.ID As ProductID,
				b.JobName, 
				b.LastUser, 
				b.TestCenterLocationID,
				l3.[Values] As TestCenterLocation,
				b.ConcurrencyID,
				b.TestStageCompletionStatus, j.WILocation,b.RQID, b.AssemblyNumber, b.AssemblyRevision,b.HWRevision, b.PartName, b.ReportRequiredBy, 
				b.ReportApprovedDate, b.IsMQual, j.ID AS JobID, MechanicalTools, l4.[Values] As RequestPurpose, l5.[Values] As Priority, b.DepartmentID, l6.[Values] AS Department,
				b.Requestor
			FROM Batches AS b WITH(NOLOCK)
				LEFT OUTER JOIN Jobs as j WITH(NOLOCK) on b.jobname = j.JobName 
				inner join TestStages as ts WITH(NOLOCK) on j.ID = ts.JobID
				inner join Tests as t WITH(NOLOCK) on ts.TestID = t.ID
				inner join DeviceTrackingLog AS dtl WITH(NOLOCK) 
				INNER JOIN TrackingLocations AS tl WITH(NOLOCK) ON dtl.TrackingLocationID = tl.ID
				INNER JOIN TrackingLocationTypes as tlt WITH(NOLOCK) on tl.TrackingLocationTypeID = tlt.id 
				inner join TestUnits AS tu WITH(NOLOCK) ON dtl.TestUnitID = tu.ID on tu.CurrentTestName = t.TestName and b.id = tu.batchid  --batches where there's a tracking log
				INNER JOIN Products p WITH(NOLOCK) ON b.ProductID=p.id
				INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
				LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON b.AccessoryGroupID=l2.LookupID  
				LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON b.TestCenterLocationID=l3.LookupID  
				LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON b.RequestPurpose=l4.LookupID   
				LEFT OUTER JOIN Lookups l5 WITH(NOLOCK) ON b.Priority=l5.LookupID
				LEFT OUTER JOIN Lookups l6 WITH(NOLOCK) ON b.DepartmentID=l6.LookupID
			WHERE (b.TestCenterLocationID = @TestCentreLocation or @TestCentreLocation is null) and j.TechnicalOperationsTest = 1 and j.MechanicalTest=0 and  tlt.TrackingLocationFunction= 4  and t.ResultBasedOntime = 1 AND dtl.OutTime IS NULL AND dtl.OutUser IS NULL
			AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
		)as b
	) as batchesrows
 	WHERE ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) OR @startRowIndex = -1 OR @maximumRows = -1) 
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
select distinct pvt.id, null as batchunitnumber, pvt.ReasonForRequest AS ReasonForRequestID,lp.[values] AS ProductGroupName,b.JobName, ts.teststagename
, t.TestName, (SELECT TOP 1 LastUser FROM TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS LastUser,
(SELECT TOP 1 ConcurrencyID FROM TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS ConcurrencyID,
pvt.TestStageID, pvt.TestUnitID, pvt.ProductTypeID, pvt.AccessoryGroupID, pvt.ProductID,
l2.[Values] As AccessoryGroupName, l.[Values] As ProductType, pvt.IsMQual, l3.[Values] As TestCenter, l3.[LookupID] As TestCenterID,
l4.[Values] AS ReasonForRequest
FROM vw_ExceptionsPivoted as pvt
	LEFT OUTER JOIN Tests t WITH(NOLOCK) ON pvt.Test = t.ID
	LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.LookupID=pvt.ProductTypeID
	LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.LookupID=pvt.AccessoryGroupID
	LEFT OUTER JOIN Products p WITH(NOLOCK) ON p.ID=pvt.ProductID
	LEFT OUTER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
	LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.LookupID=pvt.TestCenterID
	LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON l4.LookupID=pvt.ReasonForRequest
	, Batches as b, teststages ts WITH(NOLOCK), Jobs j WITH(NOLOCK)
where b.QRANumber = @qranumber 
	and (ts.JobID = j.ID or j.ID is null)
	and (b.JobName = j.JobName or j.JobName is null)
	and pvt.TestUnitID is null
	and (ts.id = pvt.teststageid or pvt.TestStageID is null)
	and 
	(
		(pvt.ProductID = b.ProductID and pvt.ReasonForRequest is null) 
		or 
		(pvt.ProductID = b.ProductID and pvt.ReasonForRequest = b.RequestPurpose)
		or
		(pvt.ProductID is null and pvt.ReasonForRequest = b.RequestPurpose)
		or
		(pvt.ProductID is null and pvt.ReasonForRequest is null)
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
	AND
	(
		(pvt.TestCenterID IS NULL)
		OR
		(pvt.TestCenterID IS NOT NULL AND pvt.TestCenterID = b.TestCenterLocationID)
	)
	AND
	(
		(pvt.IsMQual IS NULL)
		OR
		(pvt.IsMQual IS NOT NULL AND pvt.IsMQual = b.IsMQual)
	)

union all

--then get any for the test units.
select distinct pvt.id, tu.BatchUnitNumber, pvt.ReasonForRequest AS ReasonForRequestID,lp.[Values] AS ProductGroupName,b.JobName, 
(select teststagename from teststages WITH(NOLOCK) where teststages.id =pvt.TestStageid) as teststagename, t.testname,
(SELECT TOP 1 LastUser FROM TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS LastUser,
(SELECT TOP 1 ConcurrencyID FROM TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS ConcurrencyID
, pvt.TestStageID, pvt.TestUnitID, pvt.ProductTypeID, pvt.AccessoryGroupID,pvt.ProductID,
l2.[Values] As AccessoryGroupName, l.[Values] As ProductType, pvt.IsMQual, l3.[Values] As TestCenter, l3.[LookupID] As TestCenterID,
l4.[Values] AS ReasonForRequest
FROM vw_ExceptionsPivoted as pvt
	LEFT OUTER JOIN Tests t WITH(NOLOCK) ON pvt.Test = t.ID
	LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.LookupID=pvt.ProductTypeID
	LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.LookupID=pvt.AccessoryGroupID
	LEFT OUTER JOIN Products p WITH(NOLOCK) ON p.ID=pvt.ProductID
	LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.LookupID=pvt.TestCenterID
	LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON l4.LookupID=pvt.ReasonForRequest
	INNER JOIN testunits tu WITH(NOLOCK) ON tu.ID=pvt.TestUnitID
	INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID
	LEFT OUTER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
WHERE b.QRANumber = @qranumber and tu.batchid = b.id and pvt.TestUnitID = tu.id
order by pvt.TestUnitID desc,TestName
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesSelectListAtTrackingLocation]'
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectListAtTrackingLocation]
	@TrackingLocationID int,
	@StartRowIndex int = -1,
	@MaximumRows int = -1,
	@RecordCount int = NULL OUTPUT,
	@sortExpression varchar(100) = null,
	@direction varchar(100) = 'asc'
AS
IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (select  COUNT(*) from (select DISTINCT b.id	FROM  Batches AS b WITH(NOLOCK) INNER JOIN
                      DeviceTrackingLog AS dtl WITH(NOLOCK) INNER JOIN
                      TrackingLocations AS tl WITH(NOLOCK) ON dtl.TrackingLocationID = tl.ID INNER JOIN
                      TestUnits AS tu WITH(NOLOCK) ON dtl.TestUnitID = tu.ID ON b.id = tu.BatchID --batches where there's a tracking log
				WHERE  tl.id = @TrackingLocationID AND dtl.OutTime IS NULL AND dtl.OutUser IS NULL)as records)  --and the tracking log has not been 'scanned' out
		RETURN
	END

SELECT BatchesRows.Row, BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,
				 BatchesRows.JobName,BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,BatchesRows.QRANumber,
				 BatchesRows.RequestPurpose,BatchesRows.TestCenterLocation,BatchesRows.TestStageName,batchesrows.ProductType, batchesrows.AccessoryGroupName,Batchesrows.ProductID,
				 batchesrows.TestStageCompletionStatus,testunitcount,
				 (testunitcount -
			   (select COUNT(*) 
			  from TestUnits as tu WITH(NOLOCK)
			  INNER JOIN DeviceTrackingLog as dtl WITH(NOLOCK) ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			  where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
			  ) as HasUnitsToReturnToRequestor,
		(CASE WHEN BatchesRows.WILocation IS NULL THEN NULL ELSE BatchesRows.WILocation END) AS jobWILocation,BatchesRows.TestCenterLocationID,
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
	CONVERT(BIT,0) AS HasBatchSpecificExceptions,
	batchesrows.AccessoryGroupID,batchesrows.ProductTypeID,BatchesRows.RQID As ReqID, AssemblyNumber, AssemblyRevision, HWRevision, PartName, ReportRequiredBy, 
	ReportApprovedDate, IsMQual, JobID, ExecutiveSummary, MechanicalTools, batchesrows.RequestPurposeID, batchesrows.PriorityID, DepartmentID, Department, Requestor
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
					  ProductTypeID,
					  AccessoryGroupID,
					  ProductID,
                      JobName, 
					  TestCenterLocationID,
                      TestCenterLocation,
                      LastUser, 
                      ConcurrencyID,
                      b.TestStageCompletionStatus,
					 (select count(*) from testunits WITH(NOLOCK) where testunits.batchid = b.id) as testUnitCount,
					 b.WILocation, b.RQID, b.AssemblyNumber, b.AssemblyRevision,b.HWRevision, b.PartName, b.ReportRequiredBy, b.ReportApprovedDate, b.IsMQual, JobID,
					 ExecutiveSummary, MechanicalTools, RequestPurposeID, PriorityID, DepartmentID, Department, Requestor
                      from
				(SELECT DISTINCT 
                      b.ID, 
                      b.QRANumber, 
                      b.Comment,
                      b.RequestPurpose As RequestPurposeID, 
                      b.Priority AS PriorityID,
                      b.TestStageName, 
                      b.BatchStatus, 
                      lp.[Values] AS ProductGroupName, 
					  b.ProductTypeID,
					  b.AccessoryGroupID,
					  l.[Values] As ProductType,
					  l2.[Values] As AccessoryGroupName,
					  l3.[Values] As TestCenterLocation,
					  p.ID As ProductID,
                      b.JobName, 
                      b.LastUser, 
                      b.TestCenterLocationID,
                      b.ConcurrencyID,
                      b.TestStageCompletionStatus,
                      j.WILocation,
					  b.RQID, b.AssemblyNumber, b.AssemblyRevision,b.HWRevision, b.PartName, b.ReportRequiredBy, b.ReportApprovedDate, b.IsMQual, j.ID As JobID,
					  ExecutiveSummary, MechanicalTools, l4.[Values] AS RequestPurpose, l5.[Values] AS Priority, b.DepartmentID, l6.[Values] AS Department, b.Requestor
				FROM Batches AS b 
					INNER JOIN DeviceTrackingLog AS dtl WITH(NOLOCK) 
					INNER JOIN TrackingLocations AS tl WITH(NOLOCK) ON dtl.TrackingLocationID = tl.ID 
					INNER JOIN TestUnits AS tu WITH(NOLOCK) ON dtl.TestUnitID = tu.ID ON b.id = tu.batchid --batches where there's a tracking log
					inner join Products p WITH(NOLOCK) on p.ID=b.ProductID
					INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
					LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = b.JobName
					LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON b.ProductTypeID=l.LookupID  
					LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON b.AccessoryGroupID=l2.LookupID 
					LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON b.TestCenterLocationID=l3.LookupID 
					LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON b.RequestPurpose=l4.LookupID   
					LEFT OUTER JOIN Lookups l5 WITH(NOLOCK) ON b.Priority=l5.LookupID
					LEFT OUTER JOIN Lookups l6 WITH(NOLOCK) ON b.DepartmentID=l6.LookupID
WHERE     tl.id = @TrackingLocationId AND dtl.OutTime IS NULL AND dtl.OutUser IS NULL)as b) as batchesrows
	WHERE
	 ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) 
			OR @startRowIndex = -1 OR @maximumRows = -1) 
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[vw_GetBatchRequestResult]'
GO
ALTER VIEW [dbo].[vw_GetBatchRequestResult]
AS
SELECT b.QRANumber, b.BatchStatus, b.DateCreated, b.ExecutiveSummary, b.ExpectedSampleSize, b.IsMQual, b.UnitsToBeReturnedToRequestor,
	tu.BatchUnitNumber, tu.BSN, tu.IMEI, lp.[values] AS ProductGroupName, PT.[Values] As ProductType, ag.[Values] As AccessoryGroup,
	tc.[Values] As TestCenter, reqpur.[Values] As RequestPurpose, pty.[Values] As Priority, dpmt.[Values] As Department,
	rtn.[Values] As RequestName, rfs.Name, rfd.Value, ts.TestStageName, t.TestName, mn.[Values] As MeasurementName, 
	m.MeasurementValue, m.UpperLimit, m.LowerLimit, m.Archived, m.Comment, m.DegradationVal, m.Description, m.PassFail, m.ReTestNum,
	mut.[Values] As MeasurementUnitType, ri.Name As InformationName, ri.Value As InformationValue, ri.IsArchived As InformationArchived,
	rp.ParameterName, rp.Value As ParameterValue, rx.VerNum AS XMLVerNum, rx.StationName, rx.StartDate, rx.EndDate
FROM Batches b
	INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
	INNER JOIN Req.Request rq WITH(NOLOCK) ON rq.RequestNumber=b.QRANumber
	INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
	INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
	INNER JOIN Req.ReqFieldData rfd WITH(NOLOCK) ON rfd.RequestID=rq.RequestID
	INNER JOIN Req.ReqFieldSetup rfs WITH(NOLOCK) ON rfs.ReqFieldSetupID=rfd.ReqFieldSetupID
	INNER JOIN Req.RequestType rt ON rt.RequestTypeID=rfs.RequestTypeID
	INNER JOIN Relab.Results r WITH(NOLOCK) ON r.TestUnitID=tu.ID
	INNER JOIN TestStages ts WITH(NOLOCK) ON ts.ID=r.TestStageID
	INNER JOIN Tests t WITH(NOLOCK) ON t.ID=r.TestID
	INNER JOIN Jobs j WITH(NOLOCK) ON j.ID=ts.JobID
	INNER JOIN Relab.ResultsXML rx WITH(NOLOCK) ON rx.ResultID=r.ID
	INNER JOIN Relab.ResultsMeasurements m WITH(NOLOCK) ON m.ResultID=r.ID
	INNER JOIN Relab.ResultsInformation ri WITH(NOLOCK) ON ri.XMLID=rx.ID
	LEFT OUTER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON rp.ResultMeasurementID=m.ID
	LEFT OUTER JOIN Lookups PT WITH(NOLOCK) ON b.ProductTypeID=PT.LookupID  
	LEFT OUTER JOIN Lookups ag WITH(NOLOCK) ON b.AccessoryGroupID=ag.LookupID  
	LEFT OUTER JOIN Lookups tc WITH(NOLOCK) ON b.TestCenterLocationID=tc.LookupID
	LEFT OUTER JOIN Lookups reqpur WITH(NOLOCK) ON b.RequestPurpose=reqpur.LookupID
	LEFT OUTER JOIN Lookups pty WITH(NOLOCK) ON b.Priority=pty.LookupID
	LEFT OUTER JOIN Lookups dpmt WITH(NOLOCK) ON b.DepartmentID=dpmt.LookupID
	LEFT OUTER JOIN Lookups rtn WITH(NOLOCK) ON rt.TypeID=rtn.LookupID
	INNER JOIN Lookups mn WITH(NOLOCK) ON mn.LookupID = m.MeasurementTypeID 
	INNER JOIN Lookups mut WITH(NOLOCK) ON mut.LookupID = m.MeasurementUnitTypeID
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
	SELECT pc.ProductID AS ID, lp.[Values] AS ProductGroupName
	FROM ProductConfigurationUpload pc
		INNER JOIN Products p on pc.ProductID = p.ID
		INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
	WHERE pc.TestID=@TestID AND pc.ProductID <> @productID
	GROUP BY pc.ProductID, lp.[Values]
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispGetProducts]'
GO
ALTER PROCEDURE [dbo].[remispGetProducts] @ByPassProductCheck INT, @UserID INT, @ShowArchived INT
AS
BEGIN
	DECLARE @TrueBit BIT
	SET @TrueBit = CONVERT(BIT, 1)

	SELECT ID, lp.[values] AS ProductGroupName
	FROM Products p
		INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
	WHERE (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
		AND
		(
			(@ShowArchived = 1)
			OR
			(@ShowArchived = 0 AND lp.IsActive = @TrueBit)
		)
	ORDER BY ProductGroupname
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispGetProductNameByID]'
GO
ALTER PROCEDURE [dbo].[remispGetProductNameByID] @ProductID INT
AS
BEGIN
	SELECT ID, lp.[Values] AS ProductGroupName
	FROM Products p
		INNER JOIN Lookups lp ON lp.LookupID=p.LookupID
	WHERE ID=@ProductID
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispSaveProduct]'
GO
ALTER PROCEDURE [dbo].[remispSaveProduct] @ProductID int , @isActive int, @ProductGroupName NVARCHAR(150), @QAP NVARCHAR(255), @TSDContact NVARCHAR(255)
AS
BEGIN
	IF (@ProductID = 0)--ensure we don't have it
	BEGIN
		SELECT @ProductID = ID
		FROM Products p
			INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
		WHERE LTRIM(RTRIM(lp.[values]))=LTRIM(RTRIM(@ProductGroupName))
	END

	IF (@ProductID = 0)--if we still dont have it insert it
	BEGIN
		DECLARE @LookupTypeID INT
		DECLARE @LookupID INT
		SELECT @LookupID = MAX(LookupID)+1 FROM Lookups
		SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='Products'		
				
		INSERT INTO Lookups ([Values], LookupID, IsActive) VALUES (LTRIM(RTRIM(@ProductGroupName)), @LookupID, CONVERT(BIT, @isActive))
		INSERT INTO Products (LookupID, QAPLocation, TSDContact) 
		VALUES (@LookupID, @QAP, @TSDContact)
	END
	ELSE
	BEGIN
		UPDATE Products
		SET QAPLocation = @QAP, TSDContact = @TSDContact
		WHERE ID=@ProductID
	END
END
GRANT EXECUTE ON remispSaveProduct TO REMI
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispGetProductIDByName]'
GO
ALTER PROCEDURE [dbo].[remispGetProductIDByName] @ProductGroupName NVARCHAR(800)
AS
BEGIN
	SELECT ID, lp.[values] AS ProductGroupName
	FROM Products p
		INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
	WHERE LTRIM(RTRIM(lp.[values]))=LTRIM(RTRIM(@ProductGroupName))
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesInsertUpdateSingleItem]'
GO
ALTER PROCEDURE [dbo].[remispBatchesInsertUpdateSingleItem]
	@ID int OUTPUT,
	@QRANumber nvarchar(11),
	@Priority NVARCHAR(150) = 'NotSet', 
	@BatchStatus int, 
	@JobName nvarchar(400),
	@TestStageName nvarchar(255)=null,
	@ProductGroupName nvarchar(800),
	@ProductType nvarchar(800),
	@AccessoryGroupName nvarchar(800) = null,
	@Comment nvarchar(1000) = null,
	@TestCenterLocation nvarchar(400),
	@RequestPurpose nvarchar(200),
	@LastUser nvarchar(255),
	@ConcurrencyID rowversion OUTPUT,
	@testStageCompletionStatus int = null,
	@requestor nvarchar(500) = null,
	@unitsToBeReturnedToRequestor bit = null,
	@expectedSampleSize int = null,
	@reportApprovedDate datetime = null,
	@reportRequiredBy datetime = null,
	@reqStatus nvarchar(500) = null,
	@cprNumber nvarchar(500) = null,
	@pmNotes nvarchar(500) = null,
	@MechanicalTools NVARCHAR(10) = null,
	@RequestPurposeID int = 0,
	@PriorityID INT = 0,
	@DepartmentID INT = 0,
	@Department NVARCHAR(150) = NULL,
	@ExecutiveSummary NVARCHAR(4000) = NULL
	AS
	DECLARE @ProductID INT
	DECLARE @ProductTypeID INT
	DECLARE @AccessoryGroupID INT
	DECLARE @TestCenterLocationID INT
	DECLARE @ReturnValue int
	DECLARE @maxid int
	DECLARE @LookupTypeID INT
	
	IF NOT EXISTS (SELECT 1 FROM Lookups l INNER JOIN LookupType lt ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='Products' AND LTRIM(RTRIM([Values])) = LTRIM(RTRIM(@ProductGroupName)))
	BEGIn
		SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='Products'
		SELECT @maxid = MAX(LookupID)+1 FROM Lookups
		INSERT INTO Lookups (LookupID, LookupTypeID, [Values]) Values (@maxid, @LookupTypeID, LTRIM(RTRIM(@ProductGroupName)))
		
		INSERT INTO Products (LookupID) Values (@maxid)
		
		SELECT @ProductID = ID FROM Products WITH(NOLOCK) WHERE LookupID=@maxid
	END
	ELSE
	BEGIN
		SELECT @maxid = l.LookupID FROM Lookups l INNER JOIN LookupType lt ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='Products' AND LTRIM(RTRIM([Values])) = LTRIM(RTRIM(@ProductGroupName))
		SELECT @ProductID = ID FROM Products WITH(NOLOCK) WHERE LookupID=@maxid
	END
	
	IF NOT EXISTS (SELECT 1 FROM Lookups l INNER JOIN LookupType lt ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='ProductType' AND LTRIM(RTRIM([Values])) = LTRIM(RTRIM(@ProductType)))
	BEGIN
		SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='ProductType'
		SELECT @maxid = MAX(LookupID)+1 FROM Lookups
		INSERT INTO Lookups (LookupID, LookupTypeID, [Values]) Values (@maxid, @LookupTypeID, LTRIM(RTRIM(@ProductType)))
	END
	
	IF LTRIM(RTRIM(@AccessoryGroupName)) <> '' AND NOT EXISTS (SELECT 1 FROM Lookups l INNER JOIN LookupType lt ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='AccessoryType' AND LTRIM(RTRIM([Values])) = LTRIM(RTRIM(@AccessoryGroupName)))
	BEGIN
		SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='AccessoryType'
		SELECT @maxid = MAX(LookupID)+1 FROM Lookups
		INSERT INTO Lookups (LookupID, LookupTypeID, [Values]) Values (@maxid, @LookupTypeID, LTRIM(RTRIM(@AccessoryGroupName)))
	END
	
	IF LTRIM(RTRIM(@TestCenterLocation)) <> '' AND NOT EXISTS (SELECT 1 FROM Lookups l INNER JOIN LookupType lt ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='TestCenter' AND LTRIM(RTRIM([Values])) = LTRIM(RTRIM(@TestCenterLocation)))
	BEGIN
		SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='TestCenter'
		SELECT @maxid = MAX(LookupID)+1 FROM Lookups
		INSERT INTO Lookups (LookupID, LookupTypeID, [Values]) Values (@maxid, @LookupTypeID, LTRIM(RTRIM(@TestCenterLocation)))
	END

	IF LTRIM(RTRIM(@Department)) <> '' AND NOT EXISTS (SELECT 1 FROM Lookups l INNER JOIN LookupType lt ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='Department' AND LTRIM(RTRIM([Values])) = LTRIM(RTRIM(@Department)))
	BEGIN
		SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='Department'
		SELECT @maxid = MAX(LookupID)+1 FROM Lookups
		INSERT INTO Lookups (LookupID, LookupTypeID, [Values]) Values (@maxid, @LookupTypeID, LTRIM(RTRIM(@Department)))
	END

	IF LTRIM(RTRIM(@RequestPurpose)) <> '' AND NOT EXISTS (SELECT 1 FROM Lookups l INNER JOIN LookupType lt ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='RequestPurpose' AND (LTRIM(RTRIM([Values])) = LTRIM(RTRIM(@RequestPurpose)) OR LTRIM(RTRIM([Description]))=LTRIM(RTRIM(@RequestPurpose))))
	BEGIN
		SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='RequestPurpose'
		SELECT @maxid = MAX(LookupID)+1 FROM Lookups
		INSERT INTO Lookups (LookupID, LookupTypeID, [Values]) Values (@maxid, @LookupTypeID, LTRIM(RTRIM(@RequestPurpose)))
	END

	IF LTRIM(RTRIM(@Priority)) <> '' AND NOT EXISTS (SELECT 1 FROM Lookups l INNER JOIN LookupType lt ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='Priority' AND LTRIM(RTRIM([Values])) = LTRIM(RTRIM(@Priority)))
	BEGIN
		SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='Priority'
		SELECT @maxid = MAX(LookupID)+1 FROM Lookups
		INSERT INTO Lookups (LookupID, LookupTypeID, [Values]) Values (@maxid, @LookupTypeID, LTRIM(RTRIM(@Priority)))
	END

	SELECT @RequestPurposeID = LookupID FROM Lookups l INNER JOIN LookupType lt ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='RequestPurpose' AND ([Values] = @RequestPurpose OR [Description] = @RequestPurpose)
	SELECT @PriorityID = LookupID FROM Lookups l INNER JOIN LookupType lt ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='Priority' AND [Values] = @Priority
	SELECT @ProductTypeID = LookupID FROM Lookups l WITH(NOLOCK) INNER JOIN LookupType lt WITH(NOLOCK) ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='ProductType' AND LTRIM(RTRIM([Values]))= LTRIM(RTRIM(@ProductType))
	SELECT @AccessoryGroupID = LookupID FROM Lookups l WITH(NOLOCK) INNER JOIN LookupType lt WITH(NOLOCK) ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='AccessoryType' AND LTRIM(RTRIM([Values]))= LTRIM(RTRIM(@AccessoryGroupName))
	SELECT @TestCenterLocationID = LookupID FROM Lookups l WITH(NOLOCK) INNER JOIN LookupType lt WITH(NOLOCK) ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='TestCenter' AND LTRIM(RTRIM([Values]))= LTRIM(RTRIM(@TestCenterLocation))
	SELECT @DepartmentID = LookupID FROM Lookups l WITH(NOLOCK) INNER JOIN LookupType lt WITH(NOLOCK) ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='Department' AND LTRIM(RTRIM([Values]))= LTRIM(RTRIM(@Department))
		
	IF (@ID IS NULL)
	BEGIN
		INSERT INTO Batches(
		QRANumber, 
		Priority, 
		BatchStatus, 
		JobName,
		TestStageName, 
		ProductTypeID,
		AccessoryGroupID,
		TestCenterLocationID,
		RequestPurpose,
		Comment,
		LastUser,
		TestStageCompletionStatus,
		Requestor,
		unitsToBeReturnedToRequestor,
		expectedSampleSize,
		reportApprovedDate,
		reportRequiredBy,
		trsStatus,
		cprNumber,
		pmNotes,
		ProductID, MechanicalTools, DepartmentID, ExecutiveSummary ) 
		VALUES 
		(@QRANumber, 
		@PriorityID, 
		@BatchStatus, 
		@JobName,
		@TestStageName,
		@ProductTypeID,
		@AccessoryGroupID,
		@TestCenterLocationID,
		@RequestPurposeID,
		@Comment,
		@LastUser,
		@testStageCompletionStatus,
		@Requestor,
		@unitsToBeReturnedToRequestor,
		@expectedSampleSize,
		@reportApprovedDate,
		@reportRequiredBy,
		@reqStatus,
		@cprNumber,
		@pmNotes,
		@ProductID, @MechanicalTools, @DepartmentID,@ExecutiveSummary)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE -- Exisiting Item
	BEGIN
		UPDATE Batches SET 
		QRANumber = @QRANumber, 
		Priority = @PriorityID, 
		Jobname = @Jobname, 
		TestStagename = @TestStagename, 
		BatchStatus = @BatchStatus, 
		ProductTypeID = @ProductTypeID,
		AccessoryGroupID = @AccessoryGroupID,
		TestCenterLocationID=@TestCenterLocationID,
		RequestPurpose=@RequestPurposeID,
		Comment = @Comment, 
		LastUser = @LastUser,
		Requestor = @Requestor,
		TestStageCompletionStatus = @testStageCompletionStatus,
		unitsToBeReturnedToRequestor=@unitsToBeReturnedToRequestor,
		expectedSampleSize=@expectedSampleSize,
		reportApprovedDate=@reportApprovedDate,
		reportRequiredBy=@reportRequiredBy,
		trsStatus=@reqStatus,
		cprNumber=@cprNumber,
		pmNotes=@pmNotes ,
		ProductID=@ProductID,
		MechanicalTools = @MechanicalTools, DepartmentID = @DepartmentID,ExecutiveSummary=@ExecutiveSummary
		WHERE (ID = @ID) AND (ConcurrencyID = @ConcurrencyID)

		SELECT @ReturnValue = @ID
	END
	
	IF EXISTS (SELECT 1 FROM Req.Request WHERE RequestNumber=@QRANumber)
		BEGIN
			UPDATE Req.Request SET BatchID=@ID WHERE RequestNumber=@QRANumber
		END

	SET @ConcurrencyID = (SELECT ConcurrencyID FROM Batches WITH(NOLOCK) WHERE ID = @ReturnValue)
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
PRINT N'Altering [dbo].[remispGetAllCalibrationXML]'
GO
ALTER PROCEDURE [dbo].[remispGetAllCalibrationXML] @ProductID INT, @HostID INT, @TestID INT
AS
BEGIN
	SELECT c.ID, c.HostID, tlh.HostName, c.ProductID, lp.[values] AS ProductGroupName, c.DateCreated, c.[File], c.Name, c.TestID, t.TestName
	FROM Calibration c
		INNER JOIN Products p ON c.ProductID=p.ID
		INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
		INNER JOIN TrackingLocationsHosts tlh ON tlh.ID=c.HostID
		INNER JOIN Tests t ON t.ID=c.TestID
	WHERE c.ProductID=@ProductID AND c.HostID=@HostID AND c.TestID=@TestID
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesSearch]'
GO
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
	@NotInTrackingLocationFunction INT  = NULL,
	@Revision NVARCHAR(10) = NULL,
	@DepartmentID INT = NULL
AS
	DECLARE @TestName NVARCHAR(400)
	DECLARE @TestStageName NVARCHAR(400)
	DECLARE @HasBatchSpecificExceptions BIT
	SET @HasBatchSpecificExceptions = CONVERT(BIT, 0)
	
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
		MechanicalTools, BatchesRows.RequestPurpose, BatchesRows.PriorityID, DepartmentID, Department, Requestor
	FROM     
		(
			SELECT DISTINCT b.BatchStatus,b.Comment, b.teststagecompletionstatus,b.ConcurrencyID,b.ID,b.JobName,b.LastUser,b.Priority AS PriorityID,b.ProductTypeID,
				b.AccessoryGroupID,p.ID As ProductID,lp.[Values] As ProductGroup,b.QRANumber,b.RequestPurpose As RequestPurposeID,b.TestCenterLocationID,b.TestStageName,
				j.WILocation,(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
				l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, l3.[Values] As TestCenterLocation,
				b.CPRNumber,b.RelabJobID, b.RQID, b.AssemblyNumber, b.AssemblyRevision,b.HWRevision, b.PartName, b.ReportRequiredBy, 
				b.ReportApprovedDate, b.IsMQual, j.ID AS JobID, b.DateCreated, j.ContinueOnFailures, MechanicalTools, l4.[Values] As RequestPurpose, l5.[Values] As Priority, 
				ISNULL(b.[Order], 100) As PriorityOrder, b.DepartmentID, l6.[Values] AS Department, b.Requestor
			FROM Batches as b WITH(NOLOCK)
				inner join Products p WITH(NOLOCK) on b.ProductID=p.id 
				INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
				LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
				LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON b.AccessoryGroupID=l2.LookupID  
				LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON b.TestCenterLocationID=l3.LookupID
				INNER JOIN TestStages ts WITH(NOLOCK) ON ts.TestStageName=b.TestStageName
				LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON b.RequestPurpose=l4.LookupID
				LEFT OUTER JOIN Lookups l5 WITH(NOLOCK) ON b.Priority=l5.LookupID
				LEFT OUTER JOIN Lookups l6 WITH(NOLOCK) ON b.DepartmentID=l6.LookupID
			WHERE ((BatchStatus NOT IN (SELECT ID FROM #ExBatchStatus) OR @ExcludedStatus IS NULL) AND (BatchStatus = @Status OR @Status IS NULL))
				AND (p.ID = @ProductID OR @ProductID IS NULL)
				AND (b.Priority = @Priority OR @Priority IS NULL)
				AND (b.ProductTypeID = @ProductTypeID OR @ProductTypeID IS NULL)
				AND (b.AccessoryGroupID = @AccessoryGroupID OR @AccessoryGroupID IS NULL)
				AND (b.TestCenterLocationID = @GeoLocationID OR @GeoLocationID IS NULL)
				AND (b.DepartmentID = @DepartmentID OR @DepartmentID IS NULL)
				AND (b.JobName = @JobName OR @JobName IS NULL)
				AND (b.RequestPurpose = @RequestReason OR @RequestReason IS NULL)
				AND (b.MechanicalTools = @Revision OR @Revision IS NULL)
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
						b.ID IN (SELECT DISTINCT tu.BatchID
						FROM TrackingLocations tl WITH(NOLOCK)
							INNER JOIN devicetrackinglog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID --AND dtl.OutTime IS NULL
								AND dtl.InTime BETWEEN @BatchStart AND @BatchEnd
						INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID=dtl.TestUnitID
						WHERE TrackingLocationTypeID=@TrackingLocationID)
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
					(@BatchStart IS NOT NULL AND @BatchEnd IS NOT NULL AND b.ID IN (Select distinct batchid FROM BatchesAudit WITH(NOLOCK) WHERE InsertTime BETWEEN @BatchStart AND @BatchEnd))
				)
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@ExecutingUserID)))
		)AS BatchesRows		
	ORDER BY BatchesRows.PriorityOrder ASC, BatchesRows.QRANumber DESC
	
	DROP TABLE #ExTestStageType
	DROP TABLE #ExBatchStatus
	RETURN
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispProductManagersSelectList]'
GO
ALTER PROCEDURE [dbo].[remispProductManagersSelectList] @UserID INT
AS
	SELECT lp.[values] AS ProductGroupName, p.ID  
	FROM UsersProducts AS uxpg
		INNER JOIN Products p ON p.ID=uxpg.ProductID
		INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
	WHERE uxpg.UserID = @UserID
	ORDER BY lp.[values] 
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
		SET @RecordCount = (SELECT COUNT(*) FROM Batches WITH(NOLOCK) WHERE BatchStatus NOT IN(5,7))	
		RETURN
	END
	
	SELECT BatchesRows.row,BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,BatchesRows.JobName,
		BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,BatchesRows.QRANumber,BatchesRows.RequestPurpose,batchesrows.ProductType, batchesrows.AccessoryGroupName,
		batchesrows.ProductID,BatchesRows.TestCenterLocationID,
		BatchesRows.TestCenterLocation,BatchesRows.TestStageName, BatchesRows.TestStageCompletionStatus, 
		batchesrows.testUnitCount,BatchesRows.RQID As ReqID,
		(CASE WHEN BatchesRows.WILocation IS NULL THEN NULL ELSE BatchesRows.WILocation END) AS jobWILocation,
		(
			testunitcount -
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
		CONVERT(BIT, 0) AS HasBatchSpecificExceptions, batchesrows.ProductTypeID, batchesrows.AccessoryGroupID, AssemblyNumber, AssemblyRevision, HWRevision, PartName, 
		ReportRequiredBy, ReportApprovedDate, IsMQual, JobID, ExecutiveSummary, MechanicalTools, BatchesRows.RequestPurposeID, BatchesRows.PriorityID, DepartmentID, Department, Requestor
	FROM     
		(
			SELECT ROW_NUMBER() OVER (ORDER BY b.ID) AS Row, 
			b.BatchStatus,b.Comment, b.teststagecompletionstatus,b.ConcurrencyID,b.ID,b.JobName,b.LastUser,b.Priority As PriorityID,lp.[Values] AS ProductGroupName,b.ProductTypeID,b.AccessoryGroupID,p.ID as ProductID,
			b.QRANumber, b.RequestPurpose As RequestPurposeID,b.TestCenterLocationID,b.TestStageName, j.WILocation,
			(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
			l2.[Values] As AccessoryGroupName, l.[Values] As ProductType,b.RQID,l3.[Values] As TestCenterLocation,
			b.AssemblyNumber, b.AssemblyRevision,b.HWRevision, b.PartName, b.ReportRequiredBy, b.ReportApprovedDate, b.IsMQual, j.ID AS JobID, ExecutiveSummary, 
			MechanicalTools, l4.[Values] As RequestPurpose, l5.[Values] As Priority, b.DepartmentID, l6.[Values] AS Department, b.Requestor
			FROM Batches as b WITH(NOLOCK)
				inner join Products p WITH(NOLOCK) on p.ID=b.ProductID
				INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
				LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs
				LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON b.ProductTypeID=l.LookupID 
				LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON b.AccessoryGroupID=l2.LookupID 
				LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON b.TestCenterLocationID=l3.LookupID
				LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON b.RequestPurpose=l4.LookupID
				LEFT OUTER JOIN Lookups l5 WITH(NOLOCK) ON b.Priority=l5.LookupID
				LEFT OUTER JOIN Lookups l6 WITH(NOLOCK) ON b.DepartmentID=l6.LookupID
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
	BatchesRows.LastUser,BatchesRows.Priority AS PriorityID,lp.[Values] AS ProductGroupName,BatchesRows.QRANumber,BatchesRows.RequestPurpose As RequestPurposeID,batchesrows.ProductTypeID,batchesrows.AccessoryGroupID,
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
	IsMQual, j.ID AS JobID, ExecutiveSummary, MechanicalTools, l4.[Values] AS RequestPurpose, l5.[Values] AS Priority, BatchesRows.OrientationID,
	BatchesRows.DepartmentID, l6.[Values] AS Department, BatchesRows.Requestor
	from Batches as BatchesRows WITH(NOLOCK)
		LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = BatchesRows.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
		INNER JOIN Products p WITH(NOLOCK) ON BatchesRows.productID=p.ID
		INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
		LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON BatchesRows.ProductTypeID=l.LookupID  
		LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON BatchesRows.AccessoryGroupID=l2.LookupID  
		LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON BatchesRows.TestCenterLocationID=l3.LookupID  
		LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON BatchesRows.RequestPurpose=l4.LookupID  
		LEFT OUTER JOIN Lookups l5 WITH(NOLOCK) ON BatchesRows.Priority=l5.LookupID
		LEFT OUTER JOIN Lookups l6 WITH(NOLOCK) ON BatchesRows.DepartmentID=l6.LookupID
	WHERE QRANumber = @QRANumber

select bc.DateAdded, bc.ID, bc.[Text], bc.LastUser from BatchComments as bc WITH(NOLOCK) where BatchID = @batchid and Active = 1 order by DateAdded desc;
	RETURN
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[vw_BatchAudit]'
GO
ALTER VIEW [dbo].[vw_BatchAudit]
AS
SELECT ba.QRANumber, ba.Priority AS PriorityID, ba.BatchStatus, ba.JobName, ba.TestStageName, ba.UserName, ba.InsertTime, ba.Action, ba.RequestPurpose AS RequestPurposeID, 
lp.[Values] AS ProductGroupName, tc.[Values] AS TestCenter, ba.IsMQual, pt.[Values] AS ProductType, at.[Values] AS AccessoryGroup,
rp.[Values] AS RequestPurpose, pr.[Values] AS Priority
FROM dbo.BatchesAudit AS ba 
INNER JOIN dbo.Products AS p ON p.ID = ba.ProductID
INNER JOIN dbo.Lookups lp ON lp.LookupID=p.LookupID
LEFT OUTER JOIN dbo.Lookups AS at ON at.LookupID = ba.AccessoryGroupID 
LEFT OUTER JOIN dbo.Lookups AS pt ON pt.LookupID = ba.ProductTypeID 
LEFT OUTER JOIN dbo.Lookups AS tc ON tc.LookupID = ba.TestCenterLocationID 
LEFT OUTER JOIN dbo.Lookups AS rp ON rp.LookupID = ba.RequestPurpose 
LEFT OUTER JOIN dbo.Lookups AS pr ON pr.LookupID = ba.Priority
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispExceptionSearch]'
GO
ALTER procedure [dbo].[remispExceptionSearch] @ProductID INT = 0, @AccessoryGroupID INT = 0, @ProductTypeID INT = 0, @TestID INT = 0, @TestStageID INT = 0, @JobName NVARCHAR(400) = NULL, 
	@IncludeBatches INT = 0, @RequestReason INT = 0, @TestCenterID INT = 0, @IsMQual INT = 0, @QRANumber NVARCHAR(11) = NULL
AS
BEGIN
	DECLARE @JobID INT
	SELECT @JobID = ID FROM Jobs WITH(NOLOCK) WHERE JobName=@JobName

	select *
	from 
	(
		select ROW_NUMBER() over (order by lp.[values] desc)as row, pvt.ID, b.QRANumber, ISNULL(tu.Batchunitnumber, 0) as batchunitnumber, pvt.[ReasonForRequest] As ReasonForRequestID, lp.[Values] AS ProductGroupName, 
		(select jobname from jobs,TestStages where teststages.id =pvt.TestStageid and Jobs.ID = TestStages.jobid) as jobname, 
		(select teststagename from teststages WITH(NOLOCK) where teststages.id =pvt.TestStageid) as teststagename, 
		t.TestName,pvt.TestStageID, pvt.TestUnitID,
		(select top 1 LastUser from TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS LastUser,
		(select top 1 ConcurrencyID from TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS ConcurrencyID,
		pvt.ProductTypeID, pvt.AccessoryGroupID, pvt.ProductID, l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, pvt.IsMQual, 
		l3.[Values] As TestCenter, l3.[LookupID] AS TestCenterID, l4.[Values] As ReasonForRequest
		FROM vw_ExceptionsPivoted as pvt WITH(NOLOCK)
			LEFT OUTER JOIN Tests t WITH(NOLOCK) ON pvt.Test = t.ID
			LEFT OUTER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = pvt.TestUnitID
			LEFT OUTER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
			LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.LookupID=pvt.ProductTypeID
			LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.LookupID=pvt.AccessoryGroupID
			LEFT OUTER JOIN Products p WITH(NOLOCK) ON p.ID=pvt.ProductID
			LEFT OUTER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
			LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.LookupID=pvt.TestCenterID
			LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON l4.LookupID=pvt.ReasonForRequest
		WHERE (
				(pvt.[ProductID]=@ProductID) 
				OR
				(@ProductID = 0)
			)
			AND
			(
				(pvt.ReasonForRequest = @RequestReason)
				OR
				(@RequestReason = 0)
			)
			AND
			(
				(pvt.IsMQual = @IsMQual) 
				OR
				(@IsMQual = 0)
			)
			AND
			(
				(pvt.TestCenterID = @TestCenterID) 
				OR
				(@TestCenterID = 0)
			)
			AND
			(
				(pvt.AccessoryGroupID = @AccessoryGroupID) 
				OR
				(@AccessoryGroupID = 0)
			)
			AND
			(
				(pvt.ProductTypeID = @ProductTypeID) 
				OR
				(@ProductTypeID = 0)
			)
			AND
			(
				(pvt.Test = @TestID) 
				OR
				(@TestID = 0)
			)
			AND
			(
				(pvt.TestStageID = @TestStageID) 
				OR
				(@TestStageID = 0 And @JobID IS NULL OR @JobID = 0)
				OR
				(@JobID > 0 And @TestStageID = 0 AND pvt.TestStageID IN (SELECT ID FROM TestStages WHERE JobID=@JobID))
			)
			AND
			(
				(@IncludeBatches = 1)
				OR
				(@IncludeBatches = 0 AND pvt.TestUnitID IS NULL)
			)
			AND
			(
				(@QRANumber IS NULL)
				OR
				(@QRANumber IS NOT NULL AND b.QRANumber=@QRANumber)
			)
	) as exceptionResults
	ORDER BY QRANumber, Batchunitnumber, TestName
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispYourBatchesGetActiveBatches]'
GO
ALTER PROCEDURE [dbo].[remispYourBatchesGetActiveBatches] @UserID int, @ByPassProductCheck INT = 0, @Year INT = 0, @OnlyShowQRAWithResults INT = 0
AS	
SELECT b.ID, lp.[Values] AS ProductGroupName,b.QRANumber, (b.QRANumber + ' ' + lp.[Values]) AS Name
	FROM Batches as b WITH(NOLOCK)
	INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
	INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
WHERE ( 
		(@Year = 0 AND BatchStatus NOT IN(5,7))
		OR
		(@Year > 0 AND b.QRANumber LIKE 'QRA-' + RIGHT(CONVERT(NVARCHAR, @Year), 2) + '%')
	  )
	AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
	AND (@OnlyShowQRAWithResults = 0 OR (@OnlyShowQRAWithResults = 1 AND b.ID IN (SELECT tu.BatchID FROM Relab.Results r INNER JOIN TestUnits tu ON tu.ID=r.TestUnitID)))
ORDER BY b.QRANumber DESC
RETURN
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
COUNT(TestUnits.ID) as TotalTestUnits 
from BatchesAudit,testunits , Products p
	INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
where p.ID=BatchesAudit.ProductID and 
BatchesAudit.InsertTime >= @StartDate and BatchesAudit.InsertTime <= @EndDate and BatchesAudit.Action = 'I' 
and (@FilterBasedOnQraNumber = 0 or (Convert(int , SUBSTRING(BatchesAudit.QRANumber, 5, 2)) >= @startYear
and Convert(int , SUBSTRING(BatchesAudit.QRANumber, 5, 2)) <= @endYear)) 
and (BatchesAudit.TestCenterLocationID = @geographicallocation or @geographicallocation IS NULL)
and BatchesAudit.BatchID = TestUnits.BatchID 
group by lp.[Values];
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
		SET @RecordCount = (SELECT COUNT(*) FROM Batches WITH(NOLOCK) WHERE BatchStatus NOT IN(5,7) and Requestor = @Requestor	)	
		RETURN
	END

	SELECT BatchesRows.row,BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,BatchesRows.JobName,
		BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,batchesrows.ProductType,batchesrows.AccessoryGroupName, batchesrows.ProductID,
		BatchesRows.QRANumber,BatchesRows.RequestPurpose, BatchesRows.TestCenterLocation,BatchesRows.TestStageName, BatchesRows.TestStageCompletionStatus, 
		batchesrows.testUnitCount,BatchesRows.RQID As ReqID,batchesrows.TestCenterLocationID,
		(CASE WHEN batchesrows.WILocation IS NULL THEN NULL ELSE batchesrows.WILocation END) AS jobWILocation,
		(
			testunitcount -
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
		CONVERT(BIT,0) AS HasBatchSpecificExceptions, BatchesRows.AccessoryGroupID,BatchesRows.ProductTypeID,
		AssemblyNumber, AssemblyRevision, HWRevision, PartName, ReportRequiredBy, ReportApprovedDate, IsMQual, JobID, ExecutiveSummary, MechanicalTools,
		BatchesRows.RequestPurposeID, BatchesRows.PriorityID, DepartmentID, Department, Requestor
	FROM     
		(
			SELECT ROW_NUMBER() OVER (ORDER BY b.ID) AS Row, 
				b.BatchStatus,b.Comment,
				b.teststagecompletionstatus,b.ConcurrencyID,b.ID,b.JobName,b.LastUser,b.Priority AS PriorityID,lp.[Values] AS ProductGroupName,b.ProductTypeID, b.AccessoryGroupID,p.ID As ProductID,b.QRANumber,
				b.RequestPurpose AS RequestPurposeID,b.TestCenterLocationID,b.TestStageName, j.WILocation,
				(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
				l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, b.RQID, l3.[Values] As TestCenterLocation,
				b.AssemblyNumber, b.AssemblyRevision, b.HWRevision, b.PartName, b.ReportRequiredBy, b.ReportApprovedDate, b.IsMQual, j.ID AS JobID, 
				ExecutiveSummary, MechanicalTools, l4.[Values] As RequestPurpose, l5.[Values] As Priority, b.DepartmentID, l6.[Values] AS Department, b.Requestor
			FROM Batches as b
				INNER JOIN Products p WITH(NOLOCK) on p.ID=b.ProductID
				INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
				LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
				LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON b.AccessoryGroupID=l2.LookupID
				LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON b.TestCenterLocationID=l3.LookupID    
				LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON b.RequestPurpose=l4.LookupID 
				LEFT OUTER JOIN Lookups l5 WITH(NOLOCK) ON b.Priority=l5.LookupID
				LEFT OUTER JOIN Lookups l6 WITH(NOLOCK) ON b.DepartmentID=l6.LookupID
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
select @jobName=b.jobname,@cprNumber =b.CPRNumber,@hwrevision = b.HWRevision, @productGroup=lp.[Values],@jobWILocation=j.WILocation,@jobid=j.ID, @batchStatus = b.BatchStatus ,
@productID=p.ID, @NoBSN=j.NoBSN, @productTypeID=b.ProductTypeID, @accessoryTypeID=b.AccessoryGroupID
from Batches as b
	INNER JOIN jobs as j ON j.JobName = b.JobName
	INNER JOIN Products p ON p.ID=b.ProductID
	INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
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
select @ApplicableTestStages = @ApplicableTestStages + ','  + TestStageName from TestStages where ISNULL(TestStages.IsArchived, 0)=0 AND testStages.TestStageType NOT IN (4,5, 0) AND TestStages.JobID = @jobID order by ProcessOrder

--get applicable tests
SELECT test.TestName, test.ProcessOrder
INTO #tests
FROM (
SELECT t.TestName, ts.ProcessOrder
FROM Tests t
INNER JOIN TrackingLocationsForTests tlft ON t.ID = tlft.TestID
INNER JOIN TrackingLocationTypes tlt ON tlt.ID = tlft.TrackingLocationtypeID
INNER JOIN TrackingLocations tl ON tl.TrackingLocationTypeID = tlt.ID
INNER JOIN TestStages ts ON ts.TestID = t.ID AND ts.JobID=@jobID AND t.TestType NOT IN (1, 3)
WHERE ISNULL(t.IsArchived, 0)=0 AND tl.ID = @selectedTrackingLocationID
UNION
SELECT t2.TestName, 0 AS ProcessOrder
FROM Tests t2
INNER JOIN TrackingLocationsForTests tlft ON t2.ID = tlft.TestID
INNER JOIN TrackingLocationTypes tlt ON tlt.ID = tlft.TrackingLocationtypeID
INNER JOIN TrackingLocations tl ON tl.TrackingLocationTypeID = tlt.ID
WHERE ISNULL(t2.IsArchived, 0)=0 AND tl.ID = @selectedTrackingLocationID AND t2.TestType IN (1, 3)
) test
ORDER BY test.ProcessOrder

SELECT @ApplicableTests = @ApplicableTests + ','  + TestName FROM #tests
DROP TABLE #tests

set @ApplicableTestStages = SUBSTRING(@ApplicableTestStages,2,Len(@ApplicableTestStages))
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
ALTER PROCEDURE [Relab].[remispResultsFileUpload] @XML AS NTEXT, @LossFile AS NTEXT = NULL
AS
BEGIN
	DECLARE @TestStageID INT
	DECLARE @TestID INT
	DECLARE @TestUnitID INT
	DECLARE @VerNum INT
	DECLARE @ResultID INT
	DECLARE @ResultsXML XML
	DECLARE @StartDate DATETIME
	DECLARE @EndDate NVARCHAR(MAX)
	DECLARE @Duration NVARCHAR(MAX)
	DECLARE @ResultsLossFile XML
	DECLARE @TestName NVARCHAR(400)
	DECLARE @TestStageName NVARCHAR(400)
	DECLARE @QRANumber NVARCHAR(11)
	DECLARE @JobName NVARCHAR(400)
	DECLARE @StationName NVARCHAR(400)
	DECLARE @FinalResult NVARCHAR(15)
	DECLARE @PassFail BIT
	DECLARE @TestUnitNumber INT
	DECLARE @Insert INT
	SET @Insert = 1

	SELECT @ResultsXML = CONVERT(XML, @XML)
	SELECT @ResultsLossFile = CONVERT(XML, @LossFile)

	SELECT @TestName = T.c.query('TestName').value('.', 'nvarchar(max)'),
		@QRANumber = T.c.query('JobNumber').value('.', 'nvarchar(max)'),
		@TestUnitNumber = T.c.query('UnitNumber').value('.', 'int'),
		@TestStageName = T.c.query('TestStage').value('.', 'nvarchar(max)'),
		@JobName = T.c.query('TestType').value('.', 'nvarchar(max)'),
		@FinalResult = T.c.query('FinalResult').value('.', 'nvarchar(max)'),
		@EndDate = T.c.query('DateCompleted').value('.', 'nvarchar(max)'),
		@Duration = T.c.query('Duration').value('.', 'nvarchar(max)'),
		@StationName = T.c.query('StationName').value('.', 'nvarchar(400)')
	FROM @ResultsXML.nodes('/TestResults/Header') T(c)
		
	IF (@QRANumber IS NULL OR LTRIM(RTRIM(@QRANumber)) = '')
	BEGIN
		SELECT @QRANumber = T.c.query('RequestNumber').value('.', 'nvarchar(max)')
		FROM @ResultsXML.nodes('/TestResults/Header') T(c)
	END
	IF (@JobName IS NULL OR LTRIM(RTRIM(@JobName)) = '')
	BEGIN
		SELECT @JobName = T.c.query('JobName').value('.', 'nvarchar(max)')
		FROM @ResultsXML.nodes('/TestResults/Header') T(c)
	END
	
	IF (@EndDate IS NULL OR LTRIM(RTRIM(@EndDate)) = '')
	BEGIN
		SELECT @EndDate = T.c.query('DateCompleted').value('.', 'nvarchar(max)')
		FROM @ResultsXML.nodes('/TestResults/Footer') T(c)
	END
	
	IF (@Duration IS NULL OR LTRIM(RTRIM(@Duration)) = '')
	BEGIN
		SELECT @Duration = T.c.query('Duration').value('.', 'nvarchar(max)')
		FROM @ResultsXML.nodes('/TestResults/Footer') T(c)
	END
	
	if (@FinalResult IS NOT NULL AND LTRIM(RTRIM(@FinalResult)) <> '')
	BEGIN
		IF (@FinalResult = 'Pass')
		BEGIN
			SET @PassFail = 1
		END
		ELSE
		BEGIN
			SET @PassFail = 0
		END
	END
	ELSE
	BEGIN
		IF (EXISTS (SELECT T.c.query('.').value('.', 'nvarchar(max)') FROM @ResultsXML.nodes('/TestResults/Measurements/Measurement/PassFail') T(c) WHERE LTRIM(RTRIM(T.c.query('.').value('.', 'nvarchar(max)'))) = 'fail'))
		BEGIN
			SET @PassFail = 0
		END
		ELSE
		BEGIN
			SET @PassFail = 1
		END
	END

	SELECT @EndDate= STUFF(@EndDate, CHARINDEX('-',@EndDate,(charindex('-',@EndDate, (charindex('-',@EndDate)+1))+1)), 1, ' ')
	SELECT @EndDate= STUFF(@EndDate, CHARINDEX('-',@EndDate,(charindex('-',@EndDate, (charindex('-',@EndDate)+1))+1)), 1, ':')
	SELECT @EndDate= STUFF(@EndDate, CHARINDEX('-',@EndDate,(charindex('-',@EndDate, (charindex('-',@EndDate)+1))+1)), 1, ':')
					
	If (CHARINDEX('.', @Duration) > 0)
		SET @Duration = SUBSTRING(@Duration, 1, CHARINDEX('.', @Duration)-1)
			
	SET @StartDate=dateadd(s,-datediff(s,0,convert(DATETIME,@Duration)), CONVERT(DATETIME, @EndDate))

	SELECT @TestUnitID = tu.ID
	FROM TestUnits tu
		INNER JOIN Batches b ON tu.BatchID=b.ID
	WHERE QRANumber=@QRANumber AND tu.BatchUnitNumber=@TestUnitNumber
	
	PRINT 'QRA: ' + CONVERT(VARCHAR, @QRANumber)
	PRINT 'Unit Number: ' + CONVERT(VARCHAR, @TestUnitNumber)
	PRINT 'Unit Number: ' + CONVERT(VARCHAR, @TestUnitNumber)
	PRINT 'Duration: ' + CONVERT(VARCHAR, @Duration)
	PRINT 'Date Started: ' + CONVERT(VARCHAR, @StartDate)
	PRINT 'Date Completed: ' + CONVERT(VARCHAR, @EndDate)
	PRINT 'Test Stage: ' + @TestStageName
	PRINT 'Job: ' + @JobName
	PRINT 'Test Name: ' + @TestName

	IF (@TestUnitID IS NOT NULL)
	BEGIN
		PRINT 'TestUnitID: ' + CONVERT(VARCHAR, @TestUnitID)

		SELECT @TestStageID = ts.ID 
		FROM Jobs j
			INNER JOIN TestStages ts ON j.ID=ts.JobID
		WHERE j.JobName=@JobName AND ts.TestStageName=@TestStageName
	
		PRINT 'TestStageID: ' + CONVERT(VARCHAR, @TestStageID)

		SELECT @TestID = t.ID
		FROM Tests t
		WHERE t.TestName=@TestName
	
		PRINT 'TestID: ' + CONVERT(VARCHAR, @TestID)
	
		IF (@TestID = 1099)--sensor
		BEGIN
			IF ((SELECT COUNT(*) FROM @ResultsXML.nodes('/TestResults/Measurements/Measurement/FileName') T(c) WHERE LTRIM(RTRIM(T.c.query('.').value('.', 'nvarchar(max)'))) <> '')=0)
			BEGIN
				SET @Insert = 0
			END
		END
	
		IF (@Insert = 1)
		BEGIN	
			SELECT @ResultID=ID FROM Relab.Results WHERE TestStageID=@TestStageID AND TestID=@TestID AND TestUnitID=@TestUnitID
	
			IF (@ResultID IS NULL OR @ResultID = 0)
			BEGIN
				IF (@TestStageID IS NULL OR @TestID IS NULL)
					BEGIN
						INSERT INTO Relab.ResultsOrphaned (ResultXML, LossFile)
						VALUES (@XML, @ResultsLossFile)
					END
				ELSE
					BEGIN
						INSERT INTO Relab.Results (TestStageID, TestID,TestUnitID, PassFail)
						VALUES (@TestStageID, @TestID, @TestUnitID, @PassFail)

						SELECT @ResultID=ID FROM Relab.Results WHERE TestStageID=@TestStageID AND TestID=@TestID AND TestUnitID=@TestUnitID

						INSERT INTO Relab.ResultsXML (ResultID, ResultXML, VerNum, StationName, StartDate, EndDate, LossFile)
						VALUES (@ResultID, @XML, 1, @StationName, @StartDate, CONVERT(DATETIME, @EndDate), @ResultsLossFile)
					END
			END
			ELSE
			BEGIN
				SELECT @VerNum = ISNULL(COUNT(*), 0)+1 FROM Relab.ResultsXML WHERE ResultID=@ResultID

				INSERT INTO Relab.ResultsXML (ResultID, ResultXML, VerNum, StationName, StartDate, EndDate, LossFile)
				VALUES (@ResultID, @XML, @VerNum, @StationName, @StartDate, CONVERT(DATETIME, @EndDate), @ResultsLossFile)
			END
		END
	END
	ELSE
	BEGIN
		INSERT INTO Relab.ResultsOrphaned (ResultXML, LossFile)
		VALUES (@XML, @ResultsLossFile)
	END
END
GO
GRANT EXECUTE ON [Relab].[remispResultsFileUpload] TO REMI
GO
ALTER PROCEDURE Req.remispGetRequestTypes @UserName NVARCHAR(255)
AS
BEGIN
	SELECT lt.[Values] AS RequestType, l.[Values] AS Department, rta.IsActive, rt.HasIntegration, rt.RequestTypeID, ISNULL(ud.IsAdmin, 0) AS IsAdmin, ud.UserDetailsID, rt.IsExternal
	FROM Req.RequestTypeAccess rta
		INNER JOIN Lookups l ON rta.LookupID=l.LookupID
		INNER JOIN Req.RequestType rt ON rt.RequestTypeID=rta.RequestTypeID
		INNER JOIN Lookups lt ON rt.TypeID=lt.LookupID
		INNER JOIN UserDetails ud ON ud.LookupID = l.LookupID
		INNER JOIN Users u ON u.ID=ud.UserID
	WHERE u.LDAPLogin=@UserName
END
GO
GRANT EXECUTE ON Req.remispGetRequestTypes TO REMI
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
IF EXISTS (SELECT * FROM #tmpErrors) ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT>0 BEGIN
PRINT 'The database update succeeded'
COMMIT TRANSACTION
END
ELSE PRINT 'The database update failed'
GO
DROP TABLE #tmpErrors
GO