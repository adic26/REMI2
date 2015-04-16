ALTER PROCEDURE [Relab].[remispDeleteAllResults] @RequestNumber NVARCHAR(11), @IncludeBatch BIT = 0, @IncludeRequest BIT = 0 , @UserName NVARCHAR(50)
AS
BEGIN
	SET NOCOUNT ON
	
	IF IS_ROLEMEMBER ('db_owner', @UserName) = 1
	BEGIN
		IF (@IncludeRequest = 1 AND @IncludeBatch = 0)
		BEGIN
			SET @IncludeBatch = 1
		END

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
		DELETE FROM Relab.ResultsStatus WHERE BatchID=@batchid
		UPDATE TestUnits SET CurrentTestName='', CurrentTestStageName='' WHERE BatchID=@batchid
		
		IF (@IncludeBatch = 1)
		BEGIN
			DELETE FROM BatchesJira WHERE BatchID=@batchid
			DELETE FROM BatchComments WHERE BatchID=@batchid
			DELETE FROM BatchSpecificTestDurations WHERE BatchID=@batchid
			DELETE FROM DeviceTrackingLog WHERE TestUnitID IN (SELECT ID FROM TestUnits WHERE BatchID=@batchid)
			DELETE FROM TestRecordsXTrackingLogs WHERE TestRecordID IN (SELECT ID FROM TestRecords WHERE TestUnitID IN (SELECT ID FROM TestUnits WHERE BatchID=@batchid))
			DELETE FROM TestRecords WHERE TestUnitID IN (SELECT ID FROM TestUnits WHERE BatchID=@batchid)
			DELETE FROM TaskAssignments WHERE BatchID=@batchid
			DELETE FROM Req.RequestSetup WHERE BatchID=@batchid
			DELETE FROM TestUnits WHERE BatchID=@batchid
			UPDATE Req.Request SET BatchID=NULL WHERE BatchID=@batchid
			DELETE FROM Batches WHERE ID=@batchid
		END
		
		IF (@IncludeRequest = 1)
		BEGIN
			DELETE FROM Req.ReqFieldData WHERE RequestID IN (SELECT RequestID FROM Req.Request WHERE RequestNumber=@RequestNumber)
			DELETE FROM Req.ReqDistribution WHERE RequestID IN (SELECT RequestID FROM Req.Request WHERE RequestNumber=@RequestNumber)
			DELETE FROM Req.Request WHERE RequestNumber=@RequestNumber
		END
	END
	
	SET NOCOUNT OFF
END
GO
GRANT EXECUTE ON [Relab].[remispDeleteAllResults] TO Remi
GO