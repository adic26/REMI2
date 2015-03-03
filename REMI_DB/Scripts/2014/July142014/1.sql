/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        (local).REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 7/8/2014 2:55:15 PM

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
PRINT N'Altering [dbo].[ProductTestReady]'
GO
ALTER TABLE [dbo].[ProductTestReady] ADD
[JIRA] [int] NULL
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispProductTestReady]'
GO
ALTER PROCEDURE [dbo].[remispProductTestReady] @ProductID INT, @MNum NVARCHAR(3)
AS
BEGIN
	DECLARE @PSID AS INT = (SELECT ID FROM ProductSettings WHERE KeyName=@MNum AND ProductID=@ProductID)
	
	SELECT t.TestName, @MNum AS M, CASE ptr.IsReady WHEN 1 THEN 'Yes' WHEN 2 THEN 'No' WHEN 3 THEN 'N/A' ELSE '' END AS IsReady, 
		ptr.Comment, t.Owner, t.Trainee, t.ID As TestID, ptr.ID As ReadyID, @PSID As PSID,
		CASE ptr.IsNestReady WHEN 1 THEN 'Yes' WHEN 2 THEN 'No' WHEN 3 THEN 'N/A' ELSE '' END AS IsNestReady, CASE WHEN JIRA = 0 THEN NULL ELSE JIRA END AS JIRA
	FROM Tests t
		LEFT OUTER JOIN ProductTestReady ptr ON ptr.TestID=t.ID AND ptr.ProductID=@ProductID AND ptr.PSID=@PSID
	WHERE t.TestName IN ('Parametric Radiated Wi-Fi','Acoustic Test', 'HAC Test', 'Sensor Test',
		'Touch Panel Test','Insertion','Top Facing Keys Tactility Test','Peripheral Keys Tactility Test','Charging Test',
		'Camera Front','Bluetooth Test','Accessory Charging','Accessory Acoustic Test','Radiated RF Test','KET Top Facing Keys Cycling Test')
		AND ISNULL(t.IsArchived, 0) = 0
	ORDER BY t.TestName
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTrackingTypesTests]'
GO
ALTER PROCEDURE [dbo].[remispTrackingTypesTests] @TestTypeID INT = 1, @IncludeArchived BIT = 0, @TrackTypeID INT = 0
AS
BEGIN
	DECLARE @rows VARCHAR(8000)
	DECLARE @query VARCHAR(4000)
	SELECT @rows=  ISNULL(STUFF(
	( 
	SELECT DISTINCT '],[' + tlt.TrackingLocationTypeName
	FROM  dbo.TrackingLocationTypes tlt
	WHERE (@TrackTypeID > 0 AND tlt.TrackingLocationFunction = @TrackTypeID) OR (@TrackTypeID = 0)
	ORDER BY '],[' +  tlt.TrackingLocationTypeName
	FOR XML PATH('')), 1, 2, '') + ']','[na]')
	
	SET @query = '
		SELECT *
		FROM
		(
			SELECT CASE WHEN tlft.ID IS NOT NULL THEN 1 ELSE NULL END As Row, t.TestName, tlt.TrackingLocationTypeName
			FROM dbo.TrackingLocationTypes tlt
				LEFT OUTER JOIN dbo.TrackingLocationsForTests tlft ON tlft.TrackingLocationtypeID = tlt.ID
				INNER JOIN dbo.Tests t ON t.ID=tlft.TestID
			WHERE t.TestName IS NOT NULL AND t.TestType=' + CONVERT(VARCHAR, @TestTypeID) + ' AND ISNULL(t.IsArchived, 0)=' + CONVERT(VARCHAR, @IncludeArchived) + '
		)r
		PIVOT 
		(
			MAX(Row) 
			FOR TrackingLocationTypeName 
				IN ('+@rows+')
		) AS pvt
		ORDER BY TestName'
	EXECUTE (@query)
END
GO
ALTER PROCEDURE Relab.remispResultsSearch @MeasurementTypeID INT, @TestID INT, @ParameterName NVARCHAR(255)=NULL, @ParameterValue NVARCHAR(250)=NULL, @ProductIDs NVARCHAR(MAX) = NULL, @JobName NVARCHAR(400)='All', @TestStageID INT = 0, @TestCenterID INT = 0, @ShowFailureOnly INT = 0
AS
BEGIN
	CREATE TABLE #products (id INT)
	DECLARE @LoopValue NVARCHAR(500)
	DECLARE @ID INT
	DECLARE @query VARCHAR(MAX)
	DECLARE @query2 VARCHAR(MAX)
	DECLARE @FalseBit BIT
	SET @FalseBit = CONVERT(BIT, 0)
	SET @query = ''	
	SET @query2 = ''
	EXEC (@ProductIDs)
	
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
		)
		AND
		(
			(LTRIM(RTRIM(''' + @JobName + ''')) <> ''all'' AND LTRIM(RTRIM(j.JobName))=LTRIM(RTRIM(''' + @JobName + ''')))
			OR
			(''' + @JobName + ''' = ''All'')
		)
		AND
		(
			(' + CONVERT(VARCHAR,@TestStageID) + ' > 0 AND ts.ID=' + CONVERT(VARCHAR,@TestStageID) + ')
			OR
			(' + CONVERT(VARCHAR,@TestStageID) + ' = 0)
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
END
GO
GRANT EXECUTE ON Relab.remispResultsSearch TO REMI
GO
ALTER PROCEDURE Relab.remispGetParametersByMeasurementTest @BatchIDs NVARCHAR(MAX), @TestID INT, @MeasurementTypeID INT, @ParameterName NVARCHAR(255) = NULL, @ShowOnlyFailValue INT = 0, @TestStageID INT = 0
AS
BEGIN
	CREATE Table #batches(id int) 
	DECLARE @Count INT
	EXEC(@BatchIDs)
	
	SELECT @Count = COUNT(*) FROM #batches

	IF (@Count = 0)
	BEGIN
		SELECT DISTINCT Relab.ResultsParametersNameComma(m.ID, CASE WHEN @ParameterName IS NOT NULL THEN 'V' ELSE 'N' END) AS ParameterName
			FROM TestUnits tu WITH(NOLOCK)
				INNER JOIN Relab.Results r WITH(NOLOCK) ON r.TestUnitID=tu.ID
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
				AND
				(
					(@TestStageID > 0 AND r.TestStageID= @TestStageID)
					OR
					(@TestStageID = 0)
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
GRANT EXECUTE ON Relab.remispGetParametersByMeasurementTest TO REMI
GO
insert into TargetAccess (TargetName,DenyAccess,WorkstationName) Values ('RemiTimedServiceAvailable', 0, NULL)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
IF EXISTS (SELECT * FROM #tmpErrors) ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT>0 BEGIN
PRINT 'The database update succeeded'
commit TRANSACTION
END
ELSE PRINT 'The database update failed'
GO
DROP TABLE #tmpErrors
GO