ALTER PROCEDURE [dbo].[remispTestRecordsSelectOne] @ID int= null
AS
BEGIN	
	SELECT tr.Comment,tr.ConcurrencyID,tr.FailDocNumber,tr.ID,tr.JobName,tr.LastUser,tr.ResultSource,tr.RelabVersion,tr.Status,tr.TestName,tr.TestStageName,tr.TestUnitID, b.QRANumber, tu.BatchUnitNumber
	,(Select sum(datediff(MINUTE,dtl.intime,(case when (dtl.OutTime IS null) then GETUTCDATE() else dtl.outtime  end ))) 
	 from Testrecordsxtrackinglogs as trXtl, DeviceTrackingLog as dtl where trXtl.TestRecordID = tr.id and dtl.ID = trXtl.TrackingLogID
	) as TotalTestTimeMinutes
	,(select COUNT (*) as NumberOfTests from Testrecordsxtrackinglogs as trXtl, DeviceTrackingLog as dtl where trXtl.TestRecordID = tr.id and dtl.ID = trXtl.TrackingLogID
	) as NumberOfTests, tr.TestID, tr.TestStageID, tr.FunctionalType
	FROM TestRecords tr WITH(NOLOCK)
		INNER JOIN testunits tu WITH(NOLOCK) ON tu.ID=tr.TestUnitID
		INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
	WHERE tr.ID = @id
END
GO
GRANT EXECUTE ON remispTestRecordsSelectOne TO Remi
GO