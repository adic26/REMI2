ALTER PROCEDURE [dbo].[remispMoveBatchForward] @RequestNumber NVARCHAR(11), @UserName NVARCHAR(255)
AS
BEGIN
	DECLARE @ReqStatus NVARCHAR(50)
	DECLARE @BatchStatus NVARCHAR(50)
	DECLARE @NewBatchStatus INT
	DECLARE @BatchID INT
	DECLARE @RequestID INT
	DECLARE @JobID INT
	DECLARE @ProductID INT
	DECLARE @RowID INT
	DECLARE @TestStageID INT
	DECLARE @TestStageName NVARCHAR(255)
	DECLARE @ReturnVal INT
	DECLARE @TestID INT
	DECLARE @IncomingCount INT
	DECLARE @FailureCount INT
	DECLARE @UnitCount INT
	DECLARE @ExitedEarly BIT
	DECLARE @ProductType NVARCHAR(150)
	SET @ExitedEarly = CONVERT(BIT, 0)
	SET @ReturnVal = 0
	CREATE TABLE #TempSetup (TestStageID INT, TestStageName NVARCHAR(255), TestID INT, TestName NVARCHAR(255), Selected BIT)
	CREATE TABLE #Setup (ID INT IDENTITY(1,1), TestStageID INT, TestStageName NVARCHAR(255), TestID INT, TestName NVARCHAR(255), Selected BIT)
	CREATE TABLE #exceptions (Row INT, ID INT, RequestNumber NVARCHAR(11), BatchUnitNumber INT, ReasonForRequestID INT, ProductGroupName NVARCHAR(150), JobName NVARCHAR(150), TestStageName NVARCHAR(150), TestName NVARCHAR(150), TestStageID INT, TestUnitID INT, LastUser NVARCHAR(150), ProductTypeID INT, AccessoryGroupID INT, ProductID INT, ProductType NVARCHAR(150), AccessoryGroupName NVARCHAR(150), IsMQual INT, TestCenter NVARCHAR(MAX), TestCenterID INT, ReasonForRequest NVARCHAR(150), TestID INT)

	BEGIN TRY
		SELECT @RequestID=RequestID, @BatchID=BatchID FROM Req.Request WHERE RequestNumber=@RequestNumber
		SELECT @UnitCount = COUNT(ID) FROM TestUnits WHERE BatchID=@BatchID
		SELECT @JobID = j.ID, @ProductID=b.ProductID, @BatchStatus = CASE b.BatchStatus WHEN 1 THEN 'Held' WHEN 2 THEN 'InProgress' WHEN 3 THEN 'Quarantined'
			WHEN 4 THEN 'Received' WHEN 5 THEN 'Complete' WHEN 7 THEN 'Rejected' WHEN 8 THEN 'TestingComplete' ELSE 'NotSet' END, @NewBatchStatus = b.BatchStatus,
			@ProductType = l.[Values]
		FROM Batches b
			INNER JOIN Jobs j ON j.JobName = b.JobName
			INNER JOIN Lookups l ON l.LookupID=b.ProductTypeID
		WHERE b.ID=@BatchID

		--Get the setup information for the batch
		INSERT INTO #TempSetup
		EXEC Req.GetRequestSetupInfo @ProductID, @JobID, @BatchID, 1, 0, '', 0
		INSERT INTO #TempSetup
		EXEC Req.GetRequestSetupInfo @ProductID, @JobID, @BatchID, 2, 0, '', 0

		DELETE FROM #TempSetup WHERE Selected=0

		--Determine Request Status Value
		SELECT @ReqStatus = rd.Value
		FROM Req.ReqFieldData rd
			INNER JOIN Req.ReqFieldSetup fs ON fs.ReqFieldSetupID=rd.ReqFieldSetupID
			INNER JOIN Req.ReqFieldMapping fm ON fm.ExtField=fs.Name AND fm.RequestTypeID=fs.RequestTypeID AND fm.IntField='RequestStatus'
		WHERE RequestID=@RequestID

		--If request is closed/cancelled/completed and the batch isn't then close it
		If (LOWER(@ReqStatus) = 'completed' OR LOWER(@ReqStatus) = 'canceled' OR LOWER(@ReqStatus) LIKE '%closed%') AND @BatchStatus <> 'Complete'
		BEGIN
			SET @NewBatchStatus=5
		END

		--If batch is at incoming and the request was set to assigned then move back forward to Assigned status
		IF (@BatchStatus = 'Received' And @ReqStatus = 'Assigned')
		BEGIN
			SET @NewBatchStatus=2
		END

		--If batch is not at rejected but the request status is rejected then set to rejected
		IF (@BatchStatus <> 'Rejected' And @ReqStatus = 'Rejected')
		BEGIN
			SET @NewBatchStatus=7
		END

		--Determine if it should be at incoming
		SELECT @TestStageID=ID FROM TestStages ts WHERE ts.JobID=@JobID AND ISNULL(IsArchived, 0)=0 AND TestStageName='Sample Evaluation'
		SELECT @TestID=ID FROM Tests ts WHERE ISNULL(IsArchived, 0)=0 AND TestName='Sample Evaluation'
		
		SELECT @IncomingCount = COUNT(DISTINCT TestUnitID) 
		FROM TestRecords tr 
		WHERE tr.TestUnitID IN (SELECT ID FROM TestUnits tu WHERE tu.BatchID=@BatchID) AND TestID=@TestID AND TestStageID=@TestStageID
		
		IF (@UnitCount <> @IncomingCount AND LOWER(@ProductType)='handheld')
		BEGIN
			SET @TestStageName = 'Sample Evaluation'
			SET @NewBatchStatus = 4
		END
		ELSE
		BEGIN
			SET @TestStageID = NULL
			SET @TestID = NULL
			SET @FailureCount = NULL
			
			--Get the Request Setup
			INSERT INTO #Setup
			SELECT s.* 
			FROM #TempSetup s
				INNER JOIN TestStages ts ON ts.ID = s.TestStageID
			ORDER BY ts.ProcessOrder ASC
			
			INSERT INTO #exceptions (row,ID,RequestNumber, BatchUnitNumber, ReasonForRequestID, ProductGroupName, JobName, TestStageName, TestName, TestStageID, TestUnitID,LastUser, ProductTypeID, AccessoryGroupID, ProductID, ProductType, AccessoryGroupName, IsMQual, TestCenter, TestCenterID, ReasonForRequest, TestID)
			EXEC [dbo].[remispExceptionSearch] @IncludeBatches=1,@QRANumber=@RequestNumber

			SELECT @RowID=MIN(ID) FROM #Setup

			WHILE (@RowID IS NOT NULL)
			BEGIN
				DECLARE @CountUnitExceptioned INT
				DECLARE @TestStageType INT
				DECLARE @ProcessOrder INT
				SET @ProcessOrder = 0
				SET @TestStageType = 0
				SET @CountUnitExceptioned = 0
				SET @TestID=NULL
				SET @TestStageID=NULL
				SET @TestStageName=NULL
				
				SELECT @TestID=s.TestID, @TestStageID=s.TestStageID, @TestStageName=s.TestStageName, @TestStageType=ts.TestStageType, @ProcessOrder=ts.ProcessOrder
				FROM #Setup s
					INNER JOIN TestStages ts ON ts.ID=s.TestStageID
				WHERE s.ID=@RowID

				SELECT @CountUnitExceptioned = COUNT(DISTINCT TestUnitID)
				FROM #exceptions e
				WHERE (e.TestID=@TestID AND e.TestStageID IS NULL AND e.TestUnitID IS NULL)--Exception For Test regardless of unit
					OR
					(e.TestID=@TestID AND e.TestStageID = @TestStageID AND e.TestUnitID IS NULL)--Exception For Test/Stage regardless of unit
					OR
					(e.TestID=@TestID AND e.TestStageID = @TestStageID AND e.TestUnitID IN (SELECT ID FROM TestUnits WHERE BatchID=@BatchID))--Unit Exception For Test/Stage
					OR
					(e.TestID IS NULL AND e.TestStageID = @TestStageID AND e.TestUnitID IS NULL)--Exception For Stage regardless of unit
					OR
					(e.TestID IS NULL AND e.TestStageID IS NULL AND e.TestUnitID IN (SELECT ID FROM TestUnits WHERE BatchID=@BatchID))--Entire Unit Level Exception
					OR
					(e.TestID IS NULL AND e.TestStageID = @TestStageID AND e.TestUnitID IN (SELECT ID FROM TestUnits WHERE BatchID=@BatchID))--Unit Exception For Stage

				IF ((@UnitCount - @CountUnitExceptioned) <> (SELECT COUNT(DISTINCT ID) 
								FROM TestRecords tr
								WHERE TestStageID=@TestStageID AND TestID=@TestID 
									AND TestUnitID IN (SELECT ID FROM TestUnits WHERE BatchID=@BatchID)
									AND tr.Status IN (1, 2, 3, 6)))
				BEGIN
					SET @RowID = NULL
					SET @ExitedEarly = CONVERT(BIT, 1)
					BREAK
				END
				ELSE
				BEGIN
					SET @ExitedEarly = CONVERT(BIT, 0)
					SET @TestStageID = NULL
					SET @TestStageName = NULL
					SET @TestID = NULL
					SELECT @RowID=MIN(ID) FROM #Setup WHERE ID > @RowID
					CONTINUE
				END
			END
		END

		IF (@ExitedEarly = CONVERT(BIT, 0))
		BEGIN
			TRUNCATE TABLE #Setup
			INSERT INTO #Setup
			EXEC Req.GetRequestSetupInfo @ProductID, @JobID, @BatchID, 5, 0, '', 0
			
			IF ((SELECT COUNT(*) FROM #Setup)=1)
			BEGIN 
				SELECT @FailureCount = COUNT(DISTINCT TestUnitID) 
				FROM TestRecords tr 
				WHERE tr.TestUnitID IN (SELECT ID FROM TestUnits tu WHERE tu.BatchID=@BatchID) AND tr.Status=3
				
				IF (@FailureCount > 0)
				BEGIN
					IF (@FailureCount <> (SELECT COUNT(DISTINCT TestUnitID)
						FROM TestRecords tr 
							INNER JOIN #Setup s ON s.TestID=tr.TestID AND s.TestStageID=tr.TestStageID
						WHERE tr.TestUnitID IN (SELECT ID FROM TestUnits tu WHERE tu.BatchID=@BatchID)))
					BEGIN
						SELECT @TestStageName = s.TestStageName FROM #Setup s
					END
				END
			END
			ELSE
			BEGIN
				TRUNCATE TABLE #Setup
				INSERT INTO #Setup
				EXEC Req.GetRequestSetupInfo @ProductID, @JobID, @BatchID, 4, 0, '', 0
				
				IF ((SELECT COUNT(*) FROM #Setup WHERE TestStageName='Report')=1)
				BEGIN
					SET @TestStageName = 'Report'
				END
			END
		END
		
		IF (@TestStageID > 0)
		BEGIN
			UPDATE Batches SET TestStageName=@TestStageName, LastUser=@UserName, BatchStatus=@NewBatchStatus WHERE ID=@BatchID
		END
		SET @ReturnVal = 1
	END TRY
	BEGIN CATCH
		SET @ReturnVal = 0
	END CATCH
	
	RETURN @ReturnVal

	DROP TABLE #TempSetup
	DROP TABLE #Setup
	DROP TABLE #exceptions
END
GO
GRANT EXECUTE ON remispMoveBatchForward TO Remi
GO