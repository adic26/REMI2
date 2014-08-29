ALTER PROCEDURE [dbo].[remispTestRecordsSelectForBatch] @QRANumber nvarchar(11) = null
AS
BEGIN
	SELECT tr.FailDocRQID,tr.Comment,tr.ConcurrencyID,tr.FailDocNumber,tr.ID,tr.JobName,tr.ResultSource,tr.LastUser,tr.RelabVersion,tr.Status,tr.TestName,
		tr.TestStageName,tr.TestUnitID, b.QRANumber, tu.BatchUnitNumber,
	(
		Select sum(datediff(MINUTE,dtl.intime,(case when (dtl.OutTime IS null) then GETUTCDATE() else dtl.outtime  end ))) 
		from Testrecordsxtrackinglogs trXtl WITH(NOLOCK)
			INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON dtl.ID = trXtl.TrackingLogID
		where trXtl.TestRecordID = tr.id
	) as TotalTestTimeMinutes,
	(
		select COUNT (*)
		from Testrecordsxtrackinglogs as trXtl WITH(NOLOCK)
			INNER JOIN DeviceTrackingLog as dtl WITH(NOLOCK) ON dtl.ID = trXtl.TrackingLogID
		where trXtl.TestRecordID = tr.id
	) as NumberOfTests, tr.TestID, tr.TestStageID, tr.FunctionalType
	FROM TestRecords as tr WITH(NOLOCK)
		INNER JOIN testunits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
		INNER JOIN Batches b WITH(NOLOCK) ON b.id = tu.batchid
	WHERE b.QRANumber = @QRANumber
	ORDER BY tr.TestStageName, tr.TestName, tr.TestUnitID
END
GO
GRANT EXECUTE ON remispTestRecordsSelectForBatch TO Remi
GO