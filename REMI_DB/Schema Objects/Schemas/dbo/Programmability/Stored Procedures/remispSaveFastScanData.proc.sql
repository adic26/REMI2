CREATE procedure [dbo].[remispSaveFastScanData]
@qranumber nvarchar(11),
@unitnumber int,
@userName nvarchar(255),
@TrackingLocationID int,
@testname nvarchar(400)=null,
@teststagename nvarchar(400)=null,
@testrecordstatus int

as

	----------------------
	--    setup vars    --
	----------------------
declare @testunitid int
set @testunitid = (select testunits.id from TestUnits, Batches where Batches.QRANumber = @qranumber and TestUnits.BatchID = batches.id and TestUnits.BatchUnitNumber = @unitnumber)
declare @testrecordID int


declare @LogID int
set @LogID =(select   top(1)	dtl.id as LastLogID             	               
	FROM     DeviceTrackingLog as dtl
	WHERE     (dtl.TestUnitID = @TestUnitID)
	order by dtl.intime desc)
	
	declare @scandirection int
set @scandirection = case when (select top(1) dtl.OutUser as LastLogID             	               
	FROM     DeviceTrackingLog as dtl
	WHERE     (dtl.TestUnitID = @TestUnitID)
	order by dtl.intime desc) IS null then 1 else 2 end --2 =in, 1 =out
	
	
	----------------------
	-- Check for errors --
	----------------------


	if @testrecordstatus is null and @ScanDirection = 1
	 --testing scan out but no status given. error
		return -2
	if @testunitid is null
	 --must have a tu id
		return -4


	----------------------
	--       Scan       --
	----------------------
	
	
begin transaction scan
if @ScanDirection = 1--outward
begin
	set @testrecordID = (select Testrecordid from TestRecordsXTrackingLogs as trxt
	where TrackingLogID = @LogID)
	
	update TestUnits set CurrentTestName = null, LastUser = @userName, AssignedTo = null where id = @testunitid
	update DeviceTrackingLog set OutTime=getutcdate(), OutUser=@username  where id = @logid

	update TestRecords set LastUser = @userName, Status = @testrecordstatus, ResultSource=3 where ID = @testrecordID
	--do the inward scan too
	set @scandirection = 2
end
if @ScanDirection = 2 --inward
begin
	--set the test unit to the new values
	update TestUnits set  LastUser = @userName, AssignedTo = @userName where id = @testunitid
	--create a new tracking log
	insert into DeviceTrackingLog (testunitid, TrackingLocationID, intime, InUser) 
	values (@testunitid,@TrackingLocationID, getutcdate(),@userName)
	set @logid = SCOPE_IDENTITY()
	
	--this is a testing scan
	if @testname is not null and @teststagename is not null
	begin
		--change the testunit test stage if required
		update TestUnits set CurrentTestStageName = @teststagename, CurrentTestName = @testname where id = @testunitid
		--check if there is already a test record
		set @testrecordID = (select Tr.id from TestRecords as tr, Batches as b, TestUnits as tu where
		tu.ID = @testunitid and b.ID = tu.BatchID  and
		tr.JobName = b.JobName and tr.TestStageName = @teststagename and tr.TestName = @testName and tr.TestUnitID = @testunitid)
		
		if @testrecordID is null --new record required?
		begin
			declare @jobname nvarchar(400)
			set @jobname = (select b.jobname from  batches as b, testunits as tu where tu.ID = @testunitid and b.ID = tu.BatchID )
			insert into TestRecords (TestUnitID, TestName, TestStageName, JobName, Status, LastUser, ResultSource) 
			values (@testunitid, @testname, @teststagename, @jobname, 8, @userName,3) --status = "inprogress for inward scan" --resultsource: manual
			set @testrecordID = SCOPE_IDENTITY()
		end
		--else
		--update TestRecords set LastUser = @userName where ID = @testrecordID
		--create a new TL Link
	insert into TestRecordsXTrackingLogs (testrecordid, TrackingLogID) values (@testrecordid, @LogID)
	
	--finally check the test units test stages mean that we should set the batch teststage (>50% of tu's at test stage then change the batch to amtch)
	declare @totalUnits float 
	set @totalunits= (select cast(COUNT(*) as float) from TestUnits as tu where BatchID = (select ID from Batches where QRANumber=  @qranumber))
	
	declare @totalUnitsAtTestStage float
	set @totalUnitsAtTestStage = (select cast(COUNT(*) as float) from TestUnits as tu where tu.CurrentTestStageName = @teststagename and tu.BatchID = (select ID from Batches where QRANumber=  @qranumber))
	
	if ((select teststagename from Batches where QRANumber = @qranumber) <> @teststagename and @totalUnitsAtTestStage is not null and @totalUnits is not null and @totalunits != 0 and (@totalUnitsAtTestStage / @totalUnits) > 0.5)
	update Batches set TestStageName = @teststagename where QRANumber = @qranumber
	
	end
end






	IF (@@ERROR != 0)
	BEGIN
		ROLLBACK TRANSACTION scan;
		RETURN -3
	END
	ELSE
	BEGIN
		commit transaction scan;
		RETURN 0
	END