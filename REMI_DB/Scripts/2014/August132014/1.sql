/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        (local).REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 7/29/2014 1:41:43 PM

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
PRINT N'Altering [Relab].[remispGetParametersByMeasurementTest]'
GO
ALTER PROCEDURE Relab.remispGetParametersByMeasurementTest @BatchIDs NVARCHAR(MAX), @TestID INT, @MeasurementTypeID INT, @ParameterName NVARCHAR(255) = NULL, @ShowOnlyFailValue INT = 0, @TestStageIDs NVARCHAR(MAX) = NULL
AS
BEGIN
	CREATE Table #batches(id int) 
	CREATE Table #stages(id int) 
	DECLARE @Count INT
	EXEC(@BatchIDs)
	EXEC(@TestStageIDs)
	
	SELECT @Count = COUNT(*) FROM #batches

	IF (@Count = 0)
	BEGIN
		SELECT DISTINCT Relab.ResultsParametersNameComma(m.ID, CASE WHEN @ParameterName IS NOT NULL THEN 'V' ELSE 'N' END) AS ParameterName
			FROM TestUnits tu WITH(NOLOCK)
				INNER JOIN Relab.Results r WITH(NOLOCK) ON r.TestUnitID=tu.ID
				INNER JOIN Relab.ResultsMeasurements m WITH(NOLOCK) on m.ResultID=r.ID 
				INNER JOIN #stages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
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
				INNER JOIN #batches b WITH(NOLOCK) ON tu.BatchID=b.ID
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

	DROP TABLE #batches
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[remispJobsList]'
GO
CREATE PROCEDURE [dbo].remispJobsList
AS
	BEGIN
		DECLARE @TrueBit BIT
		SET @TrueBit = CONVERT(BIT, 1)
		
		SELECT j.ID, j.JobName, j.IsActive, j.ContinueOnFailures, j.LastUser, j.NoBSN, j.TechnicalOperationsTest, j.ProcedureLocation, j.MechanicalTest,
			j.WILocation, j.OperationsTest, j.Comment
		FROM Jobs j
		WHERE j.IsActive=@TrueBit
		ORDER BY j.JobName
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
	CREATE TABLE #products (id INT)
	CREATE TABLE #jobs (id INT)
	CREATE TABLE #stages (id INT)
	DECLARE @LoopValue NVARCHAR(500)
	DECLARE @ID INT
	DECLARE @query VARCHAR(MAX)
	DECLARE @query2 VARCHAR(MAX)
	DECLARE @FalseBit BIT
	SET @FalseBit = CONVERT(BIT, 0)
	SET @query = ''	
	SET @query2 = ''
	EXEC (@ProductIDs)
	EXEC (@JobNameIDs)
	EXEC (@TestStageIDs)
	
	SET @query = 'SELECT b.QRANumber, tu.BatchUnitNumber, ts.TestStageName AS TestStageName, rm.MeasurementValue AS MeasurementValue, rm.LowerLimit, rm.UpperLimit, 
		r.ID AS ResultID, b.ID AS BatchID, pd.ProductGroupName, pd.ID AS ProductID, j.JobName, l.[values] AS TestCenter, CASE WHEN rm.PassFail=1 THEN ''Pass'' ELSE ''Fail'' END AS PassFail,
		Relab.ResultsParametersComma(p.ResultMeasurementID) As Params, lm.[Values] AS MeasurementName
	FROM Relab.Results r WITH(NOLOCK)
		INNER JOIN TestUnits tu WITH(NOLOCK) ON r.TestUnitID=tu.ID
		INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID
		INNER JOIN Relab.ResultsMeasurements rm WITH(NOLOCK) ON r.ID=rm.ResultID
		INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
		LEFT OUTER JOIN Relab.ResultsParameters p WITH(NOLOCK) ON p.ResultMeasurementID=rm.ID
		INNER JOIN Products pd WITH(NOLOCK) ON pd.ID = b.ProductID
		INNER JOIN Jobs j WITH(NOLOCK) ON j.ID=ts.JobID
		INNER JOIN Lookups l WITH(NOLOCK) ON l.LookupID=b.TestCenterLocationID
		INNER JOIN #products products WITH(NOLOCK) ON products.ID = pd.ID
		INNER JOIN Lookups lm ON lm.LookupID = rm.MeasurementTypeID AND lm.Type=''MeasurementType''
		INNER JOIN #jobs job WITH(NOLOCK) ON job.id=j.ID
		INNER JOIN #stages stage WITH(NOLOCK) ON stage.id=ts.ID
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
		SET @query2 = ' AND (Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN '''+ ISNULL(@ParameterName,'')+''' <> '''' THEN ''N'' ELSE ''V'' END)='''+ ISNULL(@ParameterName,'')+''') '
	IF (@ParameterValue IS NOT NULL)
		SET @query2 = ' AND (Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN ''V'' ELSE ''N'' END)='''+ ISNULL(@ParameterValue,'')+''') '


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
	DROP TABLE #products
	DROP TABLE #stages
	DROP TABLE #jobs
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering permissions on [dbo].[remispJobsList]'
GO
GRANT EXECUTE ON  [dbo].[remispJobsList] TO [remi]
GO
alter table Lookups Add ParentID INT NULL
GO

ALTER PROCEDURE remispGetLookups @Type NVARCHAR(150), @ProductID INT = NULL, @ParentID INT = NULL
AS
BEGIN
	SELECT 0 AS LookupID, @Type AS Type, '' As LookupType, CONVERT(BIT, 0) As HasAccess, NULL AS Description, NULL AS ParentID, NULL AS Parent
	UNION
	SELECT l.LookupID, l.Type, l.[Values] As LookupType, CASE WHEN pl.ID IS NOT NULL THEN CONVERT(BIT, 1) ELSE CONVERT(BIT, 0) END As HasAccess, l.Description, l.ParentID, p.[Values] AS Parent
	FROM Lookups l
		LEFT OUTER JOIN ProductLookups pl ON pl.ProductID=@ProductID AND l.LookupID=pl.LookupID
		LEFT OUTER JOIN Lookups p ON p.LookupID=l.ParentID
	WHERE l.Type=@Type AND l.IsActive=1 AND 
		(
			(@ParentID IS NOT NULL AND @ParentID <> 0 AND l.ParentID = @ParentID)
			OR
			(@ParentID IS NULL OR @ParentID = 0)
		)
	ORDER By LookupType
END
GO
GRANT EXECUTE ON remispGetLookups TO REMI
GO
ALTER PROCEDURE [dbo].[remispSaveLookup] @LookupType NVARCHAR(150), @Value NVARCHAR(150), @IsActive INT = 1, @Description NVARCHAR(200) = NULL, @ParentID INT = NULL
AS
BEGIN
	DECLARE @LookupID INT
	SELECT @LookupID = MAX(LookupID) + 1 FROM Lookups

	IF (@ParentID = 0)
	BEGIN
		SET @ParentID = NULL
	END
	
	IF LTRIM(RTRIM(@Value)) <> '' AND NOT EXISTS (SELECT 1 FROM Lookups WHERE Type=@LookupType AND LTRIM(RTRIM([Values])) = LTRIM(RTRIM(@Value)))
	BEGIN
		INSERT INTO Lookups (LookupID, Type, [Values], IsActive, Description, ParentID) 
		VALUES (@LookupID, @LookupType, LTRIM(RTRIM(@Value)), @IsActive, @Description, @ParentID)
	END
	ELSE
	BEGIN
		UPDATE Lookups
		SET IsActive=@IsActive, Description=@Description, ParentID=@ParentID
		WHERE Type=@LookupType AND [values]=LTRIM(RTRIM(@Value))
	END
END
GO
GRANT EXECUTE ON remispSaveLookup TO Remi
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