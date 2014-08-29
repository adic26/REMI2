begin tran
go
ALTER PROCEDURE Relab.remispGetUnitsByTestMeasurementParameters @BatchIDs NVARCHAR(MAX), @TestID INT, @MeasurementTypeID INT, @ParameterName NVARCHAR(255)=null, @ParameterValue NVARCHAR(255)=null, @GetStages BIT = 0, @ShowOnlyFailValue INT = 0
AS
BEGIN
	CREATE Table #batches(id int) 
	DECLARE @Count INT
	EXEC(@BatchIDs)
	
	SELECT DISTINCT CASE WHEN @GetStages = 1 THEN ts.ID ELSE tu.batchUnitNumber END AS ID, tu.BatchID, CASE WHEN @GetStages = 1 THEN ts.TestStageName ELSE CONVERT(VARCHAR, tu.batchUnitNumber) END AS Name
	FROM TestUnits tu WITH(NOLOCK)
		INNER JOIN Relab.Results r WITH(NOLOCK) ON r.TestUnitID=tu.ID
		INNER JOIN Relab.ResultsMeasurements m WITH(NOLOCK) on m.ResultID=r.ID 
		LEFT OUTER JOIN Relab.ResultsParameters p WITH(NOLOCK) ON m.ID=p.ResultMeasurementID
		INNER JOIN #batches b WITH(NOLOCK) ON tu.BatchID=b.ID
		INNER JOIN TestStages ts ON ts.ID = r.TestStageID
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
	GROUP BY CASE WHEN @GetStages = 1 THEN ts.ID ELSE tu.batchUnitNumber END, tu.BatchID, CASE WHEN @GetStages = 1 THEN ts.TestStageName ELSE CONVERT(VARCHAR, tu.batchUnitNumber) END
	
	DROP TABLE #batches
END
GO
GRANT EXECUTE ON Relab.remispGetUnitsByTestMeasurementParameters TO REMI
GO
ALTER PROCEDURE Relab.remispResultsGraph @MeasurementTypeID INT, @batchIDs NVARCHAR(MAX), @UnitIDs NVARCHAR(MAX), @TestID INT, @ParameterName NVARCHAR(255)=NULL, @ParameterValue NVARCHAR(250)=NULL, @ShowUpperLowerLimits INT = 1, @Xaxis INT, @PlotValue INT, @IncludeArchived INT = 0, @Stages NVARCHAR(MAX)
AS
BEGIN
	DECLARE @LoopValue NVARCHAR(500)
	DECLARE @ID INT
	DECLARE @query VARCHAR(MAX)
	DECLARE @query2 VARCHAR(MAX)
	CREATE TABLE #batches (id INT)
	CREATE TABLE #units (id INT)
	CREATE TABLE #stages (id INT)
	CREATE TABLE #Graph (RowID INT, YAxis NVARCHAR(500), XAxis NVARCHAR(500), LoopValue NVARCHAR(500), LowerLimit NVARCHAR(255), UpperLimit NVARCHAR(255))
	EXEC (@batchIDs)
	EXEC (@UnitIDs)
	EXEC (@Stages)
	SET @query = ''	
	SET @query2 = ''
	
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
		CASE WHEN '''+ ISNULL(@ParameterName,'')+''' = '''' THEN CONVERT(VARCHAR,tu.BatchUnitNumber) WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN CONVERT(VARCHAR,tu.BatchUnitNumber) ELSE CONVERT(VARCHAR,tu.BatchUnitNumber) +'': '' + Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' = '''' THEN ''V'' ELSE ''N'' END) END AS XAxis, 
		' + CASE WHEN @IncludeArchived = 1 THEN ' ts.TestStageName + convert(varchar,rm.ReTestNum) ' ELSE ' ts.TestStageName ' END + ' AS LoopValue, rm.LowerLimit, rm.UpperLimit '		
	END
	ELSE IF (@Xaxis=1)
	BEGIN
		SET @query = 'INSERT INTO #Graph SELECT ROW_NUMBER() OVER (ORDER BY rm.MeasurementValue) AS RowID, rm.MeasurementValue AS YAxis, 
		CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN CONVERT(VARCHAR,ts.TestStageName) ELSE CONVERT(VARCHAR,ts.TestStageName) +'': '' + Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' = '''' THEN ''V'' ELSE ''N'' END) END AS XAxis, 
		' + CASE WHEN @IncludeArchived = 1 THEN ' tu.BatchUnitNumber + convert(varchar,rm.ReTestNum) ' ELSE ' tu.BatchUnitNumber ' END + ' AS LoopValue, rm.LowerLimit, rm.UpperLimit '		
	END
	ELSE IF (@Xaxis=2 AND @PlotValue = 1)
	BEGIN
		SET @query = 'INSERT INTO #Graph SELECT ROW_NUMBER() OVER (ORDER BY rm.MeasurementValue) AS RowID, rm.MeasurementValue AS YAxis,
		ts.TestStageName + '':'' + CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN ''V'' ELSE ''N'' END) ELSE Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN ''V'' ELSE ''N'' END) +'': '' + Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' = '''' THEN ''V'' ELSE ''N'' END) END AS XAxis, 
		' + CASE WHEN @IncludeArchived = 1 THEN ' tu.BatchUnitNumber + convert(varchar,rm.ReTestNum) ' ELSE ' tu.BatchUnitNumber ' END + ' AS LoopValue, rm.LowerLimit, rm.UpperLimit '
	END
	ELSE IF (@Xaxis=2 AND @PlotValue = 0)
	BEGIN
		SET @query = 'INSERT INTO #Graph SELECT ROW_NUMBER() OVER (ORDER BY rm.MeasurementValue) AS RowID, rm.MeasurementValue AS YAxis, 
			convert(varchar,tu.BatchUnitNumber) + '': '' + Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN ''V'' ELSE ''N'' END) AS XAxis, 
			' + CASE WHEN @IncludeArchived = 1 THEN ' ts.TestStageName + convert(varchar,rm.ReTestNum) ' ELSE ' ts.TestStageName ' END + ' AS LoopValue, rm.LowerLimit, rm.UpperLimit '
	END
	
	SET @query += 'FROM Relab.Results r WITH(NOLOCK)
		INNER JOIN TestUnits tu WITH(NOLOCK) ON r.TestUnitID=tu.ID
		INNER JOIN Relab.ResultsMeasurements rm WITH(NOLOCK) ON r.ID=rm.ResultID
		INNER JOIN #batches b WITH(NOLOCK) ON tu.batchID=b.ID
		INNER JOIN #units u WITH(NOLOCK) ON u.id=tu.BatchUnitNumber
		INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
		INNER JOIN #stages s WITH(NOLOCK) ON s.ID = ts.ID
		LEFT OUTER JOIN Relab.ResultsParameters p ON p.ResultMeasurementID=rm.ID
	WHERE rm.MeasurementTypeID='+CONVERT(VARCHAR,@MeasurementTypeID)+' AND r.TestID='+CONVERT(VARCHAR,@TestID)+' AND MeasurementValue IS NOT NULL '
	
	IF (@Xaxis=2)
		BEGIN
			IF (@ParameterName IS NOT NULL)
				SET @query2 = ' AND (Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN '''+ ISNULL(@ParameterName,'')+''' <> '''' THEN ''N'' ELSE ''V'' END)='''+ ISNULL(@ParameterName,'')+''') '
			
			IF (@ParameterValue IS NOT NULL)
				SET @query2 = ' AND (Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN ''V'' ELSE ''N'' END)='''+ ISNULL(@ParameterValue,'')+''') '
		END
	ELSE
		BEGIN
			IF (@ParameterName IS NOT NULL)
				SET @query2 = ' AND (Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN '''+ ISNULL(@ParameterName,'')+''' <> '''' THEN ''N'' ELSE ''V'' END)='''+ ISNULL(@ParameterName,'')+''') '
			IF (@ParameterValue IS NOT NULL)
				SET @query2 = ' AND (Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN ''V'' ELSE ''N'' END)='''+ ISNULL(@ParameterValue,'')+''') '
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
			UPDATE #Graph SET LowerLimit = 0 WHERE LTRIM(RTRIM(LowerLimit))='N/A'
			UPDATE #Graph SET Upperlimit = 0 WHERE LTRIM(RTRIM(Upperlimit))='N/A'

			SELECT DISTINCT ROUND(Lowerlimit, 3) AS YAxis, XAxis, (LoopValue + ' Lower Specification Limit') AS LoopValue 
			FROM #Graph
			WHERE LowerLimit IS NOT NULL AND ISNUMERIC(LowerLimit)=1 AND LoopValue = (SELECT MIN(LoopValue) FROM #Graph)
			
			SELECT DISTINCT ROUND(Upperlimit, 3) AS YAxis, XAxis, (LoopValue + ' Upper Specification Limit') AS LoopValue 
			FROM #Graph
			WHERE Upperlimit IS NOT NULL AND ISNUMERIC(Upperlimit)=1 AND LoopValue = (SELECT MIN(LoopValue) FROM #Graph)
		END	
	END
	
	DECLARE select_cursor CURSOR FOR SELECT DISTINCT LoopValue FROM #Graph
	OPEN select_cursor

	FETCH NEXT FROM select_cursor INTO @LoopValue

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT DISTINCT ROUND(YAxis, 3) AS YAxis, XAxis, LoopValue, LowerLimit, UpperLimit FROM #Graph WHERE LoopValue=@LoopValue AND ISNUMERIC(YAxis)=1 ORDER BY 2
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
alter PROCEDURE Relab.remispGetParametersByMeasurementTest @BatchIDs NVARCHAR(MAX), @TestID INT, @MeasurementTypeID INT, @ParameterName NVARCHAR(255) = NULL, @ShowOnlyFailValue INT = 0
AS
BEGIN
	CREATE Table #batches(id int) 
	DECLARE @Count INT
	EXEC(@BatchIDs)
	
	SELECT @Count = COUNT(*) FROM #batches

	IF (@Count = 0)
	BEGIN
		SELECT DISTINCT Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN @ParameterName IS NOT NULL THEN 'V' ELSE 'N' END) AS ParameterName
			FROM TestUnits tu WITH(NOLOCK)
				INNER JOIN Relab.Results r WITH(NOLOCK) ON r.TestUnitID=tu.ID
				INNER JOIN Relab.ResultsMeasurements m WITH(NOLOCK) on m.ResultID=r.ID 
				INNER JOIN Relab.ResultsParameters p WITH(NOLOCK) ON m.ID=p.ResultMeasurementID
			WHERE m.MeasurementTypeID=@MeasurementTypeID AND r.TestID=@TestID AND m.Archived=0
				AND 
				(
					(@ParameterName IS NOT NULL AND Relab.ResultsParametersNameComma(p.ResultMeasurementID, 
													CASE WHEN @ParameterName IS NOT NULL THEN 'N' ELSE 'V' END)=@ParameterName
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
			GROUP BY p.ResultMeasurementID
	END
	ELSE
		BEGIN	
			SELECT DISTINCT Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN @ParameterName IS NOT NULL THEN 'V' ELSE 'N' END) AS ParameterName
			FROM TestUnits tu WITH(NOLOCK)
				INNER JOIN Relab.Results r WITH(NOLOCK) ON r.TestUnitID=tu.ID
				INNER JOIN Relab.ResultsMeasurements m WITH(NOLOCK) on m.ResultID=r.ID 
				INNER JOIN Relab.ResultsParameters p WITH(NOLOCK) ON m.ID=p.ResultMeasurementID
				INNER JOIN #batches b WITH(NOLOCK) ON tu.BatchID=b.ID
			WHERE m.MeasurementTypeID=@MeasurementTypeID AND r.TestID=@TestID AND m.Archived=0
				AND 
				(
					(@ParameterName IS NOT NULL AND Relab.ResultsParametersNameComma(p.ResultMeasurementID, 
													CASE WHEN @ParameterName IS NOT NULL THEN 'N' ELSE 'V' END)=@ParameterName
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
			GROUP BY p.ResultMeasurementID
			HAVING COUNT(DISTINCT b.ID) >= @Count
		END

	DROP TABLE #batches
END
GO
GRANT EXECUTE ON Relab.remispGetParametersByMeasurementTest TO REMI
GO
ALTER PROCEDURE Relab.remispGetMeasurementsByTest @BatchIDs NVARCHAR(MAX), @TestID INT, @ShowOnlyFailValue INT = 0
AS
BEGIN
	CREATE Table #batches(id int) 
	DECLARE @Count INT
	EXEC(@BatchIDs)
	
	SELECT @Count = COUNT(*) FROM #batches
	
	SELECT DISTINCT m.MeasurementTypeID, Lookups.[Values] As Measurement
	FROM TestUnits tu WITH(NOLOCK)
		INNER JOIN Relab.Results r WITH(NOLOCK) ON r.TestUnitID=tu.ID
		INNER JOIN Relab.ResultsMeasurements m WITH(NOLOCK) on m.ResultID=r.ID 
		INNER JOIN Lookups WITH(NOLOCK) ON m.MeasurementTypeID=Lookups.LookupID
		INNER JOIN #batches b WITH(NOLOCK) ON tu.BatchID=b.ID
	WHERE r.TestID=@TestID AND 
		(
			ISNUMERIC(m.MeasurementValue)=1 OR LOWER(m.MeasurementValue) IN ('true', 'pass', 'fail', 'false')
		)
		AND
		(
			(@ShowOnlyFailValue = 1 AND m.PassFail=0)
			OR
			(@ShowOnlyFailValue = 0)
		)
	GROUP BY m.MeasurementTypeID, Lookups.[Values]
	HAVING COUNT(DISTINCT b.ID) >= @Count
	
	DROP TABLE #batches
END
GO
GRANT EXECUTE ON Relab.remispGetMeasurementsByTest TO REMI
GO
create PROCEDURE Relab.remispResultsSearch @MeasurementTypeID INT, @TestID INT, @ParameterName NVARCHAR(255)=NULL, @ParameterValue NVARCHAR(250)=NULL
AS
BEGIN
	DECLARE @LoopValue NVARCHAR(500)
	DECLARE @ID INT
	DECLARE @query VARCHAR(MAX)
	DECLARE @query2 VARCHAR(MAX)
	SET @query = ''	
	SET @query2 = ''
	
	SET @query = 'SELECT b.QRANumber, tu.BatchUnitNumber, ts.TestStageName AS TestStageName, rm.MeasurementValue AS MeasurementValue, rm.LowerLimit, rm.UpperLimit
	FROM Relab.Results r WITH(NOLOCK)
		INNER JOIN TestUnits tu WITH(NOLOCK) ON r.TestUnitID=tu.ID
		INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID
		INNER JOIN Relab.ResultsMeasurements rm WITH(NOLOCK) ON r.ID=rm.ResultID
		INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
		LEFT OUTER JOIN Relab.ResultsParameters p ON p.ResultMeasurementID=rm.ID
	WHERE rm.MeasurementTypeID='+CONVERT(VARCHAR,@MeasurementTypeID)+' AND r.TestID='+CONVERT(VARCHAR,@TestID)+' AND MeasurementValue IS NOT NULL '

	IF (@ParameterName IS NOT NULL)
		SET @query2 = ' AND (Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN '''+ ISNULL(@ParameterName,'')+''' <> '''' THEN ''N'' ELSE ''V'' END)='''+ ISNULL(@ParameterName,'')+''') '
	IF (@ParameterValue IS NOT NULL)
		SET @query2 = ' AND (Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN ''V'' ELSE ''N'' END)='''+ ISNULL(@ParameterValue,'')+''') '


	SET @query2 += ' AND ISNULL(rm.Archived,0)=0 AND rm.PassFail=0
	ORDER BY QRANumber, BatchUnitNumber, TestStageName'
	
	print @query
	print @query2
	
	EXEC(@query + @query2)
END
GO
GRANT EXECUTE ON Relab.remispResultsSearch TO REMI
GO
rollback tran
