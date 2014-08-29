begin tran
go
ALTER PROCEDURE [Relab].[remispResultsFailureAnalysis] @TestID INT, @BatchID INT
AS
BEGIN
	SET NOCOUNT ON

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
	WHERE r.TestID=@TestID AND tu.BatchID=@BatchID AND r.PassFail=0
	ORDER BY Measurement, [Parameters]
	
	UPDATE #FailureAnalysis SET ResultMeasurementID = (
				SELECT TOP 1 rm.ID 
				FROM Relab.Results r 
					INNER JOIN Relab.ResultsMeasurements rm WITH(NOLOCK) ON rm.ResultID=r.ID AND rm.PassFail=0 AND rm.Archived=0
					INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID=r.TestUnitID
				WHERE #FailureAnalysis.TestStageID=r.TestStageID AND #FailureAnalysis.MeasurementID=rm.MeasurementTypeID
					AND r.TestID=@TestID AND tu.BatchID=@BatchID AND r.PassFail=0
				)

	INSERT INTO #FailureAnalysis (MeasurementID, Measurement, [Parameters], TestStageID, TestStageName)
	SELECT 0, 'Total', '', 0, ''	

	SELECT @RowID = MIN(RowID) FROM #units WITH(NOLOCK)

	WHILE (@RowID IS NOT NULL)
	BEGIN
		SELECT @BatchUnitNumber=BatchUnitNumber, @TestUnitID = ID FROM #units WHERE RowID=@RowID
		SET @COUNT = 0
	
		EXECUTE ('ALTER TABLE #FailureAnalysis ADD [' + @BatchUnitNumber + '] INT NULL ')
	
		SELECT @RecordID = MIN(RowID) FROM #FailureAnalysis WITH(NOLOCK) WHERE Measurement <> 'Total'
	
		WHILE (@RecordID IS NOT NULL)
		BEGIN
			SET @ResultMeasurementID = 0
			SET @SQL = '' 
			SET @SQL2 = ''
			SELECT @MeasurementID = MeasurementID, @TestStageID = TestStageID, @Parameters= [Parameters] FROM #FailureAnalysis WHERE RowID=@RecordID
	
			SELECT @COUNT = COUNT(DISTINCT r.ID)
			FROM Relab.Results r WITH(NOLOCK)
				INNER JOIN Relab.ResultsMeasurements rm WITH(NOLOCK) ON rm.ResultID=r.ID AND rm.PassFail=0 AND rm.Archived=0
			WHERE r.TestID=@TestID AND r.TestUnitID=@TestUnitID AND r.PassFail=0
				AND r.TestStageID=@TestStageID AND rm.MeasurementTypeID=@MeasurementID AND ISNULL(Relab.ResultsParametersComma(rm.ID), '') = @Parameters
				
			SET @SQL = 'UPDATE #FailureAnalysis SET [' + CONVERT(VARCHAR, @BatchUnitNumber) + '] = ' + CONVERT(VARCHAR, ISNULL(@Count, 0)) + ' WHERE TestStageID = ' + CONVERT(VARCHAR, @TestStageID) + ' AND MeasurementID = ' + CONVERT(VARCHAR, @MeasurementID) + ' AND LTRIM(RTRIM(Parameters)) = '
			SET @SQL2 = ' LTRIM(RTRIM(''' + CONVERT(NVARCHAR(MAX), @Parameters) + '''))'
			EXECUTE (@SQL + @SQL2)			
			
			SELECT @RecordID = MIN(RowID) FROM #FailureAnalysis WITH(NOLOCK) WHERE RowID > @RecordID AND Measurement <> 'Total'
		END
	
		EXECUTE('UPDATE #FailureAnalysis SET [' + @BatchUnitNumber + '] = result.summary 
				FROM (SELECT SUM([' + @BatchUnitNumber + ']) AS Summary FROM #FailureAnalysis WHERE Measurement <> ''Total'' ) result WHERE Measurement=''Total''')
		
		SELECT @RowID = MIN(RowID) FROM #units WHERE RowID > @RowID
	END

	SET @Row = (SELECT '[' + Cast(BatchUnitNumber AS VARCHAR(MAX)) + '] + ' FROM #units FOR XML PATH(''))
	SET @Row = SUBSTRING(@Row, 0, LEN(@Row)-1)

	SET @SQL = 'SELECT Measurement, [Parameters], TestStageName, ResultMeasurementID, TestStageID, ' + REPLACE(@Row, '+',',') + ', SUM(' + @Row + ') AS Total FROM #FailureAnalysis GROUP BY Measurement, [Parameters], TestStageName, ResultMeasurementID, TestStageID, ' + REPLACE(@Row, '+',',') + ' ORDER BY Measurement, [Parameters], TestStageName '

	EXECUTE (@SQL)

	DROP TABLE #FailureAnalysis
	DROP TABLE #units

	SET NOCOUNT OFF
END
GO
GRANT EXECUTE ON [Relab].[remispResultsFailureAnalysis] TO Remi
GO
ALTER PROCEDURE Relab.remispResultsGraph @MeasurementTypeID INT, @batchIDs NVARCHAR(MAX), @UnitIDs NVARCHAR(MAX), @TestID INT, @ParameterName NVARCHAR(255)=NULL, @ParameterValue NVARCHAR(250)=NULL, @ShowUpperLowerLimits INT = 1, @Xaxis INT, @PlotValue INT, @IncludeArchived INT = 0, @Stages NVARCHAR(MAX)
AS
BEGIN
	DECLARE @COUNT INT
	DECLARE @LoopValue NVARCHAR(500)
	DECLARE @ID INT
	DECLARE @query VARCHAR(MAX)
	DECLARE @query2 VARCHAR(MAX)
	CREATE TABLE #batches (id INT)
	CREATE TABLE #units (id INT)
	CREATE TABLE #stages (id INT)
	CREATE TABLE #Graph (RowID INT, YAxis NVARCHAR(500), XAxis NVARCHAR(500), LoopValue NVARCHAR(500), LowerLimit NVARCHAR(255), UpperLimit NVARCHAR(255), QRANumber NVARCHAR(11))
	EXEC (@batchIDs)
	EXEC (@UnitIDs)
	EXEC (@Stages)
	SET @query = ''	
	SET @query2 = ''
	SELECT @COUNT = COUNT(*) FROM #batches
	
	/*@Xaxis
	Units: 0
	Stages: 1
	Parameter: 2
	*/
	/*@PlotValue
	Units: 0
	Stages: 1
	*/

	IF (@Xaxis=0)
	BEGIN
		SET @query = 'INSERT INTO #Graph SELECT ROW_NUMBER() OVER (ORDER BY rm.MeasurementValue) AS RowID, rm.MeasurementValue AS YAxis, 
		CASE WHEN '''+ ISNULL(@ParameterName,'')+''' = '''' THEN CONVERT(VARCHAR,tu.BatchUnitNumber) 
		WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN CONVERT(VARCHAR,tu.BatchUnitNumber) 
		ELSE CONVERT(VARCHAR,tu.BatchUnitNumber) +'': '' + Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' = '''' THEN ''V'' ELSE ''N'' END) END AS XAxis, 
		' + CASE WHEN @IncludeArchived = 1 THEN ' CASE WHEN ' + CONVERT(VARCHAR, @COUNT) + ' > 1 THEN Batches.QRANumber + '' '' ELSE '''' END + SUBSTRING(j.JobName, 0, CHARINDEX('' '', j.Jobname, 0)) + '' '' + ts.TestStageName + convert(varchar,rm.ReTestNum) ' 
		ELSE ' CASE WHEN ' + CONVERT(VARCHAR, @COUNT) + ' > 1 THEN Batches.QRANumber + '' '' ELSE '''' END + SUBSTRING(j.JobName, 0, CHARINDEX('' '', j.Jobname, 0)) + '' '' + ts.TestStageName ' END + ' AS LoopValue, 
		rm.LowerLimit, rm.UpperLimit, Batches.QRANumber '
	END
	ELSE IF (@Xaxis=1)
	BEGIN
		SET @query = 'INSERT INTO #Graph SELECT ROW_NUMBER() OVER (ORDER BY rm.MeasurementValue) AS RowID, rm.MeasurementValue AS YAxis, 
		CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN SUBSTRING(j.JobName, 0, CHARINDEX('' '', j.Jobname, 0)) + '' '' + CONVERT(VARCHAR,ts.TestStageName) ELSE SUBSTRING(j.JobName, 0, CHARINDEX('' '', j.Jobname, 0)) + '' '' + CONVERT(VARCHAR,ts.TestStageName) +'': '' + Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' = '''' THEN ''V'' ELSE ''N'' END) END AS XAxis, 
		' + CASE WHEN @IncludeArchived = 1 THEN ' convert(varchar,tu.BatchUnitNumber) + convert(varchar,rm.ReTestNum) ' ELSE ' convert(varchar,tu.BatchUnitNumber) ' END + ' AS LoopValue, 
		rm.LowerLimit, rm.UpperLimit, Batches.QRANumber '
	END
	ELSE IF (@Xaxis=2 AND @PlotValue = 1)
	BEGIN
		SET @query = 'INSERT INTO #Graph SELECT ROW_NUMBER() OVER (ORDER BY rm.MeasurementValue) AS RowID, rm.MeasurementValue AS YAxis,
		SUBSTRING(j.JobName, 0, CHARINDEX('' '', j.Jobname, 0)) + '' '' + ts.TestStageName + '':'' + CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN ''V'' ELSE ''N'' END) 
		ELSE Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN ''V'' ELSE ''N'' END) +'': '' + Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' = '''' THEN ''V'' ELSE ''N'' END) END AS XAxis, 
		' + CASE WHEN @IncludeArchived = 1 THEN ' tu.BatchUnitNumber + convert(varchar,rm.ReTestNum) ' ELSE ' tu.BatchUnitNumber ' END + ' AS LoopValue, 
		rm.LowerLimit, rm.UpperLimit, Batches.QRANumber '
	END
	ELSE IF (@Xaxis=2 AND @PlotValue = 0)
	BEGIN
		SET @query = 'INSERT INTO #Graph SELECT ROW_NUMBER() OVER (ORDER BY rm.MeasurementValue) AS RowID, rm.MeasurementValue AS YAxis, 
			convert(varchar,tu.BatchUnitNumber) + '': '' + Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN ''V'' ELSE ''N'' END) AS XAxis, 
			' + CASE WHEN @IncludeArchived = 1 THEN ' SUBSTRING(j.JobName, 0, CHARINDEX('' '', j.Jobname, 0)) + '' '' + ts.TestStageName + convert(varchar,rm.ReTestNum) ' ELSE ' SUBSTRING(j.JobName, 0, CHARINDEX('' '', j.Jobname, 0)) + '' '' + ts.TestStageName ' END + ' AS LoopValue, 
			rm.LowerLimit, rm.UpperLimit, Batches.QRANumber '
	END
	
	SET @query += 'FROM Relab.Results r WITH(NOLOCK)
		INNER JOIN #units u WITH(NOLOCK) ON u.id=r.TestUnitID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON u.ID=tu.ID
		INNER JOIN Relab.ResultsMeasurements rm WITH(NOLOCK) ON r.ID=rm.ResultID
		INNER JOIN #batches b WITH(NOLOCK) ON tu.batchID=b.ID
		INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
		INNER JOIN #stages s WITH(NOLOCK) ON s.ID = ts.ID
		INNER JOIN Batches ON Batches.ID=b.ID
		INNER JOIN Jobs j ON j.ID=ts.JobID
	WHERE rm.MeasurementTypeID='+CONVERT(VARCHAR,@MeasurementTypeID)+' AND r.TestID='+CONVERT(VARCHAR,@TestID)+' AND MeasurementValue IS NOT NULL '
	
	IF (@Xaxis=2)
		BEGIN
			IF (@ParameterName IS NOT NULL)
				SET @query2 = ' AND (Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterName,'')+''' <> '''' THEN ''N'' ELSE ''V'' END)='''+ ISNULL(@ParameterName,'')+''') '
			
			IF (@ParameterValue IS NOT NULL)
				SET @query2 = ' AND (Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN ''V'' ELSE ''N'' END)='''+ ISNULL(@ParameterValue,'')+''') '
		END
	ELSE
		BEGIN
			IF (@ParameterName IS NOT NULL)
				SET @query2 = ' AND (Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterName,'')+''' <> '''' THEN ''N'' ELSE ''V'' END)='''+ ISNULL(@ParameterName,'')+''') '
			IF (@ParameterValue IS NOT NULL)
				SET @query2 = ' AND (Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN ''V'' ELSE ''N'' END)='''+ ISNULL(@ParameterValue,'')+''') '
		END

	SET @query2 += ' AND (' + CONVERT(varchar, @IncludeArchived) + ' = 1 OR (' + CONVERT(varchar, @IncludeArchived) + ' = 0 AND ISNULL(rm.Archived,0)=0)) 
	ORDER BY LoopValue'
	
	print @query
	print @query2
	
	EXEC(@query + @query2)
	
	UPDATE #Graph SET YAxis=1 WHERE YAxis IN ('True','Pass')
	UPDATE #Graph SET YAxis=0 WHERE YAxis IN ('Fail','False')
		
	select UpperLimit, LowerLimit, COUNT(*) as va
	into #GraphLimits
	FROM #Graph
	GROUP BY UpperLimit, LowerLimit
			
	IF (@@ROWCOUNT = 1)
	BEGIN
		IF (@ShowUpperLowerLimits = 1)
		BEGIN
			IF ((SELECT COUNT(*) FROM #Graph WHERE LowerLimit IS NOT NULL AND ISNUMERIC(LowerLimit)=1 AND LoopValue = (SELECT MIN(LoopValue) FROM #Graph)) > 0)
			BEGIN
				SELECT DISTINCT ROUND(Lowerlimit, 3) AS YAxis, XAxis, (LoopValue + ' Lower Specification Limit') AS LoopValue 
				FROM #Graph
				WHERE LowerLimit IS NOT NULL AND ISNUMERIC(LowerLimit)=1 AND LoopValue = (SELECT MIN(LoopValue) FROM #Graph)
			END
			
			IF ((SELECT COUNT(*) FROM #Graph WHERE Upperlimit IS NOT NULL AND ISNUMERIC(Upperlimit)=1 AND LoopValue = (SELECT MIN(LoopValue) FROM #Graph)) > 0)
			BEGIN
				SELECT DISTINCT ROUND(Upperlimit, 3) AS YAxis, XAxis, (LoopValue + ' Upper Specification Limit') AS LoopValue 
				FROM #Graph
				WHERE Upperlimit IS NOT NULL AND ISNUMERIC(Upperlimit)=1 AND LoopValue = (SELECT MIN(LoopValue) FROM #Graph)
			END
		END	
	END
	
	DECLARE select_cursor CURSOR FOR SELECT DISTINCT LoopValue FROM #Graph
	OPEN select_cursor

	FETCH NEXT FROM select_cursor INTO @LoopValue

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT DISTINCT ROUND(YAxis, 3) AS YAxis, XAxis, LoopValue, LowerLimit, UpperLimit, QRANumber
		FROM #Graph 
		WHERE LoopValue=@LoopValue AND ISNUMERIC(YAxis)=1 
		ORDER BY 2
		
		FETCH NEXT FROM select_cursor INTO @LoopValue
	END
	
	CLOSE select_cursor
	DEALLOCATE select_cursor
	
	DROP TABLE #Graph
	DROP TABLE #batches
	DROP TABLE #units
	DROP TABLE #stages
	DROP TABLE #GraphLimits
END
GO
GRANT EXECUTE ON Relab.remispResultsGraph TO REMI
GO
ALTER PROCEDURE Relab.remispGetUnitsByTestMeasurementParameters @BatchIDs NVARCHAR(MAX), @TestID INT, @MeasurementTypeID INT, @ParameterName NVARCHAR(255)=null, @ParameterValue NVARCHAR(255)=null, @GetStages BIT = 0, @ShowOnlyFailValue INT = 0
AS
BEGIN
	CREATE Table #batches(id int) 
	DECLARE @Count INT
	EXEC(@BatchIDs)
	
	SELECT DISTINCT CASE WHEN @GetStages = 1 THEN ts.ID ELSE tu.ID END AS ID, tu.BatchID, CASE WHEN @GetStages = 1 THEN SUBSTRING(j.JobName, 0, CHARINDEX(' ', j.Jobname, 0)) + ' ' + ts.TestStageName ELSE CONVERT(VARCHAR, tu.batchUnitNumber) END AS Name, Batches.QRANumber
	FROM TestUnits tu WITH(NOLOCK)
		INNER JOIN Relab.Results r WITH(NOLOCK) ON r.TestUnitID=tu.ID
		INNER JOIN Relab.ResultsMeasurements m WITH(NOLOCK) on m.ResultID=r.ID 
		LEFT OUTER JOIN Relab.ResultsParameters p WITH(NOLOCK) ON m.ID=p.ResultMeasurementID
		INNER JOIN #batches b WITH(NOLOCK) ON tu.BatchID=b.ID
		INNER JOIN TestStages ts ON ts.ID = r.TestStageID
		INNER JOIN Jobs j ON j.ID=ts.JobID
		INNER JOIN Batches ON b.id = Batches.ID
	WHERE m.MeasurementTypeID=@MeasurementTypeID AND r.TestID=@TestID AND m.Archived=0		
		AND 
		(
			(@ParameterName IS NOT NULL AND Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN @ParameterName IS NOT NULL THEN 'N' ELSE 'V' END)=@ParameterName
				AND 
				(
					(@ParameterValue IS NOT NULL AND  Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN @ParameterValue IS NOT NULL THEN 'V' ELSE 'N' END)=@ParameterValue) 
					OR 
					(@ParameterValue IS NULL)
				)
			) 
			OR 
			(@ParameterName IS NULL)
		)
		AND
		(
			(@ShowOnlyFailValue = 1 AND m.PassFail=0)
			OR
			(@ShowOnlyFailValue = 0)
		)
	GROUP BY CASE WHEN @GetStages = 1 THEN ts.ID ELSE tu.ID END, tu.BatchID, CASE WHEN @GetStages = 1 THEN SUBSTRING(j.JobName, 0, CHARINDEX(' ', j.Jobname, 0)) + ' ' + ts.TestStageName ELSE CONVERT(VARCHAR, tu.batchUnitNumber) END, Batches.QRANumber
	
	DROP TABLE #batches
END
GO
GRANT EXECUTE ON Relab.remispGetUnitsByTestMeasurementParameters TO REMI
GO
rollback tran