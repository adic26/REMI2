/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        CI0000001593275.REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 11/5/2013 9:54:35 AM

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
PRINT N'Creating [dbo].[vw_GetTaskInfoCompleted]'
GO
CREATE VIEW [dbo].[vw_GetTaskInfoCompleted]
AS
SELECT qranumber, processorder, BatchID,
	   tsname, 
	   tname, 
	   testtype, 
	   teststagetype, 
	   resultbasedontime, 
	   testunitsfortest, 
	   (SELECT CASE WHEN specifictestduration IS NULL THEN generictestduration ELSE specifictestduration END) AS expectedDuration,
	   TestStageID, TestWI, TestID, IsArchived, RecordExists, TestIsArchived, TestRecordExists
FROM   
	(
		SELECT b.qranumber,b.ID AS BatchID,
		ts.processorder, ts.teststagename AS tsname, t.testname AS tname, t.testtype, ts.teststagetype, t.duration AS genericTestDuration, ts.ID AS TestStageID,t.ID AS TestID,
		t.WILocation As TestWI, ISNULL(ts.IsArchived, 0) AS IsArchived, ISNULL(t.IsArchived, 0) AS TestIsArchived, 
			t.resultbasedontime, 
			(
				SELECT bstd.duration 
				FROM   batchspecifictestdurations AS bstd WITH(NOLOCK)
				WHERE  bstd.testid = t.id 
					   AND bstd.batchid = b.id
			) AS specificTestDuration,
			(				
				SELECT Cast(tu.batchunitnumber AS VARCHAR(MAX)) + ', ' 
				FROM testunits AS tu WITH(NOLOCK)
				WHERE tu.batchid = b.id 
				FOR xml path ('')
			) AS TestUnitsForTest,
			(SELECT TOP 1 1
			FROM TestRecords tr WITH(NOLOCK)
				INNER JOIN TestUnits tu ON tr.TestUnitID = tu.ID
			WHERE tr.TestStageID=ts.ID AND tu.BatchID=b.ID) AS RecordExists,
			(SELECT TOP 1 1
			FROM TestRecords tr WITH(NOLOCK)
				INNER JOIN TestUnits tu ON tr.TestUnitID = tu.ID
			WHERE tr.TestID=t.ID AND tu.BatchID=b.ID AND tr.TestStageID = ts.ID) AS TestRecordExists
		FROM TestStages ts WITH(NOLOCK)
		INNER JOIN Jobs j WITH(NOLOCK) ON ts.JobID=j.ID
		INNER JOIN Batches b WITH(NOLOCK) on j.jobname = b.jobname 
		INNER JOIN Tests t WITH(NOLOCK) ON ( ( ts.teststagetype = 2 AND ts.testid = t.id ) OR ts.teststagetype != 2 AND ts.teststagetype = t.testtype )
		INNER JOIN Products p WITH(NOLOCK) ON b.ProductID=p.ID
	) AS unitData
WHERE TestUnitsForTest IS NOT NULL AND ISNULL(TestRecordExists, 0) = 1 AND ISNULL(RecordExists,0) = 1



GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchGetTaskInfo]'
GO
ALTER PROCEDURE [dbo].[remispBatchGetTaskInfo] @BatchID INT, @TestStageID INT = 0
AS
BEGIN
	DECLARE @BatchStatus INT
	SELECT @BatchStatus = BatchStatus FROM Batches WHERE ID=@BatchID

	IF (@BatchStatus = 5)
	BEGIN
		SELECT QRANumber, expectedDuration, processorder, resultbasedontime, tname As TestName, testtype, teststagetype, tsname AS TestStageName, testunitsfortest, TestID, TestStageID, IsArchived, TestIsArchived, TestWI
		FROM vw_GetTaskInfoCompleted
		WHERE BatchID = @BatchID
			AND
			(
				(@TestStageID = 0)
				OR
				(@TestStageID <> 0 AND TestStageID=@TestStageID)
			)
		ORDER BY ProcessOrder
	END
	ELSE
	BEGIN
		SELECT QRANumber, expectedDuration, processorder, resultbasedontime, tname As TestName, testtype, teststagetype, tsname AS TestStageName, testunitsfortest, TestID, TestStageID, IsArchived, TestIsArchived, TestWI
		FROM vw_GetTaskInfo 
		WHERE BatchID = @BatchID
			AND
			(
				(@TestStageID = 0)
				OR
				(@TestStageID <> 0 AND TestStageID=@TestStageID)
			)
		ORDER BY ProcessOrder
	END
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispGetEstimatedTSTime]'
GO
ALTER PROCEDURE [dbo].[remispGetEstimatedTSTime] @BatchID INT, @TestStageName NVARCHAR(400), @JobName NVARCHAR(400), @TSTimeLeft REAL OUTPUT, @JobTimeLeft REAL OUTPUT,
	@TestStageID INT = NULL, @JobID INT = NULL
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @TestUnitID INT
	DECLARE @BatchUnitNumber INT
	DECLARE @ProcessOrder INT
	DECLARE @TaskID INT
	DECLARE @resultbasedontime INT
	DECLARE @TotalTestTimeMinutes BIGINT
	DECLARE @Status INT
	DECLARE @BatchStatus INT
	DECLARE @UnitTotalTime REAL
	DECLARE @expectedDuration REAL
	DECLARE @StressingTimeOverage REAL -- How much stressing time to minus from job remaining time
	DECLARE @TestType INT
	DECLARE @TSID INT
	DECLARE @TID INT
	SET @TSTimeLeft = 0
	SET @JobTimeLeft = 0
	SET @StressingTimeOverage = 0

	IF (@TestStageID IS NULL OR @TestStageID = 0)
		SELECT @TestStageID = ID FROM TestStages WHERE TestStageName=@TestStageName

	IF (@JobID IS NULL OR @JobID = 0)
		SELECT @JobID = ID FROM Jobs WHERE JobName=@JobName

	SELECT ID AS TestUnitID
	INTO #tempUnits
	FROM TestUnits WITH(NOLOCK)
	WHERE BatchID=@BatchID
	ORDER BY TestUnitID
	
	SELECT @BatchStatus = BatchStatus FROM Batches WHERE ID=@BatchID

	CREATE TABLE #Tasks (ID INT IDENTITY(1, 1), tname NVARCHAR(400), resultbasedontime INT, expectedDuration REAL, processorder INT, tsname NVARCHAR(400), testtype INT, TestID INT, TestStageID INT)

	IF (@BatchStatus = 5)
	BEGIN
		INSERT INTO #Tasks (tname, resultbasedontime,expectedDuration, processorder, tsname, TestType, TestID, TestStageID)
		SELECT tname, resultbasedontime,expectedDuration, processorder, tsname, TestType, TestID, TestStageID
		FROM vw_GetTaskInfoCompleted WITH(NOLOCK)
		WHERE BatchID=@BatchID AND testtype IN (1,2)
		ORDER BY processorder
	END
	ELSE
	BEGIN
		INSERT INTO #Tasks (tname, resultbasedontime,expectedDuration, processorder, tsname, TestType, TestID, TestStageID)
		SELECT tname, resultbasedontime,expectedDuration, processorder, tsname, TestType, TestID, TestStageID
		FROM vw_GetTaskInfo WITH(NOLOCK)
		WHERE BatchID=@BatchID AND testtype IN (1,2)
		ORDER BY processorder
	END
	
	DELETE FROM #Tasks WHERE processorder < (SELECT DISTINCT ProcessOrder FROM #Tasks WHERE TestStageID = @TestStageID)

	SELECT @TestUnitID =MIN(TestUnitID) FROM #tempUnits
	
	--PRINT 'Current Test Stage: ' + @TestStageName

	WHILE (@TestUnitID IS NOT NULL)
	BEGIN
		--PRINT 'TestUnitID: ' + CONVERT(VARCHAR, @TestUnitID)
		SET @UnitTotalTime = 0		

		SELECT @TaskID = MIN(ID) FROM #Tasks
			
		WHILE (@TaskID IS NOT NULL)
		BEGIN
			SELECT @resultbasedontime=resultbasedontime,@expectedDuration=expectedDuration, @ProcessOrder=processorder, @TestType = TestType, @TSID = TestStageID, @TID = TestID
			FROM #Tasks 
			WHERE ID = @TaskID
			
			--PRINT 'Loop Test Stage: ' + @TSName

			--Test has not been done so add expected duration to overall unit time.
			IF NOT EXISTS (SELECT TOP 1 1 FROM TestRecords WITH(NOLOCK) WHERE TestStageID = @TSID AND TestUnitID=@TestUnitID AND TestID=@TID)
				BEGIN
					IF (@TSID = @TestStageID)
					BEGIN
						SET @TSTimeLeft += @expectedDuration
					END
					If (@TestType = 2)
					BEGIN
						SET @StressingTimeOverage += @expectedDuration
					END
					SET @UnitTotalTime += @expectedDuration
				END
			ELSE --Test Record exists
				BEGIN
					--Get Status of test record and how long it has currently been running
					select @Status = Status, @TotalTestTimeMinutes = 
						(
							Select sum(datediff(MINUTE,dtl.intime,(case when (dtl.OutTime IS null) then GETUTCDATE() else dtl.outtime  end ))) 
							from Testrecordsxtrackinglogs as trXtl WITH(NOLOCK)
								INNER JOIN DeviceTrackingLog as dtl WITH(NOLOCK) ON dtl.ID = trXtl.TrackingLogID
							where trXtl.TestRecordID = TestRecords.id
						)
					FROM TestRecords WITH(NOLOCK)
					where TestStageID = @TSID AND TestUnitID=@TestUnitID AND TestID=@TID
					
					If (NOT(@Status = 1 OR @Status = 2 OR @Status=7))
					BEGIN	
						IF (@resultbasedontime = 1)
							BEGIN
								--PRINT 'Result Based On Time: ' + CONVERT(VARCHAR, @Status) + ' = ' + CONVERT(VARCHAR, @TotalTestTimeMinutes) + ' = ' + CONVERT(VARCHAR, @expectedDuration)

								--Test isn't done and the total test time in minutes divided by 60 = hrs <= expected duration
   								IF ((@TotalTestTimeMinutes/60) <= @expectedDuration)--Test isn't done
								BEGIN
									If (@TestType = 2)
									BEGIN
										SET @StressingTimeOverage += (@expectedDuration - (@TotalTestTimeMinutes/60))
									END
									IF (@TSID = @TestStageID)
									BEGIN
										SET @TSTimeLeft += (@expectedDuration - (@TotalTestTimeMinutes/60))
									END
									--Add time by taking expected hrs and minusing total test time hours
									SET @UnitTotalTime += (@expectedDuration - (@TotalTestTimeMinutes/60))
								END
							END
						ELSE
							BEGIN
								If (@TestType = 2)
								BEGIN
									SET @StressingTimeOverage += @expectedDuration
								END
								IF (@TSID = @TestStageID)
								BEGIN
									SET @TSTimeLeft += @expectedDuration
								END
								
								--PRINT 'Result Not Based On Time'
								SET @UnitTotalTime += @expectedDuration
							END
					END
				END
			SELECT @TaskID =MIN(ID) FROM #Tasks WHERE ID > @TaskID
		END
		
		SET @JobTimeLeft += @UnitTotalTime
		SELECT @TestUnitID = MIN(TestUnitID) FROM #tempUnits WHERE TestUnitID > @TestUnitID
	END
	
	IF (@StressingTimeOverage > 0)
	BEGIN
		SET @StressingTimeOverage = @StressingTimeOverage - (@StressingTimeOverage / (SELECT COUNT(*) FROM #tempUnits))
		SET @TSTimeLeft = @TSTimeLeft / (SELECT COUNT(*) FROM #tempUnits)
	END
	
	SET @JobTimeLeft -= @StressingTimeOverage

	--PRINT CONVERT(CHAR(10),DATEADD(SECOND, CAST(@JobTimeLeft * 3600 AS INT), 0),108)
	PRINT @JobTimeLeft
	--PRINT CONVERT(CHAR(10),DATEADD(SECOND, CAST(@TSTimeLeft * 3600 AS INT), 0),108)
	PRINT @TSTimeLeft

	DROP TABLE #Tasks
	DROP TABLE #tempUnits
	SET NOCOUNT OFF
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispGetBatchDocuments]'
GO
ALTER PROCEDURE [dbo].remispGetBatchDocuments @QRANumber nvarchar(11)
AS
BEGIN
	DECLARE @JobName NVARCHAR(400)
	DECLARE @ProductID INT
	DECLARE @ID INT
	SELECT @JobName = JobName, @ProductID = ProductID, @ID = ID FROM Batches WITH(NOLOCK) WHERE QRANumber=@QRANumber

	CREATE TABLE #view (QRANumber NVARCHAR(11), expectedDuration REAL, processorder INT, resultbasedontime INT, TestName NVARCHAR(400), testtype INT, teststagetype INT, TestStageName NVARCHAR(400), testunitsfortest NVARCHAR(MAX), TestID INT, TestStageID INT, IsArchived BIT, TestIsArchived BIT, TestWI NVARCHAR(400))

	insert into #view (QRANumber, expectedDuration, processorder, resultbasedontime, TestName, testtype, teststagetype, TestStageName, testunitsfortest, TestID, TestStageID, IsArchived, TestIsArchived, TestWI)
	exec remispBatchGetTaskInfo @BatchID=@ID

	SELECT (j.JobName + ' WI') AS WIType, j.WILocation AS Location
	FROM Jobs j WITH(NOLOCK)
	WHERE j.JobName=@JobName AND LTRIM(RTRIM(ISNULL(j.WILocation, ''))) <> ''
	UNION
	SELECT DISTINCT TestName AS WIType, TestWI AS Location
	FROM #view WITH(NOLOCK)
	WHERE QRANumber=@QRANumber and processorder > 0 AND testtype IN (1,2) AND LTRIM(RTRIM(ISNULL(TestWI,''))) <> ''
	UNION
	SELECT (j.JobName + ' Procedure') AS WIType, j.ProcedureLocation AS Location
	FROM Jobs j WITH(NOLOCK)
	WHERE j.JobName=@JobName AND LTRIM(RTRIM(ISNULL(j.ProcedureLocation, ''))) <> ''
	UNION
	SELECT 'Specification' AS WIType, 'https://hwqaweb.rim.net/pls/trs/data_entry.main?req=QRA-ENG-SP-11-0001' AS Location
	UNION
	SELECT 'QAP' As WIType, p.QAPLocation AS Location
	FROM Products p WITH(NOLOCK)
	WHERE p.ID=@ProductID AND LTRIM(RTRIM(ISNULL(QAPLocation, ''))) <> ''

	DROP TABLE #view
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
	CREATE TABLE #results (TestID INT)
	CREATE TABLE #exceptions (ID INT, BatchUnitNumber INT, ReasonForRequest INT, ProductGroupName NVARCHAR(150), JobName NVARCHAR(150), TestStageName NVARCHAR(150), TestName NVARCHAR(150), LastUser NVARCHAR(150), TestStageID INT, TestUnitID INT, ProductTypeID INT, AccessoryGroupID INT, ProductID INT, ProductType NVARCHAR(150), AccessoryGroupName NVARCHAR(150), TestID INT, IsMQual INT, TestCenter NVARCHAR(MAX), TestCenterID INT)
	CREATE TABLE #view (qranumber NVARCHAR(11), processorder INT, BatchID INT, tsname NVARCHAR(400), tname NVARCHAR(400), testtype INT, teststagetype INT, resultbasedontime INT, testunitsfortest NVARCHAR(MAX), expectedDuration REAL, TestStageID INT, TestWI NVARCHAR(400), TestID INT, IsArchived BIT, RecordExists BIT, TestIsArchived BIT, TestRecordExists BIT)
	
	SELECT @QRANumber = QRANumber, @ProductID = ProductID, @ProductTypeID=ProductTypeID, @AccessoryGroupID = AccessoryGroupID, @BatchStatus = BatchStatus
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
			
		UPDATE #exceptions SET BatchUnitNumber=0 WHERE BatchUnitNumber IS NULL
	END
	
	SET @query = 'INSERT INTO #results
	SELECT DISTINCT TestID, TName AS [' + @QRANumber + '],
		(
			CASE WHEN
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
					(
						SELECT COUNT(DISTINCT TestStageID) * ' + CONVERT(VARCHAR, (@UnitCount)) + ' AS val '
						
						IF (@BatchStatus = 5)
						BEGIN
							SET @query += 'FROM TestRecords WHERE TestUnitID IN (SELECT ID FROM #units) AND 
							(
								(TestID=i.TestID OR TestID IS NULL)
							)
							GROUP BY TestUnitID, TestStageID '
						END
						ELSE
						BEGIN
							SET @query += 'FROM #exceptions WHERE 
							(
								((TestID=i.TestID OR TestID IS NULL) AND TestUnitID IS NULL)
								OR
								((TestID=i.TestID OR TestID IS NULL) AND TestUnitID IS NOT NULL)
							)
							GROUP BY BatchUnitNumber, TestStageID '
						END
						
						SET @query += '
					) AS c), 0))
				) = 
				(
					SELECT COUNT(DISTINCT r.ID) 
					FROM Relab.Results r WITH(NOLOCK) 
						INNER JOIN TestUnits u WITH(NOLOCK) ON u.ID=r.TestUnitID
						INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
					WHERE LOWER(LTRIM(RTRIM(ts.TestStageName))) <> ''analysis'' AND r.TestID=i.TestID AND u.BatchID='+CONVERT(VARCHAR,@BatchID)+' 
				) THEN ''Y'' ELSE ''N'' END
		) as Completed,
		(
			CASE
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
		) AS [Pass/Fail] '
		
	SET @query2 = 'FROM #view i WITH(NOLOCK)
	ORDER BY TName'

	EXECUTE (@query + @query2)
print @query + @query2
	SELECT @RowID = MIN(RowID) FROM #units
			
	WHILE (@RowID IS NOT NULL)
	BEGIN
		SELECT @BatchUnitNumber=BatchUnitNumber FROM #units WITH(NOLOCK) WHERE RowID=@RowID
		
		EXECUTE ('ALTER TABLE #results ADD [' + @BatchUnitNumber + '] NVARCHAR(10) NULL')
		
		SET @query3 = 'UPDATE #Results SET [' + CONVERT(VARCHAR,@BatchUnitNumber) + '] = (
		CASE
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
	
	SELECT * FROM #results WITH(NOLOCK)
	
	DROP TABLE #exceptions
	DROP TABLE #units
	DROP TABLE #results
	DROP TABLE #view
	SET NOCOUNT OFF
END
GO
ALTER PROCEDURE Relab.remispResultsSearch @MeasurementTypeID INT, @TestID INT, @ParameterName NVARCHAR(255)=NULL, @ParameterValue NVARCHAR(250)=NULL, @ProductID INT = 0, @JobName NVARCHAR(400), @TestStageID INT = 0, @TestCenterID INT = 0
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
	
	SET @query = 'SELECT b.QRANumber, tu.BatchUnitNumber, ts.TestStageName AS TestStageName, rm.MeasurementValue AS MeasurementValue, rm.LowerLimit, rm.UpperLimit, 
		r.ID AS ResultID, b.ID AS BatchID, pd.ProductGroupName, pd.ID AS ProductID, j.JobName, l.[values] AS TestCenter
	FROM Relab.Results r WITH(NOLOCK)
		INNER JOIN TestUnits tu WITH(NOLOCK) ON r.TestUnitID=tu.ID
		INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID
		INNER JOIN Relab.ResultsMeasurements rm WITH(NOLOCK) ON r.ID=rm.ResultID
		INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
		LEFT OUTER JOIN Relab.ResultsParameters p WITH(NOLOCK) ON p.ResultMeasurementID=rm.ID
		INNER JOIN Products pd WITH(NOLOCK) ON pd.ID = b.ProductID
		INNER JOIN Jobs j WITH(NOLOCK) ON j.ID=ts.JobID
		INNER JOIN Lookups l WITH(NOLOCK) ON l.LookupID=b.TestCenterLocationID
	WHERE rm.MeasurementTypeID='+CONVERT(VARCHAR,@MeasurementTypeID)+' AND r.TestID='+CONVERT(VARCHAR,@TestID)+' AND MeasurementValue IS NOT NULL 
		AND
		(
			(' + CONVERT(VARCHAR,@ProductID) + ' > 0 AND pd.ID=' + CONVERT(VARCHAR,@ProductID) + ')
			OR
			(' + CONVERT(VARCHAR,@ProductID) + ' = 0)
		)
		AND
		(
			(' + CONVERT(VARCHAR,@TestCenterID) + ' > 0 AND b.TestCenterLocationID=' + CONVERT(VARCHAR,@TestCenterID) + ')
			OR
			(' + CONVERT(VARCHAR,@TestCenterID) + ' = 0)
		)
		AND
		(
			(LTRIM(RTRIM(''' + @JobName + ''')) <> ''All'' AND LTRIM(RTRIM(j.JobName))=LTRIM(RTRIM(''' + @JobName + ''')))
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


	SET @query2 += ' AND ISNULL(rm.Archived,0)=' + CONVERT(VARCHAR, @FalseBit) + ' AND rm.PassFail=' + CONVERT(VARCHAR, @FalseBit) + '
	ORDER BY QRANumber, BatchUnitNumber, TestStageName'
	
	print @query
	print @query2

	EXEC(@query + @query2)
END
GO
GRANT EXECUTE ON Relab.remispResultsSearch TO REMI
GO
ALTER PROCEDURE [dbo].[remispTrackingLocationsSearchFor]
	@RecordCount int = NULL OUTPUT,
	@ID int = null,
	@TrackingLocationName nvarchar(400)= null, 
	@GeoLocationID INT= null, 
	@Status int = null,
	@TrackingLocationTypeID int= null,
	@TrackingLocationTypeName nvarchar(400)=null,
	@TrackingLocationFunction int = null,
	@HostName nvarchar(255) = null,
	@OnlyActive INT = 0,
	@RemoveHosts INT = 0,
	@ShowHostsNamedAll INT = 0
AS
DECLARE @TrueBit BIT
DECLARE @FalseBit BIT
SET @TrueBit = CONVERT(BIT, 1)
SET @FalseBit = CONVERT(BIT, 0)

IF (@RecordCount IS NOT NULL)
BEGIN
	SET @RecordCount = (SELECT distinct COUNT(*) 
	FROM TrackingLocations as tl 
		INNER JOIN TrackingLocationTypes as tlt ON tl.TrackingLocationTypeID = tlt.ID
		LEFT OUTER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
	WHERE (tl.ID = @ID or @ID is null) 
	and (tlh.status = @Status or @Status is null)
	and (tl.TrackingLocationName = @TrackingLocationName or @TrackingLocationName is null)
	and (TestCenterLocationID = @GeoLocationID or @GeoLocationID is null)
	and (tlh.HostName = @HostName or tlh.HostName='all' or @HostName is null)
	and (tl.TrackingLocationTypeID = @TrackingLocationTypeID or @TrackingLocationTypeID is null)
	and ((tl.TrackingLocationTypeID= tlt.id and tlt.TrackingLocationTypeName = @TrackingLocationTypeName) or @TrackingLocationTypeName is null)
	 and ((tl.TrackingLocationTypeID= tlt.id and tlt.TrackingLocationFunction = @TrackingLocationFunction )or @TrackingLocationFunction is null)
	 AND (
				(@OnlyActive = 1 AND ISNULL(tl.Decommissioned, 0) = 0)
				OR
				(@OnlyActive = 0)
			)
	)
	RETURN
END

SELECT DISTINCT tl.ID, tl.TrackingLocationName, tl.TestCenterLocationID, 
	CASE WHEN @RemoveHosts = 1 THEN 1 ELSE CASE WHEN tlh.Status IS NULL THEN 3 ELSE tlh.Status END END AS Status, 
	tl.LastUser, 
	CASE WHEN @RemoveHosts = 1 THEN '' ELSE tlh.HostName END AS HostName,
	tl.ConcurrencyID, tl.comment,l3.[Values] AS GeoLocationName, 
	CASE WHEN @RemoveHosts = 1 THEN 0 ELSE ISNULL(tlh.ID,0) END AS TrackingLocationHostID,
	(
		SELECT COUNT(*) as CurrentCount 
		FROM TestUnits AS tu
			INNER JOIN DeviceTrackingLog AS dtl ON dtl.TestUnitID = tu.ID
		WHERE dtl.TrackingLocationID = tl.ID and (dtl.OutUser IS NULL)
	) AS CurrentCount,
	tlt.wilocation as TLTWILocation, tlt.UnitCapacity as TLTUnitCapacity, tlt.Comment as TLTComment, tlt.ConcurrencyID as TLTConcurrencyID, tlt.LastUser as TLTLastUser,
	tlt.ID as TLTID, tlt.TrackingLocationTypeName as TLTName, tlt.TrackingLocationFunction as TLTFunction,
	(
		SELECT TOP(1) tu.CurrentTestName as CurrentTestName
		FROM TestUnits AS tu
			INNER JOIN DeviceTrackingLog AS dtl ON dtl.TestUnitID = tu.ID
		WHERE tu.CurrentTestName is not null and dtl.TrackingLocationID = tl.ID and (dtl.OutUser IS NULL)
	) AS CurrentTestName,
	(CASE WHEN EXISTS (SELECT TOP 1 1 FROM DeviceTrackingLog dl WHERE dl.TrackingLocationID=tl.ID) THEN @FalseBit ELSE @TrueBit END) As CanDelete,
	ISNULL(tl.Decommissioned, 0) AS Decommissioned, ISNULL(tl.IsMultiDeviceZone, 0) AS IsMultiDeviceZone, tl.Status AS LocationStatus
	FROM TrackingLocations as tl
		INNER JOIN TrackingLocationTypes as tlt ON tl.TrackingLocationTypeID = tlt.ID
		LEFT OUTER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
		LEFT OUTER JOIN Lookups l3 ON l3.Type='TestCenter' AND l3.lookupID=tl.TestCenterLocationID
	WHERE (tl.ID = @ID or @ID is null) and (tlh.status = @Status or @Status is null)
		and (tl.TrackingLocationName = @TrackingLocationName or @TrackingLocationName is null)
		and (TestCenterLocationID = @GeoLocationID or @GeoLocationID is null)
		and 
		(
			tlh.HostName = @HostName 
			or 
			(
				(@ShowHostsNamedAll = 1 AND tlh.HostName='all')
			)
			or
			@HostName is null 
			or 
			(
				@HostName is not null 
				and exists 
					(
						SELECT tlt1.TrackingLocationTypeName 
						FROM TrackingLocations as tl1
							INNER JOIN trackinglocationtypes as tlt1 ON tlt1.ID = tl1.TrackingLocationTypeID
							INNER JOIN TrackingLocationsHosts tlh1 ON tl1.ID = tlh1.TrackingLocationID
						WHERE tlh1.HostName = @HostName and tlt1.TrackingLocationTypeName = 'Storage'
					)
			)
		)
		and (tl.TrackingLocationTypeID= tlt.id and tlt.id = @TrackingLocationTypeID or @TrackingLocationTypeID is null)
		and (tl.TrackingLocationTypeID= tlt.id and tlt.TrackingLocationTypeName = @TrackingLocationTypeName or @TrackingLocationTypeName is null)
		and (tl.TrackingLocationTypeID= tlt.id and tlt.TrackingLocationFunction = @TrackingLocationFunction or @TrackingLocationFunction is null)
		AND (
				(@OnlyActive = 1 AND ISNULL(tl.Decommissioned, 0) = 0)
				OR
				(@OnlyActive = 0)
			)
	ORDER BY ISNULL(tl.Decommissioned, 0), tl.TrackingLocationName
GO
GRANT EXECUTE ON remispTrackingLocationsSearchFor TO Remi
GO
DROP PROCEDURE remispBatchesSelectTestingCompleteBatches
GO
DROP PROCEDURE remispBatchesSelectHeldBatches
GO
DROP PROCEDURE remispBatchesSelectBatchesForReport 
GO
DROP PROCEDURE remispBatchesActiveSelectByJob
GO
DROP PROCEDURE remispBatchesSelectActiveBatchesForProductGroup
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