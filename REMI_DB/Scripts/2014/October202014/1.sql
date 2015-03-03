/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        (local).REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 10/20/2014 2:37:50 PM

*/
SET NUMERIC_ROUNDABORT OFF
GO
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#tmpErrors')) DROP TABLE #tmpErrors
GO
CREATE TABLE #tmpErrors (Error int)
GO
SET XACT_ABORT ON
GO
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO
BEGIN TRANSACTION
GO
PRINT N'Altering [dbo].[remispGetStagesNeedingCompletionByUnit]'
GO
ALTER PROCEDURE [dbo].remispGetStagesNeedingCompletionByUnit @RequestNumber NVARCHAR(11), @BatchUnitNumber INT = NULL
AS
BEGIN
	DECLARE @UnitID INT
	
	SELECT tu.ID, tu.BatchUnitNumber
	INTO #units
	FROM TestUnits tu
		INNER JOIN Batches b ON tu.BatchID=b.ID
	WHERE b.QRANumber=@RequestNumber AND ((@BatchUnitNumber IS NULL) OR (@BatchUnitNumber IS NOT NULL AND tu.BatchUnitNumber=@BatchUnitNumber))
	ORDER BY tu.ID
	
	SELECT @UnitID = MIN(ID) FROM #units
		
	WHILE (@UnitID IS NOT NULL)
	BEGIN
		PRINT @UnitID
		SELECT @BatchUnitNumber = BatchUnitNumber FROM #units WHERE ID=@UnitID

		SELECT ROW_NUMBER() OVER (ORDER BY tsk.ProcessOrder) AS Row, tsk.TestStageID, @BatchUnitNumber AS BatchUnitNumber, tsk.teststagetype, tsk.tsname AS TestStageName
		FROM vw_GetTaskInfo tsk 
		WHERE qranumber=@RequestNumber AND tsk.testunitsfortest LIKE '%' + CONVERT(NVARCHAR, @BatchUnitNumber) + ',%' AND tsk.teststagetype IN (2,1) AND tsk.TestStageID NOT IN (SELECT ISNULL(tr.TestStageID,0)
		FROM TestRecords tr
			INNER JOIN TestUnits tu ON tu.ID=tr.TestUnitID
			INNER JOIN Batches b ON b.ID=tu.BatchID
		WHERE tu.ID=@UnitID AND b.QRANumber=tsk.qranumber AND tr.Status IN (1,2,3,4,6,7))
		ORDER BY tsk.processorder
		
		SELECT @UnitID = MIN(ID) FROM #units WHERE ID > @UnitID
	END
	
	DROP TABLE #units
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[remispGetBatchUnitNextTestStage]'
GO
CREATE PROCEDURE [dbo].[remispGetBatchUnitNextTestStage] @RequestNumber NVARCHAR(11), @BatchUnitNumber INT 
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
		SELECT TOP 1 @CurrentTestStageID = ID, @CurrentProcessOrder = ProcessOrder FROM TestStages WHERE JobID=@JobID
	END
	ELSE
	BEGIN
		SELECT @CurrentTestStageID = ID, @CurrentProcessOrder = ProcessOrder FROM TestStages WHERE TestStageName=@TestStageName AND JobID=@JobID
	END
	
	SELECT TOP 1 @NextTestStageID = TestStageID
	FROM vw_GetTaskInfo
	WHERE BatchID=@BatchID AND ProcessOrder > @CurrentProcessOrder AND testunitsfortest LIKE '%' + CONVERT(NVARCHAR, @BatchUnitNumber) + ',%'
	ORDER BY ProcessOrder
	
	EXEC [dbo].[remispTestStagesSelectSingleItem] @ID=@NextTestStageID
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[remispTestsSelectByBatchUnitStage]'
GO
CREATE PROCEDURE [dbo].[remispTestsSelectByBatchUnitStage] @RequestNumber NVARCHAR(11), @BatchUnitNumber INT, @TestStageID INT
AS
BEGIN
	SELECT t.Comment,t.ConcurrencyID,t.Duration,t.ID,t.LastUser,t.ResultBasedOntime,t.TestName,t.TestType,t.WILocation, dbo.remifnTestCanDelete(t.ID) AS CanDelete, t.IsArchived,
		(SELECT TestStageName FROM TestStages WHERE TestID=t.ID) As TestStage, (SELECT JobName FROM Jobs WHERE ID IN (SELECT JobID FROM TestStages WHERE TestID=t.ID)) As JobName,
		t.Owner, t.Trainee, t.DegradationVal
	FROM Tests t
		INNER JOIN vw_GetTaskInfo v ON v.qranumber=@RequestNumber AND testunitsfortest LIKE '%' + CONVERT(NVARCHAR, @BatchUnitNumber) + ',%'
			AND v.TestStageID=@TestStageID AND v.TestID=t.ID
	ORDER BY TestName;
	
	SELECT t.id, tlt.id, tlt.TrackingLocationTypeName    
	FROM trackinglocationtypes as tlt, TrackingLocationsForTests as tlfort, Tests as t
		INNER JOIN vw_GetTaskInfo v ON v.qranumber=@RequestNumber AND testunitsfortest LIKE '%' + CONVERT(NVARCHAR, @BatchUnitNumber) + ',%'
			AND v.TestStageID=@TestStageID AND v.TestID=t.ID
	WHERE tlfort.testid = t.id and tlt.ID = tlfort.TrackingLocationtypeID
	ORDER BY tlt.TrackingLocationTypeName asc
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering permissions on [dbo].[remispGetBatchUnitNextTestStage]'
GO
GRANT EXECUTE ON  [dbo].[remispGetBatchUnitNextTestStage] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispTestsSelectByBatchUnitStage]'
GO
GRANT EXECUTE ON  [dbo].[remispTestsSelectByBatchUnitStage] TO [remi]
GO
IF EXISTS (SELECT * FROM #tmpErrors) ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT>0 BEGIN
PRINT 'The database update succeeded'
COMMIT TRANSACTION
END
ELSE PRINT 'The database update failed'
GO
DROP TABLE #tmpErrors
GO