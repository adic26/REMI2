begin tran
go
ALTER PROCEDURE [Relab].[remispResultMeasurements] @ResultID INT, @OnlyFails INT = 0, @IncludeArchived INT = 0
AS
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #parameters (ResultMeasurementID INT)

	DECLARE @rows VARCHAR(8000)
	DECLARE @sql VARCHAR(8000)
	SELECT @rows=  ISNULL(STUFF(
		( 
		SELECT DISTINCT '],[' + rp.ParameterName
		FROM Relab.ResultsMeasurements rm WITH(NOLOCK)
			LEFT OUTER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON rm.ID=rp.ResultMeasurementID
		WHERE ResultID=@ResultID AND ((@IncludeArchived = 0 AND rm.Archived=0) OR (@IncludeArchived=1)) AND ((@OnlyFails = 1 AND PassFail=0) OR (@OnlyFails = 0))
		ORDER BY '],[' +  rp.ParameterName
		FOR XML PATH('')), 1, 2, '') + ']','[na]')

	SET @sql = 'ALTER TABLE #parameters ADD ' + convert(varchar(8000), replace(@rows, ']', '] NVARCHAR(250)'))
	EXEC (@sql)

	IF (@rows != '[na]')
	BEGIN
		EXEC ('INSERT INTO #parameters SELECT *
		FROM (
			SELECT rp.ResultMeasurementID, rp.ParameterName, rp.Value
			FROM Relab.ResultsMeasurements rm WITH(NOLOCK)
				LEFT OUTER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON rm.ID=rp.ResultMeasurementID
			WHERE ResultID=' + @ResultID + ' AND ((' + @IncludeArchived + ' = 0 AND rm.Archived=0) OR (' + @IncludeArchived + '=1)) 
				AND ((' + @OnlyFails + ' = 1 AND PassFail=0) OR (' + @OnlyFails + ' = 0))
			) te PIVOT (MAX(Value) FOR ParameterName IN (' + @rows + ')) AS pvt')
	END
	ELSE
	BEGIN
		EXEC ('ALTER TABLE #parameters DROP COLUMN na')
	END
	
	SELECT rm.ID, lt.[Values] As Measurement, LowerLimit AS [Lower Limit], UpperLimit AS [Upper Limit], MeasurementValue AS Result, lu.[Values] As Unit, 
		CASE WHEN PassFail=1 THEN 'Pass' ELSE 'Fail' END AS [Pass/Fail],
		rm.MeasurementTypeID, rm.ReTestNum AS [Test Num], rm.Archived, rm.XMLID, 
		(SELECT MAX(VerNum) FROM Relab.ResultsXML WHERE ResultID=rm.ResultID) AS MaxVersion, rm.Comment,
		ISNULL(rmf.[File], 0) AS [Image], 
		ISNULL(UPPER(SUBSTRING(rmf.ContentType,2,LEN(rmf.ContentType))), 'PNG') AS ContentType, p.*
	FROM Relab.ResultsMeasurements rm WITH(NOLOCK)
		LEFT OUTER JOIN Lookups lu WITH(NOLOCK) ON lu.Type='UnitType' AND lu.LookupID=rm.MeasurementUnitTypeID
		LEFT OUTER JOIN Lookups lt WITH(NOLOCK) ON lt.Type='MeasurementType' AND lt.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Relab.ResultsMeasurementsFiles rmf ON rmf.ResultMeasurementID=rm.ID
		LEFT OUTER JOIN #parameters p ON p.ResultMeasurementID=rm.ID
	WHERE ResultID=@ResultID AND ((@IncludeArchived = 0 AND rm.Archived=0) OR (@IncludeArchived=1)) AND ((@OnlyFails = 1 AND PassFail=0) OR (@OnlyFails = 0))
	ORDER BY lt.[Values], rm.ReTestNum ASC

	DROP TABLE #parameters

	SET NOCOUNT OFF
END
GO
GRANT EXECUTE ON [Relab].[remispResultMeasurements] TO Remi
GO
ALTER PROCEDURE [Relab].[remispResultsSummaryExport] @BatchID INT, @ResultID INT = NULL
AS
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #parameters (ResultMeasurementID INT)

	DECLARE @rows VARCHAR(8000)
	DECLARE @sql VARCHAR(8000)
	SELECT @rows=  ISNULL(STUFF(
		( 
		SELECT DISTINCT '],[' + rp.ParameterName
		FROM Relab.Results r
			INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
			INNER JOIN Tests t WITH(NOLOCK) ON r.TestID=t.ID
			INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID=r.TestUnitID
			INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID
			INNER JOIN Relab.ResultsMeasurements m WITH(NOLOCK) ON m.ResultID=r.ID
			LEFT OUTER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON m.ID=rp.ResultMeasurementID
		WHERE b.ID=@BatchID AND (@ResultID IS NULL OR (@ResultID IS NOT NULL AND r.ID=@ResultID))
		ORDER BY '],[' +  rp.ParameterName
		FOR XML PATH('')), 1, 2, '') + ']','[na]')

	SET @sql = 'ALTER TABLE #parameters ADD ' + convert(varchar(8000), replace(@rows, ']', '] NVARCHAR(250)'))
	EXEC (@sql)

	IF (@rows != '[na]')
	BEGIN
		SET @sql = 'INSERT INTO #parameters SELECT *
		FROM (
			SELECT rp.ResultMeasurementID, rp.ParameterName, rp.Value
			FROM Relab.Results r
				INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
				INNER JOIN Tests t WITH(NOLOCK) ON r.TestID=t.ID
				INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID=r.TestUnitID
				INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID
				INNER JOIN Relab.ResultsMeasurements m WITH(NOLOCK) ON m.ResultID=r.ID
				LEFT OUTER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON m.ID=rp.ResultMeasurementID
			WHERE b.ID=' + CONVERT(VARCHAR, @BatchID) + ' AND (' + CASE WHEN convert(varchar,@ResultID) IS NULL THEN 'NULL' ELSE convert(varchar,@ResultID) END + ' IS NULL OR (' + CASE WHEN convert(varchar,@ResultID) IS NULL THEN 'NULL' ELSE convert(varchar,@ResultID) END + ' IS NOT NULL AND r.ID=' + CASE WHEN @ResultID IS NOT NULL THEN CONVERT(VARCHAR, @ResultID) ELSE 'NULL' END + '))
			) te PIVOT (MAX(Value) FOR ParameterName IN (' + @rows + ')) AS pvt'
		EXEC (@sql)
	END
	ELSE
	BEGIN
		EXEC ('ALTER TABLE #parameters DROP COLUMN na')
	END

	SELECT b.QRANumber, tu.BatchUnitNumber As Unit, tu.BSN, ts.TestStageName AS TestStage, t.TestName, 
		lm.[Values] AS MeasurementType, m.LowerLimit, m.UpperLimit, m.MeasurementValue AS Result, lu.[Values] AS Units,
		CASE WHEN m.PassFail=1 THEN 'Pass' ELSE 'Fail' END AS PassFail, --Relab.ResultsParametersComma(m.ID) AS Parameters, 
		m.ReTestNum, m.Archived, m.Comment, rxml.VerNum AS XMLVersion, p.*
	FROM Relab.Results r
		INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
		INNER JOIN Tests t WITH(NOLOCK) ON r.TestID=t.ID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID=r.TestUnitID
		INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID
		INNER JOIN Relab.ResultsMeasurements m WITH(NOLOCK) ON m.ResultID=r.ID
		INNER JOIN Lookups lm WITH(NOLOCK) ON m.MeasurementTypeID=lm.LookupID
		INNER JOIN Lookups lu WITH(NOLOCK) ON m.MeasurementUnitTypeID=lu.LookupID
		INNER JOIN Relab.ResultsXML rxml ON rxml.ID=m.XMLID
		LEFT OUTER JOIN #parameters p ON p.ResultMeasurementID=m.ID
	WHERE b.ID=@BatchID AND (@ResultID IS NULL OR (@ResultID IS NOT NULL AND r.ID=@ResultID))
	ORDER BY tu.BatchUnitNumber, ts.TestStageName, TestName
	
	SET NOCOUNT OFF
END
GO
GRANT EXECUTE ON [Relab].[remispResultsSummaryExport] TO Remi
GO
ALTER PROCEDURE Relab.remispResultsGraph @MeasurementTypeID INT, @batchIDs NVARCHAR(MAX), @UnitIDs NVARCHAR(MAX), @TestID INT, @ParameterName NVARCHAR(255)=NULL, @ParameterValue NVARCHAR(250)=NULL, @ShowUpperLowerLimits INT = 1, @Xaxis INT, @PlotValue INT, @IncludeArchived INT = 0
AS
BEGIN
	DECLARE @LoopValue NVARCHAR(500)
	DECLARE @ID INT
	DECLARE @query VARCHAR(MAX)
	DECLARE @query2 VARCHAR(MAX)
	CREATE TABLE #batches (id INT)
	CREATE TABLE #units (id INT)
	CREATE TABLE #Graph (RowID INT, YAxis NVARCHAR(500), XAxis NVARCHAR(500), LoopValue NVARCHAR(500), LowerLimit NVARCHAR(255), UpperLimit NVARCHAR(255))
	EXEC (@batchIDs)
	EXEC (@UnitIDs)
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
		SELECT DISTINCT ROUND(YAxis, 3) AS YAxis, XAxis, LoopValue, LowerLimit, UpperLimit FROM #Graph WHERE LoopValue=@LoopValue AND ISNUMERIC(YAxis)=1
		FETCH NEXT FROM select_cursor INTO @LoopValue
	END
	
	CLOSE select_cursor
	DEALLOCATE select_cursor
	
	DROP TABLE #Graph
	DROP TABLE #batches
	DROP TABLE #units
	DROP TABLE #GraphLimits
END
GO
GRANT EXECUTE ON Relab.remispResultsGraph TO REMI
GO
ALTER PROCEDURE Relab.remispResultsFileProcessing
AS
BEGIN
	BEGIN TRANSACTION

	BEGIN TRY
		DECLARE @ID INT
		DECLARE @idoc INT
		DECLARE @RowID INT
		DECLARE @xml XML
		DECLARE @xmlPart XML
		DECLARE @FinalResult BIT
		DECLARE @StartDate DATETIME
		DECLARE @EndDate NVARCHAR(MAX)
		DECLARE @Duration NVARCHAR(MAX)
		DECLARE @StationName NVARCHAR(400)
		DECLARE @MaxID INT
		DECLARE @VerNum INT
		DECLARE @ResultID INT
		DECLARE @Val INT

		IF ((SELECT COUNT(*) FROM Relab.ResultsXML x INNER JOIN Relab.Results r ON r.ID=x.ResultID WHERE r.TestID <> 1099 AND ISNULL(IsProcessed,0)=0)=0)
		BEGIN
			GOTO HANDLE_SUCCESS
			RETURN
		END
		
		SET NOCOUNT ON
		
		SELECT @Val = COUNT(*) FROM Relab.ResultsXML x INNER JOIN Relab.Results r ON r.ID=x.ResultID WHERE r.TestID <> 1099 AND ISNULL(isProcessed,0)=0
		
		SELECT TOP 1 @ID=x.ID, @xml = x.ResultXML, @VerNum = x.VerNum, @ResultID = x.ResultID
		FROM Relab.ResultsXML x
			INNER JOIN Relab.Results r ON r.ID=x.ResultID
		WHERE r.TestID <> 1099 AND ISNULL(IsProcessed,0)=0
		ORDER BY ResultID, VerNum ASC
		
		PRINT '# Files To Process: ' + CONVERT(VARCHAR, @Val)
		PRINT 'XMLID: ' + CONVERT(VARCHAR, @ID)
		PRINT 'ResultID: ' + CONVERT(VARCHAR, @ResultID)

		SELECT @xmlPart = T.c.query('.') 
		FROM @xml.nodes('/TestResults/Header') T(c)
				
		select @EndDate = T.c.query('DateCompleted').value('.', 'nvarchar(max)'),
			@Duration = T.c.query('Duration').value('.', 'nvarchar(max)'),
			@StationName = T.c.query('StationName').value('.', 'nvarchar(400)')
		FROM @xmlPart.nodes('/Header') T(c)

		SELECT @EndDate= STUFF(@EndDate, CHARINDEX('-',@EndDate,(charindex('-',@EndDate, (charindex('-',@EndDate)+1))+1)), 1, ' ')
		SELECT @EndDate= STUFF(@EndDate, CHARINDEX('-',@EndDate,(charindex('-',@EndDate, (charindex('-',@EndDate)+1))+1)), 1, ':')
		SELECT @EndDate= STUFF(@EndDate, CHARINDEX('-',@EndDate,(charindex('-',@EndDate, (charindex('-',@EndDate)+1))+1)), 1, ':')
				
		If (CHARINDEX('.', @Duration) > 0)
			SET @Duration = SUBSTRING(@Duration, 1, CHARINDEX('.', @Duration)-1)
		
		SET @StartDate=dateadd(s,-datediff(s,0,convert(DATETIME,@Duration)), CONVERT(DATETIME, @EndDate))
	
		PRINT 'INSERT Lookups UnitType'
		SELECT DISTINCT (1) AS LookupID, T.c.query('Units').value('.', 'nvarchar(max)') AS UnitType, 1 AS Active
		INTO #LookupsUnitType
		FROM @xml.nodes('/TestResults/Measurements/Measurement') T(c)
		WHERE LTRIM(RTRIM(CONVERT(VARCHAR(MAX), T.c.query('Units').value('.', 'nvarchar(max)')))) NOT IN ( (SELECT [Values] FROM Lookups WHERE Type='UnitType')) 
			AND CONVERT(VARCHAR(MAX), T.c.query('Units').value('.', 'nvarchar(max)')) NOT IN ('N/A')
		
		SELECT @MaxID = MAX(LookupID)+1 FROM Lookups
		
		INSERT INTO Lookups (LookupID, Type,[Values], IsActive)
		SELECT (ROW_NUMBER() OVER (ORDER BY LookupID)) + @MaxID AS LookupID, 'UnitType' AS Type, UnitType AS [Values], Active
		FROM #LookupsUnitType
		
		DROP TABLE #LookupsUnitType
		
		PRINT 'INSERT Lookups MeasurementType'
		SELECT DISTINCT (1) AS LookupID, T.c.query('MeasurementName').value('.', 'nvarchar(max)') AS MeasurementType, 1 AS Active
		INTO #LookupsMeasurementType
		FROM @xml.nodes('/TestResults/Measurements/Measurement') T(c)
		WHERE LTRIM(RTRIM(CONVERT(VARCHAR(MAX), T.c.query('MeasurementName').value('.', 'nvarchar(max)')))) NOT IN ( (SELECT [Values] FROM Lookups WHERE Type='MeasurementType')) 
			AND CONVERT(VARCHAR(MAX), T.c.query('MeasurementName').value('.', 'nvarchar(max)')) NOT IN ('N/A')
		
		SELECT @MaxID = MAX(LookupID)+1 FROM Lookups
		
		INSERT INTO Lookups (LookupID, Type, [Values], IsActive)
		SELECT (ROW_NUMBER() OVER (ORDER BY LookupID)) + @MaxID AS LookupID, 'MeasurementType' AS Type, MeasurementType AS [Values], Active
		FROM #LookupsMeasurementType
		
		DROP TABLE #LookupsMeasurementType
		
		PRINT 'Load Measurements into temp table'
		SELECT  ROW_NUMBER() OVER (ORDER BY T.c) AS RowID, T.c.query('.') AS value 
		INTO #temp2
		FROM @xml.nodes('/TestResults/Measurements/Measurement') T(c)
		WHERE LOWER(T.c.query('MeasurementName').value('.', 'nvarchar(max)')) <> LOWER('cableloss')

		SELECT @RowID = MIN(RowID) FROM #temp2
		
		WHILE (@RowID IS NOT NULL)
		BEGIN
			DECLARE @FileName NVARCHAR(200)
			SET @FileName = NULL

			SELECT @xmlPart  = value FROM #temp2 WHERE RowID=@RowID	

			select l2.LookupID AS MeasurementTypeID,
				T.c.query('LowerLimit').value('.', 'nvarchar(max)') AS LowerLimit,
				T.c.query('UpperLimit').value('.', 'nvarchar(max)') AS UpperLimit,
				T.c.query('MeasuredValue').value('.', 'nvarchar(max)') AS MeasurementValue,
				(CASE WHEN T.c.query('PassFail').value('.', 'nvarchar(max)') = 'Pass' THEN 1 ELSE 0 END) AS PassFail,
				l.LookupID AS UnitTypeID,
				T.c.query('FileName').value('.', 'nvarchar(max)') AS [FileName], 
				[Relab].[ResultsXMLParametersComma] ((select T.c.query('.') from @xmlPart.nodes('/Measurement/Parameters') T(c))) AS Parameters
			INTO #measurement
			FROM @xmlPart.nodes('/Measurement') T(c)
				LEFT OUTER JOIN Lookups l ON l.Type='UnitType' AND l.[Values]=LTRIM(RTRIM(CONVERT(VARCHAR(MAX), T.c.query('Units').value('.', 'nvarchar(max)'))))
				LEFT OUTER JOIN Lookups l2 ON l2.Type='MeasurementType' AND l2.[Values]=LTRIM(RTRIM(CONVERT(VARCHAR(MAX), T.c.query('MeasurementName').value('.', 'nvarchar(max)'))))

			IF (@VerNum = 1)
			BEGIN
				PRINT 'INSERT Version 1 Measurements'
				INSERT INTO Relab.ResultsMeasurements (ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, MeasurementUnitTypeID, PassFail, ReTestNum, Archived, XMLID)
				SELECT @ResultID As ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, UnitTypeID, CONVERT(BIT, PassFail), 1, 0, @ID
				FROM #measurement

				DECLARE @ResultMeasurementID INT
				SET @ResultMeasurementID = @@IDENTITY
				
				PRINT 'INSERT Version 1 Parameters'
				INSERT INTO Relab.ResultsParameters (ResultMeasurementID, ParameterName, Value)
				SELECT @ResultMeasurementID AS ResultMeasurementID, T.c.value('@ParameterName','nvarchar(max)') AS ParameterName, T.c.query('.').value('.', 'nvarchar(max)') AS Value
				FROM @xmlPart.nodes('/Measurement/Parameters/Parameter') T(c)

				SELECT @FileName = LTRIM(RTRIM([FileName]))
				FROM #measurement
				
				IF (@FileName IS NOT NULL AND @FileName <> '')
					BEGIN
						UPDATE Relab.ResultsMeasurementsFiles 
						SET ResultMeasurementID=@ResultMeasurementID 
						WHERE LOWER(LTRIM(RTRIM(FileName)))=LOWER(@FileName) AND ResultMeasurementID IS NULL
					END
			END
			ELSE
			BEGIN
				DECLARE @MeasurementTypeID INT
				DECLARE @Parameters NVARCHAR(MAX)
				DECLARE @MeasuredValue NVARCHAR(500)
				DECLARE @OldMeasuredValue NVARCHAR(500)
				DECLARE @ReTestNum INT
				SET @ReTestNum = 1
				SET @OldMeasuredValue = NULL
				SET @MeasuredValue = NULL
				SET @Parameters = NULL
				SET @MeasurementTypeID = NULL
				SELECT @MeasurementTypeID=MeasurementTypeID, @Parameters=ISNULL(Parameters, ''), @MeasuredValue=MeasurementValue FROM #measurement
				
				SELECT @OldMeasuredValue = MeasurementValue , @ReTestNum = reTestNum+1
				FROM Relab.ResultsMeasurements 
				WHERE ResultID=@ResultID AND MeasurementTypeID=@MeasurementTypeID AND ISNULL(Relab.ResultsParametersComma(ID),'') = ISNULL(@Parameters,'') AND Archived=0

				IF (@OldMeasuredValue IS NOT NULL AND @OldMeasuredValue <> @MeasuredValue)
				--That result has that measurement type and exact parameters but measured value is different
				BEGIN
					PRINT 'INSERT ReTest Measurements'
					INSERT INTO Relab.ResultsMeasurements (ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, MeasurementUnitTypeID, PassFail, ReTestNum, Archived, XMLID)
					SELECT @ResultID As ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, UnitTypeID, CONVERT(BIT, PassFail), @ReTestNum, 0, @ID
					FROM #measurement
					
					DECLARE @ResultMeasurementID2 INT
					SET @ResultMeasurementID2 = @@IDENTITY
					
					SELECT @FileName = LTRIM(RTRIM([FileName]))
					FROM #measurement
				
					IF (@FileName IS NOT NULL AND @FileName <> '')
						BEGIN
							UPDATE Relab.ResultsMeasurementsFiles 
							SET ResultMeasurementID=@ResultMeasurementID2 
							WHERE LOWER(LTRIM(RTRIM(FileName)))=LOWER(@FileName) AND ResultMeasurementID IS NULL
						END

					IF (@Parameters <> '')
					BEGIN
						PRINT 'INSERT ReTest Parameters'
						INSERT INTO Relab.ResultsParameters (ResultMeasurementID, ParameterName, Value)
						SELECT @ResultMeasurementID2 AS ResultMeasurementID, T.c.value('@ParameterName','nvarchar(max)') AS ParameterName, T.c.query('.').value('.', 'nvarchar(max)') AS Value
						FROM @xmlPart.nodes('/Measurement/Parameters/Parameter') T(c)
						
						UPDATE Relab.ResultsMeasurements 
						SET Archived=1 
						WHERE ResultID=@ResultID AND Archived=0 AND MeasurementTypeID=@MeasurementTypeID AND ISNULL(Relab.ResultsParametersComma(ID),'') = ISNULL(@Parameters,'') AND ReTestNum < @ReTestNum
					END
				END
				ELSE IF (@OldMeasuredValue IS NOT NULL AND @OldMeasuredValue = @MeasuredValue)
				--That measurement already exists in the current active measurements
				BEGIN
					SET @ReTestNum = 0
				END
				ELSE
				--That result does not have that measurement type and exact parameters
				BEGIN
					PRINT 'INSERT New Measurements'
					INSERT INTO Relab.ResultsMeasurements (ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, MeasurementUnitTypeID, PassFail, ReTestNum, Archived, XMLID)
					SELECT @ResultID As ResultID, MeasurementTypeID, LowerLimit, UpperLimit, MeasurementValue, UnitTypeID, CONVERT(BIT, PassFail), 1, 0, @ID
					FROM #measurement

					DECLARE @ResultMeasurementID3 INT
					SET @ResultMeasurementID3 = @@IDENTITY
					
					SELECT @FileName = LTRIM(RTRIM([FileName]))
					FROM #measurement
				
					IF (@FileName IS NOT NULL AND @FileName <> '')
						BEGIN
							UPDATE Relab.ResultsMeasurementsFiles 
							SET ResultMeasurementID=@ResultMeasurementID3 
							WHERE LOWER(LTRIM(RTRIM(FileName)))=LOWER(@FileName) AND ResultMeasurementID IS NULL
						END
					
					IF (@Parameters <> '')
					BEGIN								
						PRINT 'INSERT New Parameters'
						INSERT INTO Relab.ResultsParameters (ResultMeasurementID, ParameterName, Value)
						SELECT @ResultMeasurementID3 AS ResultMeasurementID, T.c.value('@ParameterName','nvarchar(max)') AS ParameterName, T.c.query('.').value('.', 'nvarchar(max)') AS Value
						FROM @xmlPart.nodes('/Measurement/Parameters/Parameter') T(c)
					END
				END
			END
			
			DROP TABLE #measurement
		
			SELECT @RowID = MIN(RowID) FROM #temp2 WHERE RowID > @RowID
		END
		
		PRINT 'Update Result'
		UPDATE Relab.ResultsXML 
		SET EndDate=CONVERT(DATETIME, @EndDate), StartDate =@StartDate, IsProcessed=1, StationName=@StationName
		WHERE ID=@ID
		
		UPDATE Relab.Results
		SET PassFail=CASE WHEN (SELECT COUNT(*) FROM Relab.ResultsMeasurements WHERE ResultID=@ResultID AND Archived=0 AND PassFail=0) > 0 THEN 0 ELSE 1 END
		WHERE ID=@ResultID
	
		DROP TABLE #temp2
		SET NOCOUNT OFF

		GOTO HANDLE_SUCCESS
	END TRY
	BEGIN CATCH
		SET NOCOUNT OFF
		SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_SEVERITY() AS ErrorSeverity, ERROR_STATE() as ErrorState, ERROR_PROCEDURE() as ErrorProcedure, ERROR_LINE() as ErrorLine, ERROR_MESSAGE() as ErrorMessage

		GOTO HANDLE_ERROR
	END CATCH

	HANDLE_SUCCESS:
		IF @@TRANCOUNT > 0
		BEGIN
			PRINT 'COMMIT TRANSACTION'
			COMMIT TRANSACTION
		END
		RETURN	
	
	HANDLE_ERROR:
		IF @@TRANCOUNT > 0
		BEGIN
			PRINT 'ROLLBACK TRANSACTION'
			ROLLBACK TRANSACTION
		END
		RETURN
END
GO
GRANT EXECUTE ON Relab.remispResultsFileProcessing TO REMI
GO
ALTER VIEW [dbo].[vw_GetTaskInfo]
AS
SELECT qranumber, processorder, BatchID,
	   tsname, 
	   tname, 
	   testtype, 
	   teststagetype, 
	   resultbasedontime, 
	   testunitsfortest, 
	   (SELECT CASE WHEN specifictestduration IS NULL THEN generictestduration ELSE specifictestduration END) AS expectedDuration,
	   TestStageID, TestWI, TestID, IsArchived, RecordExists
FROM   
	(
		SELECT b.qranumber,b.ID AS BatchID,
		ts.processorder, ts.teststagename AS tsname, t.testname AS tname, t.testtype, ts.teststagetype, t.duration AS genericTestDuration, ts.ID AS TestStageID,t.ID AS TestID,
		t.WILocation As TestWI, ISNULL(ts.IsArchived, 0) AS IsArchived, 
			t.resultbasedontime, 
			(
				SELECT bstd.duration 
				FROM   batchspecifictestdurations AS bstd 
				WHERE  bstd.testid = t.id 
					   AND bstd.batchid = b.id
			) AS specificTestDuration,
			(				
				SELECT Cast(tu.batchunitnumber AS VARCHAR(MAX)) + ', ' 
				FROM testunits AS tu 
				WHERE tu.batchid = b.id 
					AND 
					(
						NOT EXISTS 
						(
							SELECT DISTINCT 1
							FROM vw_ExceptionsPivoted as pvt
							where pvt.ID IN (SELECT ID FROM TestExceptions WHERE LookupID=3 AND Value = tu.ID) AND
							(
								(pvt.TestStageID IS NULL AND pvt.Test = t.ID ) 
								OR 
								(pvt.Test IS NULL AND pvt.TestStageID = ts.id) 
								OR 
								(pvt.TestStageID = ts.id AND pvt.Test = t.ID)
								OR
								(pvt.TestStageID IS NULL AND pvt.Test IS NULL)
							)
						)
					)
				FOR xml path ('')
			) AS TestUnitsForTest,
			(SELECT TOP 1 1
			FROM TestRecords tr
			WHERE tr.TestStageName=ts.TestStageName AND tr.TestUnitID IN (SELECT ID FROM TestUnits WHERE BatchID=b.ID)) AS RecordExists
		FROM TestStages ts
		INNER JOIN Jobs j ON ts.JobID=j.ID
		INNER JOIN Batches b on j.jobname = b.jobname 
		INNER JOIN Tests t ON ( ( ts.teststagetype = 2 AND ts.testid = t.id ) OR ts.teststagetype != 2 AND ts.teststagetype = t.testtype )
		INNER JOIN Products p ON b.ProductID=p.ID
		WHERE NOT EXISTS 
			(
				SELECT DISTINCT 1
				FROM vw_ExceptionsPivoted as pvt
				WHERE pvt.testunitid IS NULL AND pvt.Test = t.ID
					AND ( pvt.teststageid IS NULL OR ts.id = pvt.teststageid ) 
					AND ( 
							(pvt.ProductID = p.ID AND pvt.reasonforrequest IS NULL)
							OR 
							(pvt.ProductID = p.ID AND pvt.reasonforrequest = b.requestpurpose ) 
							OR
							(pvt.ProductID IS NULL AND b.requestpurpose IS NOT NULL AND pvt.reasonforrequest = b.requestpurpose)
							OR
							(pvt.ProductID IS NULL AND pvt.reasonforrequest IS NULL)
						) 
					AND
						(
							(pvt.AccessoryGroupID IS NULL)
							OR
							(pvt.AccessoryGroupID IS NOT NULL AND pvt.AccessoryGroupID = b.AccessoryGroupID)
						)
					AND
						(
							(pvt.ProductTypeID IS NULL)
							OR
							(pvt.ProductTypeID IS NOT NULL AND pvt.ProductTypeID = b.ProductTypeID)
						)
			)
	) AS unitData 
WHERE TestUnitsForTest IS NOT NULL AND 
	(
		(ISNULL(RecordExists,0) > 0 AND IsArchived = 1)
		OR
		(ISNULL(IsArchived, 0) = 0)
	)
GO
ALTER PROCEDURE [Relab].[remispOverallResultsSummary] @BatchID INT
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @query VARCHAR(8000)
	DECLARE @query2 VARCHAR(8000)
	DECLARE @query3 VARCHAR(8000)
	DECLARE @QRANumber NVARCHAR(11)
	DECLARE @RowID INT
	DECLARE @TestStageID INT
	DECLARE @BatchUnitNumber INT
	DECLARE @StageCount INT
	DECLARE @UnitCount INT
	CREATE TABLE #results (TestID INT)
	
	SELECT @QRANumber = QRANumber FROM Batches WHERE ID=@BatchID
	SELECT @StageCount = COUNT(DISTINCT TSName) FROM dbo.vw_GetTaskInfo WHERE BatchID=@BatchID and Processorder > 0 AND Testtype=1 AND LOWER(LTRIM(RTRIM(TSName))) <> 'analysis'
	SELECT @TestStageID = TestStageID FROM dbo.vw_GetTaskInfo WHERE BatchID=@BatchID and Processorder > 0 AND Testtype=1 AND LOWER(LTRIM(RTRIM(TSName))) = 'analysis'
	SELECT @UnitCount = COUNT(*) FROM TestUnits WHERE BatchID=@BatchID
	
	IF (@TestStageID IS NULL)
		SET @TestStageID=0
		
	SET @query2 = ''
	SET @query = ''
	SET @query3 =''	

	EXECUTE ('ALTER TABLE #results ADD [' + @QRANumber + '] NVARCHAR(400) NULL, Completed NVARCHAR(3) NULL, [Pass/Fail] NVARCHAR(3) NULL')
	
	SELECT pvt.Test, pvt.TestStageID, pvt.TestUnitID, CASE WHEN pvt.TestStageID IS NULL THEN @StageCount ELSE 1 END AS Num, tu.BatchUnitNumber
	INTO #exceptions
	FROM vw_ExceptionsPivoted as pvt WITH(NOLOCK)
		INNER JOIN TestUnits tu ON tu.ID=pvt.TestUnitID
	where tu.batchID=@BatchID AND
	(
		(pvt.TestStageID IS NULL AND pvt.Test IS NOT NULL ) 
		OR 
		(pvt.Test IS NULL AND pvt.TestStageID IS NOT NULL) 
		OR 
		(pvt.TestStageID IS NOT NULL AND pvt.Test IS NOT NULL)
		OR 
		(pvt.TestStageID IS NULL AND pvt.Test IS NULL)
	)	
		
	SET @query = 'INSERT INTO #results
	SELECT DISTINCT TestID, TName AS [' + @QRANumber + '],
		(
			CASE WHEN
				(
					' + CONVERT(VARCHAR, (@UnitCount * @StageCount)) + ' - ISNULL((SELECT SUM(Num)
					FROM 
					(
						SELECT *
						FROM #exceptions
						where 
						(
							(TestStageID IS NULL AND Test = i.TestID ) 
							OR 
							(Test IS NULL AND TestStageID IS NOT NULL) 
							OR 
							(TestStageID IS NOT NULL AND Test = i.TestID)
							OR 
							(TestStageID IS NULL AND Test IS NULL)
						)
					) AS c),0)
				) = 
				(
					SELECT COUNT(DISTINCT r.ID) 
					FROM Relab.Results r WITH(NOLOCK) 
						INNER JOIN TestUnits u WITH(NOLOCK) ON u.ID=r.TestUnitID
					WHERE r.TestStageID <> '+CONVERT(VARCHAR,@TestStageID)+'  AND r.TestID=i.TestID AND u.BatchID='+CONVERT(VARCHAR,@BatchID)+' 
				) THEN ''Y'' ELSE ''N'' END
		) as Completed,
		(
			CASE
				WHEN 
				(
					SELECT TOP 1 1 
					FROM Relab.Results r WITH(NOLOCK)
						INNER JOIN TestUnits u WITH(NOLOCK) ON u.ID=r.TestUnitID 
					WHERE r.TestID=i.TestID AND u.BatchID='+CONVERT(VARCHAR,@BatchID)+'
				) IS NULL THEN ''N/A''
				WHEN
				(
					SELECT COUNT(*)
					FROM Relab.Results r WITH(NOLOCK) 
						INNER JOIN TestUnits u WITH(NOLOCK) ON u.ID=r.TestUnitID 
					WHERE r.TestID=i.TestID AND u.BatchID='+CONVERT(VARCHAR,@BatchID)+' AND PassFail=1
				) = 
				(
					SELECT COUNT(*)
					FROM Relab.Results r WITH(NOLOCK) 
						INNER JOIN TestUnits u WITH(NOLOCK) ON u.ID=r.TestUnitID 
					WHERE r.TestID=i.TestID AND u.BatchID='+CONVERT(VARCHAR,@BatchID)+'
				) THEN ''P'' 
				ELSE ''F'' END
		) AS [Pass/Fail] '
		
	SET @query2 = 'FROM dbo.vw_GetTaskInfo i WITH(NOLOCK)
	WHERE processorder > 0 AND testtype=1 AND i.BatchID='+CONVERT(VARCHAR,@BatchID)+'
	ORDER BY TName'

	EXECUTE (@query + @query2)
		
	SELECT ROW_NUMBER() OVER (ORDER BY tu.ID) AS RowID, tu.BatchUnitNumber, tu.ID
	INTO #units
	FROM TestUnits tu
	WHERE BatchID=@BatchID

	SELECT @RowID = MIN(RowID) FROM #units
			
	WHILE (@RowID IS NOT NULL)
	BEGIN
		SELECT @BatchUnitNumber=BatchUnitNumber FROM #units WHERE RowID=@RowID
		
		EXECUTE ('ALTER TABLE #results ADD [' + @BatchUnitNumber + '] NVARCHAR(10) NULL')
		
		SET @query3 = 'UPDATE #Results SET [' + CONVERT(VARCHAR,@BatchUnitNumber) + '] = (
		CASE
			WHEN 
			(
				SELECT TOP 1 1
				FROM Relab.Results r WITH(NOLOCK)
					INNER JOIN TestUnits u WITH(NOLOCK) ON u.ID=r.TestUnitID 
				WHERE r.TestID=#Results.TestID AND u.ID=r.TestUnitID AND u.BatchUnitNumber =' + CONVERT(VARCHAR,@BatchUnitNumber) + ' AND u.BatchID='+CONVERT(VARCHAR,@BatchID)+'
			) IS NULL THEN ''N/S''
			WHEN
			(
				SELECT COUNT(*)
				FROM Relab.Results r WITH(NOLOCK) 
					INNER JOIN TestUnits u WITH(NOLOCK) ON u.ID=r.TestUnitID 
				WHERE r.TestID=#Results.TestID AND u.ID=r.TestUnitID AND PassFail=1 AND u.BatchUnitNumber =' + CONVERT(VARCHAR,@BatchUnitNumber) + ' AND u.BatchID='+CONVERT(VARCHAR,@BatchID)+'
			) = 
			(
				SELECT COUNT(*)
				FROM Relab.Results r WITH(NOLOCK)
					INNER JOIN TestUnits u WITH(NOLOCK) ON u.ID=r.TestUnitID 
				WHERE r.TestID=#Results.TestID AND u.ID=r.TestUnitID AND u.BatchUnitNumber =' + CONVERT(VARCHAR,@BatchUnitNumber) + ' AND u.BatchID='+CONVERT(VARCHAR,@BatchID)+'
			) THEN ''P'' ELSE ''F'' END
		) + '' ('' + ISNULL((SELECT CONVERT(VARCHAR, SUM(Num))
					FROM 
					(
						SELECT *
						FROM #exceptions
						where BatchUnitNumber =' + CONVERT(VARCHAR,@BatchUnitNumber) + ' AND
						(
							(TestStageID IS NULL AND Test = #Results.TestID ) 
							OR 
							(Test IS NULL AND TestStageID IS NOT NULL) 
							OR 
							(TestStageID IS NOT NULL AND Test = #Results.TestID)
							OR 
							(TestStageID IS NULL AND Test IS NULL)
						)
					) AS c),0) + '')'''
		
		EXECUTE (@query3)
		
		SELECT @RowID = MIN(RowID) FROM #units WHERE RowID > @RowID
	END
	
	SELECT * FROM #results
	
	DROP TABLE #exceptions
	DROP TABLE #units
	DROP TABLE #results
	SET NOCOUNT OFF
END
GO
GRANT EXECUTE ON [Relab].[remispOverallResultsSummary] TO Remi
GO
rollback tran