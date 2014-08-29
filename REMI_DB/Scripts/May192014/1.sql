/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        CI0000001593275.REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 5/16/2014 12:17:20 PM

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
alter table tests Add Owner nvarchar(255) null
go
alter table tests Add Trainee nvarchar(255) null
go
PRINT N'Altering [dbo].[remifnUserCanDelete]'
GO
ALTER FUNCTION dbo.remifnUserCanDelete (@UserName NVARCHAR(255))
RETURNS BIT
AS
BEGIN
	DECLARE @Exists BIT
	SET @UserName = LTRIM(RTRIM(@UserName))
	
	SELECT @Exists = (SELECT DISTINCT 0
		FROM BatchComments
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM Batches
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM BatchSpecificTestDurations
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM Jobs
		WHERE LTRIM(RTRIM(LastUser))=@UserName	
		UNION
		SELECT DISTINCT 0
		FROM ProductConfiguration
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM ProductConfigValues
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM ProductSettings
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM StationConfigurationUpload
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM TestExceptions
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM TestRecords
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM Tests
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM Tests
		WHERE LTRIM(RTRIM(Owner))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM Tests
		WHERE LTRIM(RTRIM(Trainee))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM TestStages
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM TestUnits
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM TrackingLocations
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION 
		SELECT DISTINCT 0
		FROM TrackingLocationsHosts
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION 
		SELECT DISTINCT 0
		FROM TrackingLocationsHostsConfiguration
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION 
		SELECT DISTINCT 0
		FROM TrackingLocationsHostsConfigValues
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM TrackingLocationTypePermissions
		WHERE LTRIM(RTRIM(LastUser))=@UserName OR LTRIM(RTRIM(UserName))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM TaskAssignments
		WHERE LTRIM(RTRIM(AssignedTo))=@UserName OR LTRIM(RTRIM(AssignedBy))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM TrackingLocationTypes
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM UsersProducts
		WHERE LTRIM(RTRIM(LastUser))=@UserName
		UNION
		SELECT DISTINCT 0
		FROM ProductConfigurationUpload
		WHERE LTRIM(RTRIM(LastUser))=@UserName)
	
	RETURN ISNULL(@Exists, 1)
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestsSelectSingleItemByName]'
GO
ALTER PROCEDURE [dbo].[remispTestsSelectSingleItemByName] @Name nvarchar(400), @ParametricOnly INT = 1
AS
	SELECT t.Comment,t.ConcurrencyID,t.Duration,t.ID,t.LastUser,t.ResultBasedOntime,t.TestName,t.TestType,t.WILocation, t.IsArchived, t.Owner, t.Trainee
	FROM Tests as t
	WHERE t.TestName = @name AND 
		(
			@ParametricOnly = 0
			OR
			(@ParametricOnly = 1 AND TestType=1)
		)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispGetEstimatedTSTime]'
GO
ALTER PROCEDURE [dbo].[remispGetEstimatedTSTime] @BatchID INT, @TestStageName NVARCHAR(400), @JobName NVARCHAR(400), @TSTimeLeft REAL OUTPUT, @JobTimeLeft REAL OUTPUT,
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
						print @TSName
							INSERT INTO #Stressing VALUES (@TSID, 1, @expectedDuration, CASE WHEN @TSName LIKE '%Drop%' OR @TSName LIKE '%Tumble%' THEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@TSName,' Drops', ''),' Drop', ''),' Tumbles', ''),' Tumble', ''), 'Drop', '') ELSE NULL END, 0)
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
											INSERT INTO #Stressing VALUES (@TSID, 1, (@expectedDuration - (@TotalTestTimeMinutes/60)), CASE WHEN @TSName LIKE '%Drop%' OR @TSName LIKE '%Tumble%' THEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@TSName,' Drops', ''),' Drop', ''),' Tumbles', ''),' Tumble', ''), 'Drop', '') ELSE NULL END, 0)
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
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestsSelectSingleItem]'
GO
ALTER PROCEDURE [dbo].[remispTestsSelectSingleItem] @ID int
AS
	SELECT t.Comment,t.ConcurrencyID,t.Duration,t.ID,t.LastUser,t.ResultBasedOntime,t.TestName,t.TestType,t.WILocation, t.IsArchived, t.Owner, t.Trainee
	FROM Tests as t
	WHERE t.ID = @ID
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestsSelectListByType]'
GO
ALTER PROCEDURE [dbo].[remispTestsSelectListByType] @TestType int, @IncludeArchived BIT = 0
AS
BEGIN
	SELECT t.Comment,t.ConcurrencyID,t.Duration,t.ID,t.LastUser,t.ResultBasedOntime,t.TestName,t.TestType,t.WILocation, dbo.remifnTestCanDelete(t.ID) AS CanDelete, t.IsArchived,
		(SELECT TestStageName FROM TestStages WHERE TestID=t.ID) As TestStage, (SELECT JobName FROM Jobs WHERE ID IN (SELECT JobID FROM TestStages WHERE TestID=t.ID)) As JobName,
		t.Owner, t.Trainee
	FROM Tests t
	WHERE TestType = @TestType 
		AND
		(
			(@IncludeArchived = 0 AND ISNULL(t.IsArchived, 0) = 0)
			OR
			(@IncludeArchived = 1)
		)
	ORDER BY TestName;
	
	SELECT t.id, tlt.id, tlt.TrackingLocationTypeName    
	FROM trackinglocationtypes as tlt, TrackingLocationsForTests as tlfort, Tests as t
	WHERE tlfort.testid = t.id and tlt.ID = tlfort.TrackingLocationtypeID
		AND t.TestType = @TestType
	ORDER BY tlt.TrackingLocationTypeName asc
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestsInsertUpdateSingleItem]'
GO
ALTER PROCEDURE [dbo].[remispTestsInsertUpdateSingleItem]
	@TestName nvarchar(400), 
	@Duration real, 
	@TestType int,
	@WILocation nvarchar(800)=null,
	@Comment nvarchar(1000)=null,	
	@ID int OUTPUT,
	@LastUser nvarchar(255),
	@ResultBasedOnTime bit,
	@ConcurrencyID rowversion OUTPUT,
	@IsArchived BIT = 0,
	@Owner NVARCHAR(255) = NULL,
	@Trainee NVARCHAR(255) = NULL
AS
	DECLARE @ReturnValue int
	
	IF (@ID IS NULL) and (((select count (*) from Tests where TestName = @TestName)= 0) or @TestType != 1)-- New Item
	BEGIN
		INSERT INTO Tests (TestName, Duration, TestType, WILocation, Comment, lastUser, ResultBasedOntime, IsArchived, Owner, Trainee)
		VALUES
		(
			@TestName, 
			@Duration, 
			@TestType, 
			@WILocation,
			@Comment,
			@lastUser,
			@ResultBasedOnTime,
			@IsArchived,
			@Owner, @Trainee
		)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE -- Exisiting Item
	BEGIN
		UPDATE Tests SET
			TestName = @TestName, 
			Duration = @Duration, 
			TestType = @TestType, 
			WILocation = @WILocation,
			Comment = @Comment,
			lastUser = @LastUser,
			ResultBasedOntime = @ResultBasedOnTime,
			IsArchived = @IsArchived,
			Owner=@Owner, Trainee=@Trainee
		WHERE ID = @ID AND ConcurrencyID = @ConcurrencyID

		SELECT @ReturnValue = @ID
	END

	SET @ConcurrencyID = (SELECT ConcurrencyID FROM Tests WHERE ID = @ReturnValue)
	SET @ID = @ReturnValue
	
	IF (@@ERROR != 0)
	BEGIN
		RETURN -1
	END
	ELSE
	BEGIN
		RETURN 0
	END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[ProductTestReady]'
GO
CREATE TABLE [dbo].[ProductTestReady]
(
[ProductID] [int] NOT NULL,
[TestID] [int] NOT NULL,
[PSID] [int] NOT NULL,
[Comment] [ntext] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IsReady] [int] NULL,
[ID] [int] NOT NULL IDENTITY(1, 1)
)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating primary key [PK_ProductTestReady] on [dbo].[ProductTestReady]'
GO
ALTER TABLE [dbo].[ProductTestReady] ADD CONSTRAINT [PK_ProductTestReady] PRIMARY KEY CLUSTERED  ([ID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[remispProductTestReady]'
GO
CREATE PROCEDURE [dbo].[remispProductTestReady] @ProductID INT, @MNum NVARCHAR(3)
AS
BEGIN
	DECLARE @PSID AS INT = (SELECT ID FROM ProductSettings WHERE KeyName=@MNum AND ProductID=@ProductID)
	
	SELECT t.TestName, @MNum AS M, CASE ptr.IsReady WHEN 1 THEN 'Yes' WHEN 2 THEN 'No' WHEN 3 THEN 'N/A' ELSE '' END AS IsReady, 
		ptr.Comment, t.Owner, t.Trainee, t.ID As TestID, ptr.ID As ReadyID, @PSID As PSID
	FROM Tests t
		LEFT OUTER JOIN ProductTestReady ptr ON ptr.TestID=t.ID AND ptr.ProductID=@ProductID AND ptr.PSID=@PSID
	WHERE t.TestName IN ('Parametric Radiated Wi-Fi','Acoustic Test', 'HAC Test', 'Sensor Test',
		'Touch Panel Test','Insertion','Top Facing Keys Tactility Test','Peripheral Keys Tactility Test','Charging Test',
		'Camera Front','Bluetooth Test','Accessory Charging','Accessory Acoustic Test','Radiated RF Test','KET Top Facing Keys Cycling Test')
	ORDER BY t.TestName
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
				'
					IF (@BatchStatus = 5)
						BEGIN
							SET @query += ' (SELECT COUNT(*) FROM TestRecords WHERE TestUnitID IN (SELECT ID FROM #units) AND TestID=i.TestID ) '
						END
						ELSE
						BEGIN
							SET @query += ' (SELECT COUNT(DISTINCT r.ID) 
								FROM Relab.Results r WITH(NOLOCK) 
									INNER JOIN TestUnits u WITH(NOLOCK) ON u.ID=r.TestUnitID
									INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
								WHERE LOWER(LTRIM(RTRIM(ts.TestStageName))) <> ''analysis'' AND r.TestID=i.TestID AND u.BatchID='+CONVERT(VARCHAR,@BatchID)+' ) '
						END
				SET @query += ' END THEN ''Y'' ELSE ''N'' END
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
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding foreign keys to [dbo].[ProductTestReady]'
GO
ALTER TABLE [dbo].[ProductTestReady] ADD CONSTRAINT [FK_ProductTestReady_Products] FOREIGN KEY ([ProductID]) REFERENCES [dbo].[Products] ([ID])
ALTER TABLE [dbo].[ProductTestReady] ADD CONSTRAINT [FK_ProductTestReady_Tests] FOREIGN KEY ([TestID]) REFERENCES [dbo].[Tests] ([ID])
ALTER TABLE [dbo].[ProductTestReady] ADD CONSTRAINT [FK_ProductTestReady_ProductSettings] FOREIGN KEY ([PSID]) REFERENCES [dbo].[ProductSettings] ([ID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering permissions on [dbo].[remispProductTestReady]'
GO
GRANT EXECUTE ON  [dbo].[remispProductTestReady] TO [remi]
GO

ALTER PROCEDURE remispGetUserTraining @UserID INT, @ShowTrainedOnly INT
AS
BEGIN
	SELECT UserTraining.ID, UserID, DateAdded, Lookups.LookupID, Lookups.[Values] AS TrainingOption, 
		CASE WHEN ID IS NOT NULL THEN CONVERT(BIT,1) ELSE CONVERT(BIT, 0) END AS IsTrained,
		ll.[Values] As Level, ISNULL(UserTraining.LevelLookupID,0) AS LevelLookupID,
		ConfirmDate, CASE WHEN ConfirmDate IS NOT NULL THEN 1 ELSE 0 END AS IsConfirmed, ll.[Values] As Level
	FROM Lookups
		LEFT OUTER JOIN UserTraining ON UserTraining.LookupID=Lookups.LookupID AND UserTraining.UserID=@UserID
		LEFT OUTER JOIN Lookups ll ON ll.LookupID=UserTraining.LevelLookupID AND ll.Type='Level'
	WHERE Lookups.Type='Training'
		AND 
		(
			(@ShowTrainedOnly = 1 AND CASE WHEN ID IS NOT NULL THEN CONVERT(BIT,1) ELSE CONVERT(BIT, 0) END = CONVERT(BIT,1))
			OR
			(@ShowTrainedOnly = 0)
		)
	ORDER BY Lookups.[Values]
END
GO
GRANT EXECUTE ON remispGetUserTraining TO REMI
GO
ALTER procedure [dbo].[remispUsersSearch] @ProductID INT = 0, @TestCenterID INT = 0, @TrainingID INT = 0, @TrainingLevelID INT = 0, @ByPass INT = 0, @showAllGrid BIT = 0, @UserID INT = 0
AS
BEGIN
	IF (@showAllGrid = 0)
	BEGIN
		SELECT DISTINCT u.ID, u.LDAPLogin
		FROM Users u
			LEFT OUTER JOIN UserTraining ut ON ut.UserID = u.ID
			LEFT OUTER JOIN UsersProducts up ON up.UserID = u.ID
		WHERE u.IsActive=1 AND (
				(u.TestCentreID=@TestCenterID) 
				OR
				(@TestCenterID = 0)
			  )
			  AND
			  (
				(ut.LookupID=@TrainingID) 
				OR
				(@TrainingID = 0)
			  )
			  AND
			  (
				(ut.LevelLookupID=@TrainingLevelID) 
				OR
				(@TrainingLevelID = 0)
			  )
			  AND
			  (
				(u.ByPassProduct=@ByPass) 
				OR
				(@ByPass = 0)
			  )
			  AND
			  (
				(up.ProductID=@ProductID) 
				OR
				(@ProductID = 0)
			  )
		ORDER BY u.LDAPLogin
	END
	ELSE
	BEGIN
		DECLARE @rows VARCHAR(8000)
		DECLARE @query VARCHAR(4000)
		SELECT @rows=  ISNULL(STUFF(
		( 
		SELECT DISTINCT '],[' + l.[Values]
		FROM Lookups l
		WHERE l.Type='Training' And l.IsActive=1
		AND (
				(l.LookupID=@TrainingID) 
				OR
				(@TrainingID = 0)
			  )
		ORDER BY '],[' + l.[Values]
		FOR XML PATH('')), 1, 2, '') + ']','[na]')

		SET @query = '
			SELECT *
			FROM
			(
				SELECT CASE WHEN ut.lookupID IS NOT NULL THEN (CASE WHEN ut.LevelLookupID IS NULL THEN ''*'' ELSE (SELECT SUBSTRING([values], 1, 1) FROM Lookups WHERE LookupID=LevelLookupID) END) ELSE NULL END As Row, u.LDAPLogin, l.[values] As Training
				FROM Users u WITH(NOLOCK)
					LEFT OUTER JOIN UserTraining ut ON ut.UserID = u.ID
					LEFT OUTER JOIN Lookups l on l.lookupid=ut.lookupid
				WHERE u.IsActive = 1 AND (
				(u.TestCentreID=' + CONVERT(VARCHAR, @TestCenterID) + ') 
				OR
				(' + CONVERT(VARCHAR, @TestCenterID) + ' = 0)
			  )
			  AND
			  (
				(ut.LookupID=' + CONVERT(VARCHAR, @TrainingID) + ') 
				OR
				(' + CONVERT(VARCHAR, @TrainingID) + ' = 0)
			  )
			  AND
			  (
				(u.ID=' + CONVERT(VARCHAR, @UserID) + ')
				OR
				(' + CONVERT(VARCHAR, @UserID) + ' = 0)
			  )
			)r
			PIVOT 
			(
				MAX(row) 
				FOR Training 
					IN ('+@rows+')
			) AS pvt'
		EXECUTE (@query)	
	END
END
GO
GRANT EXECUTE ON remispUsersSearch TO REMI
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