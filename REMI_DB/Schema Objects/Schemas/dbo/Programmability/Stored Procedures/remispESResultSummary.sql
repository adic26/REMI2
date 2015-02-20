ALTER PROCEDURE [dbo].[remispESResultSummary] @BatchID INT
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @UnitRows VARCHAR(8000)
	DECLARE @sql VARCHAR(8000)
	DECLARE @BatchUnitNumber INT
	DECLARE @UnitCount INT
	DECLARE @RowID INT
	DECLARE @ID INT
	CREATE TABLE #Results (TestID INT, TestName NVARCHAR(MAX), TestStageID INT, TestStageName NVARCHAR(MAX))

	SELECT ROW_NUMBER() OVER (ORDER BY tu.ID) AS RowID, tu.BatchUnitNumber, tu.ID
	INTO #units
	FROM TestUnits tu WITH(NOLOCK)
	WHERE BatchID=@BatchID

	INSERT INTO #Results (TestID, TestName, TestStageID, TestStageName)
	SELECT DISTINCT r.TestID, t.TestName, r.TestStageID, ts.TestStageName
	FROM Batches b 
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.BatchID=b.ID
		INNER JOIN Relab.Results r WITH(NOLOCK) ON r.TestUnitID=tu.ID
		INNER JOIN Tests t WITH(NOLOCK) ON t.ID=r.TestID
		INNER JOIN TestStages ts WITH(NOLOCK) ON ts.ID=r.TestStageID
	WHERE b.ID=@BatchID AND ts.TestStageName NOT IN ('Analysis')

	SELECT @UnitCount = COUNT(RowID) FROM #units WITH(NOLOCK)

	SELECT @RowID = MIN(RowID) FROM #units
				
	WHILE (@RowID IS NOT NULL)
	BEGIN
		SELECT @BatchUnitNumber=BatchUnitNumber, @ID=ID FROM #units WITH(NOLOCK) WHERE RowID=@RowID

		EXECUTE ('ALTER TABLE #Results ADD [' + @BatchUnitNumber + '] NVARCHAR(10) NULL')
		print @ID
		SET @SQL = 'UPDATE rr
				SET [' + CONVERT(VARCHAR,@BatchUnitNumber) + '] = (
						SELECT CASE WHEN PassFail  = 1 THEN ''Pass'' WHEN PassFail = 0 THEN ''Fail'' ELSE NULL END + 
							CASE WHEN (SELECT CONVERT(VARCHAR,COUNT(*))
							FROM Relab.ResultsMeasurements rm
								INNER JOIN Relab.ResultsMeasurementsFiles rmf ON rmf.ResultMeasurementID=rm.ID
							WHERE rm.ResultID=r.ID) > 0 THEN ''1'' ELSE ''0'' END
						FROM Relab.Results r 
						WHERE r.TestUnitID=' + CONVERT(NVARCHAR, @ID) + '
							AND rr.TestID=r.TestID AND rr.TestStageID=r.TestStageID
					)
				FROM #Results rr'
		
		EXECUTE (@SQL)
		SELECT @RowID = MIN(RowID) FROM #units WITH(NOLOCK) WHERE RowID > @RowID
	END
	
	ALTER TABLE #Results DROP COLUMN TestID
	ALTER TABLE #Results DROP COLUMN TestStageID
	
	SELECT * 
	FROM #Results WITH(NOLOCK)

	DROP TABLE #units
	DROP TABLE #Results
	SET NOCOUNT OFF
END
GO
GRANT EXECUTE ON [dbo].[remispESResultSummary] TO Remi
GO