/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        (local).REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 10/14/2014 11:40:39 AM

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
PRINT N'Altering [Relab].[remispMeasurementsByReq_Test]'
GO
ALTER PROCEDURE [Relab].[remispMeasurementsByReq_Test] @RequestNumber NVARCHAR(11), @TestName NVARCHAR(400)
AS
BEGIN
	SET NOCOUNT ON

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
			LEFT OUTER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON rm.ID=rp.ResultMeasurementID
		WHERE b.QRANumber=@RequestNumber AND rm.Archived=@FalseBit AND t.TestName=@TestName AND rp.ParameterName <> 'Command'
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
				LEFT OUTER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON rm.ID=rp.ResultMeasurementID
			WHERE b.QRANumber=''' + @RequestNumber + ''' AND rm.Archived=' + @FalseBit + ' AND t.TestName=''' + @TestName + ''' AND rp.ParameterName <> ''Command'' 
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
		INNER JOIN TestStages ts ON ts.ID=r.TestStageID
		LEFT OUTER JOIN Lookups lu WITH(NOLOCK) ON lu.Type='UnitType' AND lu.LookupID=rm.MeasurementUnitTypeID
		LEFT OUTER JOIN Lookups lt WITH(NOLOCK) ON lt.Type='MeasurementType' AND lt.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Lookups ltsf WITH(NOLOCK) ON ltsf.Type='SFIFunctionalMatrix' AND ltsf.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Lookups ltmf WITH(NOLOCK) ON ltmf.Type='MFIFunctionalMatrix' AND ltmf.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Lookups ltacc WITH(NOLOCK) ON ltacc.Type='AccFunctionalMatrix' AND ltacc.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Relab.ResultsMeasurementsFiles rmf WITH(NOLOCK) ON rmf.ResultMeasurementID=rm.ID
		LEFT OUTER JOIN #parameters p WITH(NOLOCK) ON p.ResultMeasurementID=rm.ID
		LEFT OUTER JOIN Relab.ResultsXML x ON x.ID = rm.XMLID
	WHERE b.QRANumber=@RequestNumber AND rm.Archived=@FalseBit AND t.TestName=@TestName
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
ROLLBACK TRANSACTION
END
ELSE PRINT 'The database update failed'
GO
DROP TABLE #tmpErrors
GO