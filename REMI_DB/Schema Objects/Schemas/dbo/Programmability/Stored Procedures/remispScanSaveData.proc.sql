ALTER procedure [dbo].[remispScanSaveData]
@unitnumber int,
@qranumber nvarchar(11),
@selectedTrackingLocationID int,
@selectedTestStageName nvarchar(400)=null,
@jobname nvarchar(500),
@selectedTestName nvarchar(400)=null,
@userName nvarchar(255),
@currentTestRecordStatus int = null,
@currentTestRecordID int = null,
@currentTestRecordStatusModified bit = 0,
@selectedTestRecordStatus int=null,
@selectedTestRecordID int=null,
@selectedTestRecordStatusModified bit = 0,
@ResultSource INT = 0
AS
declare @testunitid int = (select testunits.id from TestUnits, Batches where Batches.QRANumber = @qranumber and TestUnits.BatchID = batches.id and TestUnits.BatchUnitNumber = @unitnumber)
declare @scandirection int = 0
declare @LogID int = 0
declare @batchModified bit = 0
declare @transactionName nvarchar(10) = 'Scan'
select   top(1)	@LogID=dtl.id, @scandirection = (case when dtl.OutUser IS null then 1 else 2 end)    --2 =in, 1 =out        	               
	FROM     DeviceTrackingLog as dtl
	WHERE     (dtl.TestUnitID = @TestUnitID)
	order by dtl.intime desc

begin transaction @transactionName
if @ScanDirection = 1 --outward
begin
--there is an inward/outward scan here from when the system first went live. It was to deeply ingrained in the sql and database
-- to remove without some major refactoring. I just deal with it as below.
	update DeviceTrackingLog set OutTime=getutcdate(), OutUser=@username  where id = @logid;
	
	-- update the tr if there were changes
	if @currentTestRecordStatusModified =1 
	begin
	print @ResultSource
		update TestRecords set LastUser = @userName, Status = @currentTestRecordStatus, ResultSource=@ResultSource where ID = @currentTestRecordID;
	end
	--do the inward scan too
	set @scandirection = 2;
end
if (@ScanDirection = 2 or @scandirection is null or @ScanDirection = 0) AND @testunitid IS NOT NULL
begin

	--create a new tracking log
	insert into DeviceTrackingLog (testunitid, TrackingLocationID, intime, InUser) 
	values (@testunitid,@selectedTrackingLocationID, getutcdate(),@userName);
	set @logid = SCOPE_IDENTITY();
	
	--the following code updates the testrecords and possibly batch
	--this code needs to be moved out of here becuase it is causing locks and
	--concurrency errors.
	--this is a testing scan
	if @selectedtestname is not null and @selectedteststagename is not null
	begin
		--change the testunit test stage if required and set the new 'owner'
		update TestUnits set LastUser = @userName, AssignedTo = @userName, CurrentTestStageName = @selectedteststagename, CurrentTestName = @selectedtestname where id = @testunitid;
			
		if @selectedTestRecordID is null  --new record required?
		begin
			DECLARE @TestStageID INT
			DECLARE @TestID INT
			DECLARE @JobID INT
			
			SELECT @JobID=ID FROM Jobs WHERE JobName=@jobname
			SELECT @TestStageID=ID FROM TestStages WHERE JobID=@JobID AND TestStageName=@selectedteststagename
			SELECT @TestID=TestID FROM TestStages WHERE ID=@TestStageID
			
			IF (@TestID = 0 OR @TestID IS NULL)
			BEGIN
				SELECT @TestID=ID FROM Tests WHERE TestName=@selectedtestname
			END

			insert into TestRecords (TestUnitID, TestName, TestStageName, JobName, [Status], LastUser, ResultSource, TestID, TestStageID) 
			values (@testunitid, @selectedtestname, @selectedteststagename, @jobname, 8, @userName,3, @TestID, @TestStageID); --status = "inprogress for inward scan" --resultsource: manual
			set @selectedTestRecordID = SCOPE_IDENTITY();
			set @selectedTestRecordStatusModified = 0 ;--no update required
		end

		if @selectedTestRecordStatusModified =1 --update if required
		begin
			update TestRecords set [Status] = @selectedTestRecordStatus where ID = @selectedTestRecordID;
		end
	
		--create the link between tracking log and test record
		insert into TestRecordsXTrackingLogs (testrecordid, TrackingLogID) values (@selectedTestRecordID, @LogID);
	
		--finally check the test units test stages mean that we should set the batch teststage (>50% of tu's at test stage then change the batch to amtch)
		declare @totalUnits float = (select cast(COUNT(*) as float) from TestUnits as tu where BatchID = (select ID from Batches where QRANumber=  @qranumber))
	
		declare @totalUnitsAtTestStage float = (select cast(COUNT(*) as float) from TestUnits as tu where tu.CurrentTestStageName = @selectedteststagename and tu.BatchID = (select ID from Batches where QRANumber=  @qranumber))
	
		if ((select teststagename from Batches where QRANumber = @qranumber) <> @selectedteststagename and @totalUnitsAtTestStage is not null and @totalUnits is not null and @totalunits != 0 and (@totalUnitsAtTestStage / @totalUnits) > 0.5)
		begin
			update Batches set TestStageName = @selectedteststagename where QRANumber = @qranumber;
			set @batchModified = 1;
		end
	end
	else
	--this is not a testing scan
	begin
		--change the testunit test to null and set the user
		update TestUnits set LastUser = @userName, AssignedTo = @userName, CurrentTestName = @selectedtestname where id = @testunitid;
	end
	GOTO end_process_foundUnit;
end
else
	GOTO complete_process_noupdate;

end_process_foundUnit:
	IF (@@ERROR != 0)
	BEGIN
		ROLLBACK TRANSACTION @transactionName;
		RETURN -3
	END
	ELSE
	BEGIN
		commit transaction @transactionName;
		RETURN 0
	END

complete_process_noupdate:
	begin
		COMMIT TRANSACTION @transactionName;
		RETURN -3
	end
GO
GRANT EXECUTE ON remispScanSaveData TO REMI
GO