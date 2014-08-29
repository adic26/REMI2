ALTER PROCEDURE [dbo].[remispTestRecordsSelectByStatus] @status int= null
AS
BEGIN
	SELECT tr.Comment,tr.ConcurrencyID,tr.FailDocNumber,tr.ID,tr.JobName,tr.ResultSource,tr.LastUser,tr.RelabVersion,tr.Status,tr.TestName,tr.TestStageName,tr.TestUnitID, b.QRANumber, tu.BatchUnitNumber
	,(Select sum(datediff(MINUTE,dtl.intime,(case when (dtl.OutTime IS null) then GETUTCDATE() else dtl.outtime  end ))) 
	 from Testrecordsxtrackinglogs as trXtl, DeviceTrackingLog as dtl where trXtl.TestRecordID = tr.id and dtl.ID = trXtl.TrackingLogID
	) as TotalTestTimeMinutes
	,(select COUNT (*) as NumberOfTests from Testrecordsxtrackinglogs as trXtl, DeviceTrackingLog as dtl where trXtl.TestRecordID = tr.id and dtl.ID = trXtl.TrackingLogID
	) as NumberOfTests, tr.TestID, tr.TestStageID, tr.FunctionalType
	FROM TestRecords as tr,  testunits as tu, Batches as b
	                    
	WHERE tr.Status = @status and  tu.batchid = b.id and tu.ID = tr.TestUnitID 
END
GO
GRANT EXECUTE ON remispTestRecordsSelectByStatus TO Remi
GO