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
	CREATE TABLE #Graph (YAxis NVARCHAR(500), XAxis NVARCHAR(500), LoopValue NVARCHAR(500), LowerLimit NVARCHAR(255), UpperLimit NVARCHAR(255), QRANumber NVARCHAR(11), paramName NVARCHAR(500), paramValue NVARCHAR(500), BatchUnitNumber INT, ReTestNum INT, paramValueNumeric INT)
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
		SET @query = 'INSERT INTO #Graph SELECT rm.MeasurementValue AS YAxis, 
		CASE WHEN ('''+ ISNULL(@ParameterValue,'')+''' = '''' And '''+ ISNULL(@ParameterName,'')+''' = '''') OR ('''+ ISNULL(@ParameterValue,'')+''' <> '''') THEN CONVERT(VARCHAR, tu.BatchUnitNumber) 
		WHEN ('''+ ISNULL(@ParameterValue,'')+''' = '''' And '''+ ISNULL(@ParameterName,'')+''' <> '''') THEN Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' = '''' THEN ''V'' ELSE ''N'' END) + '': '' + Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN ''V'' ELSE ''N'' END)
		ELSE ISNULL(Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN ''N'' ELSE ''V'' END), '''') + '': '' + ISNULL(Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' = '''' THEN ''V'' ELSE ''N'' END), '''') END AS XAxis, 
		CASE WHEN ' + CONVERT(VARCHAR, @COUNT) + ' > 1 THEN Batches.QRANumber + '' '' ELSE '''' END + SUBSTRING(j.JobName, 0, CHARINDEX('' '', j.Jobname, 0)) + '' '' + ts.TestStageName + 
		' + CASE WHEN @IncludeArchived = 1 THEN ' + '' '' + convert(varchar,rm.ReTestNum) ' ELSE ' + '''' ' END + ' + 
		CASE WHEN ('''+ ISNULL(@ParameterValue,'')+''' = '''' And '''+ ISNULL(@ParameterName,'')+''' = '''') OR ('''+ ISNULL(@ParameterValue,'')+''' <> '''') THEN ''''
		WHEN ('''+ ISNULL(@ParameterValue,'')+''' = '''' And '''+ ISNULL(@ParameterName,'')+''' <> '''') THEN '' '' + CONVERT(VARCHAR, tu.BatchUnitNumber)
		ELSE '' '' + CONVERT(VARCHAR, tu.BatchUnitNumber) END AS LoopValue, 
		rm.LowerLimit, rm.UpperLimit, Batches.QRANumber, ISNULL(Relab.ResultsParametersNameComma(rm.ID, ''N''), '''') AS ParamName, ISNULL(Relab.ResultsParametersNameComma(rm.ID, ''V''), '''') AS ParamValue,
		tu.BatchUnitNumber, rm.ReTestNum, ISNUMERIC(ISNULL(Relab.ResultsParametersNameComma(rm.ID, ''V''), '''')) AS paramValueNumeric '
	END
	ELSE IF (@Xaxis=1)
	BEGIN
		SET @query = 'INSERT INTO #Graph SELECT rm.MeasurementValue AS YAxis, 
		SUBSTRING(j.JobName, 0, CHARINDEX('' '', j.Jobname, 0)) + '' '' + CONVERT(VARCHAR,ts.TestStageName) AS XAxis,
		
		CASE WHEN '''+ ISNULL(@ParameterName,'')+''' <> '''' AND '''+ ISNULL(@ParameterValue,'')+''' = '''' THEN
			ISNULL(Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' = '''' THEN ''N'' ELSE ''V'' END), '''') + '': '' + ISNULL(Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' = '''' THEN ''V'' ELSE ''N'' END), '''')
		ELSE '''' 
		END + 
		 '' Unit: '' + ' + CASE WHEN @IncludeArchived = 1 THEN ' convert(varchar,tu.BatchUnitNumber) + '' TestNum: '' + convert(varchar,rm.ReTestNum) ' ELSE ' convert(varchar,tu.BatchUnitNumber) ' END + ' AS LoopValue, 
		
		rm.LowerLimit, rm.UpperLimit, Batches.QRANumber, ISNULL(Relab.ResultsParametersNameComma(rm.ID, ''N''), '''') AS ParamName, ISNULL(Relab.ResultsParametersNameComma(rm.ID, ''V''), '''') AS ParamValue,
		tu.BatchUnitNumber, rm.ReTestNum, ISNUMERIC(ISNULL(Relab.ResultsParametersNameComma(rm.ID, ''V''), '''')) AS paramValueNumeric '
	END
	ELSE IF (@Xaxis=2 AND @PlotValue = 1)
	BEGIN
		SET @query = 'INSERT INTO #Graph SELECT rm.MeasurementValue AS YAxis,
		SUBSTRING(j.JobName, 0, CHARINDEX('' '', j.Jobname, 0)) + '' '' + ts.TestStageName + '':'' + CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN ''N'' ELSE ''V'' END) + '': '' + Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN ''V'' ELSE ''N'' END) 
		ELSE Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' = '''' THEN ''N'' ELSE ''V'' END) + '': '' + Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' = '''' THEN ''V'' ELSE ''N'' END) END AS XAxis,
		SUBSTRING(j.JobName, 0, CHARINDEX('' '', j.Jobname, 0)) + '' '' + ts.TestStageName + '' '' + ' + CASE WHEN @IncludeArchived = 1 THEN ' CONVERT(VARCHAR, tu.BatchUnitNumber) + '' '' + convert(varchar,rm.ReTestNum) ' ELSE ' CONVERT(varchar, tu.BatchUnitNumber) ' END + ' AS LoopValue,  
		rm.LowerLimit, rm.UpperLimit, Batches.QRANumber, ISNULL(Relab.ResultsParametersNameComma(rm.ID, ''N''), '''') AS ParamName, ISNULL(Relab.ResultsParametersNameComma(rm.ID, ''V''), '''') AS ParamValue,
		tu.BatchUnitNumber, rm.ReTestNum, ISNUMERIC(ISNULL(Relab.ResultsParametersNameComma(rm.ID, ''V''), '''')) AS paramValueNumeric '
	END
	ELSE IF (@Xaxis=2 AND @PlotValue = 0)
	BEGIN
		SET @query = 'INSERT INTO #Graph SELECT rm.MeasurementValue AS YAxis, 
		SUBSTRING(j.JobName, 0, CHARINDEX('' '', j.Jobname, 0)) + '':'' + CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN ''N'' ELSE ''V'' END) + '': '' + Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN ''V'' ELSE ''N'' END) 
		ELSE Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN ''V'' ELSE ''N'' END) +'': '' + Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' = '''' THEN ''V'' ELSE ''N'' END) END AS XAxis, 
		' + CASE WHEN @IncludeArchived = 1 THEN ' SUBSTRING(j.JobName, 0, CHARINDEX('' '', j.Jobname, 0)) + '' '' + ts.TestStageName + '' '' + CONVERT(VARCHAR, tu.BatchUnitNumber) + '' '' + convert(varchar,rm.ReTestNum) ' ELSE ' SUBSTRING(j.JobName, 0, CHARINDEX('' '', j.Jobname, 0)) + '' '' + ts.TestStageName + '' '' + CONVERT(VARCHAR, tu.BatchUnitNumber) ' END + ' AS LoopValue, 
		rm.LowerLimit, rm.UpperLimit, Batches.QRANumber, ISNULL(Relab.ResultsParametersNameComma(rm.ID, ''N''), '''') AS ParamName, ISNULL(Relab.ResultsParametersNameComma(rm.ID, ''V''), '''') AS ParamValue,
		tu.BatchUnitNumber, rm.ReTestNum, ISNUMERIC(ISNULL(Relab.ResultsParametersNameComma(rm.ID, ''V''), '''')) AS paramValueNumeric '
	END
	
	SET @query += 'FROM Relab.Results r WITH(NOLOCK)
		INNER JOIN #units u WITH(NOLOCK) ON u.id=r.TestUnitID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON u.ID=tu.ID
		INNER JOIN Relab.ResultsMeasurements rm WITH(NOLOCK) ON r.ID=rm.ResultID
		INNER JOIN #batches b WITH(NOLOCK) ON tu.batchID=b.ID
		INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID AND LTRIM(RTRIM(ts.TestStageName)) <> ''calibration'' 
		INNER JOIN #stages s WITH(NOLOCK) ON s.ID = ts.ID
		INNER JOIN Batches WITH(NOLOCK) ON Batches.ID=b.ID
		INNER JOIN Jobs j WITH(NOLOCK) ON j.ID=ts.JobID
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

	SET @query2 += ' AND (' + CONVERT(varchar, @IncludeArchived) + ' = 1 OR (' + CONVERT(varchar, @IncludeArchived) + ' = 0 AND ISNULL(rm.Archived,0)=0)) '
		
	print @query
	print @query2
	
	EXEC(@query + @query2)
	
	UPDATE #Graph SET YAxis=1 WHERE YAxis IN ('True','Pass')
	UPDATE #Graph SET YAxis=0 WHERE YAxis IN ('Fail','False')
	
	SELECT DISTINCT LoopValue, ParamValue, 0 AS Num, 0 AS IntParamValue
	INTO #tmp
	FROM #Graph

	UPDATE #tmp SET Num=ISNUMERIC(ParamValue)

	UPDATE #tmp SET IntParamValue=ISNULL(CASE WHEN Num=1 THEN CONVERT(REAL, ParamValue) END,0)
	
	alter table #tmp drop column num
	
	select * into #tmp2 from #tmp order by convert(int,0+IntParamValue)

	DECLARE @IntParamValue INT
	DECLARE @Val NVARCHAR(500)
	DECLARE select_cursor CURSOR FOR SELECT DISTINCT LoopValue FROM #tmp2
	OPEN select_cursor

	FETCH NEXT FROM select_cursor INTO @LoopValue

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT DISTINCT ROUND(YAxis, 3) AS YAxis, XAxis, g.LoopValue, LowerLimit, UpperLimit, QRANumber, CASE WHEN @ParameterValue <> '' THEN XAxis WHEN temp.IntParamValue=0 THEN XAxis END AS Val
		into #tmp3
		FROM #Graph g
			INNER JOIN #tmp2 temp ON temp.LoopValue=g.LoopValue
		WHERE g.LoopValue=@LoopValue AND ISNUMERIC(g.YAxis)=1
		ORDER BY CASE WHEN @ParameterValue <> '' THEN XAxis WHEN temp.IntParamValue=0 THEN XAxis END
		
		SELECT YAxis, XAxis, LoopValue, LowerLimit, UpperLimit, QRANumber FROM #tmp3
		DROP TABLE #tmp3
		FETCH NEXT FROM select_cursor INTO @LoopValue
	END
	
	CLOSE select_cursor
	DEALLOCATE select_cursor
	
	DECLARE @MaxLoopValue NVARCHAR(MAX)
	DECLARE @MaxLoopValueCount INT
	SELECT DISTINCT TOP 1 @MaxLoopValue = LoopValue, @MaxLoopValueCount = COUNT(LoopValue) FROM #Graph GROUP BY LoopValue ORDER BY COUNT(LoopValue) DESC
		
	select UpperLimit, LowerLimit, COUNT(*) as va
	into #GraphLimits
	FROM #Graph
	GROUP BY UpperLimit, LowerLimit
			
	IF (@@ROWCOUNT = 1)
	BEGIN
		IF (@ShowUpperLowerLimits = 1)
		BEGIN
			IF ((SELECT COUNT(*) FROM #Graph WHERE LowerLimit IS NOT NULL AND ISNUMERIC(LowerLimit)=1 AND LoopValue = @MaxLoopValue) > 0)
			BEGIN				
				SELECT ROUND(Lowerlimit, 3) As YAxis, XAxis, LoopValue + ' Lower Specification Limit' As LoopValue
				FROM #Graph
				WHERE LowerLimit IS NOT NULL AND ISNUMERIC(LowerLimit)=1 AND LoopValue = @MaxLoopValue		
			END
			
			IF ((SELECT COUNT(*) FROM #Graph WHERE Upperlimit IS NOT NULL AND ISNUMERIC(Upperlimit)=1 AND LoopValue = @MaxLoopValue) > 0)
			BEGIN				
				SELECT ROUND(Upperlimit, 3) As YAxis, XAxis, LoopValue + ' Upper Specification Limit' As LoopValue
				FROM #Graph
				WHERE Upperlimit IS NOT NULL AND ISNUMERIC(Upperlimit)=1 AND LoopValue = @MaxLoopValue
			END
		END	
	END
	
	DROP TABLE #Graph
	DROP TABLE #batches
	DROP TABLE #units
	DROP TABLE #stages
	DROP TABLE #GraphLimits
END
GO
GRANT EXECUTE ON Relab.remispResultsGraph TO REMI
GO