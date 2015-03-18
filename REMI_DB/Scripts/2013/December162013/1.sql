/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        (local).REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 12/12/2013 2:34:48 PM

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
PRINT N'Creating [dbo].[remispKPIReports]'
GO
create PROCEDURE dbo.remispKPIReports @StartDate DATETIME, @EndDate DATETIME, @Type INT, @TestCenterID INT
AS
BEGIN
	DECLARE @BID INT
	CREATE TABLE #batches (ID INT IDENTITY(1,1), BatchID INT, QRANumber NVARCHAR(11), JobName NVARCHAR(250))

	SET NOCOUNT ON

	--Get batches modified during the start and end date
	INSERT INTO #batches (BatchID, QRANumber, JobName)
	SELECT b.ID, b.QRANumber, b.JobName
	FROM Batches b
	WHERE b.ID IN (SELECT BatchID FROM BatchesAudit ba WHERE ba.InsertTime BETWEEN @StartDate AND @EndDate)
		AND b.TestCenterLocationID=@TestCenterID
	ORDER BY b.QRANumber DESC

	SELECT @BID = MIN(ID) FROM #batches

	IF (@Type = 1)
	BEGIN
		CREATE TABLE #result (BatchUnitNumber INT, DiffMinutes REAL, InIncoming DATETIME, FirstOutOfIncoming DATETIME, QRANumber NVARCHAR(11))
		
		SELECT ID
		INTO #incomingMachines
		FROM TrackingLocations 
		WHERE (TrackingLocationName like '%incom%' or TrackingLocationName like '%rems%') and TestCenterLocationID=@TestCenterID and ISNULL(Decommissioned, 0) = 0

		WHILE (@BID IS NOT NULL)
		BEGIN
			INSERT INTO #result
			SELECT tu.BatchUnitNumber, dbo.GetDateDiffInMinutes((SELECT DATEADD(HH,-5, MIN(dtl.InTime)) FROM DeviceTrackingLog dtl WHERE dtl.TestUnitID=tu.ID AND OutTime IS NOT NULL AND TrackingLocationID IN (SELECT ID FROM #incomingMachines)),
					(SELECT DATEADD(HH,-5, MIN(dtl.InTime)) FROM DeviceTrackingLog dtl WHERE dtl.TestUnitID=tu.ID AND TrackingLocationID NOT IN (SELECT ID FROM #incomingMachines))) As DiffMinutes,
				(SELECT DATEADD(HH,-5, MIN(dtl.InTime)) FROM DeviceTrackingLog dtl WHERE dtl.TestUnitID=tu.ID AND OutTime IS NOT NULL AND TrackingLocationID IN (SELECT ID FROM #incomingMachines)) As InIncoming,
				(SELECT DATEADD(HH,-5, MIN(dtl.InTime)) FROM DeviceTrackingLog dtl WHERE dtl.TestUnitID=tu.ID AND TrackingLocationID NOT IN (SELECT ID FROM #incomingMachines)) As FirstOutOfIncoming,
				(SELECT QRANumber FROM #batches WHERE ID=@BID) AS QRANumber
			FROM TestUnits tu
			WHERE tu.BatchID = (SELECT BatchID FROM #batches WHERE ID=@BID)

			SELECT @BID = MIN(ID) FROM #batches WHERE ID > @BID
		END

		SELECT b.QRANumber, b.JobName, ROUND(((SELECT SUM(DiffMinutes) FROM #result r WHERE r.QRANumber= b.QRANumber) / (SELECT COUNT(ID) FROM TestUnits WHERE BatchID=b.BatchID)), 2) AS LostMinutes
		FROM #batches b
		
		DROP TABLE #result
		DROP TABLE #incomingMachines
	END
	
	DROP TABLE #batches
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Relab].[remispOverallResultsSummary]'
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
	DECLARE @BatchUnitNumber INT
	DECLARE @StageCount INT
	DECLARE @StageCount2 INT
	DECLARE @UnitCount INT
	DECLARE @BatchStatus INT
	DECLARE @TestCenterID INT
	DECLARE @IsMQual BIT
	DECLARE @ID INT
	CREATE TABLE #results (TestID INT, TestType INT)
	CREATE TABLE #exceptions (ID INT, BatchUnitNumber INT, ReasonForRequest INT, ProductGroupName NVARCHAR(150), JobName NVARCHAR(150), TestStageName NVARCHAR(150), TestName NVARCHAR(150), LastUser NVARCHAR(150), TestStageID INT, TestUnitID INT, ProductTypeID INT, AccessoryGroupID INT, ProductID INT, ProductType NVARCHAR(150), AccessoryGroupName NVARCHAR(150), TestID INT, IsMQual INT, TestCenter NVARCHAR(MAX), TestCenterID INT)
	CREATE TABLE #view (qranumber NVARCHAR(11), processorder INT, BatchID INT, tsname NVARCHAR(400), tname NVARCHAR(400), testtype INT, teststagetype INT, resultbasedontime INT, testunitsfortest NVARCHAR(MAX), expectedDuration REAL, TestStageID INT, TestWI NVARCHAR(400), TestID INT, IsArchived BIT, RecordExists BIT, TestIsArchived BIT, TestRecordExists BIT)
	
	SELECT @QRANumber = QRANumber, @ProductID = ProductID, @ProductTypeID=ProductTypeID, @AccessoryGroupID = AccessoryGroupID, @BatchStatus = BatchStatus, @TestCenterID = TestCenterLocationID, @IsMQual = IsMQual
	FROM Batches WITH(NOLOCK) 
	WHERE ID=@BatchID

	if (@BatchStatus = 5)
	BEGIN
		INSERT INTO #view (qranumber, processorder, BatchID, tsname, tname, testtype, teststagetype, resultbasedontime, testunitsfortest, expectedDuration, TestStageID, TestWI, TestID, IsArchived, RecordExists, TestIsArchived, TestRecordExists)
		SELECT * FROM vw_GetTaskInfoCompleted WITH(NOLOCK) WHERE BatchID=@BatchID and Processorder > -1 AND (Testtype=1 or TestID=1029)
	END
	ELSE
	BEGIN
		INSERT INTO #view (qranumber, processorder, BatchID, tsname, tname, testtype, teststagetype, resultbasedontime, testunitsfortest, expectedDuration, TestStageID, TestWI, TestID, IsArchived, RecordExists, TestIsArchived, TestRecordExists)
		SELECT * FROM vw_GetTaskInfo WITH(NOLOCK) WHERE BatchID=@BatchID and Processorder > -1 AND (Testtype=1 or TestID=1029)
	END
		
	INSERT INTO #view (qranumber, processorder, BatchID, tsname, tname, testtype, teststagetype, resultbasedontime, testunitsfortest, expectedDuration, TestStageID, TestWI, TestID, IsArchived, RecordExists, TestIsArchived, TestRecordExists)
	SELECT * FROM vw_GetTaskInfoCompleted WITH(NOLOCK) WHERE BatchID=@BatchID and Processorder > -1 AND (Testtype=2)
	
	SELECT @StageCount = COUNT(DISTINCT TSName) FROM #view WITH(NOLOCK) WHERE LOWER(LTRIM(RTRIM(TSName))) <> 'analysis' AND TestStageType=1
	SELECT @StageCount2 = COUNT(DISTINCT TSName) FROM #view WITH(NOLOCK) WHERE LOWER(LTRIM(RTRIM(TSName))) <> 'analysis' AND TestStageType=2
			
	SELECT ROW_NUMBER() OVER (ORDER BY tu.ID) AS RowID, tu.BatchUnitNumber, tu.ID
	INTO #units
	FROM TestUnits tu WITH(NOLOCK)
	WHERE BatchID=@BatchID

	SELECT @UnitCount = COUNT(RowID) FROM #units WITH(NOLOCK)
			
	SET @query2 = ''
	SET @query = ''
	SET @query3 =''	

	EXECUTE ('ALTER TABLE #results ADD [' + @QRANumber + '] NVARCHAR(400) NULL, Completed NVARCHAR(3) NULL, [Pass/Fail] NVARCHAR(3) NULL')
	
	IF (@BatchStatus <> 5)
	BEGIN
		--Get Batch Exceptions
		insert into #exceptions (ID, BatchUnitNumber, ReasonForRequest, ProductGroupName, JobName, TestStageName, TestName, LastUser, TestStageID, TestUnitID, ProductTypeID, AccessoryGroupID, ProductID, ProductType, AccessoryGroupName, TestID, IsMQual, TestCenter, TestCenterID)
		exec [dbo].[remispTestExceptionsGetBatchOnlyExceptions] @QraNumber = @QRANumber
		
		--Get Product Exceptions
		insert into #exceptions (ID, BatchUnitNumber, ReasonForRequest, ProductGroupName, JobName, TestStageName, TestName, LastUser, TestStageID, TestUnitID, ProductTypeID, AccessoryGroupID, ProductID, ProductType, AccessoryGroupName, TestID, IsMQual, TestCenter, TestCenterID)
		exec [dbo].[remispTestExceptionsGetProductExceptions] @ProductID = @ProductID, @recordCount = null, @startrowindex =-1, @maximumrows=-1
		
		--Get non product exceptions
		insert into #exceptions (ID, BatchUnitNumber, ReasonForRequest, ProductGroupName, JobName, TestStageName, TestName, LastUser, TestStageID, TestUnitID, ProductTypeID, AccessoryGroupID, ProductID, ProductType, AccessoryGroupName, TestID, IsMQual, TestCenter, TestCenterID)
		exec [dbo].[remispTestExceptionsGetProductExceptions] @ProductID = 0, @recordCount = null, @startrowindex =-1, @maximumrows=-1
		
		--Remove product exceptions where it's not the current product type or accessorygroup
		DELETE FROM #exceptions
		WHERE ProductTypeID <> @ProductTypeID OR AccessoryGroupID <>  @AccessoryGroupID OR TestStageID IN (SELECT ID FROM TestStages WHERE TestStageType=4)
			OR TestStageID NOT IN (SELECT TestStageID FROM #view)
			OR TestCenterID <> @TestCenterID
			Or ISNULL(IsMQual, 0) <> ISNULL(@IsMQual, 0)

		UPDATE #exceptions SET BatchUnitNumber=0 WHERE BatchUnitNumber IS NULL
	END
	
	SET @query = 'INSERT INTO #results
	SELECT DISTINCT TestID, i.TestType, TName AS [' + @QRANumber + '],
		(
			CASE
			WHEN i.TestType = 2 THEN
				CASE WHEN (ISNULL((SELECT SUM(val) FROM (SELECT COUNT(DISTINCT TestStageID) * ' + CONVERT(VARCHAR, (@UnitCount)) + ' AS val 
				FROM TestRecords WHERE TestUnitID IN (SELECT ID FROM #units) AND Status IN (1,2,6) AND 
					(
						(TestID=i.TestID OR TestID IS NULL)
					)
					And LOWER(LTRIM(RTRIM(TestStageName))) <> ''analysis'')  AS c), 0)
					) = (SELECT COUNT(*) FROM #Units) THEN ''Y'' ELSE ''N'' END 
			WHEN
				( '
					IF (@BatchStatus = 5)
					BEGIN
						SET @query += ' (ISNULL((SELECT SUM(val) '
					END
					ELSE
					BEGIN
						SET @query += 'CASE 
							WHEN TestStageType = 1 THEN 
								' + CONVERT(VARCHAR, (@UnitCount * @StageCount)) + ' 
							ELSE ' + CONVERT(VARCHAR, (@UnitCount * @StageCount2)) + ' 
						END - (ISNULL((SELECT SUM(val) '
					END 
					SET @query += ' FROM
					( '
						IF (@BatchStatus = 5)
						BEGIN
							SET @query += ' SELECT COUNT(DISTINCT TestStageID) * ' + CONVERT(VARCHAR, (@UnitCount)) + ' AS val '
						END
						ELSE
						BEGIN
							SET @query += ' SELECT COUNT(DISTINCT TestStageID) * (CASE WHEN TestUnitID IS NOT NULL THEN 1 ELSE ' + CONVERT(VARCHAR, (@UnitCount)) + ' END) AS val '
						END
						
						IF (@BatchStatus = 5)
						BEGIN
							SET @query += 'FROM TestRecords WHERE TestUnitID IN (SELECT ID FROM #units) AND 
							(
								(TestID=i.TestID OR TestID IS NULL)
							)
							And LOWER(LTRIM(RTRIM(TestStageName))) <> ''analysis'' '
						END
						ELSE
						BEGIN
							SET @query += 'FROM #exceptions WHERE 
							(
								((TestID=i.TestID OR TestID IS NULL) AND TestUnitID IS NULL)
								OR
								((TestID=i.TestID OR TestID IS NULL) AND TestUnitID IS NOT NULL)
							)
							GROUP BY BatchUnitNumber, TestStageID, TestUnitID '
						END
						
						SET @query += '
					) AS c), 0))
				) = 				
				CASE WHEN i.TestType=2 THEN (SELECT COUNT(*) FROM #Units)
				ELSE				
				(
					SELECT COUNT(DISTINCT r.ID) 
					FROM Relab.Results r WITH(NOLOCK) 
						INNER JOIN TestUnits u WITH(NOLOCK) ON u.ID=r.TestUnitID
						INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
					WHERE LOWER(LTRIM(RTRIM(ts.TestStageName))) <> ''analysis'' AND r.TestID=i.TestID AND u.BatchID='+CONVERT(VARCHAR,@BatchID)+' 
				) END THEN ''Y'' ELSE ''N'' END
		) as Completed,
		(
			CASE
				WHEN 
					(i.TestType = 2) THEN
						CASE WHEN (SELECT COUNT(*) FROM TestRecords WHERE TestUnitID IN (SELECT ID FROM #units) AND 
							((TestID=i.TestID)) And LOWER(LTRIM(RTRIM(TestStageName))) <> ''analysis'' AND Status=2)
							=
							(SELECT COUNT(*) FROM TestRecords WHERE TestUnitID IN (SELECT ID FROM #units) AND ((TestID=i.TestID))
							And LOWER(LTRIM(RTRIM(TestStageName))) <> ''analysis'')
						THEN ''P''
						WHEN (SELECT COUNT(*) FROM TestRecords WHERE TestUnitID IN (SELECT ID FROM #units) AND 
							((TestID=i.TestID)) And LOWER(LTRIM(RTRIM(TestStageName))) <> ''analysis'' AND Status=1) > 0
						THEN ''F'' 
						ELSE ''N/A''
						END
				WHEN 
				(
					SELECT TOP 1 1 
					FROM Relab.Results r WITH(NOLOCK)
						INNER JOIN TestUnits u WITH(NOLOCK) ON u.ID=r.TestUnitID 
						INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
					WHERE LOWER(LTRIM(RTRIM(ts.TestStageName))) <> ''analysis'' AND r.TestID=i.TestID AND u.BatchID='+CONVERT(VARCHAR,@BatchID)+'
				) IS NULL THEN ''N/A''
				WHEN
				(
					SELECT COUNT(*)
					FROM Relab.Results r WITH(NOLOCK) 
						INNER JOIN TestUnits u WITH(NOLOCK) ON u.ID=r.TestUnitID 
						INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
					WHERE LOWER(LTRIM(RTRIM(ts.TestStageName))) <> ''analysis'' AND r.TestID=i.TestID AND u.BatchID='+CONVERT(VARCHAR,@BatchID)+' AND PassFail=1
				) = 
				(
					SELECT COUNT(*)
					FROM Relab.Results r WITH(NOLOCK) 
						INNER JOIN TestUnits u WITH(NOLOCK) ON u.ID=r.TestUnitID 
						INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
					WHERE LOWER(LTRIM(RTRIM(ts.TestStageName))) <> ''analysis'' AND r.TestID=i.TestID AND u.BatchID='+CONVERT(VARCHAR,@BatchID)+'
				) THEN ''P'' 
				ELSE ''F'' END
		) + 
		ISNULL((
			SELECT TOP 1 '' *'' 
			FROM Relab.ResultsMeasurementsAudit rma 
				INNER JOIN Relab.ResultsMeasurements rm ON rma.ResultMeasurementID=rm.ID
			WHERE rma.PassFail <> rm.PassFail AND rm.ResultID IN (			
						SELECT r.ID
						FROM Relab.Results r WITH(NOLOCK) 
									INNER JOIN TestUnits u WITH(NOLOCK) ON u.ID=r.TestUnitID 
									INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
								WHERE LOWER(LTRIM(RTRIM(ts.TestStageName))) <> ''analysis'' AND r.TestID=i.TestID AND u.BatchID='+CONVERT(VARCHAR,@BatchID)+'
						)
			ORDER BY DateEntered DESC
		),'''')
		AS [Pass/Fail] '
		
	SET @query2 = 'FROM #view i WITH(NOLOCK)
	ORDER BY TName'

	EXECUTE (@query + @query2)

	SELECT @RowID = MIN(RowID) FROM #units
			
	WHILE (@RowID IS NOT NULL)
	BEGIN
		SELECT @BatchUnitNumber=BatchUnitNumber, @ID=ID FROM #units WITH(NOLOCK) WHERE RowID=@RowID
		
		EXECUTE ('ALTER TABLE #results ADD [' + @BatchUnitNumber + '] NVARCHAR(10) NULL')
		
		SET @query3 = 'UPDATE #Results SET [' + CONVERT(VARCHAR,@BatchUnitNumber) + '] = (
		CASE
			WHEN (#Results.TestType = 2) THEN 
				CASE WHEN (SELECT COUNT(*) FROM TestRecords WHERE TestUnitID = ' + CONVERT(VARCHAR,@ID) + ' AND 
					((TestID=#Results.TestID)) And LOWER(LTRIM(RTRIM(TestStageName))) <> ''analysis'' AND Status=2)
					=
					(SELECT COUNT(*) FROM TestRecords WHERE TestUnitID = ' + CONVERT(VARCHAR,@ID) + ' AND ((TestID=#Results.TestID))
					And LOWER(LTRIM(RTRIM(TestStageName))) <> ''analysis'')
					THEN ''P''
				WHEN (SELECT COUNT(*) FROM TestRecords WHERE TestUnitID = ' + CONVERT(VARCHAR,@ID) + ' AND 
					((TestID=#Results.TestID)) And LOWER(LTRIM(RTRIM(TestStageName))) <> ''analysis'' AND Status=1) > 0
					THEN ''F''
				ELSE ''N/A'' END
			WHEN 
			(
				SELECT TOP 1 1
				FROM Relab.Results r WITH(NOLOCK)
					INNER JOIN TestUnits u WITH(NOLOCK) ON u.ID=r.TestUnitID 
					INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
				WHERE LOWER(LTRIM(RTRIM(ts.TestStageName))) <> ''analysis'' AND r.TestID=#Results.TestID AND u.ID=r.TestUnitID AND u.BatchUnitNumber =' + CONVERT(VARCHAR,@BatchUnitNumber) + ' AND u.BatchID='+CONVERT(VARCHAR,@BatchID)+'
			) IS NULL THEN ''N/S''
			WHEN
			(
				SELECT COUNT(*)
				FROM Relab.Results r WITH(NOLOCK) 
					INNER JOIN TestUnits u WITH(NOLOCK) ON u.ID=r.TestUnitID 
					INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
				WHERE LOWER(LTRIM(RTRIM(ts.TestStageName))) <> ''analysis'' AND r.TestID=#Results.TestID AND u.ID=r.TestUnitID AND PassFail=1 AND u.BatchUnitNumber =' + CONVERT(VARCHAR,@BatchUnitNumber) + ' AND u.BatchID='+CONVERT(VARCHAR,@BatchID)+'
			) = 
			(
				SELECT COUNT(*)
				FROM Relab.Results r WITH(NOLOCK)
					INNER JOIN TestUnits u WITH(NOLOCK) ON u.ID=r.TestUnitID 
					INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
				WHERE LOWER(LTRIM(RTRIM(ts.TestStageName))) <> ''analysis'' AND r.TestID=#Results.TestID AND u.ID=r.TestUnitID AND u.BatchUnitNumber =' + CONVERT(VARCHAR,@BatchUnitNumber) + ' AND u.BatchID='+CONVERT(VARCHAR,@BatchID)+'
			) THEN ''P'' ELSE ''F'' END
		) + '' ('' + CONVERT(VARCHAR, ISNULL((SELECT SUM(val)
					FROM
					(
						SELECT COUNT(DISTINCT TestStageID) * ' + CONVERT(VARCHAR, (@UnitCount)) + ' AS val 
						FROM #exceptions 
						WHERE 
							(
								((TestID=#Results.TestID OR TestID IS NULL) AND TestUnitID IS NULL)
								OR
								((TestID=#Results.TestID OR TestID IS NULL) AND TestUnitID IS NOT NULL
									AND BatchUnitNumber =' + CONVERT(VARCHAR,@BatchUnitNumber) + ')
							)
						GROUP BY BatchUnitNumber, TestStageID
					) AS c), 0)) + '')'''
		
		EXECUTE (@query3)
		
		SELECT @RowID = MIN(RowID) FROM #units WITH(NOLOCK) WHERE RowID > @RowID
	END
	
	ALTER TABLE #results DROP Column TestType
	SELECT * FROM #results WITH(NOLOCK)
	
	DROP TABLE #exceptions
	DROP TABLE #units
	DROP TABLE #results
	DROP TABLE #view
	SET NOCOUNT OFF
END
GO
GRANT EXECUTE ON [Relab].[remispOverallResultsSummary] TO Remi
GO

IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering permissions on [dbo].[remispKPIReports]'
GO
GRANT EXECUTE ON  [dbo].[remispKPIReports] TO [remi]
GO
IF EXISTS (SELECT * FROM #tmpErrors) ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT>0 BEGIN
PRINT 'The database update succeeded'
rollback TRANSACTION
END
ELSE PRINT 'The database update failed'
GO
DROP TABLE #tmpErrors
GO