ALTER PROCEDURE [dbo].[remispTestRecordsSearchFor]
/*	'===============================================================
	'   NAME:                	remispTestRecordsSearchFor
	'   DATE CREATED:       	9 Oct 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves data from table: TestRecords OR the number of records in the table
	'   IN:         JobXTestStageID, TestID, BatchID  Optional: RecordCount         
	'   OUT: 		List Of: ID, TestUnitID,TestStageID, JobID, FANumber,FARaisedBy, FARaisedOn, Status,FAPriority, ConcurrencyID              
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/
	@JobName nvarchar(400) = null,
	@TestStageName nvarchar(400) = null,
	@TestName nvarchar(400) = null,
	@TestUnitID int = null,
	@ID int= null,
	@Status int = null,
	@BatchID int = null,
	@OnlyIncompleteRecords bit = 0,
	@QRANumber nvarchar(11) = null	
AS	
	if (@QRANumber is not null)
	begin
		set @BatchID = (select ID from dbo.Batches where dbo.batches.QRANumber = @QRANumber)

		if @BatchID is null
		begin
			set @BatchID = 0
		end
	end

	SELECT tr.Comment,tr.ConcurrencyID,tr.FailDocNumber,tr.ID,tr.ResultSource,tr.JobName,tr.LastUser,tr.RelabVersion,tr.Status,tr.TestName,tr.TestStageName,tr.TestUnitID, t.TestType as TestType,t.Duration as ExpectedTestTime, b.QRANumber, tu.BatchUnitNumber
	,(Select sum(datediff(MINUTE,dtl.intime,(case when (dtl.OutTime IS null) then GETUTCDATE() else dtl.outtime  end ))) 
	 from Testrecordsxtrackinglogs as trXtl, DeviceTrackingLog as dtl where trXtl.TestRecordID = tr.id and dtl.ID = trXtl.TrackingLogID
	) as TotalTestTimeMinutes
	,(select COUNT (*) as NumberOfTests from Testrecordsxtrackinglogs as trXtl, DeviceTrackingLog as dtl where trXtl.TestRecordID = tr.id and dtl.ID = trXtl.TrackingLogID
	) as NumberOfTests
	FROM TestRecords as tr, Tests as t, testunits as tu, Batches as b
	                    
	WHERE     (tr.Jobname = @Jobname or @Jobname IS NULL) 
	AND (tr.Testname = @Testname or @Testname is null)
	AND (tr.teststagename = @TestStagename or @TestStagename is null)   
	and (tr.TestUnitID = @TestUnitID or @TestUnitID is null)
	and (tr.ID = @ID or @ID is null) 
	and (tr.Status = @Status or @Status is null)
	and (b.id = tu.batchid and tu.ID = tr.TestUnitID and tr.ID=tr.id)
	and t.TestName = tr.TestName
	and ((tu.batchid =b.id and b.id= @batchID and tr.TestUnitID = tu.id) or (@batchID is null and tu.ID = tr.TestUnitID))
	and ((@OnlyIncompleteRecords = 1 and not(tr.status = 1 or tr.Status = 2 or tr.Status=10)) or @OnlyIncompleteRecords=0 or @OnlyIncompleteRecords is null)
	