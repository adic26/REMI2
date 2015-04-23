ALTER PROCEDURE [Relab].[remispDeleteAllResults] @RequestNumber NVARCHAR(11), @KeepFiles BIT = 0, @IncludeBatch BIT = 0, @IncludeRequest BIT = 0 , @UserName NVARCHAR(50)
AS
BEGIN
	SET NOCOUNT ON
	
	IF IS_ROLEMEMBER ('db_owner', @UserName) = 1
	BEGIN
		PRINT 'Started: ' + CONVERT(VARCHAR, getdate())
		PRINT 'KeepFiles: ' +  CONVERT(VARCHAR, @KeepFiles)
		PRINT 'IncludeBatch: ' +  CONVERT(VARCHAR, @IncludeBatch)
		PRINT 'IncludeRequest: ' +  CONVERT(VARCHAR, @IncludeRequest)
	
		IF (@IncludeRequest = 1 AND @IncludeBatch = 0)
		BEGIN
			SET @IncludeBatch = 1
			PRINT 'Reset IncludeBatch: ' +  CONVERT(VARCHAR, @IncludeBatch)
		END
		
		IF (@KeepFiles = 1 AND @IncludeBatch = 1)
		BEGIN
			SET @IncludeBatch = 0
			SET @IncludeRequest = 0
			PRINT 'Reset IncludeBatch: ' +  CONVERT(VARCHAR, @IncludeBatch)
			PRINT 'Reset IncludeRequest: ' +  CONVERT(VARCHAR, @IncludeRequest)
		END

		DECLARE @batchid INT
		SELECT @batchid=id FROM Batches WHERE QRANumber=@RequestNumber
		
		PRINT 'BatchID: ' +  CONVERT(VARCHAR, @batchid)
		
		IF (@IncludeBatch = 0)
		BEGIN
			DELETE trtl
			FROM TestRecordsXTrackingLogs trtl
			WHERE trtl.TestRecordID in (SELECT tr.id 
										FROM TestRecords tr
											INNER JOIN TestUnits tu ON tr.TestUnitID=tu.id
										WHERE tu.BatchID=@batchid AND TestName NOT LIKE '%Sample Evaluation%')

			PRINT 'Deleted Test Record Tracking Logs'
		
			DELETE tr 
			FROM TestRecords tr
				INNER JOIN TestUnits tu ON tr.TestUnitID=tu.id
			WHERE tu.BatchID=@batchid AND TestName NOT LIKE '%Sample Evaluation%'

			PRINT 'Deleted Test Records'
		END
		
		PRINT 'Started Deleting Result'
		DELETE x FROM Relab.ResultsInformation x WHERE x.XMLID IN (SELECT id FROM Relab.ResultsXML WHERE ResultID in (SELECT ID FROM Relab.Results WHERE TestUnitID IN (SELECT id FROM TestUnits WHERE BatchID=@batchid)))
				
		IF (@KeepFiles = 1)
		BEGIN
			PRINT 'Keeping Files Data'
			UPDATE rmf
			SET rmf.ResultMeasurementID=NULL
			FROM Relab.ResultsMeasurementsFiles rmf
			WHERE ResultMeasurementID IN (SELECT ID FROM Relab.ResultsMeasurements rm WHERE rm.ResultID IN (SELECT id FROM Relab.Results WHERE TestUnitID IN (SELECT id FROM TestUnits WHERE BatchID=@batchid)))
		END
		ELSE
		BEGIN
			DELETE rmf FROM Relab.ResultsMeasurementsFiles rmf WHERE ResultMeasurementID IN (SELECT ID FROM Relab.ResultsMeasurements rm WHERE rm.ResultID IN (SELECT id FROM Relab.Results WHERE TestUnitID IN (SELECT id FROM TestUnits WHERE BatchID=@batchid)))
		END
		
		DELETE rma FROM Relab.ResultsMeasurementsAudit rma WHERE ResultMeasurementID IN (SELECT ID FROM Relab.ResultsMeasurements rm WHERE rm.ResultID IN (SELECT id FROM Relab.Results WHERE TestUnitID IN (SELECT id FROM TestUnits WHERE BatchID=@batchid)))
		DELETE rp FROM Relab.ResultsParameters rp where rp.ResultMeasurementID IN (SELECT ID FROM Relab.ResultsMeasurements rm WHERE rm.ResultID IN (SELECT id FROM Relab.Results WHERE TestUnitID IN (SELECT id FROM TestUnits WHERE BatchID=@batchid)))
		DELETE rm FROM Relab.ResultsMeasurements rm WHERE rm.ResultID IN (SELECT id FROM Relab.Results WHERE TestUnitID IN (SELECT id FROM TestUnits WHERE BatchID=@batchid))
		DELETE x FROM Relab.ResultsXML x WHERE x.ResultID IN (SELECT ID FROM Relab.Results WHERE TestUnitID IN (SELECT id FROM TestUnits WHERE BatchID=@batchid))
		DELETE r FROM Relab.Results r WHERE TestUnitID IN (SELECT id FROM TestUnits WHERE BatchID=@batchid)
		DELETE FROM Relab.ResultsStatus WHERE BatchID=@batchid
		UPDATE TestUnits SET CurrentTestName='', CurrentTestStageName='' WHERE BatchID=@batchid
		
		PRINT 'Finished Deleting Results'
		
		IF (@IncludeBatch = 1)
		BEGIN
			PRINT 'Started Deleting Batch'
			DELETE FROM BatchesJira WHERE BatchID=@batchid
			DELETE FROM BatchComments WHERE BatchID=@batchid
			DELETE FROM BatchSpecificTestDurations WHERE BatchID=@batchid
			DELETE FROM TestRecordsXTrackingLogs WHERE TestRecordID IN (SELECT ID FROM TestRecords WHERE TestUnitID IN (SELECT ID FROM TestUnits WHERE BatchID=@batchid))
			DELETE FROM DeviceTrackingLog WHERE TestUnitID IN (SELECT ID FROM TestUnits WHERE BatchID=@batchid)
			DELETE FROM TestRecords WHERE TestUnitID IN (SELECT ID FROM TestUnits WHERE BatchID=@batchid)
			DELETE FROM TaskAssignments WHERE BatchID=@batchid
			DELETE FROM Req.RequestSetup WHERE BatchID=@batchid
			DELETE FROM TestUnits WHERE BatchID=@batchid
			UPDATE Req.Request SET BatchID=NULL WHERE BatchID=@batchid
			DELETE FROM Batches WHERE ID=@batchid
			PRINT 'Finished Deleting Batch'
		END
		
		IF (@IncludeRequest = 1)
		BEGIN
			PRINT 'Started Deleting Request'
			DELETE FROM Req.ReqFieldData WHERE RequestID IN (SELECT RequestID FROM Req.Request WHERE RequestNumber=@RequestNumber)
			DELETE FROM Req.ReqDistribution WHERE RequestID IN (SELECT RequestID FROM Req.Request WHERE RequestNumber=@RequestNumber)
			DELETE FROM Req.Request WHERE RequestNumber=@RequestNumber
			PRINT 'Finished Deleting Request'
		END
		PRINT 'Finished: ' + CONVERT(VARCHAR, getdate())
	END
	ELSE
	BEGIN
		 RAISERROR ('You Must Be A Member Of The db_owner Group To Perform This Action.', 16, 2)
	END
	
	SET NOCOUNT OFF
END
GO
GRANT EXECUTE ON [Relab].[remispDeleteAllResults] TO Remi
GO