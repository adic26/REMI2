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
GRANT EXECUTE On remispGetFastScanData TO Remi
GO