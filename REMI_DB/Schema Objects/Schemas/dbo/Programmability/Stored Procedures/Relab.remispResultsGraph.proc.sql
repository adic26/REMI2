ALTER PROCEDURE Relab.remispResultsSearch @MeasurementTypeID INT, @TestID INT, @ParameterName NVARCHAR(255)=NULL, @ParameterValue NVARCHAR(250)=NULL, @ProductIDs NVARCHAR(MAX) = NULL, @JobNameIDs NVARCHAR(MAX) = NULL, @TestStageIDs NVARCHAR(MAX) = NULL, @TestCenterID INT = 0, @ShowFailureOnly INT = 0
AS
BEGIN		
	DECLARE @LoopValue NVARCHAR(500)
	DECLARE @ID INT
	DECLARE @query VARCHAR(MAX)
	DECLARE @query2 VARCHAR(MAX)
	DECLARE @FalseBit BIT
	SET @FalseBit = CONVERT(BIT, 0)
	SET @query = ''	
	SET @query2 = ''
	
	CREATE TABLE #products (ID INT)
	CREATE TABLE #jobs (ID INT)
	CREATE TABLE #stageIDs (ID INT)
	INSERT INTO #stageIDs SELECT s FROM dbo.Split(',', @TestStageIDs)
	INSERT INTO #jobs SELECT s FROM dbo.Split(',',  @JobNameIDs)
	INSERT INTO #products SELECT s FROM dbo.Split(',', @ProductIDs)
	
	SET @query = 'SELECT b.QRANumber, tu.BatchUnitNumber, ts.TestStageName AS TestStageName, rm.MeasurementValue AS MeasurementValue, rm.LowerLimit, rm.UpperLimit, 
		r.ID AS ResultID, b.ID AS BatchID, pd.ProductGroupName, pd.ID AS ProductID, j.JobName, l.[values] AS TestCenter, CASE WHEN rm.PassFail=1 THEN ''Pass'' ELSE ''Fail'' END AS PassFail,
		Relab.ResultsParametersComma(rm.ID) As Params, lm.[Values] AS MeasurementName, ISNULL(CONVERT(NVARCHAR, rm.DegradationVal), ''N/A'') AS DegradationVal 
	FROM Relab.Results r WITH(NOLOCK)
		INNER JOIN TestUnits tu WITH(NOLOCK) ON r.TestUnitID=tu.ID
		INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID
		INNER JOIN Relab.ResultsMeasurements rm WITH(NOLOCK) ON r.ID=rm.ResultID
		INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
		INNER JOIN Products pd WITH(NOLOCK) ON pd.ID = b.ProductID
		INNER JOIN Jobs j WITH(NOLOCK) ON j.ID=ts.JobID
		INNER JOIN Lookups l WITH(NOLOCK) ON l.LookupID=b.TestCenterLocationID
		INNER JOIN #products products WITH(NOLOCK) ON products.ID = pd.ID
		INNER JOIN Lookups lm ON lm.LookupID = rm.MeasurementTypeID AND lm.Type=''MeasurementType''
		INNER JOIN #jobs job WITH(NOLOCK) ON job.id=j.ID
		INNER JOIN #stageIDs stage WITH(NOLOCK) ON stage.id=ts.ID
	WHERE r.TestID='+CONVERT(VARCHAR,@TestID)+' AND MeasurementValue IS NOT NULL 
		AND
		(
			(' + CONVERT(VARCHAR,@MeasurementTypeID) + ' > 0 AND rm.MeasurementTypeID=' + CONVERT(VARCHAR,@MeasurementTypeID) + ')
			OR
			(' + CONVERT(VARCHAR,@MeasurementTypeID) + ' = 0)
		)		
		AND
		(
			(' + CONVERT(VARCHAR,@TestCenterID) + ' > 0 AND b.TestCenterLocationID=' + CONVERT(VARCHAR,@TestCenterID) + ')
			OR
			(' + CONVERT(VARCHAR,@TestCenterID) + ' = 0)
		) '

	IF (@ParameterName IS NOT NULL)
		SET @query2 = ' AND (Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterName,'')+''' <> '''' THEN ''N'' ELSE ''V'' END)='''+ ISNULL(@ParameterName,'')+''') '
	IF (@ParameterValue IS NOT NULL)
		SET @query2 = ' AND (Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN ''V'' ELSE ''N'' END)='''+ ISNULL(@ParameterValue,'')+''') '


	SET @query2 += ' AND ISNULL(rm.Archived,0)=' + CONVERT(VARCHAR, @FalseBit) + '
		AND
		(
			(' + CONVERT(VARCHAR, @ShowFailureOnly) + ' = 1 AND rm.PassFail=0)
			OR
			(' + CONVERT(VARCHAR, @ShowFailureOnly) + ' = 0)
		)
	ORDER BY QRANumber, BatchUnitNumber, TestStageName'
	
	print @query
	print @query2

	EXEC(@query + @query2)
	
	DROP TABLE #stageIDs
	DROP TABLE #jobs
	DROP TABLE #products
END
GO
GRANT EXECUTE ON Relab.remispResultsSearch TO REMI
GO