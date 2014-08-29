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
	CREATE TABLE #exceptions (ID INT, BatchUnitNumber INT, ReasonForRequestID INT, ProductGroupName NVARCHAR(150), JobName NVARCHAR(150), TestStageName NVARCHAR(150), TestName NVARCHAR(150), LastUser NVARCHAR(150), TestStageID INT, TestUnitID INT, ProductTypeID INT, AccessoryGroupID INT, ProductID INT, ProductType NVARCHAR(150), AccessoryGroupName NVARCHAR(150), TestID INT, IsMQual INT, TestCenter NVARCHAR(MAX), TestCenterID INT, ReasonForRequest NVARCHAR(150))
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
		insert into #exceptions (ID, BatchUnitNumber, ReasonForRequestID, ProductGroupName, JobName, TestStageName, TestName, LastUser, TestStageID, TestUnitID, ProductTypeID, AccessoryGroupID, ProductID, ProductType, AccessoryGroupName, TestID, IsMQual, TestCenter, TestCenterID, ReasonForRequest)
		exec [dbo].[remispTestExceptionsGetBatchExceptions] @QraNumber = @QRANumber
		
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