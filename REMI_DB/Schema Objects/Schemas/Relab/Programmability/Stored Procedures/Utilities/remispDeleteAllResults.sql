ALTER PROCEDURE [Relab].[remispDeleteAllResults] @RequestNumber NVARCHAR(11)
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @batchid INT
	SELECT @batchid=id FROM Batches WHERE QRANumber=@RequestNumber

	DELETE trtl
	FROM TestRecordsXTrackingLogs trtl
	WHERE trtl.TestRecordID in (SELECT tr.id 
								FROM TestRecords tr
									INNER JOIN TestUnits tu ON tr.TestUnitID=tu.id
								WHERE tu.BatchID=@batchid AND TestName NOT LIKE '%Sample Evaluation%')

	DELETE tr 
	FROM TestRecords tr
		INNER JOIN TestUnits tu ON tr.TestUnitID=tu.id
	WHERE tu.BatchID=@batchid AND TestName NOT LIKE '%Sample Evaluation%'

	DELETE x FROM Relab.ResultsInformation x WHERE x.XMLID IN (SELECT id FROM Relab.ResultsXML WHERE ResultID in (SELECT ID FROM Relab.Results WHERE TestUnitID IN (SELECT id FROM TestUnits WHERE BatchID=@batchid)))
	DELETE rmf FROM Relab.ResultsMeasurementsFiles rmf WHERE ResultMeasurementID IN (SELECT ID FROM Relab.ResultsMeasurements rm WHERE rm.ResultID IN (SELECT id FROM Relab.Results WHERE TestUnitID IN (SELECT id FROM TestUnits WHERE BatchID=@batchid)))
	DELETE rma FROM Relab.ResultsMeasurementsAudit rma WHERE ResultMeasurementID IN (SELECT ID FROM Relab.ResultsMeasurements rm WHERE rm.ResultID IN (SELECT id FROM Relab.Results WHERE TestUnitID IN (SELECT id FROM TestUnits WHERE BatchID=@batchid)))
	DELETE rp FROM Relab.ResultsParameters rp where rp.ResultMeasurementID IN (SELECT ID FROM Relab.ResultsMeasurements rm WHERE rm.ResultID IN (SELECT id FROM Relab.Results WHERE TestUnitID IN (SELECT id FROM TestUnits WHERE BatchID=@batchid)))
	DELETE rm FROM Relab.ResultsMeasurements rm WHERE rm.ResultID IN (SELECT id FROM Relab.Results WHERE TestUnitID IN (SELECT id FROM TestUnits WHERE BatchID=@batchid))
	DELETE x FROM Relab.ResultsXML x WHERE x.ResultID IN (SELECT ID FROM Relab.Results WHERE TestUnitID IN (SELECT id FROM TestUnits WHERE BatchID=@batchid))
	DELETE r FROM Relab.Results r WHERE TestUnitID IN (SELECT id FROM TestUnits WHERE BatchID=@batchid)

	UPDATE TestUnits SET CurrentTestName='', CurrentTestStageName='' WHERE BatchID=@batchid

	SET NOCOUNT OFF
END
GO
GRANT EXECUTE ON [Relab].[remispDeleteAllResults] TO Remi
GO