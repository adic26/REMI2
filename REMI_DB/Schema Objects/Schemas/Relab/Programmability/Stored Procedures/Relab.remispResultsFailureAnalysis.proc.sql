
ALTER PROCEDURE [Relab].[remispResultsFailureAnalysis] @TestID INT, @BatchID INT
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @FalseBit BIT
	DECLARE @RecordID INT
	DECLARE @BatchUnitNumber INT
	DECLARE @TestUnitID INT
	DECLARE @RowID INT
	DECLARE @MeasurementID INT
	DECLARE @TestStageID INT
	DECLARE @COUNT INT
	DECLARE @RowCount INT
	DECLARE @ResultMeasurementID INT
	DECLARE @Parameters NVARCHAR(MAX)
	DECLARE @SQL NVARCHAR(MAX)
	DECLARE @SQL2 NVARCHAR(MAX)
	DECLARE @Row NVARCHAR(MAX)
	CREATE TABLE #FailureAnalysis (RowID INT IDENTITY(1,1), MeasurementID INT, Measurement NVARCHAR(150), [Parameters] NVARCHAR(MAX), TestStageID INT, TestStageName NVARCHAR(400), ResultMeasurementID INT)
	SET @FalseBit = CONVERT(BIT, 0)

	SELECT ROW_NUMBER() OVER (ORDER BY tu.ID) AS RowID, tu.BatchUnitNumber, tu.ID
	INTO #units
	FROM TestUnits tu WITH(NOLOCK)
	WHERE BatchID=@BatchID

	INSERT INTO #FailureAnalysis (MeasurementID, Measurement, [Parameters], TestStageID, TestStageName)
	SELECT DISTINCT lm.LookupID As MeasurementID, lm.[Values] As Measurement, ISNULL(Relab.ResultsParametersComma(rm.ID), '') AS [Parameters], ts.ID, ts.TestStageName 
	FROM Relab.Results r WITH(NOLOCK)
		INNER JOIN Relab.ResultsMeasurements rm WITH(NOLOCK) ON rm.ResultID=r.ID AND rm.PassFail=0 AND rm.Archived=0
		INNER JOIN Lookups lm WITH(NOLOCK) ON lm.LookupID=rm.MeasurementTypeID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID=r.TestUnitID
		INNER JOIN TestStages ts WITH(NOLOCK) ON ts.ID=r.TestStageID
	WHERE r.TestID=@TestID AND tu.BatchID=@BatchID AND r.PassFail=@FalseBit
	ORDER BY Measurement, [Parameters]
	
	UPDATE #FailureAnalysis SET ResultMeasurementID = (
				SELECT TOP 1 rm.ID 
				FROM Relab.Results r WITH(NOLOCK) 
					INNER JOIN Relab.ResultsMeasurements rm WITH(NOLOCK) ON rm.ResultID=r.ID AND rm.PassFail=0 AND rm.Archived=0
					INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID=r.TestUnitID
				WHERE #FailureAnalysis.TestStageID=r.TestStageID AND #FailureAnalysis.MeasurementID=rm.MeasurementTypeID
					AND r.TestID=@TestID AND tu.BatchID=@BatchID AND r.PassFail=@FalseBit
					AND (ISNUMERIC(MeasurementValue) > 0 OR MeasurementValue IN ('Fail', 'False', 'Pass', 'True'))
				)

	--INSERT INTO #FailureAnalysis (MeasurementID, Measurement, [Parameters], TestStageID, TestStageName)
	--SELECT 0, 'Total', '', 0, ''	

	SELECT @RowID = MIN(RowID) FROM #units WITH(NOLOCK)

	WHILE (@RowID IS NOT NULL)
	BEGIN
		SELECT @BatchUnitNumber=BatchUnitNumber, @TestUnitID = ID FROM #units WHERE RowID=@RowID
		SET @COUNT = 0
	
		EXECUTE ('ALTER TABLE #FailureAnalysis ADD [' + @BatchUnitNumber + '] INT NULL ')
	
		SELECT @RecordID = MIN(RowID) FROM #FailureAnalysis WITH(NOLOCK)-- WHERE Measurement <> 'Total'
	
		WHILE (@RecordID IS NOT NULL)
		BEGIN
			DECLARE @val INT
			SET @ResultMeasurementID = 0
			SET @SQL = '' 
			SET @SQL2 = ''
			SET @val = 0
			SELECT @MeasurementID = MeasurementID, @TestStageID = TestStageID, @Parameters= [Parameters] FROM #FailureAnalysis WITH(NOLOCK) WHERE RowID=@RecordID

			--SELECT @COUNT = COUNT(DISTINCT r.ID)
			SELECT @val = rm.ResultID
			FROM Relab.Results r WITH(NOLOCK)
				INNER JOIN Relab.ResultsMeasurements rm WITH(NOLOCK) ON rm.ResultID=r.ID AND rm.PassFail=@FalseBit AND rm.Archived=@FalseBit
			WHERE r.TestID=@TestID AND r.TestUnitID=@TestUnitID AND r.PassFail=@FalseBit
				AND r.TestStageID=@TestStageID AND rm.MeasurementTypeID=@MeasurementID AND ISNULL(Relab.ResultsParametersComma(rm.ID), '') = ISNULL(@Parameters, '')

			SET @SQL = 'UPDATE #FailureAnalysis SET [' + CONVERT(VARCHAR, @BatchUnitNumber) + '] = ' + CONVERT(VARCHAR, ISNULL(@val, 0)) + ' 
			WHERE TestStageID = ' + CONVERT(VARCHAR, @TestStageID) + ' AND MeasurementID = ' + CONVERT(VARCHAR, @MeasurementID) + ' AND LTRIM(RTRIM(ISNULL(Parameters, ''''))) = '
			SET @SQL2 = ' LTRIM(RTRIM(ISNULL(''' + CONVERT(NVARCHAR(MAX), @Parameters) + ''','''')))'
			
			EXECUTE (@SQL + @SQL2)			
			
			SELECT @RecordID = MIN(RowID) FROM #FailureAnalysis WITH(NOLOCK) WHERE RowID > @RecordID --AND Measurement <> 'Total'
		END
	
		--EXECUTE('UPDATE #FailureAnalysis SET [' + @BatchUnitNumber + '] = result.summary 
		--		FROM (SELECT SUM([' + @BatchUnitNumber + ']) AS Summary FROM #FailureAnalysis WHERE Measurement <> ''Total'' ) result WHERE Measurement=''Total''')
		
		SELECT @RowID = MIN(RowID) FROM #units WHERE RowID > @RowID
	END

	SET @Row = (SELECT '[' + Cast(BatchUnitNumber AS VARCHAR(MAX)) + '] + ' FROM #units FOR XML PATH(''))
	SET @Row = SUBSTRING(@Row, 0, LEN(@Row)-1)

	--SET @SQL = 'SELECT Measurement, [Parameters], TestStageName, ResultMeasurementID, TestStageID, ' + REPLACE(@Row, '+',',') + ', SUM(' + @Row + ') AS Total FROM #FailureAnalysis GROUP BY Measurement, [Parameters], TestStageName, ResultMeasurementID, TestStageID, ' + REPLACE(@Row, '+',',') + ' ORDER BY Measurement, [Parameters], TestStageName '
	SET @SQL = 'SELECT Measurement, [Parameters], TestStageName AS Stage, ResultMeasurementID, TestStageID, ' + REPLACE(@Row, '+',',') + ' FROM #FailureAnalysis GROUP BY Measurement, [Parameters], TestStageName, ResultMeasurementID, TestStageID, ' + REPLACE(@Row, '+',',') + ' ORDER BY Measurement, [Parameters], TestStageName '
	
	EXECUTE (@SQL)

	DROP TABLE #FailureAnalysis
	DROP TABLE #units

	SET NOCOUNT OFF
END
GO
GRANT EXECUTE ON [Relab].[remispResultsFailureAnalysis] TO Remi
GO