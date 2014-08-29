/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        CI0000001593275.REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 8/7/2013 9:54:06 AM

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
PRINT N'Dropping foreign keys from [Relab].[ResultsMeasurements]'
GO
ALTER TABLE [Relab].[ResultsMeasurements] DROP CONSTRAINT[FK_ResultsMeasurements_ResultsXML_XMLID]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [Relab].[FunctionalMatrixByTestRecord]'
GO
CREATE PROCEDURE [Relab].[FunctionalMatrixByTestRecord] @TRID INT = NULL, @TestStageID INT, @TestID INT, @BatchID INT, @UnitIDs NVARCHAR(MAX) = NULL
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @TestUnitID INT
	DECLARE @rows VARCHAR(8000)
	DECLARE @sql VARCHAR(8000)
	CREATE Table #units(id int) 
	
	IF (@TRID IS NOT NULL)
	BEGIN
		SELECT @TestUnitID = TestUnitID FROM TestRecords WHERE ID=@TRID
		INSERT INTO #units VALUES (@TestUnitID)
	END
	ELSE
	BEGIN
		EXEC(@UnitIDs)
	END
	
	SELECT @rows=  ISNULL(STUFF(
		(SELECT DISTINCT '],[' + l.[Values]
		FROM dbo.Lookups l
		WHERE l.IsActive = 1 AND Type='FunctionalMatrix'
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
							LEFT OUTER JOIN Lookups lr ON lr.Type=''FunctionalMatrix'' AND rm.MeasurementTypeID=lr.LookupID
						WHERE rm.ResultID=r.ID AND lr.[values] = l.[values])
				END As Row
			FROM dbo.Lookups l
			INNER JOIN TestUnits tu ON tu.BatchID = ' + CONVERT(VARCHAR, @BatchID) + ' AND 
				(
					(' + CONVERT(VARCHAR, ISNULL(CONVERT(VARCHAR,@TestUnitID), 'NULL')) + ' IS NULL)
					OR
					(' + CONVERT(VARCHAR, ISNULL(CONVERT(VARCHAR,@TestUnitID), 'NULL')) + ' IS NOT NULL AND tu.ID=' + CONVERT(VARCHAR, ISNULL(CONVERT(VARCHAR,@TestUnitID), 'NULL')) + ')
				)
			INNER JOIN #units ON tu.ID=#units.ID
			LEFT OUTER JOIN Relab.Results r ON r.TestID = ' + CONVERT(VARCHAR, @TestID) + ' AND r.TestStageID = ' + CONVERT(VARCHAR, @TestStageID) + ' 
				AND r.TestUnitID = tu.ID
			WHERE l.IsActive = 1 AND l.Type=''FunctionalMatrix''
			) te 
			PIVOT (MAX(row) FOR [Values] IN (' + @rows + ')) AS pvt
			ORDER BY BatchUnitNumber'
	
	PRINT @sql
	EXEC(@sql)
	
	SET NOCOUNT OFF
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Relab].[ResultsMeasurements]'
GO
ALTER TABLE [Relab].[ResultsMeasurements] ALTER COLUMN [XMLID] [int] NULL
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
		LEFT OUTER JOIN Lookups lm WITH(NOLOCK) ON m.MeasurementTypeID=lm.LookupID
		LEFT OUTER JOIN Lookups lu WITH(NOLOCK) ON m.MeasurementUnitTypeID=lu.LookupID
		LEFT OUTER JOIN Relab.ResultsXML rxml ON rxml.ID=m.XMLID
		LEFT OUTER JOIN #parameters p ON p.ResultMeasurementID=m.ID
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
	
	SELECT rm.ID, ISNULL(lt.[Values], lft.[Values]) As Measurement, LowerLimit AS [Lower Limit], UpperLimit AS [Upper Limit], MeasurementValue AS Result, lu.[Values] As Unit, 
		CASE WHEN PassFail=1 THEN 'Pass' ELSE 'Fail' END AS [Pass/Fail],
		rm.MeasurementTypeID, rm.ReTestNum AS [Test Num], rm.Archived, rm.XMLID, 
		(SELECT MAX(Relab.ResultsMeasurements.ReTestNum) FROM Relab.ResultsMeasurements WHERE Relab.ResultsMeasurements.ResultID=rm.ResultID) AS MaxVersion, rm.Comment,
		ISNULL(rmf.[File], 0) AS [Image], 
		ISNULL(UPPER(SUBSTRING(rmf.ContentType,2,LEN(rmf.ContentType))), 'PNG') AS ContentType, p.*
	FROM Relab.ResultsMeasurements rm WITH(NOLOCK)
		LEFT OUTER JOIN Lookups lu WITH(NOLOCK) ON lu.Type='UnitType' AND lu.LookupID=rm.MeasurementUnitTypeID
		LEFT OUTER JOIN Lookups lt WITH(NOLOCK) ON lt.Type='MeasurementType' AND lt.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Lookups lft WITH(NOLOCK) ON lft.Type='FunctionalMatrix' AND lft.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Relab.ResultsMeasurementsFiles rmf ON rmf.ResultMeasurementID=rm.ID
		LEFT OUTER JOIN #parameters p ON p.ResultMeasurementID=rm.ID
	WHERE ResultID=@ResultID AND ((@IncludeArchived = 0 AND rm.Archived=0) OR (@IncludeArchived=1)) AND ((@OnlyFails = 1 AND PassFail=0) OR (@OnlyFails = 0))
	ORDER BY lt.[Values], rm.ReTestNum ASC

	DROP TABLE #parameters

	SET NOCOUNT OFF
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding foreign keys to [Relab].[ResultsMeasurements]'
GO
ALTER TABLE [Relab].[ResultsMeasurements] ADD CONSTRAINT [FK_ResultsMeasurements_ResultsXML_XMLID] FOREIGN KEY ([XMLID]) REFERENCES [Relab].[ResultsXML] ([ID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering permissions on [Relab].[FunctionalMatrixByTestRecord]'
GO
GRANT EXECUTE ON  [Relab].[FunctionalMatrixByTestRecord] TO [remi]
GO
ALTER PROCEDURE [Relab].[remispOverallResultsSummary] @BatchID INT
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @query VARCHAR(8000)
	DECLARE @query2 VARCHAR(8000)
	DECLARE @query3 VARCHAR(8000)
	DECLARE @QRANumber NVARCHAR(11)
	DECLARE @ProductID INT
	DECLARE @ProductTypeID INT
	DECLARE @AccessoryGroupID INT
	DECLARE @RowID INT
	DECLARE @TestStageID INT
	DECLARE @BatchUnitNumber INT
	DECLARE @StageCount INT
	DECLARE @UnitCount INT
	CREATE TABLE #results (TestID INT)
	CREATE TABLE #exceptions (ID INT, BatchUnitNumber INT, ReasonForRequest INT, ProductGroupName NVARCHAR(150), JobName NVARCHAR(150), TestStageName NVARCHAR(150), TestName NVARCHAR(150), LastUser NVARCHAR(150), TestStageID INT, TestUnitID INT, ProductTypeID INT, AccessoryGroupID INT, ProductID INT, ProductType NVARCHAR(150), AccessoryGroupName NVARCHAR(150), TestID INT)
	
	SELECT @QRANumber = QRANumber, @ProductID = ProductID, @ProductTypeID=ProductTypeID, @AccessoryGroupID = AccessoryGroupID FROM Batches WHERE ID=@BatchID
	SELECT @StageCount = COUNT(DISTINCT TSName) FROM dbo.vw_GetTaskInfo WHERE BatchID=@BatchID and Processorder > -1 AND Testtype=1 AND LOWER(LTRIM(RTRIM(TSName))) <> 'analysis'
	SELECT @TestStageID = TestStageID FROM dbo.vw_GetTaskInfo WHERE BatchID=@BatchID and Processorder > -1 AND Testtype=1 AND LOWER(LTRIM(RTRIM(TSName))) = 'analysis'
	SELECT @UnitCount = COUNT(*) FROM TestUnits WHERE BatchID=@BatchID
	
	IF (@TestStageID IS NULL)
		SET @TestStageID=0
		
	SET @query2 = ''
	SET @query = ''
	SET @query3 =''	

	EXECUTE ('ALTER TABLE #results ADD [' + @QRANumber + '] NVARCHAR(400) NULL, Completed NVARCHAR(3) NULL, [Pass/Fail] NVARCHAR(3) NULL')
	
	--Get Batch Exceptions
	insert into #exceptions (ID, BatchUnitNumber, ReasonForRequest, ProductGroupName, JobName, TestStageName, TestName, LastUser, TestStageID, TestUnitID, ProductTypeID, AccessoryGroupID, ProductID, ProductType, AccessoryGroupName, TestID)
	exec [dbo].[remispTestExceptionsGetBatchOnlyExceptions] @QraNumber = @QRANumber
	
	--Get Product Exceptions
	insert into #exceptions (ID, BatchUnitNumber, ReasonForRequest, ProductGroupName, JobName, TestStageName, TestName, LastUser, TestStageID, TestUnitID, ProductTypeID, AccessoryGroupID, ProductID, ProductType, AccessoryGroupName, TestID)
	exec [dbo].[remispTestExceptionsGetProductExceptions] @ProductID = @ProductID, @recordCount = null, @startrowindex =-1, @maximumrows=-1
	
	--Remove product exceptions where it's not the current product type or accessorygroup
	DELETE FROM #exceptions
	WHERE ProductTypeID <> @ProductTypeID OR AccessoryGroupID <>  @AccessoryGroupID OR TestStageID IN (SELECT ID FROM TestStages WHERE TestStageType=4)
	
	UPDATE #exceptions SET BatchUnitNumber=0 WHERE BatchUnitNumber IS NULL
		
	SET @query = 'INSERT INTO #results
	SELECT DISTINCT TestID, TName AS [' + @QRANumber + '],
		(
			CASE WHEN
				(
					' + CONVERT(VARCHAR, (@UnitCount * @StageCount)) + ' - ISNULL((SELECT SUM(val)
					FROM
					(
						SELECT COUNT(*) * ' + CONVERT(VARCHAR, (@UnitCount)) + ' AS val 
						FROM #exceptions 
						WHERE (TestID=i.TestID OR TestID IS NULL) AND TestUnitID IS NULL
						GROUP BY BatchUnitNumber, TestStageID
					) AS c)
					+
					(SELECT SUM(val)
					FROM
					(
						SELECT COUNT(*) AS val 
						FROM #exceptions 
						WHERE (TestID=i.TestID OR TestID IS NULL) AND TestUnitID IS NOT NULL
						GROUP BY BatchUnitNumber, TestStageID
					) AS c), 0)
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
		) + '' ('' + CONVERT(VARCHAR, ISNULL((SELECT SUM(val)
					FROM
					(
						SELECT COUNT(*) * ' + CONVERT(VARCHAR, (@UnitCount)) + ' AS val 
						FROM #exceptions 
						WHERE (TestID=#Results.TestID OR TestID IS NULL) AND TestUnitID IS NULL
						GROUP BY BatchUnitNumber, TestStageID
					) AS c)
					+
					(SELECT SUM(val)
					FROM
					(
						SELECT COUNT(*) AS val 
						FROM #exceptions 
						WHERE (TestID=#Results.TestID OR TestID IS NULL) AND TestUnitID IS NOT NULL
							AND BatchUnitNumber =' + CONVERT(VARCHAR,@BatchUnitNumber) + '
						GROUP BY BatchUnitNumber, TestStageID
					) AS c), 0)) + '')'''
		
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
ALTER procedure [dbo].[remispTestExceptionsGetProductExceptions]
	@ProductID INT = null,
	@recordCount  int  = null output,
	@startrowindex int = -1,
	@maximumrows int = -1
AS
IF (@RecordCount IS NOT NULL)
	BEGIN
		SELECT @RecordCount = COUNT(pvt.ID)
		FROM vw_ExceptionsPivoted as pvt
		where [TestUnitID] IS NULL AND (([ProductID]=@ProductID) OR (@ProductID = 0 AND pvt.ProductID IS NULL))
return
end

--get any exceptions for the product
select ID, BatchUnitNumber, ReasonForRequest, ProductGroupName, JobName, TestStageName, TestName, LastUser, TestStageID, TestUnitID, ProductTypeID, 
	AccessoryGroupID, ProductID, ProductType, AccessoryGroupName, TestID
from 
(
	select ROW_NUMBER() over (order by p.ProductGroupName desc)as row, pvt.ID, null as batchunitnumber, pvt.[ReasonForRequest], p.ProductGroupName,
	(select jobname from jobs,TestStages where teststages.id =pvt.TestStageid and Jobs.ID = TestStages.jobid) as jobname, 
	(select teststagename from teststages where teststages.id =pvt.TestStageid) as teststagename, 
	t.TestName,pvt.TestStageID, pvt.TestUnitID,
	(select top 1 LastUser from TestExceptions WHERE ID=pvt.ID) AS LastUser,
	--(select top 1 ConcurrencyID from TestExceptions WHERE ID=pvt.ID) AS ConcurrencyID,
	pvt.ProductTypeID, pvt.AccessoryGroupID, pvt.ProductID, l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, t.ID AS TestID
	FROM vw_ExceptionsPivoted as pvt
		LEFT OUTER JOIN Tests t ON pvt.Test = t.ID
		LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND l.LookupID=pvt.ProductTypeID
		LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND l2.LookupID=pvt.AccessoryGroupID
		LEFT OUTER JOIN Products p ON p.ID=pvt.ProductID
	WHERE pvt.TestUnitID IS NULL AND
		(
			(pvt.[ProductID]=@ProductID) 
			OR
			(@ProductID = 0 AND pvt.[ProductID] IS NULL)
		)) as exceptionResults
where ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) 
			OR @startRowIndex = -1 OR @maximumRows = -1)
ORDER BY TestName
GO
GRANT EXECUTE ON remispTestExceptionsGetProductExceptions TO Remi
GO

ALTER procedure [dbo].[remispTestExceptionsGetBatchOnlyExceptions] @qraNumber nvarchar(11) = null
AS
select distinct pvt.id, null as batchunitnumber, pvt.ReasonForRequest,p.ProductGroupName,b.JobName, ts.teststagename
, t.testname, (SELECT TOP 1 LastUser FROM TestExceptions WHERE ID=pvt.ID) AS LastUser,
--(SELECT TOP 1 ConcurrencyID FROM TestExceptions WHERE ID=pvt.ID) AS ConcurrencyID, 
pvt.TestStageID, pvt.TestUnitID ,
pvt.ProductTypeID, pvt.AccessoryGroupID, pvt.ProductID, l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, t.ID AS TestID
FROM vw_ExceptionsPivoted as pvt
	LEFT OUTER JOIN Tests t ON pvt.Test = t.ID
	LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND l.LookupID=pvt.ProductTypeID
	LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND l2.LookupID=pvt.AccessoryGroupID
	LEFT OUTER JOIN Products p ON p.ID=pvt.ProductID
	, Batches as b, teststages as ts, Jobs as j 
where b.QRANumber = @qranumber and pvt.TestUnitID is null and (ts.id = pvt.teststageid or pvt.TestStageID is null)
	and (ts.JobID = j.ID or j.ID is null) and (b.JobName = j.JobName or j.JobName is null)
	and 
	(
		(pvt.ProductID is null and pvt.ReasonForRequest = b.RequestPurpose)
		or 
		(pvt.ProductID is null and pvt.ReasonForRequest is null)
	)
	AND
	(
		(b.ProductTypeID IS NOT NULL AND b.ProductTypeID = pvt.ProductTypeID )
		OR 
		pvt.ProductTypeID IS NULL
	)
	AND
	(
		(b.AccessoryGroupID IS NOT NULL AND b.AccessoryGroupID = pvt.AccessoryGroupID)
		OR
		pvt.AccessoryGroupID IS NULL
	)

union all

--get any for the test units.
select distinct pvt.id, tu.BatchUnitNumber, pvt.ReasonForRequest, p.ProductGroupName,b.JobName, 
(select teststagename from teststages where teststages.id =pvt.TestStageid) as teststagename, t.testname,
(SELECT TOP 1 LastUser FROM TestExceptions WHERE ID=pvt.ID) AS LastUser,
--(SELECT TOP 1 ConcurrencyID FROM TestExceptions WHERE ID=pvt.ID) AS ConcurrencyID, 
pvt.TestStageID, pvt.TestUnitID,pvt.ProductTypeID, pvt.AccessoryGroupID, pvt.ProductID, l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, t.ID AS TestID
FROM vw_ExceptionsPivoted as pvt
	LEFT OUTER JOIN Tests t ON pvt.Test = t.ID
	LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND l.LookupID=pvt.ProductTypeID
	LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND l2.LookupID=pvt.AccessoryGroupID
	LEFT OUTER JOIN Products p ON p.ID=pvt.ProductID
	INNER JOIN testunits tu ON tu.ID=pvt.TestUnitID
	INNER JOIN Batches as b ON b.ID=tu.BatchID
where b.QRANumber = @qranumber and tu.batchid = b.id and pvt.TestUnitID = tu.id
order by pvt.TestUnitID desc,TestName
GO
GRANT EXECUTE ON remispTestExceptionsGetBatchOnlyExceptions TO Remi
GO
ALTER procedure [dbo].[remispExceptionSearch] @ProductID INT = 0, @AccessoryGroupID INT = 0, @ProductTypeID INT = 0, @TestID INT = 0, @TestStageID INT = 0, @JobName NVARCHAR(400) = NULL, @IncludeBatches INT = 0
AS
BEGIN
	DECLARE @JobID INT
	SELECT @JobID = ID FROM Jobs WHERE JobName=@JobName

	select *
	from 
	(
		select ROW_NUMBER() over (order by p.ProductGroupName desc)as row, pvt.ID, b.QRANumber, ISNULL(tu.Batchunitnumber, 0) as batchunitnumber, pvt.[ReasonForRequest], p.ProductGroupName,
		(select jobname from jobs,TestStages where teststages.id =pvt.TestStageid and Jobs.ID = TestStages.jobid) as jobname, 
		(select teststagename from teststages where teststages.id =pvt.TestStageid) as teststagename, 
		t.TestName,pvt.TestStageID, pvt.TestUnitID,
		(select top 1 LastUser from TestExceptions WHERE ID=pvt.ID) AS LastUser,
		(select top 1 ConcurrencyID from TestExceptions WHERE ID=pvt.ID) AS ConcurrencyID,
		pvt.ProductTypeID, pvt.AccessoryGroupID, pvt.ProductID, l.[Values] As ProductType, l2.[Values] As AccessoryGroupName
		FROM vw_ExceptionsPivoted as pvt
			LEFT OUTER JOIN Tests t ON pvt.Test = t.ID
			LEFT OUTER JOIN TestUnits tu ON tu.ID = pvt.TestUnitID
			LEFT OUTER JOIN Batches b ON tu.BatchID = b.ID
			LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND l.LookupID=pvt.ProductTypeID
			LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND l2.LookupID=pvt.AccessoryGroupID
			LEFT OUTER JOIN Products p ON p.ID=pvt.ProductID
		WHERE (
				(pvt.[ProductID]=@ProductID) 
				OR
				(@ProductID = 0)
			)
			AND
			(
				(pvt.AccessoryGroupID = @AccessoryGroupID) 
				OR
				(@AccessoryGroupID = 0)
			)
			AND
			(
				(pvt.ProductTypeID = @ProductTypeID) 
				OR
				(@ProductTypeID = 0)
			)
			AND
			(
				(pvt.Test = @TestID) 
				OR
				(@TestID = 0)
			)
			AND
			(
				(pvt.TestStageID = @TestStageID) 
				OR
				(@TestStageID = 0 And @JobID IS NULL OR @JobID = 0)
				OR
				(@JobID > 0 And @TestStageID = 0 AND pvt.TestStageID IN (SELECT ID FROM TestStages WHERE JobID=@JobID))
			)
			AND
			(
				(@IncludeBatches = 1)
				OR
				(@IncludeBatches = 0 AND pvt.TestUnitID IS NULL)
			)
	) as exceptionResults
	ORDER BY QRANumber, Batchunitnumber, TestName
END
GO
GRANT EXECUTE ON remispExceptionSearch TO REMI
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