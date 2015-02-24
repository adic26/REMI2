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
GRANT EXECUTE ON [dbo].remispGetStagesNeedingCompletionByUnit TO REMI
GO