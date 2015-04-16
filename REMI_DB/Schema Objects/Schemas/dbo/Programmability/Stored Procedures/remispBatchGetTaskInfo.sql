ALTER PROCEDURE [remispBatchGetTaskInfo] @BatchID INT, @TestStageID INT = 0
AS
BEGIN
	DECLARE @BatchStatus INT
	SELECT @BatchStatus = BatchStatus FROM Batches WITH(NOLOCK) WHERE ID=@BatchID

	IF (@BatchStatus = 5)
	BEGIN
		SELECT QRANumber, expectedDuration, processorder, resultbasedontime, tname As TestName, testtype, teststagetype, tsname AS TestStageName, testunitsfortest, TestID, TestStageID, IsArchived, 
			TestIsArchived, TestWI, '' AS TestCounts
		FROM vw_GetTaskInfoCompleted WITH(NOLOCK)
		WHERE BatchID = @BatchID
			AND
			(
				(@TestStageID = 0)
				OR
				(@TestStageID <> 0 AND TestStageID=@TestStageID)
			)
		ORDER BY ProcessOrder
	END
	ELSE
	BEGIN
		SELECT QRANumber, expectedDuration, processorder, resultbasedontime, tname As TestName, testtype, teststagetype, tsname AS TestStageName, testunitsfortest, TestID, TestStageID, IsArchived, 
			TestIsArchived, TestWI, TestCounts
		FROM vw_GetTaskInfo WITH(NOLOCK)
		WHERE BatchID = @BatchID
			AND
			(
				(@TestStageID = 0)
				OR
				(@TestStageID <> 0 AND TestStageID=@TestStageID)
			)
		ORDER BY ProcessOrder
	END
END
GO
GRANT EXECUTE ON remispBatchGetTaskInfo TO Remi
GO