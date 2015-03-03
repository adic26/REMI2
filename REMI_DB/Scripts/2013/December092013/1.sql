begin tran
go
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
	SET @TSTimeLeft = 0
	SET @JobTimeLeft = 0
	SET @StressingTimeOverage = 0

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
	CREATE TABLE #Stressing (TestStageID INT, NumUnits INT, StressingTime REAL)
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

		SELECT @TaskID = MIN(ID) FROM #Tasks
			
		WHILE (@TaskID IS NOT NULL)
		BEGIN
			SELECT @resultbasedontime=resultbasedontime,@expectedDuration=expectedDuration, @ProcessOrder=processorder, @TestType = TestType, @TSID = TestStageID, @TID = TestID
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
							INSERT INTO #Stressing VALUES (@TSID, 1, @expectedDuration)
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
											INSERT INTO #Stressing VALUES (@TSID, 1, (@expectedDuration - (@TotalTestTimeMinutes/60)))
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
										INSERT INTO #Stressing VALUES (@TSID, 1, @expectedDuration)
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
		SELECT @StressingTimeOverage = SUM(StressingTime/NumUnits) FROM #Stressing

		IF EXISTS (SELECT 1 FROM #Stressing WHERE TestStageID=@TestStageID)
			SET @TSTimeLeft = @TSTimeLeft / ISNULL((SELECT NumUnits FROM #Stressing WHERE TestStageID = @TestStageID),0) --If currently at a stressing stage
	END
	
	UPDATE tst
	SET tst.TimeLeft = (TimeLeft / NumUnits)
	FROM #TestStagesTimes tst
		INNER JOIN #Stressing s ON tst.TestStageID=s.TestStageID
		
	SET @JobTimeLeft += @StressingTimeOverage

	--PRINT CONVERT(CHAR(10),DATEADD(SECOND, CAST(@JobTimeLeft * 3600 AS INT), 0),108)
	PRINT @JobTimeLeft
	--PRINT CONVERT(CHAR(10),DATEADD(SECOND, CAST(@TSTimeLeft * 3600 AS INT), 0),108)
	PRINT @TSTimeLeft
	
	IF (@ReturnTestStageGrid = 1)
	BEGIN
		SELECT tst.TimeLeft, ts.TestStageName
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
ALTER procedure [dbo].[remispExceptionSearch] @ProductID INT = 0, @AccessoryGroupID INT = 0, @ProductTypeID INT = 0, @TestID INT = 0, @TestStageID INT = 0, @JobName NVARCHAR(400) = NULL, 
	@IncludeBatches INT = 0, @RequestReason INT = 0, @TestCenterID INT = 0, @IsMQual INT = 0, @QRANumber NVARCHAR(11) = NULL
AS
BEGIN
	DECLARE @JobID INT
	SELECT @JobID = ID FROM Jobs WITH(NOLOCK) WHERE JobName=@JobName

	select *
	from 
	(
		select ROW_NUMBER() over (order by p.ProductGroupName desc)as row, pvt.ID, b.QRANumber, ISNULL(tu.Batchunitnumber, 0) as batchunitnumber, pvt.[ReasonForRequest], p.ProductGroupName,
		(select jobname from jobs,TestStages where teststages.id =pvt.TestStageid and Jobs.ID = TestStages.jobid) as jobname, 
		(select teststagename from teststages WITH(NOLOCK) where teststages.id =pvt.TestStageid) as teststagename, 
		t.TestName,pvt.TestStageID, pvt.TestUnitID,
		(select top 1 LastUser from TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS LastUser,
		(select top 1 ConcurrencyID from TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS ConcurrencyID,
		pvt.ProductTypeID, pvt.AccessoryGroupID, pvt.ProductID, l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, pvt.IsMQual, l3.[Values] As TestCenter, l3.[LookupID] AS TestCenterID
		FROM vw_ExceptionsPivoted as pvt WITH(NOLOCK)
			LEFT OUTER JOIN Tests t WITH(NOLOCK) ON pvt.Test = t.ID
			LEFT OUTER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = pvt.TestUnitID
			LEFT OUTER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
			LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND l.LookupID=pvt.ProductTypeID
			LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.Type='AccessoryType' AND l2.LookupID=pvt.AccessoryGroupID
			LEFT OUTER JOIN Products p WITH(NOLOCK) ON p.ID=pvt.ProductID
			LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.Type='TestCenter' AND l3.LookupID=pvt.TestCenterID
		WHERE (
				(pvt.[ProductID]=@ProductID) 
				OR
				(@ProductID = 0)
			)
			AND
			(
				(pvt.ReasonForRequest = @RequestReason)
				OR
				(@RequestReason = 0)
			)
			AND
			(
				(pvt.IsMQual = @IsMQual) 
				OR
				(@IsMQual = 0)
			)
			AND
			(
				(pvt.TestCenterID = @TestCenterID) 
				OR
				(@TestCenterID = 0)
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
			AND
			(
				(@QRANumber IS NULL)
				OR
				(@QRANumber IS NOT NULL AND b.QRANumber=@QRANumber)
			)
	) as exceptionResults
	ORDER BY QRANumber, Batchunitnumber, TestName
END
GO
GRANT EXECUTE ON remispExceptionSearch TO REMI
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
				AND ((' + @OnlyFails + ' = 1 AND PassFail=' + @FalseBit + ') OR (' + @OnlyFails + ' = 0))
			) te PIVOT (MAX(Value) FOR ParameterName IN (' + @rows + ')) AS pvt')
	END
	ELSE
	BEGIN
		EXEC ('ALTER TABLE #parameters DROP COLUMN na')
	END
	
	SELECT rm.ID, ISNULL(ISNULL(lt.[Values], ltsf.[Values]), ltmf.[Values]) As Measurement, LowerLimit AS [Lower Limit], UpperLimit AS [Upper Limit], MeasurementValue AS Result, lu.[Values] As Unit, 
		CASE WHEN PassFail=1 THEN 'Pass' ELSE 'Fail' END AS [Pass/Fail],
		rm.MeasurementTypeID, rm.ReTestNum AS [Test Num], rm.Archived, rm.XMLID, 
		@ReTestNum AS MaxVersion, rm.Comment, ISNULL(rmf.[File], 0) AS [Image], 
		ISNULL(UPPER(SUBSTRING(rmf.ContentType,2,LEN(rmf.ContentType))), 'PNG') AS ContentType, rm.Description, 
		ISNULL((SELECT TOP 1 1 FROM Relab.ResultsMeasurementsAudit rma WHERE rma.ResultMeasurementID=rm.ID AND rma.PassFail <> rm.PassFail ORDER BY DateEntered DESC), 0) As WasChanged,
		p.*
	FROM Relab.ResultsMeasurements rm WITH(NOLOCK)
		LEFT OUTER JOIN Lookups lu WITH(NOLOCK) ON lu.Type='UnitType' AND lu.LookupID=rm.MeasurementUnitTypeID
		LEFT OUTER JOIN Lookups lt WITH(NOLOCK) ON lt.Type='MeasurementType' AND lt.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Lookups ltsf WITH(NOLOCK) ON ltsf.Type='SFIFunctionalMatrix' AND ltsf.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Lookups ltmf WITH(NOLOCK) ON ltmf.Type='MFIFunctionalMatrix' AND ltmf.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Relab.ResultsMeasurementsFiles rmf WITH(NOLOCK) ON rmf.ResultMeasurementID=rm.ID
		LEFT OUTER JOIN #parameters p WITH(NOLOCK) ON p.ResultMeasurementID=rm.ID
	WHERE ResultID=@ResultID AND ((@IncludeArchived = 0 AND rm.Archived=@FalseBit) OR (@IncludeArchived=1)) AND ((@OnlyFails = 1 AND PassFail=@FalseBit) OR (@OnlyFails = 0))
	ORDER BY CASE WHEN @IncludeArchived = 1 THEN ISNULL(ISNULL(lt.[Values], ltsf.[Values]), ltmf.[Values]) ELSE CONVERT(VARCHAR, rm.ID) END, rm.ReTestNum ASC

	DROP TABLE #parameters
	SET NOCOUNT OFF
END
GO
GRANT EXECUTE ON [Relab].[remispResultMeasurements] TO Remi
GO
CREATE TABLE [Relab].[ResultsMeasurementsAudit](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ResultMeasurementID] [int] NOT NULL,
	[PassFail] [bit] NULL,
	[Comment] [nvarchar](400) NULL,
	[LastUser] [nvarchar](255) NULL,
	[DateEntered] [datetime] NULL,
 CONSTRAINT [PK_ResultsMeasurementsAudit] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [Relab].[ResultsMeasurementsAudit]  WITH CHECK ADD  CONSTRAINT [FK_ResultsMeasurementsAudit_ResultsMeasurements] FOREIGN KEY([ResultMeasurementID])
REFERENCES [Relab].[ResultsMeasurements] ([ID])
GO

ALTER TABLE [Relab].[ResultsMeasurementsAudit] CHECK CONSTRAINT [FK_ResultsMeasurementsAudit_ResultsMeasurements]
GO

ALTER TABLE [Relab].[ResultsMeasurementsAudit] ADD  DEFAULT (getdate()) FOR [DateEntered]
GO
alter table [Relab].[ResultsMeasurements] add LastUser NVARCHAR(255) NULL
go
CREATE TRIGGER [Relab].[ResultsMeasurementsAuditUpdate]
   ON  [Relab].[ResultsMeasurements]
    after update
AS 
BEGIN
	SET NOCOUNT ON;
 
	Declare @action char(1)
	DECLARE @count INT

	If Exists(Select * From Inserted) and Exists(Select * From Deleted) --Update, both tables referenced
	begin
		Set @action= 'U'
	end
	else
	begin
		if not Exists(Select * From Inserted) and not Exists(Select * From Deleted)--nothing changed, get out of here
		Begin
			RETURN
		end
	end

	--Only inserts records into the Audit table if the row was either updated or inserted and values actually changed.
	select @count= count(*) from
	(
	   select PassFail, Comment, LastUser from Inserted
	   except
	   select PassFail, Comment, LastUser from Deleted
	) a

	if ((@count) >0)
	begin
		insert into Relab.ResultsMeasurementsAudit (ResultMeasurementID, PassFail, Comment, LastUser)
		Select ID, PassFail, Comment, LastUser
		FROM deleted
	END
END
go
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
GRANT EXECUTE ON [Relab].[remispOverallResultsSummary] TO Remi
GO
alter table Batches Add ExecutiveSummary NVARCHAR(4000) NULL
go
alter table BatchesAudit Add ExecutiveSummary NVARCHAR(4000) NULL

go
rollback tran