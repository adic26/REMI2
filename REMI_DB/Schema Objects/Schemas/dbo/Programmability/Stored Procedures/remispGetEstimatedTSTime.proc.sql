ALTER PROCEDURE remispGetEstimatedTSTime @BatchID INT, @TestStageName NVARCHAR(400), @JobName NVARCHAR(400), @TSTimeLeft REAL OUTPUT, @JobTimeLeft REAL OUTPUT,
	@TestStageID INT = NULL, @JobID INT = NULL, @ReturnTestStageGrid INT = 0
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @TestUnitID INT
	DECLARE @BatchUnitNumber INT
	DECLARE @ProcessOrder INT
	DECLARE @TaskID INT
	DECLARE @resultbasedontime INT
	DECLARE @TotalTestTimeMinutes REAL
	DECLARE @Status INT
	DECLARE @BatchStatus INT
	DECLARE @UnitTotalTime REAL
	DECLARE @expectedDuration REAL
	DECLARE @StressingTimeOverage REAL -- How much stressing time to minus from job remaining time
	DECLARE @TestType INT
	DECLARE @TSID INT
	DECLARE @TID INT
	DECLARE @1DropTime REAL
	DECLARE @10TumbleTime REAL
	DECLARE @TSName NVARCHAR(255)
	SET @TSTimeLeft = 0
	SET @JobTimeLeft = 0
	SET @StressingTimeOverage = 0
	SET @TSName = ''
	SET @1DropTime = 1
	SET @10TumbleTime = 1

	IF (@JobID IS NULL OR @JobID = 0)
		SELECT @JobID = ID FROM Jobs WHERE JobName=@JobName

	IF (@TestStageID IS NULL OR @TestStageID = 0)
		SELECT @TestStageID = ID FROM TestStages WHERE TestStageName=@TestStageName AND JobID=@JobID

	SELECT ID AS TestUnitID
	INTO #tempUnits
	FROM TestUnits WITH(NOLOCK)
	WHERE BatchID=@BatchID
	ORDER BY TestUnitID
	
	SELECT @BatchStatus = BatchStatus FROM Batches WHERE ID=@BatchID

	CREATE TABLE #Tasks (ID INT IDENTITY(1, 1), tname NVARCHAR(400), resultbasedontime INT, expectedDuration REAL, processorder INT, tsname NVARCHAR(400), testtype INT, TestID INT, TestStageID INT)
	CREATE TABLE #Stressing (ID INT IDENTITY(1, 1), TestStageID INT, NumUnits INT, StressingTime REAL, NUMDT REAL, NumDTDiff REAL)
	CREATE TABLE #TestStagesTimes (TestStageID INT, ProcessOrder INT, TimeLeft REAL)

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
	
	DELETE FROM #Tasks WHERE processorder < 0
	
	SELECT @TestUnitID =MIN(TestUnitID) FROM #tempUnits

	WHILE (@TestUnitID IS NOT NULL)
	BEGIN
		SET @UnitTotalTime = 0
		SET @TSName = ''

		SELECT @TaskID = MIN(ID) FROM #Tasks
			
		WHILE (@TaskID IS NOT NULL)
		BEGIN
			SELECT @resultbasedontime=resultbasedontime,@expectedDuration=expectedDuration, @ProcessOrder=processorder, @TestType = TestType, @TSID = TestStageID, @TID = TestID, @TSName = TSName
			FROM #Tasks 
			WHERE ID = @TaskID

			--Test has not been done so add expected duration to overall unit time.
			IF NOT EXISTS (SELECT TOP 1 1 FROM TestRecords WITH(NOLOCK) WHERE TestStageID = @TSID AND TestUnitID=@TestUnitID AND TestID=@TID)
				BEGIN
					IF (@TSID = @TestStageID)
					BEGIN
						SET @TSTimeLeft += @expectedDuration
					END
					If (@TestType = 2)
					BEGIN
						IF EXISTS (SELECT 1 FROM #Stressing WHERE TestStageID=@TSID)
						BEGIN
							UPDATE #Stressing
							SET NumUnits +=1, StressingTime += @expectedDuration
							WHERE TestStageID=@TSID
						END
						ELSE
						BEGIN
							DECLARE @num REAL
							BEGIN TRY
								SET @num = CASE WHEN @TSName LIKE '%Drop%' OR @TSName LIKE '%Tumble%' THEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@TSName,' Drops', ''),' Drop', ''),' Tumbles', ''),' Tumble', ''), 'Drop', '') ELSE NULL END
							END TRY
							BEGIN CATCH
								SET @num = 0
							END CATCH
							INSERT INTO #Stressing VALUES (@TSID, 1, @expectedDuration, @num, 0)
						END
					END
					ELSE
					BEGIN
						SET @UnitTotalTime += @expectedDuration
					END
					
					IF EXISTS (SELECT 1 FROM #TestStagesTimes WHERE TestStageID=@TSID)
					BEGIN
						UPDATE #TestStagesTimes
						SET TimeLeft += @expectedDuration
						WHERE TestStageID=@TSID
					END
					ELSE
					BEGIN
						INSERT INTO #TestStagesTimes VALUES (@TSID, @ProcessOrder, @expectedDuration)
					END					
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
					WHERE TestStageID = @TSID AND TestUnitID=@TestUnitID AND TestID=@TID

					If (@Status IN (0, 8, 12)) -- 0: NoSet, 8: In Progress, 12: TestingSuspended
					BEGIN
						IF (@resultbasedontime = 1)
							BEGIN
								--PRINT 'Result Based On Time: ' + CONVERT(VARCHAR, @Status) + ' = ' + CONVERT(VARCHAR, @TotalTestTimeMinutes) + ' = ' + CONVERT(VARCHAR, @expectedDuration)

								--Test isn't done and the total test time in minutes divided by 60 = hrs <= expected duration
   								IF ((@TotalTestTimeMinutes/60) <= @expectedDuration)--Test isn't done
								BEGIN
									If (@TestType = 2)
									BEGIN										
										IF EXISTS (SELECT 1 FROM #Stressing WHERE TestStageID=@TSID)
										BEGIN
											UPDATE #Stressing
											SET NumUnits +=1, StressingTime += (@expectedDuration - (@TotalTestTimeMinutes/60))
											WHERE TestStageID=@TSID
										END
										ELSE
										BEGIN
											DECLARE @num2 REAL
											BEGIN TRY
												SET @num2 = CASE WHEN @TSName LIKE '%Drop%' OR @TSName LIKE '%Tumble%' THEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@TSName,' Drops', ''),' Drop', ''),' Tumbles', ''),' Tumble', ''), 'Drop', '') ELSE NULL END
											END TRY
											BEGIN CATCH
												SET @num2 = 0
											END CATCH
											INSERT INTO #Stressing VALUES (@TSID, 1, (@expectedDuration - (@TotalTestTimeMinutes/60)), @num2, 0)
										END
									END
									ELSE
									BEGIN
										--Add time by taking expected hrs and minusing total test time hours
										SET @UnitTotalTime += (@expectedDuration - (@TotalTestTimeMinutes/60))
									END
									
									IF (@TSID = @TestStageID)
									BEGIN
										SET @TSTimeLeft += (@expectedDuration - (@TotalTestTimeMinutes/60))
									END
					
									IF EXISTS (SELECT 1 FROM #TestStagesTimes WHERE TestStageID=@TSID)
									BEGIN
										UPDATE #TestStagesTimes
										SET TimeLeft += (@expectedDuration - (@TotalTestTimeMinutes/60))
										WHERE TestStageID=@TSID
									END
									ELSE
									BEGIN
										INSERT INTO #TestStagesTimes VALUES (@TSID, @ProcessOrder, (@expectedDuration - (@TotalTestTimeMinutes/60)))
									END
								END
							END
						ELSE
							BEGIN
								If (@TestType = 2)
								BEGIN
									IF EXISTS (SELECT 1 FROM #Stressing WHERE TestStageID=@TSID)
									BEGIN
										UPDATE #Stressing
										SET NumUnits +=1, StressingTime += @expectedDuration
										WHERE TestStageID=@TSID
									END
									ELSE
									BEGIN
										INSERT INTO #Stressing VALUES (@TSID, 1, @expectedDuration, CASE WHEN @TSName LIKE '%Drop%' OR @TSName LIKE '%Tumble%' THEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@TSName,' Drops', ''),' Drop', ''),' Tumbles', ''),' Tumble', ''), 'Drop', '') ELSE NULL END, 0)
									END
								END
								ELSE
								BEGIN								
									--PRINT 'Result Not Based On Time'
									SET @UnitTotalTime += @expectedDuration
								END
								IF (@TSID = @TestStageID)
								BEGIN
									SET @TSTimeLeft += @expectedDuration
								END
					
								IF EXISTS (SELECT 1 FROM #TestStagesTimes WHERE TestStageID=@TSID)
								BEGIN
									UPDATE #TestStagesTimes
									SET TimeLeft += @expectedDuration
									WHERE TestStageID=@TSID
								END
								ELSE
								BEGIN
									INSERT INTO #TestStagesTimes VALUES (@TSID, @ProcessOrder, @expectedDuration)
								END
							END
					END
				END
			SELECT @TaskID =MIN(ID) FROM #Tasks WHERE ID > @TaskID
		END

		SET @JobTimeLeft += @UnitTotalTime
		
		SELECT @TestUnitID = MIN(TestUnitID) FROM #tempUnits WHERE TestUnitID > @TestUnitID
	END

	IF ((SELECT COUNT(*) FROM #Stressing) > 0)
	BEGIN
		UPDATE #Stressing
		SET StressingTime = CASE WHEN ts.TestStageName LIKE '%Drop%' THEN ((NUMDT * @1DropTime) * NumUnits) WHEN ts.TestStageName LIKE '%Tumble%' THEN ((NUMDT * @10TumbleTime) / NumUnits) ELSE StressingTime END
		FROM #Stressing
			INNER JOIN TestStages ts ON ts.ID= #Stressing.TestStageID
		
		DECLARE @ID INT
		DECLARE @PreviousTime REAL
		SET @PreviousTime = 0
		SELECT @ID = MIN(ID) FROM #Stressing
			
		WHILE (@ID IS NOT NULL)
		BEGIN
			IF (@ID > 1)
			BEGIN
				UPDATE #Stressing SET NumDTDiff = StressingTime - @PreviousTime WHERE ID=@ID
			END
			ELSE
			BEGIN
				UPDATE #Stressing SET NumDTDiff = StressingTime WHERE ID=@ID
			END
			
			SELECT @PreviousTime = StressingTime FROM #Stressing WHERE ID = @ID	
						
			SELECT @ID = MIN(ID) FROM #Stressing WHERE ID > @ID
		END
		
		UPDATE #Stressing
		SET StressingTime = NumDTDiff
	
		SELECT @StressingTimeOverage = SUM(StressingTime/NumUnits) FROM #Stressing

		IF EXISTS (SELECT 1 FROM #Stressing WHERE TestStageID=@TestStageID)
			SET @TSTimeLeft = @TSTimeLeft / ISNULL((SELECT NumUnits FROM #Stressing WHERE TestStageID = @TestStageID),0) --If currently at a stressing stage
	END
		
	UPDATE tst
	SET tst.TimeLeft = StressingTime
	FROM #TestStagesTimes tst
		INNER JOIN #Stressing s ON tst.TestStageID=s.TestStageID
		
	SET @JobTimeLeft += @StressingTimeOverage

	--PRINT CONVERT(CHAR(10),DATEADD(SECOND, CAST(@JobTimeLeft * 3600 AS INT), 0),108)
	PRINT @JobTimeLeft
	--PRINT CONVERT(CHAR(10),DATEADD(SECOND, CAST(@TSTimeLeft * 3600 AS INT), 0),108)
	PRINT @TSTimeLeft
	
	IF (@ReturnTestStageGrid = 1)
	BEGIN
		SELECT tst.TimeLeft, ts.TestStageName, tst.TestStageID
		FROM #TestStagesTimes tst
			INNER JOIN TestStages ts ON ts.ID=tst.TestStageID
		ORDER BY tst.ProcessOrder
	END

	DROP TABLE #Tasks
	DROP TABLE #tempUnits
	DROP TABLE #Stressing
	DROP TABLE #TestStagesTimes
	SET NOCOUNT OFF
END
GO
GRANT EXECUTE ON remispGetEstimatedTSTime TO Remi
GO