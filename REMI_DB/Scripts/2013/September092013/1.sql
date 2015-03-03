/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        CI0000001593275.REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 9/6/2013 10:41:36 AM

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
PRINT N'Altering [Relab].[remispResultsSearch]'
GO
ALTER PROCEDURE Relab.remispResultsSearch @MeasurementTypeID INT, @TestID INT, @ParameterName NVARCHAR(255)=NULL, @ParameterValue NVARCHAR(250)=NULL, @ProductID INT
AS
BEGIN
	DECLARE @LoopValue NVARCHAR(500)
	DECLARE @ID INT
	DECLARE @query VARCHAR(MAX)
	DECLARE @query2 VARCHAR(MAX)
	SET @query = ''	
	SET @query2 = ''
	
	SET @query = 'SELECT b.QRANumber, tu.BatchUnitNumber, ts.TestStageName AS TestStageName, rm.MeasurementValue AS MeasurementValue, rm.LowerLimit, rm.UpperLimit, 
		r.ID AS ResultID, b.ID AS BatchID, pd.ProductGroupName, pd.ID AS ProductID
	FROM Relab.Results r WITH(NOLOCK)
		INNER JOIN TestUnits tu WITH(NOLOCK) ON r.TestUnitID=tu.ID
		INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID
		INNER JOIN Relab.ResultsMeasurements rm WITH(NOLOCK) ON r.ID=rm.ResultID
		INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
		LEFT OUTER JOIN Relab.ResultsParameters p ON p.ResultMeasurementID=rm.ID
		INNER JOIN Products pd ON pd.ID = b.ProductID
	WHERE rm.MeasurementTypeID='+CONVERT(VARCHAR,@MeasurementTypeID)+' AND r.TestID='+CONVERT(VARCHAR,@TestID)+' AND MeasurementValue IS NOT NULL 
		AND
		(
			(' + CONVERT(VARCHAR,@ProductID) + ' > 0 AND pd.ID=' + CONVERT(VARCHAR,@ProductID) + ')
			OR
			(' + CONVERT(VARCHAR,@ProductID) + ' = 0)
		) '

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
ALTER PROCEDURE [Relab].[remispResultsFailureAnalysis] @TestID INT, @BatchID INT
AS
BEGIN
	SET NOCOUNT ON

	SELECT lm.[Values] + ' ' + ISNULL(Relab.ResultsParametersComma(rm.ID), '') AS Failure, ts.TestStageName, tu.BatchUnitNumber, rm.ID AS MeasurementID, r.TestID, r.ID AS ResultID, @BatchID AS BatchID
	FROM Relab.Results r
		INNER JOIN Relab.ResultsMeasurements rm ON rm.ResultID=r.ID AND rm.PassFail=0 AND rm.Archived=0
		INNER JOIN Lookups lm ON lm.LookupID=rm.MeasurementTypeID
		INNER JOIN TestUnits tu ON tu.ID=r.TestUnitID
		INNER JOIN TestStages ts ON ts.ID=r.TestStageID
	WHERE r.TestID=@TestID AND tu.BatchID=@BatchID AND r.PassFail=0
	ORDER BY BatchUnitNumber, ProcessOrder, Failure

	SET NOCOUNT OFF
END
GO
GRANT EXECUTE ON [Relab].[remispResultsFailureAnalysis] TO Remi
GO
ALTER PROCEDURE [dbo].[remispYourBatchesGetActiveBatches] @UserID int, @ByPassProductCheck INT = 0, @Year INT = 0, @OnlyShowQRAWithResults INT = 0
AS	
	SELECT BatchesRows.ID, BatchesRows.ProductGroupName,BatchesRows.QRANumber, (BatchesRows.QRANumber + ' ' + BatchesRows.ProductGroupName) AS Name
	FROM     
		(
			SELECT p.ProductGroupName,b.QRANumber, b.ID
				FROM Batches as b WITH(NOLOCK)
				INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
			WHERE ( 
					(@Year = 0 AND BatchStatus NOT IN(5,7))
					OR
					(@Year > 0 AND b.QRANumber LIKE 'QRA-' + RIGHT(CONVERT(NVARCHAR, @Year), 2) + '%')
				  )
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
				AND (@OnlyShowQRAWithResults = 0 OR (@OnlyShowQRAWithResults = 1 AND b.ID IN (SELECT tu.BatchID FROM Relab.Results r INNER JOIN TestUnits tu ON tu.ID=r.TestUnitID)))
		) AS BatchesRows
	ORDER BY BatchesRows.QRANumber
	RETURN
GO
GRANT EXECUTE ON remispYourBatchesGetActiveBatches TO Remi
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