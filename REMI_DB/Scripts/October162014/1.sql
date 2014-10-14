/*
Run this script on:

        sql51ykf\ha6.remi    -  This database will be modified

to synchronize it with:

        (local).REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 10/15/2014 11:57:00 AM

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
PRINT N'Dropping [dbo].[Split]'
GO
DROP FUNCTION [dbo].[Split]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[Split]'
GO
create FUNCTION dbo.Split(@sep nvarchar(5) = ',', @s nvarchar(MAX))
RETURNS @RtnValue table
(
    RowID INT NOT NULL IDENTITY(1,1) PRIMARY KEY CLUSTERED,
    s nvarchar(100) NOT NULL
)
AS
BEGIN
    IF @s IS NULL RETURN
    IF @s = '' RETURN

    DECLARE @split_on_len INT = LEN(@sep)
    DECLARE @start_at INT = 1
    DECLARE @end_at INT
    DECLARE @data_len INT

    WHILE 1=1
    BEGIN
        SET @end_at = CHARINDEX(@sep,@s,@start_at)
        SET @data_len = CASE @end_at WHEN 0 THEN LEN(@s) ELSE @end_at-@start_at END
        INSERT INTO @RtnValue (s) VALUES( SUBSTRING(@s,@start_at,@data_len) );
        IF @end_at = 0 BREAK;
        SET @start_at = @end_at + @split_on_len
    END

    RETURN
END
go
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Relab].[FunctionalMatrixByTestRecord]'
GO
ALTER PROCEDURE [Relab].[FunctionalMatrixByTestRecord] @TRID INT = NULL, @TestStageID INT, @TestID INT, @BatchID INT, @UnitIDs NVARCHAR(MAX) = NULL, @FunctionalType INT
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @rows VARCHAR(8000)
	DECLARE @sql VARCHAR(8000)
	DECLARE @LookupType NVARCHAR(20)
	DECLARE @TestUnitID INT
	CREATE Table #units(id int) 
	INSERT INTO #units SELECT s FROM dbo.Split(',',@UnitIDs)
	
	IF (@TRID IS NOT NULL)
	BEGIN
		SELECT @TestUnitID = TestUnitID FROM TestRecords WHERE ID=@TRID
		INSERT INTO #units VALUES (@TestUnitID)
	END
	ELSE
	BEGIN
		EXEC(@UnitIDs)
	END
	
	IF (@FunctionalType = 1)
		SET @LookupType = 'SFIFunctionalMatrix'
	ELSE IF (@FunctionalType = 2)
		SET @LookupType = 'MFIFunctionalMatrix'
	ELSE IF (@FunctionalType = 3)
		SET @LookupType = 'AccFunctionalMatrix'
	ELSE
		SET @LookupType = 'SFIFunctionalMatrix'
	
	SELECT @rows=  ISNULL(STUFF(
		(SELECT DISTINCT '],[' + l.[Values]
		FROM dbo.Lookups l
		WHERE Type=@LookupType
		ORDER BY '],[' +  l.[Values]
		FOR XML PATH('')), 1, 2, '') + ']','[na]')
	
	SET @sql = 'SELECT *
		FROM (
			SELECT l.[Values], tu.ID AS TestUnitID, tu.BatchUnitNumber, 
				CASE 
					WHEN r.ID IS NULL 
					THEN -1
					ELSE (
						SELECT PassFail 
						FROM Relab.ResultsMeasurements rm 
							LEFT OUTER JOIN Lookups lr ON lr.Type=''' + CONVERT(VARCHAR, @LookupType) + ''' AND rm.MeasurementTypeID=lr.LookupID
						WHERE rm.ResultID=r.ID AND lr.[values] = l.[values] AND rm.Archived = 0)
				END As Row
			FROM dbo.Lookups l
			INNER JOIN TestUnits tu ON tu.BatchID = ' + CONVERT(VARCHAR, @BatchID) + ' AND 
				(
					(' + CONVERT(VARCHAR, ISNULL(CONVERT(VARCHAR,@TestUnitID), 'NULL')) + ' IS NULL)
					OR
					(' + CONVERT(VARCHAR, ISNULL(CONVERT(VARCHAR,@TestUnitID), 'NULL')) + ' IS NOT NULL AND tu.ID=' + CONVERT(VARCHAR, ISNULL(CONVERT(VARCHAR,@TestUnitID), 'NULL')) + ')
				)
			INNER JOIN #units ON tu.ID=@units.ID
			LEFT OUTER JOIN Relab.Results r ON r.TestID = ' + CONVERT(VARCHAR, @TestID) + ' AND r.TestStageID = ' + CONVERT(VARCHAR, @TestStageID) + ' 
				AND r.TestUnitID = tu.ID
			WHERE l.Type=''' + CONVERT(VARCHAR, @LookupType) + '''
			) te 
			PIVOT (MAX(row) FOR [Values] IN (' + @rows + ')) AS pvt
			ORDER BY BatchUnitNumber'

	PRINT @sql
	EXEC(@sql)
	DROP TABLE #units
	
	SET NOCOUNT OFF
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Relab].[remispResultsSearch]'
GO
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
	DROP TABLE #products
	DROP TABLE #jobs
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Relab].[ResultsParametersComma]'
GO
ALTER FUNCTION Relab.ResultsParametersComma(@ResultMeasurementID INT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @listStr NVARCHAR(MAX)
	SELECT @listStr = COALESCE(@listStr+', ' ,'') + LTRIM(RTRIM(ParameterName)) + ': ' + LTRIM(RTRIM(Value))
	FROM Relab.ResultsParameters
	WHERE Relab.ResultsParameters.ResultMeasurementID=@ResultMeasurementID AND ParameterName <> 'Command'
	ORDER BY ParameterName, Value ASC
	
	Return @listStr
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Relab].[remispResultsGraph]'
GO
ALTER PROCEDURE Relab.remispResultsGraph @MeasurementTypeID INT, @batchIDs NVARCHAR(MAX), @UnitIDs NVARCHAR(MAX), @TestID INT, @ParameterName NVARCHAR(255)=NULL, @ParameterValue NVARCHAR(250)=NULL, @ShowUpperLowerLimits INT = 1, @Xaxis INT, @PlotValue INT, @IncludeArchived INT = 0, @Stages NVARCHAR(MAX)
AS
BEGIN
	DECLARE @LoopValue NVARCHAR(500)
	DECLARE @ID INT
	DECLARE @query VARCHAR(MAX)
	DECLARE @query2 VARCHAR(MAX)
	CREATE TABLE #Graph (YAxis NVARCHAR(500), XAxis NVARCHAR(500), LoopValue NVARCHAR(500), LowerLimit NVARCHAR(255), UpperLimit NVARCHAR(255), QRANumber NVARCHAR(11), paramName NVARCHAR(500), paramValue NVARCHAR(500), BatchUnitNumber INT, ReTestNum INT, paramValueNumeric INT)
	DECLARE @COUNT INT
	CREATE TABLE #batches (id INT)
	CREATE TABLE #units (id INT)
	CREATE TABLE #stageIDs (id INT)
	INSERT INTO #batches SELECT s FROM dbo.Split(',', @batchIDs)
	INSERT INTO #units SELECT s FROM dbo.Split(',', @UnitIDs)
	INSERT INTO #stageIDs SELECT s FROM dbo.Split(',', @Stages)
	SELECT @COUNT = COUNT(*) FROM #batches 
	
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
		INNER JOIN #stageIDs s WITH(NOLOCK) ON s.ID = ts.ID
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
	
	UPDATE #Graph SET YAxis=1 WHERE YAxis IN ('True','Pass', 'true', 'pass')
	UPDATE #Graph SET YAxis=0 WHERE YAxis IN ('Fail','False', 'false', 'fail')
	
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
	DROP TABLE #GraphLimits
	DROP TABLE #batches
	DROP TABLE #units
	DROP TABLE #stageIDs
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Relab].[ResultsParametersNameComma]'
GO
ALTER FUNCTION [Relab].[ResultsParametersNameComma](@ResultMeasurementID INT, @Display NVARCHAR(1))
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @listStr NVARCHAR(MAX)
	SELECT @listStr = COALESCE(@listStr+', ' ,'') + CASE WHEN @Display = 'V' THEN LTRIM(RTRIM(Value)) ELSE LTRIM(RTRIM(ParameterName)) END
	FROM Relab.ResultsParameters
	WHERE Relab.ResultsParameters.ResultMeasurementID=@ResultMeasurementID AND ParameterName <> 'Command'
	ORDER BY ParameterName ASC
	
	Return @listStr
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Relab].[remispGetTestsByBatches]'
GO
ALTER PROCEDURE Relab.remispGetTestsByBatches @BatchIDs NVARCHAR(MAX)
AS
BEGIN
	DECLARE @batches TABLE(ID INT)
	INSERT INTO @batches SELECT s FROM dbo.Split(',',@BatchIDs)
	DECLARE @Count INT
	
	SELECT @Count = COUNT(*) FROM @batches
	
	SELECT DISTINCT TestID, tname
	FROM dbo.vw_GetTaskInfo i WITH(NOLOCK)
	WHERE i.processorder > -1 AND (i.Testtype=1 or i.TestID=1029) AND i.BatchID IN (SELECT id FROM @batches)
	GROUP BY TestID, tname
	HAVING COUNT(DISTINCT BatchID) >= @Count
	ORDER BY tname
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Relab].[remispGetMeasurementsByTest]'
GO
ALTER PROCEDURE Relab.remispGetMeasurementsByTest @BatchIDs NVARCHAR(MAX), @TestID INT, @ShowOnlyFailValue INT = 0
AS
BEGIN
	DECLARE @batches TABLE(ID INT)
	INSERT INTO @batches SELECT s FROM dbo.Split(',',@BatchIDs)
	DECLARE @Count INT
	
	SELECT @Count = COUNT(*) FROM @batches
	
	SELECT DISTINCT m.MeasurementTypeID, Lookups.[Values] As Measurement
	FROM TestUnits tu WITH(NOLOCK)
		INNER JOIN Relab.Results r WITH(NOLOCK) ON r.TestUnitID=tu.ID
		INNER JOIN Relab.ResultsMeasurements m WITH(NOLOCK) on m.ResultID=r.ID 
		INNER JOIN Lookups WITH(NOLOCK) ON m.MeasurementTypeID=Lookups.LookupID
		INNER JOIN @batches b ON tu.BatchID=b.ID
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
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Relab].[remispGetParametersByMeasurementTest]'
GO
ALTER PROCEDURE Relab.remispGetParametersByMeasurementTest @BatchIDs NVARCHAR(MAX), @TestID INT, @MeasurementTypeID INT, @ParameterName NVARCHAR(255) = NULL, @ShowOnlyFailValue INT = 0, @TestStageIDs NVARCHAR(MAX) = NULL
AS
BEGIN
	DECLARE @batches TABLE(ID INT)
	DECLARE @stages TABLE(ID INT)
	INSERT INTO @batches SELECT s FROM dbo.Split(',',@BatchIDs)
	INSERT INTO @stages SELECT s FROM dbo.Split(',',@TestStageIDs)
	
	DECLARE @Count INT
	
	SELECT @Count = COUNT(*) FROM @batches

	IF (@Count = 0)
	BEGIN
		SELECT DISTINCT Relab.ResultsParametersNameComma(m.ID, CASE WHEN @ParameterName IS NOT NULL THEN 'V' ELSE 'N' END) AS ParameterName
			FROM TestUnits tu WITH(NOLOCK)
				INNER JOIN Relab.Results r WITH(NOLOCK) ON r.TestUnitID=tu.ID
				INNER JOIN Relab.ResultsMeasurements m WITH(NOLOCK) on m.ResultID=r.ID 
				INNER JOIN @stages ts ON r.TestStageID=ts.ID
			WHERE m.MeasurementTypeID=@MeasurementTypeID AND r.TestID=@TestID AND m.Archived=0
				AND 
				(
					(@ParameterName IS NOT NULL AND Relab.ResultsParametersNameComma(m.ID, 
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
				AND Relab.ResultsParametersNameComma(m.ID, CASE WHEN @ParameterName IS NOT NULL THEN 'V' ELSE 'N' END) IS NOT NULL
			GROUP BY Relab.ResultsParametersNameComma(m.ID, CASE WHEN @ParameterName IS NOT NULL THEN 'V' ELSE 'N' END)
	END
	ELSE
		BEGIN	
			SELECT distinct Relab.ResultsParametersNameComma(m.ID, CASE WHEN @ParameterName IS NOT NULL THEN 'V' ELSE 'N' END) AS ParameterName
			FROM TestUnits tu WITH(NOLOCK)
				INNER JOIN Relab.Results r WITH(NOLOCK) ON r.TestUnitID=tu.ID
				INNER JOIN @batches b ON tu.BatchID=b.ID
				INNER JOIN Relab.ResultsMeasurements m WITH(NOLOCK) on m.ResultID=r.ID 
			WHERE m.MeasurementTypeID=@MeasurementTypeID AND r.TestID=@TestID AND m.Archived=0
				AND 
				(
					(@ParameterName IS NOT NULL AND Relab.ResultsParametersNameComma(m.ID, 
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
				AND Relab.ResultsParametersNameComma(m.ID, CASE WHEN @ParameterName IS NOT NULL THEN 'V' ELSE 'N' END) IS NOT NULL  
			GROUP BY Relab.ResultsParametersNameComma(m.ID, CASE WHEN @ParameterName IS NOT NULL THEN 'V' ELSE 'N' END)
			HAVING COUNT(DISTINCT b.ID) >= @Count
		END
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Relab].[remispMeasurementsByReq_Test]'
GO
ALTER PROCEDURE [Relab].[remispMeasurementsByReq_Test] @RequestNumber NVARCHAR(11), @TestIDs NVARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @tests TABLE(ID INT)
	INSERT INTO @tests SELECT s FROM dbo.Split(',',@TestIDs)
	DECLARE @FalseBit BIT
	DECLARE @TrueBit BIT
	CREATE TABLE #parameters (ResultMeasurementID INT)
	SET @FalseBit = CONVERT(BIT, 0)
	SET @TrueBit = CONVERT(BIT, 1)

	DECLARE @rows VARCHAR(8000)
	DECLARE @sql VARCHAR(8000)
	SELECT @rows=  ISNULL(STUFF(
		( 
		SELECT DISTINCT '],[' + rp.ParameterName
		FROM Relab.ResultsMeasurements rm WITH(NOLOCK)
			INNER JOIN Relab.Results r ON r.ID=rm.ResultID
			INNER JOIN TestUnits tu ON tu.ID = r.TestUnitID
			INNER JOIN Batches b ON b.ID=tu.BatchID
			INNER JOIN Tests t ON t.ID=r.TestID
			INNER JOIN @tests tst ON t.ID=tst.ID
			LEFT OUTER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON rm.ID=rp.ResultMeasurementID
		WHERE b.QRANumber=@RequestNumber AND rm.Archived=@FalseBit AND rp.ParameterName <> 'Command'
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
				INNER JOIN Relab.Results r ON r.ID=rm.ResultID
				INNER JOIN TestUnits tu ON tu.ID = r.TestUnitID
				INNER JOIN Batches b ON b.ID=tu.BatchID
				INNER JOIN Tests t ON t.ID=r.TestID
				INNER JOIN @tests tst ON t.ID=tst.ID
				LEFT OUTER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON rm.ID=rp.ResultMeasurementID
			WHERE b.QRANumber=''' + @RequestNumber + ''' AND rm.Archived=' + @FalseBit + ' AND rp.ParameterName <> ''Command'' 
			) te PIVOT (MAX(Value) FOR ParameterName IN (' + @rows + ')) AS pvt')
	END
	ELSE
	BEGIN
		EXEC ('ALTER TABLE #parameters DROP COLUMN na')
	END

	SELECT t.TestName, ts.TestStageName, tu.BatchUnitNumber, ISNULL(ISNULL(ISNULL(lt.[Values], ltsf.[Values]), ltmf.[Values]), ltacc.[Values]) As Measurement, 
		LowerLimit AS [Lower Limit], UpperLimit AS [Upper Limit], MeasurementValue AS Result, lu.[Values] As Unit, 
		CASE WHEN rm.PassFail=1 THEN 'Pass' ELSE 'Fail' END AS [Pass/Fail], rm.ReTestNum AS [Test Num],
		ISNULL(rmf.[File], 0) AS [Image], ISNULL(UPPER(SUBSTRING(rmf.ContentType,2,LEN(rmf.ContentType))), 'PNG') AS ContentType, p.*
	FROM Relab.ResultsMeasurements rm WITH(NOLOCK)
		INNER JOIN Relab.Results r ON r.ID=rm.ResultID
		INNER JOIN TestUnits tu ON tu.ID = r.TestUnitID
		INNER JOIN Batches b ON b.ID=tu.BatchID
		INNER JOIN Tests t ON t.ID=r.TestID
		INNER JOIN @tests tst ON t.ID=tst.ID
		INNER JOIN TestStages ts ON ts.ID=r.TestStageID
		LEFT OUTER JOIN Lookups lu WITH(NOLOCK) ON lu.Type='UnitType' AND lu.LookupID=rm.MeasurementUnitTypeID
		LEFT OUTER JOIN Lookups lt WITH(NOLOCK) ON lt.Type='MeasurementType' AND lt.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Lookups ltsf WITH(NOLOCK) ON ltsf.Type='SFIFunctionalMatrix' AND ltsf.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Lookups ltmf WITH(NOLOCK) ON ltmf.Type='MFIFunctionalMatrix' AND ltmf.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Lookups ltacc WITH(NOLOCK) ON ltacc.Type='AccFunctionalMatrix' AND ltacc.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Relab.ResultsMeasurementsFiles rmf WITH(NOLOCK) ON rmf.ResultMeasurementID=rm.ID
		LEFT OUTER JOIN #parameters p WITH(NOLOCK) ON p.ResultMeasurementID=rm.ID
		LEFT OUTER JOIN Relab.ResultsXML x ON x.ID = rm.XMLID
	WHERE b.QRANumber=@RequestNumber AND rm.Archived=@FalseBit
		AND (ISNULL(ISNULL(ISNULL(lt.[Values], ltsf.[Values]), ltmf.[Values]), ltacc.[Values]) NOT IN ('start', 'Start utc', 'end'))
	ORDER BY tu.BatchUnitNumber, ts.ProcessOrder, rm.ReTestNum

	DROP TABLE #parameters
	SET NOCOUNT OFF
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Relab].[remispGetUnitsByTestMeasurementParameters]'
GO
ALTER PROCEDURE Relab.remispGetUnitsByTestMeasurementParameters @BatchIDs NVARCHAR(MAX), @TestID INT, @MeasurementTypeID INT, @ParameterName NVARCHAR(255)=null, @ParameterValue NVARCHAR(255)=null, @GetStages BIT = 0, @ShowOnlyFailValue INT = 0
AS
BEGIN
	DECLARE @batches TABLE(ID INT)
	INSERT INTO @batches SELECT s FROM dbo.Split(',',@BatchIDs)
	DECLARE @Count INT
	DECLARE @FalseBit BIT
	SET @FalseBit = CONVERT(BIT, 0)
	
	SELECT DISTINCT CASE WHEN @GetStages = 1 THEN ts.ID ELSE tu.ID END AS ID, tu.BatchID, CASE WHEN @GetStages = 1 THEN SUBSTRING(j.JobName, 0, CHARINDEX(' ', j.Jobname, 0)) + ' ' + ts.TestStageName ELSE CONVERT(VARCHAR, tu.batchUnitNumber) END AS Name, Batches.QRANumber
	FROM TestUnits tu WITH(NOLOCK)
		INNER JOIN Relab.Results r WITH(NOLOCK) ON r.TestUnitID=tu.ID
		INNER JOIN Relab.ResultsMeasurements m WITH(NOLOCK) on m.ResultID=r.ID 
		LEFT OUTER JOIN Relab.ResultsParameters p WITH(NOLOCK) ON m.ID=p.ResultMeasurementID
		INNER JOIN @batches b ON tu.BatchID=b.ID
		INNER JOIN TestStages ts WITH(NOLOCK) ON ts.ID = r.TestStageID AND LTRIM(RTRIM(ts.TestStageName)) <> 'calibration'
		INNER JOIN Jobs j WITH(NOLOCK) ON j.ID=ts.JobID
		INNER JOIN Batches WITH(NOLOCK) ON b.id = Batches.ID
	WHERE m.MeasurementTypeID=@MeasurementTypeID AND r.TestID=@TestID AND m.Archived=@FalseBit		
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
			(@ShowOnlyFailValue = 1 AND m.PassFail=@FalseBit)
			OR
			(@ShowOnlyFailValue = 0)
		)
	GROUP BY CASE WHEN @GetStages = 1 THEN ts.ID ELSE tu.ID END, tu.BatchID, CASE WHEN @GetStages = 1 THEN SUBSTRING(j.JobName, 0, CHARINDEX(' ', j.Jobname, 0)) + ' ' + ts.TestStageName ELSE CONVERT(VARCHAR, tu.batchUnitNumber) END, Batches.QRANumber
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Relab].[remispResultsSummaryExport]'
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
		FROM Relab.Results r WITH(NOLOCK)
			INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
			INNER JOIN Tests t WITH(NOLOCK) ON r.TestID=t.ID
			INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID=r.TestUnitID
			INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID
			INNER JOIN Relab.ResultsMeasurements m WITH(NOLOCK) ON m.ResultID=r.ID
			LEFT OUTER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON m.ID=rp.ResultMeasurementID
		WHERE b.ID=@BatchID AND (@ResultID IS NULL OR (@ResultID IS NOT NULL AND r.ID=@ResultID)) AND rp.ParameterName <> 'Command' 
		ORDER BY '],[' +  rp.ParameterName
		FOR XML PATH('')), 1, 2, '') + ']','[na]')

	SET @sql = 'ALTER TABLE #parameters ADD ' + convert(varchar(8000), replace(@rows, ']', '] NVARCHAR(250)'))
	EXEC (@sql)

	IF (@rows != '[na]')
	BEGIN
		SET @sql = 'INSERT INTO #parameters SELECT *
		FROM (
			SELECT rp.ResultMeasurementID, rp.ParameterName, rp.Value
			FROM Relab.Results r WITH(NOLOCK)
				INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
				INNER JOIN Tests t WITH(NOLOCK) ON r.TestID=t.ID
				INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID=r.TestUnitID
				INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID
				INNER JOIN Relab.ResultsMeasurements m WITH(NOLOCK) ON m.ResultID=r.ID
				LEFT OUTER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON m.ID=rp.ResultMeasurementID
			WHERE b.ID=' + CONVERT(VARCHAR, @BatchID) + ' AND rp.ParameterName <> ''Command'' AND (' + CASE WHEN convert(varchar,@ResultID) IS NULL THEN 'NULL' ELSE convert(varchar,@ResultID) END + ' IS NULL OR (' + CASE WHEN convert(varchar,@ResultID) IS NULL THEN 'NULL' ELSE convert(varchar,@ResultID) END + ' IS NOT NULL AND r.ID=' + CASE WHEN @ResultID IS NOT NULL THEN CONVERT(VARCHAR, @ResultID) ELSE 'NULL' END + '))
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
		m.ReTestNum, m.Archived, m.Comment, rxml.VerNum AS XMLVersion, rxml.StartDate, rxml.EndDate, rxml.StationName, m.Description, p.*
	FROM Relab.Results r WITH(NOLOCK)
		INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
		INNER JOIN Tests t WITH(NOLOCK) ON r.TestID=t.ID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID=r.TestUnitID
		INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID
		INNER JOIN Relab.ResultsMeasurements m WITH(NOLOCK) ON m.ResultID=r.ID
		LEFT OUTER JOIN Lookups lm WITH(NOLOCK) ON m.MeasurementTypeID=lm.LookupID
		LEFT OUTER JOIN Lookups lu WITH(NOLOCK) ON m.MeasurementUnitTypeID=lu.LookupID
		LEFT OUTER JOIN Relab.ResultsXML rxml WITH(NOLOCK) ON rxml.ID=m.XMLID
		LEFT OUTER JOIN #parameters p WITH(NOLOCK) ON p.ResultMeasurementID=m.ID
	WHERE b.ID=@BatchID AND (@ResultID IS NULL OR (@ResultID IS NOT NULL AND r.ID=@ResultID))
	ORDER BY tu.BatchUnitNumber, ts.TestStageName, TestName
	
	SET NOCOUNT OFF
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Relab].[remispResultMeasurements]'
GO
ALTER PROCEDURE [Relab].[remispResultMeasurements] @ResultID INT, @OnlyFails INT = 0, @IncludeArchived INT = 0
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @FalseBit BIT
	DECLARE @ReTestNum INT
	CREATE TABLE #parameters (ResultMeasurementID INT)
	SELECT @ReTestNum= MAX(Relab.ResultsMeasurements.ReTestNum) FROM Relab.ResultsMeasurements WITH(NOLOCK) WHERE Relab.ResultsMeasurements.ResultID=@ResultID
	SET @FalseBit = CONVERT(BIT, 0)

	DECLARE @rows VARCHAR(8000)
	DECLARE @sql VARCHAR(8000)
	SELECT @rows=  ISNULL(STUFF(
		( 
		SELECT DISTINCT '],[' + rp.ParameterName
		FROM Relab.ResultsMeasurements rm WITH(NOLOCK)
			LEFT OUTER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON rm.ID=rp.ResultMeasurementID
		WHERE ResultID=@ResultID AND ((@IncludeArchived = 0 AND rm.Archived=@FalseBit) OR (@IncludeArchived=1)) AND ((@OnlyFails = 1 AND PassFail=@FalseBit) OR (@OnlyFails = 0))
			AND rp.ParameterName <> 'Command'
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
			WHERE ResultID=' + @ResultID + ' AND ((' + @IncludeArchived + ' = 0 AND rm.Archived=' + @FalseBit + ') OR (' + @IncludeArchived + '=1)) 
				AND ((' + @OnlyFails + ' = 1 AND PassFail=' + @FalseBit + ') OR (' + @OnlyFails + ' = 0)) AND rp.ParameterName <> ''Command'' 
			) te PIVOT (MAX(Value) FOR ParameterName IN (' + @rows + ')) AS pvt')
	END
	ELSE
	BEGIN
		EXEC ('ALTER TABLE #parameters DROP COLUMN na')
	END

	SELECT CASE WHEN rm.Archived = 1 THEN 
	(SELECT MIN(ID) FROM relab.ResultsMeasurements rm2 WHERE rm2.ResultID=rm.ResultID AND rm2.MeasurementTypeID=rm.MeasurementTypeID 
		and isnull(Relab.ResultsParametersComma(rm.ID),'') = isnull(Relab.ResultsParametersComma(rm2.ID),'') and rm2.Archived=0)
	ELSE rm.ID END AS ID, ISNULL(ISNULL(ISNULL(lt.[Values], ltsf.[Values]), ltmf.[Values]), ltacc.[Values]) As Measurement, LowerLimit AS [Lower Limit], UpperLimit AS [Upper Limit], MeasurementValue AS Result, lu.[Values] As Unit, 
		CASE WHEN PassFail=1 THEN 'Pass' ELSE 'Fail' END AS [Pass/Fail],
		rm.MeasurementTypeID, rm.ReTestNum AS [Test Num], rm.Archived, rm.XMLID, 
		@ReTestNum AS MaxVersion, rm.Comment, ISNULL(rmf.[File], 0) AS [Image], 
		ISNULL(UPPER(SUBSTRING(rmf.ContentType,2,LEN(rmf.ContentType))), 'PNG') AS ContentType, rm.Description, 
		ISNULL((SELECT TOP 1 1 FROM Relab.ResultsMeasurementsAudit rma WHERE rma.ResultMeasurementID=rm.ID AND rma.PassFail <> rm.PassFail ORDER BY DateEntered DESC), 0) As WasChanged,
		 ISNULL(CONVERT(NVARCHAR, rm.DegradationVal), 'N/A') AS [Degradation], x.VerNum, p.*
	FROM Relab.ResultsMeasurements rm WITH(NOLOCK)
		LEFT OUTER JOIN Lookups lu WITH(NOLOCK) ON lu.Type='UnitType' AND lu.LookupID=rm.MeasurementUnitTypeID
		LEFT OUTER JOIN Lookups lt WITH(NOLOCK) ON lt.Type='MeasurementType' AND lt.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Lookups ltsf WITH(NOLOCK) ON ltsf.Type='SFIFunctionalMatrix' AND ltsf.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Lookups ltmf WITH(NOLOCK) ON ltmf.Type='MFIFunctionalMatrix' AND ltmf.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Lookups ltacc WITH(NOLOCK) ON ltacc.Type='AccFunctionalMatrix' AND ltacc.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Relab.ResultsMeasurementsFiles rmf WITH(NOLOCK) ON rmf.ResultMeasurementID=rm.ID
		LEFT OUTER JOIN #parameters p WITH(NOLOCK) ON p.ResultMeasurementID=rm.ID
		LEFT OUTER JOIN Relab.ResultsXML x ON x.ID = rm.XMLID
	WHERE rm.ResultID=@ResultID AND ((@IncludeArchived = 0 AND rm.Archived=@FalseBit) OR (@IncludeArchived=1)) AND ((@OnlyFails = 1 AND PassFail=@FalseBit) OR (@OnlyFails = 0))
	ORDER BY CASE WHEN rm.Archived = 1 THEN 
	(SELECT MIN(ID) FROM relab.ResultsMeasurements rm2 WHERE rm2.ResultID=rm.ResultID AND rm2.MeasurementTypeID=rm.MeasurementTypeID 
		and isnull(Relab.ResultsParametersComma(rm.ID),'') = isnull(Relab.ResultsParametersComma(rm2.ID),'') and rm2.Archived=0)
	ELSE rm.ID END, rm.ReTestNum

	DROP TABLE #parameters
	SET NOCOUNT OFF
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
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
