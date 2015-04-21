ALTER PROCEDURE [dbo].remispGetBatchUnitsInStage @QRANumber nvarchar(11)
AS
BEGIN
	DECLARE @rows VARCHAR(8000)
	DECLARE @sql VARCHAR(8000)
	DECLARE @RowID INT
	DECLARE @TestUnitID INT
	DECLARE @BatchUnitNumber INT
	CREATE TABLE #Testing (TestStageID INT, TestStageName NVARCHAR(400), ProcessOrder INT)

	SELECT @rows=  ISNULL(STUFF(
			( 
			SELECT DISTINCT '],[' + CONVERT(VARCHAR, tu.BatchUnitNumber)
			FROM TestUnits tu
				INNER JOIN Batches b ON b.ID=tu.BatchID
			WHERE b.QRANumber=@QRANumber
			FOR XML PATH('')), 1, 2, '') + ']','[na]')

	INSERT INTO #Testing (TestStageID, TestStageName, ProcessOrder)
	SELECT ID, TestStageName, ProcessOrder
	FROM (
	SELECT ts.ID, ts.TestStageName, ts.ProcessOrder
	FROM TestStages ts WITH(NOLOCK)
		INNER JOIN Jobs j WITH(NOLOCK) ON ts.JobID=j.ID
		INNER JOIN Batches b WITH(NOLOCK) on j.jobname = b.jobname 
		INNER JOIN Tests t WITH(NOLOCK) ON ( ( ts.teststagetype = 2 AND ts.testid = t.id ) OR ts.teststagetype != 2 AND ts.teststagetype = t.testtype )
	WHERE b.QRANumber = @QRANumber AND EXISTS 
		(
			SELECT DISTINCT 1
			FROM Req.RequestSetup rs
			WHERE
				(
					(rs.JobID IS NULL )
					OR
					(rs.JobID IS NOT NULL AND rs.JobID = j.ID)
				)
				AND
				(
					(rs.LookupID IS NULL)
					OR
					(rs.LookupID IS NOT NULL AND rs.LookupID = b.ProductID)
				)
				AND
				(
					(rs.TestID IS NULL)
					OR
					(rs.TestID IS NOT NULL AND rs.TestID = t.ID)
				)
				AND
				(
					(rs.TestStageID IS NULL)
					OR
					(rs.TestStageID IS NOT NULL AND rs.TestStageID = ts.ID)
				)
				AND
				(
					(rs.BatchID IS NULL) AND NOT EXISTS(SELECT 1 
														FROM Req.RequestSetup rs2 
															INNER JOIN TestStages ts2 ON ts2.ID=rs2.TestStageID AND ts2.TestStageType=ts.TestStageType
														WHERE rs2.BatchID = b.ID )
					OR
					(rs.BatchID IS NOT NULL AND rs.BatchID = b.ID)
				)
		)
	) s
	ORDER BY ProcessOrder

	SET @sql = 'ALTER TABLE #Testing ADD ' + convert(varchar(8000), replace(@rows, ']', '] BIT '))
	EXEC (@sql)

	SELECT ROW_NUMBER() OVER (ORDER BY tu.ID) AS RowID, tu.BatchUnitNumber, tu.ID
	INTO #units
	FROM TestUnits tu WITH(NOLOCK)
		INNER JOIN Batches b ON b.ID=tu.BatchID
	WHERE b.QRANumber=@QRANumber

	SELECT @RowID = MIN(RowID) FROM #units
				
	WHILE (@RowID IS NOT NULL)
	BEGIN
		SELECT @BatchUnitNumber=BatchUnitNumber, @TestUnitID=ID FROM #units WITH(NOLOCK) WHERE RowID=@RowID

		SET @sql = 'UPDATE t SET [' + CONVERT(VARCHAR,@BatchUnitNumber) + '] = 
			ISNULL((
				SELECT DISTINCT CONVERT(BIT, 1)
				FROM vw_GetTaskInfo ti 
				WHERE ti.QRANumber = ''' + @QRANumber + ''' AND t.TestStageID=ti.TestStageID 
					AND ti.testunitsfortest LIKE ''%' + CONVERT(VARCHAR,@BatchUnitNumber) + ',%''
			), 0)
		FROM #Testing t
	'
		
		print @sql

		EXECUTE (@sql)
		
		SELECT @RowID = MIN(RowID) FROM #units WITH(NOLOCK) WHERE RowID > @RowID

	END


	SELECT * FROM #Testing

	DROP TABLE #Testing
	DROP TABLE #units
END
GO
GRANT EXECUTE ON remispGetBatchUnitsInStage TO REMI
GO