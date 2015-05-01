﻿ALTER PROCEDURE [dbo].[remispGetBatchUnitNextTestStage] @RequestNumber NVARCHAR(11), @BatchUnitNumber INT 
AS
BEGIN
	DECLARE @BatchID INT
	DECLARE @TestUnitID INT
	DECLARE @CurrentTestStageID INT
	DECLARE @NextTestStageID INT
	DECLARE @CurrentProcessOrder INT
	DECLARE @JobID INT
	DECLARE @JobName NVARCHAR(400)
	DECLARE @TestStageName NVARCHAR(400)

	SELECT @BatchID = ID, @JobName = JobName FROM Batches WHERE QRANumber=@RequestNumber
	SELECT @JobID = ID FROM Jobs WHERE JobName=@JobName
	SELECT @TestUnitID = ID, @TestStageName = CurrentTestStageName FROM TestUnits WHERE BatchID=@BatchID AND BatchUnitNumber=@BatchUnitNumber
	
	IF (@TestStageName IS NULL OR LTRIM(RTRIM(@TestStageName)) = '')
	BEGIN
		SELECT TOP 1 @CurrentTestStageID = ID, @CurrentProcessOrder = ProcessOrder 
		FROM TestStages 
		WHERE JobID=@JobID AND ISNULL(IsArchived, 0) = 0 AND ProcessOrder >= 0
	END
	ELSE
	BEGIN
		SELECT @CurrentTestStageID = ID, @CurrentProcessOrder = ProcessOrder 
		FROM TestStages 
		WHERE TestStageName=@TestStageName AND JobID=@JobID AND ISNULL(IsArchived, 0) = 0 AND ProcessOrder >= 0
	END
	
	SELECT TOP 1 @NextTestStageID = TestStageID
	FROM vw_GetTaskInfo
	WHERE BatchID=@BatchID AND ProcessOrder > @CurrentProcessOrder AND testunitsfortest LIKE '%' + CONVERT(NVARCHAR, @BatchUnitNumber) + ',%'
	ORDER BY ProcessOrder
	
	EXEC [dbo].[remispTestStagesSelectSingleItem] @ID=@NextTestStageID
END
GO
GRANT EXECUTE ON [dbo].[remispGetBatchUnitNextTestStage] TO REMI
GO