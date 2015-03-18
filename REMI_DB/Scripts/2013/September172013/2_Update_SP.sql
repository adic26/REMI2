/*
Run this script on:

        sql51ykf\ha6.remi    -  This database will be modified

to synchronize it with:

        SQLQA10YKF\HAQA1.RemiQA

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 9/17/2013 8:50:00 AM

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
PRINT N'Altering [dbo].[remispBatchesSelectActiveBatchesForProductGroup]'
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectActiveBatchesForProductGroup]
	@ProductID INT = null,
	@AccessoryGroupID INT = null,
	@RecordCount int = null OUTPUT,
	@GetAllBatches int = 0
AS
	IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (SELECT COUNT(*) FROM Batches WITH(NOLOCK) WHERE 		
		(Batches.BatchStatus NOT IN(5,7) or @GetAllBatches =1)
		AND productID = @ProductID AND (AccessoryGroupID=@AccessoryGroupID or @AccessoryGroupID is null))
		RETURN
	END
	
	SELECT ROW_NUMBER() OVER (ORDER BY b.ID) AS Row, BatchStatus, b.Comment, b.ConcurrencyID, b.ID, j.JobName,
		b.LastUser, Priority, p.ProductGroupName, l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, productid, QRANumber, RequestPurpose,
		l3.[Values] As TestCenterLocation,TestStageName, RFBands, TestStageCompletionStatus, (select count(*) from testunits WITH(NOLOCK) where testunits.batchid = b.id) AS TestUNitCount,
		RQID As ReqID,
		(CASE WHEN WILocation IS NULL THEN NULL ELSE WILocation END) AS jobWILocation,
		((select count(*) from testunits WITH(NOLOCK) where testunits.batchid = b.id) -
			(select COUNT(*) 
			from TestUnits as tu WITH(NOLOCK)
			INNER JOIN DeviceTrackingLog as dtl WITH(NOLOCK) ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			where dtl.OutTime IS null and tu.BatchID = b.ID)
		) as HasUnitsToReturnToRequestor,
		(select AssignedTo 
		from TaskAssignments as ta WITH(NOLOCK)
			--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
			INNER JOIN TestStages ts WITH(NOLOCK) ON ta.TaskID = ts.ID AND ts.TestStageName=b.TestStageName 
			--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
			INNER JOIN Jobs j WITH(NOLOCK) ON j.ID = ts.JobID AND j.JobName = j.JobName
		where ta.BatchID = b.ID and ta.Active=1  ) as ActiveTaskAssignee, CONVERT(BIT,0) AS HasBatchSpecificExceptions,
		ProductTypeID,AccessoryGroupID, TestCenterLocationID
	FROM Batches as b WITH(NOLOCK)
		inner join Products p WITH(NOLOCK) on b.ProductID=p.id
		LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
		LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
		LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID  
		LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.Type='TestCenter' AND b.TestCenterLocationID=l3.LookupID  
	WHERE (b.BatchStatus NOT IN(5,7) or @GetAllBatches =1) AND p.ID = @ProductID and (AccessoryGroupID = @AccessoryGroupID or @AccessoryGroupID is null)
	RETURN
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesSelectChamberBatches]'
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectChamberBatches]
/*	'===============================================================
	'   NAME:                	remispBatchesSelectDailyList
	'   DATE CREATED:       	20 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retreives the batches in chamber
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/

	@StartRowIndex int = -1,
	@MaximumRows int = -1,
	@TestCentreLocation Int =null,
	@RecordCount int = NULL OUTPUT,
	@sortExpression varchar(100) = null,
	@direction varchar(100) = 'asc',
	@ByPassProductCheck INT = 0,
	@UserID int
	AS
SELECT BatchesRows.Row, BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,
	BatchesRows.JobName,BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,batchesrows.ProductType,batchesrows.AccessoryGroupName,
	batchesrows.ProductID,batchesrows.QRANumber,
	BatchesRows.RequestPurpose,BatchesRows.TestCenterLocation,BatchesRows.TestStageName, 
	batchesrows.RFBands, batchesrows.TestStageCompletionStatus,testunitcount,
	(CASE WHEN batchesrows.WILocation IS NULL THEN NULL ELSE batchesrows.WILocation END) AS jobWILocation,
	(testUnitCount -
		(select COUNT(*) 
			  from TestUnits as tu WITH(NOLOCK)
			  INNER JOIN DeviceTrackingLog as dtl WITH(NOLOCK) ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			  where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
	) as HasUnitsToReturnToRequestor,
	(select AssignedTo 
	from TaskAssignments as ta WITH(NOLOCK)
		--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
		INNER JOIN TestStages ts WITH(NOLOCK) ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
		--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
		INNER JOIN Jobs j WITH(NOLOCK) ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
	where ta.BatchID = BatchesRows.ID and ta.Active=1  ) as ActiveTaskAssignee, CONVERT(BIT,0) AS HasBatchSpecificExceptions,
	batchesrows.ProductTypeID,batchesrows.AccessoryGroupID,batchesrows.RQID As ReqID, batchesrows.TestCenterLocationID
	FROM     
	(
		SELECT ROW_NUMBER() OVER 
			(ORDER BY 
				case when @sortExpression='qra' and @direction='asc' then qranumber end,
				case when @sortExpression='qra' and @direction='desc' then qranumber end desc,
				case when @sortExpression='teststage' and @direction='asc' then b.teststagename end,
				case when @sortExpression='teststage' and @direction='desc' then b.teststagename end desc,
				case when @sortExpression='purpose' and @direction='asc' then requestpurpose end,
				case when @sortExpression='purpose' and @direction='desc' then requestpurpose end desc,
				case when @sortExpression='job' and @direction='asc' then jobname end,
				case when @sortExpression='job' and @direction='desc' then jobname end desc,
				case when @sortExpression='productgroup' and @direction='asc' then productgroupname end asc,
				case when @sortExpression='productgroup' and @direction='desc' then productgroupname end desc,
				case when @sortExpression='priority' and @direction='asc' then Priority end asc,
				case when @sortExpression='priority' and @direction='desc' then Priority end desc,
				case when @sortExpression='batchstatus' and @direction='asc' then batchstatus end,
				case when @sortExpression='batchstatus' and @direction='desc' then batchstatus end desc,
				case when @sortExpression is null then Priority end desc
			) AS Row, 
			ID, 
			QRANumber, 
			Comment,
			RequestPurpose, 
			Priority,
			TestStageName, 
			BatchStatus, 
			ProductGroupName, 
			ProductType,
			AccessoryGroupName,
			ProductTypeID,
			AccessoryGroupID,
			ProductID,
			JobName, 
			TestCenterLocationID,
			TestCenterLocation,
			LastUser, 
			ConcurrencyID,
			b.RFBands,
			b.TestStageCompletionStatus,
			(select count(*) from testunits WITH(NOLOCK) where testunits.batchid = b.id) as testUnitCount,
			b.WILocation,b.RQID
		FROM 
		(
			SELECT DISTINCT b.ID, 
				b.QRANumber, 
				b.Comment,
				b.RequestPurpose, 
				b.Priority,
				b.TestStageName, 
				b.BatchStatus, 
				p.ProductGroupName, 
				b.ProductTypeID,
				b.AccessoryGroupID,
				l.[Values] AS ProductType,
				l2.[Values] As AccessoryGroupName,
				p.ID As ProductID,
				b.JobName, 
				b.LastUser, 
				b.TestCenterLocationID,
				l3.[Values] As TestCenterLocation,
				b.ConcurrencyID,
				(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
				b.TestStageCompletionStatus, j.WILocation,b.RQID
			FROM Batches AS b WITH(NOLOCK)
				LEFT OUTER JOIN Jobs as j WITH(NOLOCK) on b.jobname = j.JobName 
				inner join TestStages as ts WITH(NOLOCK) on j.ID = ts.JobID
				inner join Tests as t WITH(NOLOCK) on ts.TestID = t.ID
				inner join DeviceTrackingLog AS dtl WITH(NOLOCK) 
				INNER JOIN TrackingLocations AS tl WITH(NOLOCK) ON dtl.TrackingLocationID = tl.ID
				INNER JOIN TrackingLocationTypes as tlt WITH(NOLOCK) on tl.TrackingLocationTypeID = tlt.id 
				inner join TestUnits AS tu WITH(NOLOCK) ON dtl.TestUnitID = tu.ID on tu.CurrentTestName = t.TestName and b.id = tu.batchid  --batches where there's a tracking log
				INNER JOIN Products p WITH(NOLOCK) ON b.ProductID=p.id
				LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID  
				LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.Type='TestCenter' AND b.TestCenterLocationID=l3.LookupID  
			WHERE (b.TestCenterLocationID = @TestCentreLocation or @TestCentreLocation is null) and j.TechnicalOperationsTest = 1 and j.MechanicalTest=0 and  tlt.TrackingLocationFunction= 4  and t.ResultBasedOntime = 1 AND dtl.OutTime IS NULL AND dtl.OutUser IS NULL
			AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
		)as b
	) as batchesrows
 	WHERE ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) OR @startRowIndex = -1 OR @maximumRows = -1) 
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Relab].[remispResultsFailureAnalysis]'
GO
ALTER PROCEDURE [Relab].[remispResultsFailureAnalysis] @TestID INT, @BatchID INT
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @FalseBit BIT
	DECLARE @RecordID INT
	DECLARE @BatchUnitNumber INT
	DECLARE @TestUnitID INT
	DECLARE @RowID INT
	DECLARE @MeasurementID INT
	DECLARE @TestStageID INT
	DECLARE @COUNT INT
	DECLARE @RowCount INT
	DECLARE @ResultMeasurementID INT
	DECLARE @Parameters NVARCHAR(MAX)
	DECLARE @SQL NVARCHAR(MAX)
	DECLARE @SQL2 NVARCHAR(MAX)
	DECLARE @Row NVARCHAR(MAX)
	CREATE TABLE #FailureAnalysis (RowID INT IDENTITY(1,1), MeasurementID INT, Measurement NVARCHAR(150), [Parameters] NVARCHAR(MAX), TestStageID INT, TestStageName NVARCHAR(400), ResultMeasurementID INT)
	SET @FalseBit = CONVERT(BIT, 0)

	SELECT ROW_NUMBER() OVER (ORDER BY tu.ID) AS RowID, tu.BatchUnitNumber, tu.ID
	INTO #units
	FROM TestUnits tu WITH(NOLOCK)
	WHERE BatchID=@BatchID

	INSERT INTO #FailureAnalysis (MeasurementID, Measurement, [Parameters], TestStageID, TestStageName)
	SELECT DISTINCT lm.LookupID As MeasurementID, lm.[Values] As Measurement, ISNULL(Relab.ResultsParametersComma(rm.ID), '') AS [Parameters], ts.ID, ts.TestStageName 
	FROM Relab.Results r WITH(NOLOCK)
		INNER JOIN Relab.ResultsMeasurements rm WITH(NOLOCK) ON rm.ResultID=r.ID AND rm.PassFail=0 AND rm.Archived=0
		INNER JOIN Lookups lm WITH(NOLOCK) ON lm.LookupID=rm.MeasurementTypeID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID=r.TestUnitID
		INNER JOIN TestStages ts WITH(NOLOCK) ON ts.ID=r.TestStageID
	WHERE r.TestID=@TestID AND tu.BatchID=@BatchID AND r.PassFail=@FalseBit
	ORDER BY Measurement, [Parameters]
	
	UPDATE #FailureAnalysis SET ResultMeasurementID = (
				SELECT TOP 1 rm.ID 
				FROM Relab.Results r WITH(NOLOCK) 
					INNER JOIN Relab.ResultsMeasurements rm WITH(NOLOCK) ON rm.ResultID=r.ID AND rm.PassFail=0 AND rm.Archived=0
					INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID=r.TestUnitID
				WHERE #FailureAnalysis.TestStageID=r.TestStageID AND #FailureAnalysis.MeasurementID=rm.MeasurementTypeID
					AND r.TestID=@TestID AND tu.BatchID=@BatchID AND r.PassFail=@FalseBit
				)

	INSERT INTO #FailureAnalysis (MeasurementID, Measurement, [Parameters], TestStageID, TestStageName)
	SELECT 0, 'Total', '', 0, ''	

	SELECT @RowID = MIN(RowID) FROM #units WITH(NOLOCK)

	WHILE (@RowID IS NOT NULL)
	BEGIN
		SELECT @BatchUnitNumber=BatchUnitNumber, @TestUnitID = ID FROM #units WHERE RowID=@RowID
		SET @COUNT = 0
	
		EXECUTE ('ALTER TABLE #FailureAnalysis ADD [' + @BatchUnitNumber + '] INT NULL ')
	
		SELECT @RecordID = MIN(RowID) FROM #FailureAnalysis WITH(NOLOCK) WHERE Measurement <> 'Total'
	
		WHILE (@RecordID IS NOT NULL)
		BEGIN
			SET @ResultMeasurementID = 0
			SET @SQL = '' 
			SET @SQL2 = ''
			SELECT @MeasurementID = MeasurementID, @TestStageID = TestStageID, @Parameters= [Parameters] FROM #FailureAnalysis WITH(NOLOCK) WHERE RowID=@RecordID
	
			SELECT @COUNT = COUNT(DISTINCT r.ID)
			FROM Relab.Results r WITH(NOLOCK)
				INNER JOIN Relab.ResultsMeasurements rm WITH(NOLOCK) ON rm.ResultID=r.ID AND rm.PassFail=@FalseBit AND rm.Archived=@FalseBit
			WHERE r.TestID=@TestID AND r.TestUnitID=@TestUnitID AND r.PassFail=@FalseBit
				AND r.TestStageID=@TestStageID AND rm.MeasurementTypeID=@MeasurementID AND ISNULL(Relab.ResultsParametersComma(rm.ID), '') = @Parameters
				
			SET @SQL = 'UPDATE #FailureAnalysis SET [' + CONVERT(VARCHAR, @BatchUnitNumber) + '] = ' + CONVERT(VARCHAR, ISNULL(@Count, 0)) + ' WHERE TestStageID = ' + CONVERT(VARCHAR, @TestStageID) + ' AND MeasurementID = ' + CONVERT(VARCHAR, @MeasurementID) + ' AND LTRIM(RTRIM(Parameters)) = '
			SET @SQL2 = ' LTRIM(RTRIM(''' + CONVERT(NVARCHAR(MAX), @Parameters) + '''))'
			EXECUTE (@SQL + @SQL2)			
			
			SELECT @RecordID = MIN(RowID) FROM #FailureAnalysis WITH(NOLOCK) WHERE RowID > @RecordID AND Measurement <> 'Total'
		END
	
		EXECUTE('UPDATE #FailureAnalysis SET [' + @BatchUnitNumber + '] = result.summary 
				FROM (SELECT SUM([' + @BatchUnitNumber + ']) AS Summary FROM #FailureAnalysis WHERE Measurement <> ''Total'' ) result WHERE Measurement=''Total''')
		
		SELECT @RowID = MIN(RowID) FROM #units WHERE RowID > @RowID
	END

	SET @Row = (SELECT '[' + Cast(BatchUnitNumber AS VARCHAR(MAX)) + '] + ' FROM #units FOR XML PATH(''))
	SET @Row = SUBSTRING(@Row, 0, LEN(@Row)-1)

	SET @SQL = 'SELECT Measurement, [Parameters], TestStageName, ResultMeasurementID, TestStageID, ' + REPLACE(@Row, '+',',') + ', SUM(' + @Row + ') AS Total FROM #FailureAnalysis GROUP BY Measurement, [Parameters], TestStageName, ResultMeasurementID, TestStageID, ' + REPLACE(@Row, '+',',') + ' ORDER BY Measurement, [Parameters], TestStageName '

	EXECUTE (@SQL)

	DROP TABLE #FailureAnalysis
	DROP TABLE #units

	SET NOCOUNT OFF
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesSelectBatchesForReport]'
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectBatchesForReport]
	@TestCentreLocation INT =null,
	@RecordCount int = NULL OUTPUT,
	@sortExpression varchar(100) = null,
	@direction varchar(100) = 'asc',
	@ByPassProductCheck INT = 0,
	@UserID int
AS
BEGIN
	SELECT ROW_NUMBER() OVER 
		(
			ORDER BY 
				case when @sortExpression='qra' and @direction='asc' then qranumber end,
				case when @sortExpression='qra' and @direction='desc' then qranumber end desc,
				case when @sortExpression='teststage' and @direction='asc' then b.teststagename end,
				case when @sortExpression='teststage' and @direction='desc' then b.teststagename end desc,
				case when @sortExpression='purpose' and @direction='asc' then requestpurpose end,
				case when @sortExpression='purpose' and @direction='desc' then requestpurpose end desc,
				case when @sortExpression='job' and @direction='asc' then jobname end,
				case when @sortExpression='job' and @direction='desc' then jobname end desc,
				case when @sortExpression='productgroup' and @direction='asc' then productgroupname end asc,
				case when @sortExpression='productgroup' and @direction='desc' then productgroupname end desc,
				case when @sortExpression='priority' and @direction='asc' then Priority end asc,
				case when @sortExpression='priority' and @direction='desc' then Priority end desc,
				case when @sortExpression='batchstatus' and @direction='asc' then batchstatus end,
				case when @sortExpression='batchstatus' and @direction='desc' then batchstatus end desc,
				case when @sortExpression is null then Priority end desc		
		) AS Row, 
		BatchStatus,Comment,ConcurrencyID,ID,
		JobName,LastUser,Priority,ProductGroupName,ProductTypeID,AccessoryGroupID,
		ProductID,b.QRANumber,RQID As ReqID,
		RequestPurpose,TestCenterLocation,TestStageName, 
		RFBands, TestStageCompletionStatus, (select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
		(CASE WHEN WILocation IS NULL THEN NULL ELSE WILocation END) AS jobWILocation,
		(
			(select count(*) from testunits WITH(NOLOCK) where testunits.batchid = b.id) -
			(select COUNT(*) 
			from TestUnits as tu WITH(NOLOCK)
				INNER JOIN DeviceTrackingLog as dtl WITH(NOLOCK) ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			where dtl.OutTime IS null and tu.BatchID = b.ID)
		) as HasUnitsToReturnToRequestor,
		(select AssignedTo 
		from TaskAssignments as ta WITH(NOLOCK)
			--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
			INNER JOIN TestStages ts WITH(NOLOCK) ON ta.TaskID = ts.ID AND ts.TestStageName=TestStageName 
			--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
			INNER JOIN Jobs j WITH(NOLOCK) ON j.ID = ts.JobID AND j.JobName = JobName
		where ta.BatchID = b.ID and ta.Active=1  ) as ActiveTaskAssignee, CONVERT(BIT,0) AS HasBatchSpecificExceptions,
		ProductType, AccessoryGroupName, TestCenterLocationID
	FROM
		(
			SELECT DISTINCT b.ID, 
				b.QRANumber, 
				b.Comment,
				b.RequestPurpose, 
				b.Priority,
				b.TestStageName, 
				b.BatchStatus, 
				p.ProductGroupName, 
				b.ProductTypeID,
				b.AccessoryGroupID,
				l.[Values] As ProductType,
				l2.[Values] As AccessoryGroupName,
				l3.[Values] As TestCenterLocation,
				p.ID As ProductID,
				b.JobName, 
				b.LastUser, 
				b.TestCenterLocationID,
				b.ConcurrencyID,
				(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
				b.TestStageCompletionStatus,
				j.WILocation,
				b.rqID
			FROM Batches AS b WITH(NOLOCK)
				inner join Products p WITH(NOLOCK) on p.ID=b.ProductID
				LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = b.JobName
				LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID  
				LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.Type='TestCenter' AND b.TestCenterLocationID=l3.LookupID  
				INNER JOIN TestStages ts WITH(NOLOCK) ON ts.TestStageName=b.TestStageName
			WHERE (b.TestCenterLocationID = @TestCentreLocation or @TestCentreLocation is null) and (b.BatchStatus != 5)
				AND ts.TestStageType=4	
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
		)as b
	order by b.QRANumber desc
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispDeviceTrackingLogDeleteSingleItem]'
GO
ALTER PROCEDURE [dbo].[remispDeviceTrackingLogDeleteSingleItem] @ID int
AS
BEGIN
	DELETE FROM DeviceTrackingLog WHERE ID = @ID
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesSelectListAtTrackingLocation]'
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectListAtTrackingLocation]
	@TrackingLocationID int,
	@StartRowIndex int = -1,
	@MaximumRows int = -1,
	@RecordCount int = NULL OUTPUT,
	@sortExpression varchar(100) = null,
	@direction varchar(100) = 'asc'
AS
IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (select  COUNT(*) from (select DISTINCT b.id	FROM  Batches AS b WITH(NOLOCK) INNER JOIN
                      DeviceTrackingLog AS dtl WITH(NOLOCK) INNER JOIN
                      TrackingLocations AS tl WITH(NOLOCK) ON dtl.TrackingLocationID = tl.ID INNER JOIN
                      TestUnits AS tu WITH(NOLOCK) ON dtl.TestUnitID = tu.ID ON b.id = tu.BatchID --batches where there's a tracking log
				WHERE  tl.id = @TrackingLocationID AND dtl.OutTime IS NULL AND dtl.OutUser IS NULL)as records)  --and the tracking log has not been 'scanned' out
		RETURN
	END

SELECT BatchesRows.Row, BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,
				 BatchesRows.JobName,BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,BatchesRows.QRANumber,
				 BatchesRows.RequestPurpose,BatchesRows.TestCenterLocation,BatchesRows.TestStageName,batchesrows.ProductType, batchesrows.AccessoryGroupName,Batchesrows.ProductID,
				 batchesrows.RFBands, batchesrows.TestStageCompletionStatus,testunitcount,
				 (testunitcount -
			   (select COUNT(*) 
			  from TestUnits as tu WITH(NOLOCK)
			  INNER JOIN DeviceTrackingLog as dtl WITH(NOLOCK) ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			  where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
			  ) as HasUnitsToReturnToRequestor,
(CASE WHEN BatchesRows.WILocation IS NULL THEN NULL ELSE BatchesRows.WILocation END) AS jobWILocation,BatchesRows.TestCenterLocationID,
	 (select AssignedTo 
	from TaskAssignments as ta WITH(NOLOCK)
		--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
		INNER JOIN TestStages ts WITH(NOLOCK) ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
		--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
		INNER JOIN Jobs j WITH(NOLOCK) ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
	where ta.BatchID = BatchesRows.ID and ta.Active=1  ) as ActiveTaskAssignee, CONVERT(BIT,0) AS HasBatchSpecificExceptions,
	batchesrows.AccessoryGroupID,batchesrows.ProductTypeID,BatchesRows.RQID As ReqID
	FROM     
		(SELECT ROW_NUMBER() OVER (ORDER BY 
case when @sortExpression='qra' and @direction='asc' then qranumber end,
case when @sortExpression='qra' and @direction='desc' then qranumber end desc,
case when @sortExpression='teststage' and @direction='asc' then b.teststagename end,
case when @sortExpression='teststage' and @direction='desc' then b.teststagename end desc,
case when @sortExpression='purpose' and @direction='asc' then requestpurpose end,
case when @sortExpression='purpose' and @direction='desc' then requestpurpose end desc,
case when @sortExpression='job' and @direction='asc' then jobname end,
case when @sortExpression='job' and @direction='desc' then jobname end desc,
case when @sortExpression='productgroup' and @direction='asc' then productgroupname end asc,
case when @sortExpression='productgroup' and @direction='desc' then productgroupname end desc,
case when @sortExpression='priority' and @direction='asc' then Priority end asc,
case when @sortExpression='priority' and @direction='desc' then Priority end desc,
case when @sortExpression='batchstatus' and @direction='asc' then batchstatus end,
case when @sortExpression='batchstatus' and @direction='desc' then batchstatus end desc,
case when @sortExpression is null then Priority end desc
		) AS Row, 
		           ID, 
                      QRANumber, 
                      Comment,
                      RequestPurpose, 
                      Priority,
                      TestStageName, 
                      BatchStatus, 
                      ProductGroupName, 
					  ProductType,
					  AccessoryGroupName,
					  ProductTypeID,
					  AccessoryGroupID,
					  ProductID,
                      JobName, 
					  TestCenterLocationID,
                      TestCenterLocation,
                      LastUser, 
                      ConcurrencyID,
                      b.RFBands,
                      b.TestStageCompletionStatus,
				 (select count(*) from testunits WITH(NOLOCK) where testunits.batchid = b.id) as testUnitCount,
				 b.WILocation,
				 b.RQID
                      from
				(SELECT DISTINCT 
                      b.ID, 
                      b.QRANumber, 
                      b.Comment,
                      b.RequestPurpose, 
                      b.Priority,
                      b.TestStageName, 
                      b.BatchStatus, 
                      p.ProductGroupName, 
					  b.ProductTypeID,
					  b.AccessoryGroupID,
					  l.[Values] As ProductType,
					  l2.[Values] As AccessoryGroupName,
					  l3.[Values] As TestCenterLocation,
					  p.ID As ProductID,
                      b.JobName, 
                      b.LastUser, 
                      b.TestCenterLocationID,
                      b.ConcurrencyID,
                      (case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
                      b.TestStageCompletionStatus,
                      j.WILocation,
					  b.RQID
				FROM Batches AS b 
                      INNER JOIN DeviceTrackingLog AS dtl WITH(NOLOCK) 
                      INNER JOIN TrackingLocations AS tl WITH(NOLOCK) ON dtl.TrackingLocationID = tl.ID 
                      INNER JOIN TestUnits AS tu WITH(NOLOCK) ON dtl.TestUnitID = tu.ID ON b.id = tu.batchid --batches where there's a tracking log
                      inner join Products p WITH(NOLOCK) on p.ID=b.ProductID
					  LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = b.JobName
					  LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
					LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID 
					LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.Type='TestCenter' AND b.TestCenterLocationID=l3.LookupID   
WHERE     tl.id = @TrackingLocationId AND dtl.OutTime IS NULL AND dtl.OutUser IS NULL)as b) as batchesrows
	WHERE
	 ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) 
			OR @startRowIndex = -1 OR @maximumRows = -1) 
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispEnvironmentalReport]'
GO
ALTER procedure [dbo].[remispEnvironmentalReport]
	@startDate datetime,
	@enddate datetime,
	@reportBasedOn int = 1,
	@testLocationID INT,
	@ByPassProductCheck INT,
	@UserID INT
AS
SET NOCOUNT ON

IF @testLocationID = 0
BEGIN
	SET @testLocationID = NULL
END

DECLARE @TrueBit BIT
SET @TrueBit = CONVERT(BIT, 1)

SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Completed Testing], p.ProductGroupName 
FROM Batches b WITH(NOLOCK)
	INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
	INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus = 8 and ba.inserttime between @startdate and @enddate
	INNER JOIN BatchesAudit ba2 WITH(NOLOCK) ON b.ID = ba2.BatchID AND ba2.BatchStatus <> 8 and ba2.inserttime between @startdate and @enddate
	INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
WHERE (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
	AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
GROUP BY p.productgroupname
ORDER BY p.productgroupname

SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# in Chamber], p.productgroupname 
FROM DeviceTrackingLog dtl WITH(NOLOCK)
	INNER JOIN TestUnits tu WITH(NOLOCK) ON dtl.TestUnitID = tu.ID
	INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
	INNER JOIN TrackingLocations tl WITH(NOLOCK) ON dtl.TrackingLocationID = tl.id
	INNER JOIN TrackingLocationTypes tlt WITH(NOLOCK) ON tl.TrackingLocationTypeID = tlt.ID AND tlt.TrackingLocationFunction = 4 --4 means chamber type device (environmentstressing)
	INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
WHERE dtl.InTime BETWEEN @startdate AND @enddate
	and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
	AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
GROUP BY p.productgroupname
ORDER BY p.productgroupname

SELECT count(tr.ID) as [# Units in FA], p.productgroupname 
FROM (
		SELECT tra.TestRecordId 
		FROM TestRecordsaudit tra WITH(NOLOCK)
		WHERE tra.Action IN ('I','U') AND tra.Status IN (3, 4) and tra.InsertTime BETWEEN @startdate AND @enddate--FQRaised and FARequired
		GROUP BY TestRecordId
	) as xer
	INNER JOIN TestRecords tr WITH(NOLOCK) ON tr.ID= xer.TestRecordId
	INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
	INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
	INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
WHERE (b.TestCenterLocationID = @testLocationID or @testLocationID is null)
	AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID))) 
GROUP BY ProductGroupName
ORDER BY p.productgroupname

SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Worked On Parametric], p.productgroupname
FROM Batches b WITH(NOLOCK)
	INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
	INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
	INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
	INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
	INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.TechnicalOperationsTest = @TrueBit
	INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
WHERE ba.inserttime between @startdate and @enddate and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
	AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
GROUP BY p.productgroupname
ORDER BY p.productgroupname

SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Completed Parametric], p.productgroupname
FROM Batches b WITH(NOLOCK)
	INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus IN (5, 8)--Complete or TestingComplete
	INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
	INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
	INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
	INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.TechnicalOperationsTest = @TrueBit
	INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
WHERE ba.inserttime between @startdate and @enddate and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
	AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
GROUP BY p.productgroupname
ORDER BY p.productgroupname

SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Worked On Drop/Tumble], p.productgroupname
FROM Batches b WITH(NOLOCK)
	INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
	INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
	INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = @TrueBit
	INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
	INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
	INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
WHERE ba.inserttime between @startdate and @enddate
	and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
	AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
GROUP BY p.productgroupname
ORDER BY p.productgroupname

SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Completed Drop/Tumble], p.productgroupname
FROM Batches b WITH(NOLOCK)
	INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus IN (5, 8)--Complete or TestingComplete
	INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
	INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = @TrueBit
	INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
	INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
	INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
WHERE ba.inserttime between @startdate and @enddate
	and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
	AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
GROUP BY p.productgroupname
ORDER BY p.productgroupname

SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Worked On Accessories], p.productgroupname
FROM Batches b WITH(NOLOCK)
	INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
	INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
	INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
	INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
	INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
	INNER JOIN Lookups l WITH(NOLOCK) ON b.ProductTypeID = l.LookupID AND l.Type='ProductType'
WHERE ba.inserttime between @startdate and @enddate AND l.[Values] = 'Accessory'
	and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
	AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
GROUP BY p.productgroupname
ORDER BY p.productgroupname

SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Worked On Component], p.productgroupname
FROM Batches b WITH(NOLOCK)
	INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
	INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
	INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
	INNER JOIN Lookups l WITH(NOLOCK) ON b.ProductTypeID = l.LookupID AND l.Type='ProductType'
WHERE ba.inserttime between @startdate and @enddate AND l.[Values] = 'Component'
	and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
	AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
GROUP BY p.productgroupname
ORDER BY p.productgroupname

SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Worked On Handheld], p.productgroupname
FROM Batches b WITH(NOLOCK)
	INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
	INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
	INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
	INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
	INNER JOIN Products p WITH(NOLOCK) ON p.ID=b.ProductID
	INNER JOIN Lookups l WITH(NOLOCK) ON b.ProductTypeID = l.LookupID AND l.Type='ProductType'
WHERE ba.inserttime between @startdate and @enddate	AND l.[Values] = 'Handheld'
	and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
	AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
GROUP BY p.productgroupname
ORDER BY p.productgroupname

SET NOCOUNT OFF
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesInsertUpdateSingleItem]'
GO
ALTER PROCEDURE [dbo].[remispBatchesInsertUpdateSingleItem]
/*	'===============================================================
	'   NAME:                	remispBatchesInsertUpdateSingleItem
	'   DATE CREATED:       	9 April 2009
	'   CREATED BY:          	Darragh O Riordan
	'   FUNCTION:            	Creates or updates an item in a table: 
	'===============================================================*/
	@ID int OUTPUT,
	@QRANumber nvarchar(11),
	@Priority int, 
	@BatchStatus int, 
	@JobName nvarchar(400),
	@TestStageName nvarchar(255)=null,
	@ProductGroupName nvarchar(800),
	@ProductType nvarchar(800),
	@AccessoryGroupName nvarchar(800) = null,
	@Comment nvarchar(1000) = null,
	@TestCenterLocation nvarchar(400),
	@RequestPurpose int,
	@LastUser nvarchar(255),
	@ConcurrencyID rowversion OUTPUT,
	@rfBands nvarchar(400) = null,
	@testStageCompletionStatus int = null,
	@requestor nvarchar(500) = null,
	@unitsToBeReturnedToRequestor bit = null,
	@expectedSampleSize int = null,
	@relabJobID int = null,
	@reportApprovedDate datetime = null,
	@reportRequiredBy datetime = null,
	@rqID int = null,
	@partName nvarchar(500) = null,
	@assemblyNumber nvarchar(500) = null,
	@assemblyRevision nvarchar(500) = null,
	@trsStatus nvarchar(500) = null,
	@cprNumber nvarchar(500) = null,
	@hwRevision nvarchar(500) = null,
	@pmNotes nvarchar(500) = null
	AS
	DECLARE @ProductID INT
	DECLARE @ProductTypeID INT
	DECLARE @AccessoryGroupID INT
	DECLARE @TestCenterLocationID INT
	DECLARE @ReturnValue int
	DECLARE @maxid int
	
	IF NOT EXISTS (SELECT 1 FROM Products WHERE LTRIM(RTRIM(ProductGroupName))= LTRIM(RTRIM(@ProductGroupName)))
	BEGIn
		INSERT INTO Products (ProductGroupName) Values (LTRIM(RTRIM(@ProductGroupName)))
	END
	
	IF NOT EXISTS (SELECT 1 FROM Lookups WHERE Type='ProductType' AND LTRIM(RTRIM([Values])) = LTRIM(RTRIM(@ProductType)))
	BEGIN
		SELECT @maxid = MAX(LookupID)+1 FROM Lookups
		INSERT INTO Lookups (LookupID, Type, [Values]) Values (@maxid, 'ProductType', LTRIM(RTRIM(@ProductType)))
	END
	
	IF LTRIM(RTRIM(@AccessoryGroupName)) <> '' AND NOT EXISTS (SELECT 1 FROM Lookups WHERE Type='AccessoryType' AND LTRIM(RTRIM([Values])) = LTRIM(RTRIM(@AccessoryGroupName)))
	BEGIN
		SELECT @maxid = MAX(LookupID)+1 FROM Lookups
		INSERT INTO Lookups (LookupID, Type, [Values]) Values (@maxid, 'AccessoryType', LTRIM(RTRIM(@AccessoryGroupName)))
	END
	
	IF LTRIM(RTRIM(@TestCenterLocation)) <> '' AND NOT EXISTS (SELECT 1 FROM Lookups WHERE Type='TestCenter' AND LTRIM(RTRIM([Values])) = LTRIM(RTRIM(@TestCenterLocation)))
	BEGIN
		SELECT @maxid = MAX(LookupID)+1 FROM Lookups
		INSERT INTO Lookups (LookupID, Type, [Values]) Values (@maxid, 'TestCenter', LTRIM(RTRIM(@TestCenterLocation)))
	END

	SELECT @ProductID = ID FROM Products WITH(NOLOCK) WHERE LTRIM(RTRIM(ProductGroupName))= LTRIM(RTRIM(@ProductGroupName))
	SELECT @ProductTypeID = LookupID FROM Lookups WITH(NOLOCK) WHERE Type='ProductType' AND LTRIM(RTRIM([Values]))= LTRIM(RTRIM(@ProductType))
	SELECT @AccessoryGroupID = LookupID FROM Lookups WITH(NOLOCK) WHERE Type='AccessoryType' AND LTRIM(RTRIM([Values]))= LTRIM(RTRIM(@AccessoryGroupName))
	SELECT @TestCenterLocationID = LookupID FROM Lookups WITH(NOLOCK) WHERE Type='TestCenter' AND LTRIM(RTRIM([Values]))= LTRIM(RTRIM(@TestCenterLocation))
	
	--set the rfbands from the productgroup if they are not given
	if @rfBands is null
	set @rfbands = (select RFBands from RFBands where RFBands.ProductGroupName = @ProductGroupName)
	
	IF (@ID IS NULL)
	BEGIN
		INSERT INTO Batches(
		QRANumber, 
		Priority, 
		BatchStatus, 
		JobName,
		TestStageName, 
		ProductTypeID,
		AccessoryGroupID,
		TestCenterLocationID,
		RequestPurpose,
		Comment,
		LastUser,
		rfbands,
		TestStageCompletionStatus,
		Requestor,
		unitsToBeReturnedToRequestor,
		expectedSampleSize,
		relabJobID,
		reportApprovedDate,
		reportRequiredBy,
		rqID,
		partName,
		assemblyNumber,
		assemblyRevision,
		trsStatus,
		cprNumber,
		hwRevision,
		pmNotes,
		ProductID ) 
		VALUES 
		(@QRANumber, 
		@Priority, 
		@BatchStatus, 
		@JobName,
		@TestStageName,
		@ProductTypeID,
		@AccessoryGroupID,
		@TestCenterLocationID,
		@RequestPurpose,
		@Comment,
		@LastUser,
		@rfBands,
		@testStageCompletionStatus,
		@Requestor,
		@unitsToBeReturnedToRequestor,
		@expectedSampleSize,
		@relabJobID,
		@reportApprovedDate,
		@reportRequiredBy,
		@rqID,
		@partName,
		@assemblyNumber,
		@assemblyRevision,
		@trsStatus,
		@cprNumber,
		@hwRevision,
		@pmNotes,
		@ProductID )

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE -- Exisiting Item
	BEGIN
		UPDATE Batches SET 
		QRANumber = @QRANumber, 
		Priority = @Priority, 
		Jobname = @Jobname, 
		TestStagename = @TestStagename, 
		BatchStatus = @BatchStatus, 
		ProductTypeID = @ProductTypeID,
		AccessoryGroupID = @AccessoryGroupID,
		TestCenterLocationID=@TestCenterLocationID,
		RequestPurpose=@RequestPurpose,
		Comment = @Comment, 
		LastUser = @LastUser,
		rfbands = @rfBands,
		Requestor = @Requestor,
		TestStageCompletionStatus = @testStageCompletionStatus,
		unitsToBeReturnedToRequestor=@unitsToBeReturnedToRequestor,
		expectedSampleSize=@expectedSampleSize,
		relabJobID=@relabJobID,
		reportApprovedDate=@reportApprovedDate,
		reportRequiredBy=@reportRequiredBy,
		rqID=@rqID,
		partName=@partName,
		assemblyNumber=@assemblyNumber,
		assemblyRevision=@assemblyRevision,
		trsStatus=@trsStatus,
		cprNumber=@cprNumber,
		hwRevision=@hwRevision,
		pmNotes=@pmNotes ,
		ProductID=@ProductID
		WHERE (ID = @ID) AND (ConcurrencyID = @ConcurrencyID)

		SELECT @ReturnValue = @ID
	END

	SET @ConcurrencyID = (SELECT ConcurrencyID FROM Batches WITH(NOLOCK) WHERE ID = @ReturnValue)
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
PRINT N'Altering [dbo].[remispBatchesSearch]'
GO
ALTER PROCEDURE [dbo].[remispBatchesSearch]
	@ByPassProductCheck INT = 0,
	@ExecutingUserID int,
	@Status int = null,
	@Priority int = null,
	@UserID int = null,
	@TrackingLocationID int = null,
	@TestStageID int = null,
	@TestID int = null,
	@ProductTypeID int = null,
	@ProductID int = null,
	@AccessoryGroupID int = null,
	@GeoLocationID INT = null,
	@JobName nvarchar(400) = null,
	@RequestReason int = null,
	@StartRowIndex int = null,
	@MaximumRows int = null,
	@BatchStart DateTime = NULL,
	@BatchEnd DateTime = NULL
AS
	DECLARE @TestName NVARCHAR(400)
	DECLARE @TestStageName NVARCHAR(400)
	
	SELECT @TestName = TestName FROM Tests WITH(NOLOCK) WHERE ID=@TestID 
	SELECT @TestStageName = TestStageName FROM TestStages WITH(NOLOCK) WHERE ID=@TestStageID 
		
	SELECT TOP 100 BatchesRows.row,BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,BatchesRows.JobName,
		BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroup As ProductGroupName,batchesrows.ProductType,batchesrows.AccessoryGroupName,batchesrows.ProductID, BatchesRows.QRANumber,BatchesRows.RequestPurpose,
		BatchesRows.TestCenterLocationID,BatchesRows.TestStageName,BatchesRows.RFBands, BatchesRows.TestStageCompletionStatus, testUnitCount, 
		(CASE WHEN BatchesRows.WILocation IS NULL THEN NULL ELSE BatchesRows.WILocation END) AS jobWILocation, batchesrows.RQID AS ReqID,
		(testunitcount -
			(select COUNT(*) 
			from TestUnits as tu WITH(NOLOCK)
			INNER JOIN DeviceTrackingLog as dtl WITH(NOLOCK) ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
		) as HasUnitsToReturnToRequestor,
		(select AssignedTo 
		from TaskAssignments as ta WITH(NOLOCK)
			--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
			INNER JOIN TestStages ts WITH(NOLOCK) ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
			--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
			INNER JOIN Jobs j WITH(NOLOCK) ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
		where ta.BatchID = BatchesRows.ID and ta.Active=1) as ActiveTaskAssignee,
		CONVERT(BIT,0) AS HasBatchSpecificExceptions, batchesrows.ProductTypeID,batchesrows.AccessoryGroupID, BatchesRows.CurrentTest, BatchesRows.CPRNumber, BatchesRows.RelabJobID, BatchesRows.TestCenterLocation
	FROM     
		(
			SELECT ROW_NUMBER() OVER (ORDER BY b.ID) AS Row, 
				b.BatchStatus,b.Comment,(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
				b.teststagecompletionstatus,b.ConcurrencyID,b.ID,b.JobName,b.LastUser,b.Priority,b.ProductTypeID,b.AccessoryGroupID,p.ID As ProductID,
				p.ProductGroupName As ProductGroup,b.QRANumber,b.RequestPurpose,b.TestCenterLocationID,b.TestStageName,j.WILocation,
				(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
				l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, l3.[Values] As TestCenterLocation,
				(
					SELECT top(1) tu.CurrentTestName as CurrentTestName 
					FROM TestUnits AS tu, DeviceTrackingLog AS dtl 
					where tu.ID = dtl.TestUnitID 
					and tu.CurrentTestName is not null
					and (dtl.OutUser IS NULL) AND tu.BatchID=b.ID
				) As CurrentTest, b.CPRNumber,b.RelabJobID, b.RQID
			FROM Batches as b WITH(NOLOCK)
				inner join Products p WITH(NOLOCK) on b.ProductID=p.id 
				LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
				LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID  
				LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.Type='TestCenter' AND b.TestCenterLocationID=l3.LookupID  
			WHERE (BatchStatus = @Status or @Status is null) 
				AND (p.ID = @ProductID OR @ProductID IS NULL)
				AND (b.Priority = @Priority OR @Priority IS NULL)
				AND (b.ProductTypeID = @ProductTypeID OR @ProductTypeID IS NULL)
				AND (b.AccessoryGroupID = @AccessoryGroupID OR @AccessoryGroupID IS NULL)
				AND (b.TestCenterLocationID = @GeoLocationID OR @GeoLocationID IS NULL)
				AND (b.JobName = @JobName OR @JobName IS NULL)
				AND (b.RequestPurpose = @RequestReason OR @RequestReason IS NULL)
				AND (b.TestStageName = @TestStageName OR @TestStageName IS NULL)
				AND
				(
					(
						SELECT top(1) tu.CurrentTestName as CurrentTestName 
						FROM TestUnits AS tu WITH(NOLOCK), DeviceTrackingLog AS dtl WITH(NOLOCK)
						where tu.ID = dtl.TestUnitID 
						and tu.CurrentTestName is not null
						and (dtl.OutUser IS NULL) AND tu.BatchID=b.ID
					) = @TestName 
					OR 
					@TestName IS NULL
				)
				AND
				(
					(
						SELECT top 1 u.id 
						FROM TestUnits as tu WITH(NOLOCK), devicetrackinglog as dtl WITH(NOLOCK), TrackingLocations as tl WITH(NOLOCK), Users u WITH(NOLOCK)
						WHERE tl.ID = dtl.TrackingLocationID and tu.id  = dtl.testunitid and tu.batchid = b.id and  inuser = u.LDAPLogin and outuser is null
					) = @UserID
					OR
					@UserID IS NULL
				)
				AND
				(
					@TrackingLocationID IS NULL
					OR
					(
						b.ID IN (select DISTINCT tu.BatchID
						from TrackingLocations tl WITH(NOLOCK)
						inner join devicetrackinglog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID
						inner join TestUnits tu WITH(NOLOCK) on tu.ID=dtl.TestUnitID
						where TrackingLocationTypeID=@TrackingLocationID)
					)
				)
				AND b.ID IN (Select distinct batchid FROM BatchesAudit WITH(NOLOCK) WHERE InsertTime BETWEEN @BatchStart AND @BatchEnd)
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@ExecutingUserID)))
		)AS BatchesRows		
	WHERE (Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) OR @startRowIndex is null OR @maximumRows is null
	ORDER BY BatchesRows.QRANumber DESC
	RETURN
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchSpecificTestDurationsInsertUpdateSingleItem]'
GO
ALTER PROCEDURE [dbo].[remispBatchSpecificTestDurationsInsertUpdateSingleItem]
@qraNumber nvarchar(11), 
@Duration real, 
@testStageID int,
@Comment nvarchar(1000)=null,	
@LastUser nvarchar(255)
AS
	DECLARE @ReturnValue int
	declare @batchid int = (select id from batches WITH(NOLOCK) where qranumber = @qranumber)
	declare @TestId int = (select t.id from teststages as ts WITH(NOLOCK), Tests as t WITH(NOLOCK) where ts.ID = @testStageID and t.ID = ts.testid)
	
	declare @ID int = (select id from BatchSpecificTestDurations WITH(NOLOCK) where BatchID = @batchid and testid = @testid)
	IF (@ID IS NULL) -- New Item

	BEGIN
		INSERT INTO BatchSpecificTestDurations (TestID, Duration, BatchID, Comment, lastUser)
		VALUES (@TestID, @Duration, @BatchID, @Comment, @lastUser)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE -- Exisiting Item
	BEGIN
		UPDATE BatchSpecificTestDurations 
		SET testid = @testid, Duration = @Duration, batchid = @batchid, Comment = @Comment, lastUser = @LastUser
		WHERE ID = @ID
		SELECT @ReturnValue = @ID
	END
	
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
PRINT N'Altering [dbo].[remispGetBatchDocuments]'
GO
ALTER PROCEDURE [dbo].remispGetBatchDocuments @QRANumber nvarchar(11)
AS
BEGIN
	DECLARE @JobName NVARCHAR(400)
	DECLARE @ProductID INT	
	SELECT @JobName = JobName, @ProductID = ProductID FROM Batches WITH(NOLOCK) WHERE QRANumber=@QRANumber

	SELECT (j.JobName + ' WI') AS WIType, j.WILocation AS Location
	FROM Jobs j WITH(NOLOCK)
	WHERE j.JobName=@JobName AND LTRIM(RTRIM(ISNULL(j.WILocation, ''))) <> ''
	UNION
	SELECT DISTINCT tname AS WIType, TestWI AS Location
	FROM [dbo].[vw_GetTaskInfo] WITH(NOLOCK)
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
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchSpecificTestDurationsDeleteSingleItem]'
GO
ALTER PROCEDURE [dbo].[remispBatchSpecificTestDurationsDeleteSingleItem]
	@qraNumber nvarchar(11),
	@testStageID int,
	@Comment nvarchar(1000)=null,
	@LastUser nvarchar(255)
AS
BEGIN
	DECLARE @ReturnValue int
	declare @batchid int = (select id from batches where qranumber = @qranumber)
	declare @TestId int = (select t.id from teststages as ts, Tests as t where ts.ID = @testStageID and t.ID = ts.testid)
	
	declare @ID int = (select id from BatchSpecificTestDurations where BatchID = @batchid and testid = @testid)
	IF (@ID IS not NULL) -- New Item

	BEGIN
		update BatchSpecificTestDurations set LastUser = @LastUser , comment = @comment where ID = @id
		delete from BatchSpecificTestDurations where ID = @id
	END
	
	IF (@@ERROR != 0)
	BEGIN
		RETURN -1
	END
	ELSE
	BEGIN
		RETURN 0
	END
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchSpecificTestDurationsGetList]'
GO
ALTER PROCEDURE [dbo].[remispBatchSpecificTestDurationsGetList] @qraNumber nvarchar(11)
AS
BEGIN
	SELECT testid, duration 
	FROM Batches as b WITH(NOLOCK)
		INNER JOIN BatchSpecificTestDurations as bstd WITH(NOLOCK) ON bstd.BatchID = b.id
	WHERE b.QRANumber = @qraNumber
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesGetActiveBatches]'
GO
ALTER PROCEDURE [dbo].[remispBatchesGetActiveBatches]
/*	'===============================================================
	'   NAME:                	remispBatchesGetActiveBatches
	'   DATE CREATED:       	10 Jun 2010
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves active batches from table: Batches 
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION:	remove hardcode string comparison and moved to ID
	'===============================================================*/
	@StartRowIndex int = null,
	@MaximumRows int = null,
	@RecordCount int = null OUTPUT
AS
	IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (SELECT COUNT(*) FROM Batches WITH(NOLOCK) WHERE BatchStatus NOT IN(5,7))	
		RETURN
	END
	
	SELECT BatchesRows.row,BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,BatchesRows.JobName,
		BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,BatchesRows.QRANumber,BatchesRows.RequestPurpose,batchesrows.ProductType, batchesrows.AccessoryGroupName,
		batchesrows.ProductID,BatchesRows.TestCenterLocationID,
		BatchesRows.TestCenterLocation,BatchesRows.TestStageName,BatchesRows.RFBands, BatchesRows.TestStageCompletionStatus, 
		batchesrows.testUnitCount,BatchesRows.RQID As ReqID,
		(CASE WHEN BatchesRows.WILocation IS NULL THEN NULL ELSE BatchesRows.WILocation END) AS jobWILocation,
		(
			testunitcount -
			(select COUNT(*) 
			from TestUnits as tu WITH(NOLOCK)
				INNER JOIN DeviceTrackingLog as dtl WITH(NOLOCK) ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
		) as HasUnitsToReturnToRequestor,
		(
			select AssignedTo 
			from TaskAssignments as ta WITH(NOLOCK)
				--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
				INNER JOIN TestStages ts WITH(NOLOCK) ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
				--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
				INNER JOIN Jobs j WITH(NOLOCK) ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
			where ta.BatchID = BatchesRows.ID and ta.Active=1
		) as ActiveTaskAssignee,
		CONVERT(BIT, 0) AS HasBatchSpecificExceptions, batchesrows.ProductTypeID, batchesrows.AccessoryGroupID
	FROM     
		(
			SELECT ROW_NUMBER() OVER (ORDER BY b.ID) AS Row, 
			b.BatchStatus,b.Comment,(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
			b.teststagecompletionstatus,b.ConcurrencyID,b.ID,b.JobName,b.LastUser,b.Priority,p.ProductGroupName,b.ProductTypeID,b.AccessoryGroupID,p.ID as ProductID,b.QRANumber,
			b.RequestPurpose,b.TestCenterLocationID,b.TestStageName, j.WILocation,
			(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
			l2.[Values] As AccessoryGroupName, l.[Values] As ProductType,b.RQID,l3.[Values] As TestCenterLocation
			FROM Batches as b WITH(NOLOCK)
				inner join Products p WITH(NOLOCK) on p.ID=b.ProductID
				LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs
				LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID  
				LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.Type='TestCenter' AND b.TestCenterLocationID=l3.LookupID  
			WHERE BatchStatus NOT IN(5,7)
		) AS BatchesRows
	WHERE (Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) OR @startRowIndex is null OR @maximumRows is null
	ORDER BY BatchesRows.QRANumber
	RETURN
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesSelectByQRANumber]'
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectByQRANumber]
	@QRANumber nvarchar(11) = null,
	@RecordCount int = null OUTPUT
AS
	IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (SELECT COUNT(*) FROM Batches WITH(NOLOCK) WHERE QRANumber = @QRANumber)
		RETURN
	END

	declare @batchid int
	DECLARE @TestStageID INT
	DECLARE @JobID INT
	declare @jobname nvarchar(400)
	declare @teststagename nvarchar(400)
	select @batchid = id, @teststagename=TestStageName, @jobname = JobName from Batches WITH(NOLOCK) where QRANumber = @QRANumber
	declare @testunitcount int = (select count(*) from testunits as tu WITH(NOLOCK) where tu.batchid = @batchid)
	SELECT @JobID = ID FROM Jobs WHERE JobName=@jobname
	SELECT @TestStageID = ID FROM TestStages ts WHERE JobID=@JobID AND TestStageName = @teststagename

	DECLARE @TSTimeLeft REAL
	DECLARE @JobTimeLeft REAL
	EXEC remispGetEstimatedTSTime @batchid,@teststagename,@jobname, @TSTimeLeft OUTPUT, @JobTimeLeft OUTPUT, @TestStageID, @JobID
	
	SELECT BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,BatchesRows.JobName,
	BatchesRows.LastUser,BatchesRows.Priority,p.ProductGroupName,BatchesRows.QRANumber,BatchesRows.RequestPurpose,batchesrows.ProductTypeID,batchesrows.AccessoryGroupID,
	batchesrows.ProductID,BatchesRows.TestCenterLocationID,
	l3.[Values] AS TestCenterLocation,BatchesRows.TestStageName,
	(case when batchesrows.RFBands IS null then (select rfbands.RFBands from RFBands WITH(NOLOCK) where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
	BatchesRows.TestStageCompletionStatus, @testunitcount as testUnitCount,
	(CASE WHEN j.WILocation IS NULL THEN NULL ELSE j.WILocation END) AS jobWILocation,@TSTimeLeft AS EstTSCompletionTime,@JobTimeLeft AS EstJobCompletionTime, 
	(@testunitcount -
			  -- TrackingLocations was only used because we were testing based on string comparison and this isn't needed anymore because we are basing on ID which DeviceTrackingLog can be used.
              (select COUNT(*) 
			  from TestUnits as tu WITH(NOLOCK)
			  INNER JOIN DeviceTrackingLog as dtl WITH(NOLOCK) ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			  where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
	) as HasUnitsToReturnToRequestor,	 
	(select AssignedTo 
	from TaskAssignments as ta WITH(NOLOCK)
		--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
		INNER JOIN TestStages ts WITH(NOLOCK) ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName AND ts.JobID = j.ID
		--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
		--INNER JOIN Jobs j ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
	where ta.BatchID = BatchesRows.ID and ta.Active=1  ) as ActiveTaskAssignee
	,BatchesRows.CPRNumber, l.[Values] AS ProductType, l2.[Values] As AccessoryGroupName,
	(
		SELECT TOP 1 CONVERT(BIT, 1) FROM TestExceptions WITH(NOLOCK) WHERE LookupID=3 AND Value IN (SELECT ID FROM TestUnits WITH(NOLOCK) WHERE BatchID=BatchesRows.ID)
    ) AS HasBatchSpecificExceptions,BatchesRows.RQID As ReqID
	from Batches as BatchesRows WITH(NOLOCK)
		LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = BatchesRows.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
		INNER JOIN Products p WITH(NOLOCK) ON BatchesRows.productID=p.ID
		LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND BatchesRows.ProductTypeID=l.LookupID  
		LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.Type='AccessoryType' AND BatchesRows.AccessoryGroupID=l2.LookupID  
		LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.Type='TestCenter' AND BatchesRows.TestCenterLocationID=l3.LookupID  
	WHERE QRANumber = @QRANumber

select bc.DateAdded, bc.ID, bc.[Text], bc.LastUser from BatchComments as bc WITH(NOLOCK) where BatchID = @batchid and Active = 1 order by DateAdded desc;
	RETURN
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Relab].[remispGetTestsByBatches]'
GO
ALTER PROCEDURE Relab.remispGetTestsByBatches @BatchIDs NVARCHAR(MAX)
AS
BEGIN
	CREATE Table #batches(id int) 
	EXEC(@BatchIDs)
	DECLARE @Count INT
	
	SELECT @Count = COUNT(*) FROM #batches
	
	SELECT DISTINCT TestID, tname
	FROM dbo.vw_GetTaskInfo i
		INNER JOIN #batches b ON b.id = i.BatchID
	WHERE i.processorder > -1 AND i.testtype=1
	GROUP BY TestID, tname
	HAVING COUNT(DISTINCT BatchID) >= @Count
	ORDER BY tname
	
	DROP TABLE #batches
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Relab].[remispGetUnitsByTestMeasurementParameters]'
GO
ALTER PROCEDURE Relab.remispGetUnitsByTestMeasurementParameters @BatchIDs NVARCHAR(MAX), @TestID INT, @MeasurementTypeID INT, @ParameterName NVARCHAR(255)=null, @ParameterValue NVARCHAR(255)=null, @GetStages BIT = 0, @ShowOnlyFailValue INT = 0
AS
BEGIN
	CREATE Table #batches(id int) 
	DECLARE @Count INT
	DECLARE @FalseBit BIT
	EXEC(@BatchIDs)
	SET @FalseBit = CONVERT(BIT, 0)
	
	SELECT DISTINCT CASE WHEN @GetStages = 1 THEN ts.ID ELSE tu.ID END AS ID, tu.BatchID, CASE WHEN @GetStages = 1 THEN SUBSTRING(j.JobName, 0, CHARINDEX(' ', j.Jobname, 0)) + ' ' + ts.TestStageName ELSE CONVERT(VARCHAR, tu.batchUnitNumber) END AS Name, Batches.QRANumber
	FROM TestUnits tu WITH(NOLOCK)
		INNER JOIN Relab.Results r WITH(NOLOCK) ON r.TestUnitID=tu.ID
		INNER JOIN Relab.ResultsMeasurements m WITH(NOLOCK) on m.ResultID=r.ID 
		LEFT OUTER JOIN Relab.ResultsParameters p WITH(NOLOCK) ON m.ID=p.ResultMeasurementID
		INNER JOIN #batches b WITH(NOLOCK) ON tu.BatchID=b.ID
		INNER JOIN TestStages ts WITH(NOLOCK) ON ts.ID = r.TestStageID
		INNER JOIN Jobs j WITH(NOLOCK) ON j.ID=ts.JobID
		INNER JOIN Batches WITH(NOLOCK) ON b.id = Batches.ID
	WHERE m.MeasurementTypeID=@MeasurementTypeID AND r.TestID=@TestID AND m.Archived=@FalseBit		
		AND 
		(
			(@ParameterName IS NOT NULL AND Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN @ParameterName IS NOT NULL THEN 'N' ELSE 'V' END)=@ParameterName
				AND 
				(
					(@ParameterValue IS NOT NULL AND  Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN @ParameterValue IS NOT NULL THEN 'V' ELSE 'N' END)=@ParameterValue) 
					OR 
					(@ParameterValue IS NULL)
				)
			) 
			OR 
			(@ParameterName IS NULL)
		)
		AND
		(
			(@ShowOnlyFailValue = 1 AND m.PassFail=@FalseBit)
			OR
			(@ShowOnlyFailValue = 0)
		)
	GROUP BY CASE WHEN @GetStages = 1 THEN ts.ID ELSE tu.ID END, tu.BatchID, CASE WHEN @GetStages = 1 THEN SUBSTRING(j.JobName, 0, CHARINDEX(' ', j.Jobname, 0)) + ' ' + ts.TestStageName ELSE CONVERT(VARCHAR, tu.batchUnitNumber) END, Batches.QRANumber
	
	DROP TABLE #batches
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesSelectTestingCompleteBatches]'
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectTestingCompleteBatches]
	@StartRowIndex int = -1,
	@MaximumRows int = -1,
	@TestCentreLocation INT =null,
	@RecordCount int = NULL OUTPUT,
	@sortExpression varchar(100) = null,
	@direction varchar(100) = 'desc',
	@ByPassProductCheck INT = 0,
	@UserID int
AS
	IF @TestCentreLocation = 0 
	BEGIN
		SET @TestCentreLocation = NULL
	END
 
SELECT BatchesRows.Row, BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,
	BatchesRows.JobName,BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,BatchesRows.QRANumber,
	BatchesRows.RequestPurpose,BatchesRows.TestCenterLocation,BatchesRows.TestStageName, batchesrows.RFBands, 
	batchesrows.TestStageCompletionStatus,batchesrows.testUnitCount,BatchesRows.ProductType,batchesrows.AccessoryGroupName,BatchesRows.ProductID,
	batchesrows.HasUnitsToReturnToRequestor,
	batchesrows.jobWILocation
	,(select AssignedTo 
	from TaskAssignments as ta WITH(NOLOCK)
		--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
		INNER JOIN TestStages ts WITH(NOLOCK) ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
		--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
		INNER JOIN Jobs j WITH(NOLOCK) ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
	where ta.BatchID = BatchesRows.ID and ta.Active=1  ) as ActiveTaskAssignee,
	(select  bc.Text + '####' from BatchComments as bc WITH(NOLOCK)
	where bc.BatchID = batchesrows.ID and bc.Active = 1 for xml path('')) as BatchCommentsConcat, CONVERT(BIT,0) AS HasBatchSpecificExceptions,
	BatchesRows.ProductTypeID, BatchesRows.AccessoryGroupID,batchesrows.RQID As ReqID, batchesrows.TestCenterLocationID
FROM
	(
		SELECT ROW_NUMBER() OVER 
			(
				ORDER BY 
				case when @sortExpression='qranumber' and @direction='asc' then qranumber end,
				case when @sortExpression='qranumber' and @direction='desc' then qranumber end desc,
				case when @sortExpression='teststage' and @direction='asc' then b.teststagename end,
				case when @sortExpression='teststage' and @direction='desc' then b.teststagename end desc,
				case when @sortExpression='purpose' and @direction='asc' then requestpurpose end,
				case when @sortExpression='purpose' and @direction='desc' then requestpurpose end desc,
				case when @sortExpression='job' and @direction='asc' then jobname end,
				case when @sortExpression='job' and @direction='desc' then jobname end desc,
				case when @sortExpression='productgroup' and @direction='asc' then productgroupname end asc,
				case when @sortExpression='productgroup' and @direction='desc' then productgroupname end desc,
				case when @sortExpression='priority' and @direction='asc' then Priority end asc,
				case when @sortExpression='priority' and @direction='desc' then Priority end desc,
				case when @sortExpression='batchstatus' and @direction='asc' then batchstatus end,
				case when @sortExpression='batchstatus' and @direction='desc' then batchstatus end desc,
				case when @sortExpression='HasUnitsToReturnToRequestor' and @direction='asc' then HasUnitsToReturnToRequestor end,
				case when @sortExpression='HasUnitsToReturnToRequestor' and @direction='desc' then HasUnitsToReturnToRequestor end desc,
				case when @sortExpression='jobwilocation' and @direction='asc' then jobWILocation end,
				case when @sortExpression='jobwilocation' and @direction='desc' then jobWILocation end desc,
				case when @sortExpression='testunitcount' and @direction='asc' then testUnitCount end,
				case when @sortExpression='testunitcount' and @direction='desc' then testUnitCount end desc,
				case when @sortExpression='comments' and @direction='asc' then comment end,
				case when @sortExpression='comments' and @direction='desc' then comment end desc,
				case when @sortExpression='testcenterlocation' and @direction='asc' then TestCenterLocationID end,
				case when @sortExpression='testcenterlocation' and @direction='desc' then TestCenterLocationID end desc,
				case when @sortExpression is null then qranumber end desc
			) AS Row, 
			ID, 
			QRANumber, 
			Comment,
			RequestPurpose, 
			Priority,
			TestStageName, 
			BatchStatus, 
			ProductGroupName, 
			ProductType,
			AccessoryGroupName,
			ProductTypeID,
			AccessoryGroupID,
			ProductID,
			JobName, 
			TestCenterLocation,
			TestCenterLocationID,
			LastUser, 
			ConcurrencyID,
			b.RFBands,
			b.TestStageCompletionStatus,
			b.testUnitCount,
			b.HasUnitsToReturnToRequestor,
			b.jobWILocation,
			b.RQID
		from
			(
				SELECT DISTINCT 
				b.ID, 
				b.QRANumber, 
				b.Comment,
				b.RequestPurpose, 
				b.Priority,
				b.TestStageName, 
				b.BatchStatus, 
				p.ProductGroupName, 
				p.ID As ProductID,
				b.ProductTypeID,
				b.AccessoryGroupID,
				l.[Values] As ProductType,
				l2.[Values] As AccessoryGroupName,
				l3.[Values] As TestCenterLocation,
				b.JobName, 
				b.LastUser, 
				b.TestCenterLocationID,
				b.ConcurrencyID,
				(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
				b.TestStageCompletionStatus,
				(select count(*) from testunits WITH(NOLOCK) where testunits.batchid = b.id) as testUnitCount,
				(select Jobs.WILocation from Jobs WITH(NOLOCK) where Jobs.JobName = b.jobname) as jobWILocation,
				(
					(select COUNT(*) from TestUnits as tu WITH(NOLOCK) where tu.batchid = b.ID) -
					(
						select COUNT(*) 
						from TestUnits as tu WITH(NOLOCK), DeviceTrackingLog as dtl WITH(NOLOCK), TrackingLocations as tl WITH(NOLOCK)
						where dtl.TrackingLocationID = tl.ID and tu.BatchID = b.ID 
							and tl.ID = 81 and dtl.OutTime IS null and dtl.TestUnitID = tu.ID
					)
				) as HasUnitsToReturnToRequestor,b.RQID
				FROM Batches AS b WITH(NOLOCK)
					INNER JOIN Products p WITH(NOLOCK) ON b.ProductID=p.ID
					LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
					LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID  
					LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.Type='TestCenter' AND b.TestCenterLocationID=l3.LookupID  	
				WHERE (b.TestCenterLocationID = @TestCentreLocation or @TestCentreLocation is null) and b.BatchStatus = 8
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
			)as b
	) as batchesrows
WHERE ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) 
OR @startRowIndex = -1 OR @maximumRows = -1) order by Row
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesSelectHeldBatches]'
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectHeldBatches]
	@TestCentreLocation INT =null,
	@RecordCount int = NULL OUTPUT,
	@sortExpression varchar(100) = null,
	@direction varchar(100) = 'asc',
	@ByPassProductCheck INT = 0,
	@UserID int
	AS
	SELECT ROW_NUMBER() OVER (ORDER BY 
		case when @sortExpression='qra' and @direction='asc' then qranumber end,
		case when @sortExpression='qra' and @direction='desc' then qranumber end desc,
		case when @sortExpression='teststage' and @direction='asc' then b.teststagename end,
		case when @sortExpression='teststage' and @direction='desc' then b.teststagename end desc,
		case when @sortExpression='purpose' and @direction='asc' then requestpurpose end,
		case when @sortExpression='purpose' and @direction='desc' then requestpurpose end desc,
		case when @sortExpression='job' and @direction='asc' then jobname end,
		case when @sortExpression='job' and @direction='desc' then jobname end desc,
		case when @sortExpression='productgroup' and @direction='asc' then productgroupname end asc,
		case when @sortExpression='productgroup' and @direction='desc' then productgroupname end desc,
		case when @sortExpression='priority' and @direction='asc' then Priority end asc,
		case when @sortExpression='priority' and @direction='desc' then Priority end desc,
		case when @sortExpression='batchstatus' and @direction='asc' then batchstatus end,
		case when @sortExpression='batchstatus' and @direction='desc' then batchstatus end desc,
		case when @sortExpression is null then Priority end desc
		) AS Row, 
		BatchStatus,Comment,ConcurrencyID,b.ID,
		JobName,LastUser,Priority,ProductGroupName,QRANumber,
		RequestPurpose,TestCenterLocation,TestStageName,ProductType, AccessoryGroupName,productID,
		RFBands, TestStageCompletionStatus, (select count(*) from testunits WITH(NOLOCK) where testunits.batchid = b.id) as testunitcount,
		(CASE WHEN WILocation IS NULL THEN NULL ELSE WILocation END) AS jobWILocation,			
		((select count(*) from testunits WITH(NOLOCK) where testunits.batchid = b.id)  -
		(select COUNT(*) 
			from TestUnits as tu WITH(NOLOCK)
			INNER JOIN DeviceTrackingLog as dtl WITH(NOLOCK) ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			where dtl.OutTime IS null and tu.BatchID = b.ID)
		) as HasUnitsToReturnToRequestor,
		(select AssignedTo 
		from TaskAssignments as ta WITH(NOLOCK)
			--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
			INNER JOIN TestStages ts WITH(NOLOCK) ON ta.TaskID = ts.ID AND ts.TestStageName=TestStageName 
			--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
			INNER JOIN Jobs j WITH(NOLOCK) ON j.ID = ts.JobID AND j.JobName = j.JobName
		where ta.BatchID = b.ID and ta.Active=1  ) as ActiveTaskAssignee, CONVERT(BIT,0) AS HasBatchSpecificExceptions,
		ProductTypeID, AccessoryGroupID,RQID As ReqID, TestCenterLocationID
	FROM
		(
			SELECT DISTINCT 
                b.ID, 
                b.QRANumber, 
                b.Comment,
                b.RequestPurpose, 
                b.Priority,
                b.TestStageName, 
                b.BatchStatus, 
                p.ProductGroupName,
				b.ProductTypeID, 
				b.AccessoryGroupID,
				l.[Values] As ProductType,
				l2.[Values] As AccessoryGroupName,
				l3.[Values] As TestCenterLocation,
				p.ID As productID,
                b.JobName, 
                b.LastUser, 
                b.TestCenterLocationID,
                b.ConcurrencyID,
                (case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
                b.TestStageCompletionStatus,
                j.WILocation,b.RQID                     
			FROM Batches AS b WITH(NOLOCK)
				 INNER JOIN Products p WITH(NOLOCK) on b.ProductID=p.id
				 LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = b.JobName
				 LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND l.LookupID=b.ProductTypeID
				 LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.Type='AccessoryType' AND l2.LookupID=b.AccessoryGroupID
				 LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.Type='TestCenter' AND b.TestCenterLocationID=l3.LookupID  
			WHERE (b.TestCenterLocationID = @TestCentreLocation or @TestCentreLocation is null) and (b.BatchStatus = 1 or b.BatchStatus = 3) 
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WITH(NOLOCK) WHERE UserID=@UserID)))
		)as b
order by QRANumber desc
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
		FROM Relab.Results r WITH(NOLOCK)
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
			FROM Relab.Results r WITH(NOLOCK)
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
	FROM Relab.Results r WITH(NOLOCK)
		INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
		INNER JOIN Tests t WITH(NOLOCK) ON r.TestID=t.ID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID=r.TestUnitID
		INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID
		INNER JOIN Relab.ResultsMeasurements m WITH(NOLOCK) ON m.ResultID=r.ID
		LEFT OUTER JOIN Lookups lm WITH(NOLOCK) ON m.MeasurementTypeID=lm.LookupID
		LEFT OUTER JOIN Lookups lu WITH(NOLOCK) ON m.MeasurementUnitTypeID=lu.LookupID
		LEFT OUTER JOIN Relab.ResultsXML rxml WITH(NOLOCK) ON rxml.ID=m.XMLID
		LEFT OUTER JOIN #parameters p WITH(NOLOCK) ON p.ResultMeasurementID=m.ID
	WHERE b.ID=@BatchID AND (@ResultID IS NULL OR (@ResultID IS NOT NULL AND r.ID=@ResultID))
	ORDER BY tu.BatchUnitNumber, ts.TestStageName, TestName
	
	SET NOCOUNT OFF
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispExceptionSearch]'
GO
ALTER procedure [dbo].[remispExceptionSearch] @ProductID INT = 0, @AccessoryGroupID INT = 0, @ProductTypeID INT = 0, @TestID INT = 0, @TestStageID INT = 0, @JobName NVARCHAR(400) = NULL, @IncludeBatches INT = 0
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
		pvt.ProductTypeID, pvt.AccessoryGroupID, pvt.ProductID, l.[Values] As ProductType, l2.[Values] As AccessoryGroupName
		FROM vw_ExceptionsPivoted as pvt WITH(NOLOCK)
			LEFT OUTER JOIN Tests t WITH(NOLOCK) ON pvt.Test = t.ID
			LEFT OUTER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = pvt.TestUnitID
			LEFT OUTER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
			LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND l.LookupID=pvt.ProductTypeID
			LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.Type='AccessoryType' AND l2.LookupID=pvt.AccessoryGroupID
			LEFT OUTER JOIN Products p WITH(NOLOCK) ON p.ID=pvt.ProductID
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
		ISNULL(UPPER(SUBSTRING(rmf.ContentType,2,LEN(rmf.ContentType))), 'PNG') AS ContentType, p.*
	FROM Relab.ResultsMeasurements rm WITH(NOLOCK)
		LEFT OUTER JOIN Lookups lu WITH(NOLOCK) ON lu.Type='UnitType' AND lu.LookupID=rm.MeasurementUnitTypeID
		LEFT OUTER JOIN Lookups lt WITH(NOLOCK) ON lt.Type='MeasurementType' AND lt.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Lookups ltsf WITH(NOLOCK) ON ltsf.Type='SFIFunctionalMatrix' AND ltsf.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Lookups ltmf WITH(NOLOCK) ON ltmf.Type='MFIFunctionalMatrix' AND ltmf.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Relab.ResultsMeasurementsFiles rmf WITH(NOLOCK) ON rmf.ResultMeasurementID=rm.ID
		LEFT OUTER JOIN #parameters p WITH(NOLOCK) ON p.ResultMeasurementID=rm.ID
	WHERE ResultID=@ResultID AND ((@IncludeArchived = 0 AND rm.Archived=@FalseBit) OR (@IncludeArchived=1)) AND ((@OnlyFails = 1 AND PassFail=@FalseBit) OR (@OnlyFails = 0))
	ORDER BY lt.[Values], rm.ReTestNum ASC

	DROP TABLE #parameters
	SET NOCOUNT OFF
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesSelectRandomSampleQRANumbers]'
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectRandomSampleQRANumbers]
AS
BEGIN
	SELECT top(5) b.QRANumber
	FROM Batches AS b WITH(NOLOCK)
		INNER JOIN DeviceTrackingLog AS dtl WITH(NOLOCK)
		INNER JOIN TrackingLocations AS tl WITH(NOLOCK) ON dtl.TrackingLocationID = tl.ID 
		INNER JOIN TestUnits AS tu WITH(NOLOCK) ON dtl.TestUnitID = tu.ID ON b.id = tu.batchid --batches where there's a tracking log
	WHERE tl.ID = 25 AND dtl.OutTime IS NULL AND dtl.OutUser IS NULL --where they're in remstar
		and (select COUNT (*) from TestUnits WITH(NOLOCK) where TestUnits.BatchID = b.ID) <=20 -- and there are less that 20 of them
	ORDER BY CAST(CHECKSUM(NEWID(), b.id) & 0x7fffffff AS float) --generates a random number between 0 and 1
/ CAST (0x7fffffff AS int)
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesGetActiveBatchesByRequestor]'
GO
ALTER PROCEDURE [dbo].[remispBatchesGetActiveBatchesByRequestor]
/*	'===============================================================
	'   NAME:                	remispBatchesGetActiveBatchesByRequestor
	'   DATE CREATED:       	28 Feb 2011
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves active batches by requestor
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/
	@StartRowIndex int = null,
	@MaximumRows int = null,
	@RecordCount int = null OUTPUT,
	@Requestor nvarchar(500) = null
AS
	IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (SELECT COUNT(*) FROM Batches WITH(NOLOCK) WHERE BatchStatus NOT IN(5,7) and Requestor = @Requestor	)	
		RETURN
	END

	SELECT BatchesRows.row,BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,BatchesRows.JobName,
		BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,batchesrows.ProductType,batchesrows.AccessoryGroupName, batchesrows.ProductID,
		BatchesRows.QRANumber,BatchesRows.RequestPurpose,
		BatchesRows.TestCenterLocation,BatchesRows.TestStageName,BatchesRows.RFBands, BatchesRows.TestStageCompletionStatus, 
		batchesrows.testUnitCount,BatchesRows.RQID As ReqID,batchesrows.TestCenterLocationID,
		(CASE WHEN batchesrows.WILocation IS NULL THEN NULL ELSE batchesrows.WILocation END) AS jobWILocation,
		(
			testunitcount -
			(select COUNT(*) 
			from TestUnits as tu WITH(NOLOCK)
				INNER JOIN DeviceTrackingLog as dtl WITH(NOLOCK) ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
		) as HasUnitsToReturnToRequestor,
		(
			select AssignedTo 
			from TaskAssignments as ta WITH(NOLOCK)
				--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
				INNER JOIN TestStages ts WITH(NOLOCK) ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
				--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
				INNER JOIN Jobs j WITH(NOLOCK) ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
			where ta.BatchID = BatchesRows.ID and ta.Active=1
		) as ActiveTaskAssignee,
		CONVERT(BIT,0) AS HasBatchSpecificExceptions, BatchesRows.AccessoryGroupID,BatchesRows.ProductTypeID
	FROM     
		(
			SELECT ROW_NUMBER() OVER (ORDER BY b.ID) AS Row, 
				b.BatchStatus,b.Comment,(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
				b.teststagecompletionstatus,b.ConcurrencyID,b.ID,b.JobName,b.LastUser,b.Priority,p.ProductGroupName,b.ProductTypeID, b.AccessoryGroupID,p.ID As ProductID,b.QRANumber,
				b.RequestPurpose,b.TestCenterLocationID,b.TestStageName, j.WILocation,
				(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
				l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, b.RQID, l3.[Values] As TestCenterLocation
			FROM Batches as b
				inner join Products p WITH(NOLOCK) on p.ID=b.ProductID
				LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
				LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID
				LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.Type='TestCenter' AND b.TestCenterLocationID=l3.LookupID    
			WHERE BatchStatus NOT IN(5,7) and Requestor = @Requestor
		) AS BatchesRows
WHERE (Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) OR @startRowIndex is null OR @maximumRows is null
order by BatchesRows.QRANumber
RETURN
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[RemispGetTestCountByType]'
GO
ALTER PROCEDURE [dbo].[RemispGetTestCountByType] @StartDate DateTime = NULL, @EndDate DateTime = NULL, @ReportBasedOn INT = NULL, @GeoLocationID INT, @GroupByType INT = 1, @BasedOn NVARCHAR(60), @ByPassProductCheck INT, @UserID INT
AS
BEGIN
	If (@StartDate IS NULL)
	BEGIN
		SET @StartDate = GETDATE()
	END

	IF (@GroupByType IS NULL)
	BEGIN
		SET @GroupByType = 1
	END
	
	IF (@ReportBasedOn IS NULL)
	BEGIN
		SET @ReportBasedOn = 1
	END

	DECLARE @TrueBit BIT
	SET @TrueBit = CONVERT(BIT, 1)

	IF (@BasedOn = '# Completed Testing')
	BEGIN
		WITH data AS 
		(
			SELECT tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
			FROM TrackingLocations tl WITH(NOLOCK)
				LEFT OUTER JOIN TrackingLocationsHosts tlh WITH(NOLOCK) ON tl.ID = tlh.TrackingLocationID
				INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID
				INNER JOIN TestRecordsXTrackingLogs trtl WITH(NOLOCK) ON trtl.TrackingLogID = dtl.ID
				INNER JOIN TestRecords tr WITH(NOLOCK) ON trtl.TestRecordID = tr.ID
				INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
				INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
				INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus = 8 and ba.inserttime between @startdate and @enddate
				INNER JOIN BatchesAudit ba2 WITH(NOLOCK) ON b.ID = ba2.BatchID AND ba2.BatchStatus <> 8 and ba2.inserttime between @startdate and @enddate
			WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
				AND dtl.InTime BETWEEN @StartDate AND @EndDate
				AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
			GROUP BY tl.TrackingLocationName, tr.TestName
		)
		SELECT *
		FROM data
		ORDER BY TrackingLocationName, TestName
	END
	ELSE IF (@BasedOn = '# in Chamber')
	BEGIN
		WITH data AS 
		(
			SELECT tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
			FROM TrackingLocations tl WITH(NOLOCK)
				INNER JOIN TrackingLocationTypes tlt WITH(NOLOCK) ON tl.TrackingLocationTypeID = tlt.ID AND tlt.TrackingLocationFunction = 4
				LEFT OUTER JOIN TrackingLocationsHosts tlh WITH(NOLOCK) ON tl.ID = tlh.TrackingLocationID
				INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID
				INNER JOIN TestRecordsXTrackingLogs trtl WITH(NOLOCK) ON trtl.TrackingLogID = dtl.ID
				INNER JOIN TestRecords tr WITH(NOLOCK) ON trtl.TestRecordID = tr.ID
				INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
				INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
			WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
				AND dtl.InTime BETWEEN @StartDate AND @EndDate
				AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
			GROUP BY tl.TrackingLocationName, tr.TestName
		)
		SELECT *
		FROM data
		ORDER BY TrackingLocationName, TestName
	END
	ELSE IF (@BasedOn = '# Units in FA')
	BEGIN
		WITH data AS 
		(
			SELECT tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
			FROM (
					SELECT tra.TestRecordId 
					FROM TestRecordsaudit tra WITH(NOLOCK)
					WHERE tra.Action IN ('I','U') AND tra.Status IN (3, 4) and tra.InsertTime BETWEEN @startdate AND @enddate--FQRaised and FARequired
					GROUP BY TestRecordId
				  ) as xer 
				INNER JOIN TestRecords tr WITH(NOLOCK) ON xer.TestRecordID = tr.ID  
				INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
				INNER JOIN TestRecordsXTrackingLogs trtl WITH(NOLOCK) ON trtl.TestRecordID = tr.ID
				INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON dtl.ID = trtl.TrackingLogID
				INNER JOIN TrackingLocations tl WITH(NOLOCK) ON tl.ID = dtl.TrackingLocationID
				LEFT OUTER JOIN TrackingLocationsHosts tlh WITH(NOLOCK) ON tl.ID = tlh.TrackingLocationID
				INNER JOIN Batches b ON tu.BatchID = b.ID
			WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
				AND dtl.InTime BETWEEN @StartDate AND @EndDate
				AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
			GROUP BY tl.TrackingLocationName, tr.TestName
		)
		SELECT *
		FROM data
		ORDER BY TrackingLocationName, TestName
	END
	ELSE IF (@BasedOn = '# Worked On Parametric')
	BEGIN
		WITH data AS 
		(
			SELECT tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
			FROM TrackingLocations tl WITH(NOLOCK)
				LEFT OUTER JOIN TrackingLocationsHosts tlh WITH(NOLOCK) ON tl.ID = tlh.TrackingLocationID
				INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID
				INNER JOIN TestRecordsXTrackingLogs trtl WITH(NOLOCK) ON trtl.TrackingLogID = dtl.ID
				INNER JOIN TestRecords tr WITH(NOLOCK) ON trtl.TestRecordID = tr.ID
				INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
				INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
				INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
				INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
				INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.TechnicalOperationsTest = @TrueBit
			WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
				AND dtl.InTime BETWEEN @StartDate AND @EndDate
				AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
			GROUP BY tl.TrackingLocationName, tr.TestName
		)
		SELECT *
		FROM data
		ORDER BY TrackingLocationName, TestName
	END
	ELSE IF (@BasedOn = '# Completed Parametric')
	BEGIN
		WITH data AS 
		(
			SELECT tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
			FROM TrackingLocations tl WITH(NOLOCK)
				LEFT OUTER JOIN TrackingLocationsHosts tlh WITH(NOLOCK) ON tl.ID = tlh.TrackingLocationID
				INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID
				INNER JOIN TestRecordsXTrackingLogs trtl WITH(NOLOCK) ON trtl.TrackingLogID = dtl.ID
				INNER JOIN TestRecords tr WITH(NOLOCK) ON trtl.TestRecordID = tr.ID
				INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
				INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
				INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus IN (5, 8)--Complete or TestingComplete
				INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
				INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.TechnicalOperationsTest = @TrueBit
			WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
				AND dtl.InTime BETWEEN @StartDate AND @EndDate
				AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
			GROUP BY tl.TrackingLocationName, tr.TestName
		)
		SELECT *
		FROM data
		ORDER BY TrackingLocationName, TestName
	END
	ELSE IF (@BasedOn = '# Worked On Drop/Tumble')
	BEGIN
		WITH data AS 
		(
			SELECT tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
			FROM TrackingLocations tl WITH(NOLOCK)
				LEFT OUTER JOIN TrackingLocationsHosts tlh WITH(NOLOCK) ON tl.ID = tlh.TrackingLocationID
				INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID
				INNER JOIN TestRecordsXTrackingLogs trtl WITH(NOLOCK) ON trtl.TrackingLogID = dtl.ID
				INNER JOIN TestRecords tr WITH(NOLOCK) ON trtl.TestRecordID = tr.ID
				INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
				INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
				INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
				INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = @TrueBit
				INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
			WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
				AND dtl.InTime BETWEEN @StartDate AND @EndDate
				AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
			GROUP BY tl.TrackingLocationName, tr.TestName
		)
		SELECT *
		FROM data
		ORDER BY TrackingLocationName, TestName
	END
	ELSE IF (@BasedOn = '# Completed Drop/Tumble')
	BEGIN
		WITH data AS 
		(
			SELECT tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
			FROM TrackingLocations tl WITH(NOLOCK)
				LEFT OUTER JOIN TrackingLocationsHosts tlh WITH(NOLOCK) ON tl.ID = tlh.TrackingLocationID
				INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID
				INNER JOIN TestRecordsXTrackingLogs trtl WITH(NOLOCK) ON trtl.TrackingLogID = dtl.ID
				INNER JOIN TestRecords tr WITH(NOLOCK) ON trtl.TestRecordID = tr.ID
				INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
				INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
				INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus IN (5, 8)--Complete or TestingComplete
				INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = @TrueBit
				INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
			WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
				AND dtl.InTime BETWEEN @StartDate AND @EndDate
				AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
			GROUP BY tl.TrackingLocationName, tr.TestName
		)
		SELECT *
		FROM data
		ORDER BY TrackingLocationName, TestName
	END
	ELSE IF (@BasedOn = '# Worked On Accessories')
	BEGIN
		WITH data AS 
		(
			SELECT tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
			FROM TrackingLocations tl WITH(NOLOCK)
				LEFT OUTER JOIN TrackingLocationsHosts tlh WITH(NOLOCK) ON tl.ID = tlh.TrackingLocationID
				INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID
				INNER JOIN TestRecordsXTrackingLogs trtl WITH(NOLOCK) ON trtl.TrackingLogID = dtl.ID
				INNER JOIN TestRecords tr WITH(NOLOCK) ON trtl.TestRecordID = tr.ID
				INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
				INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
				INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
				INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
				INNER JOIN Lookups l ON l.Type='ProductType' AND l.LookupID=b.ProductTypeID
			WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
				AND dtl.InTime BETWEEN @StartDate AND @EndDate AND l.[Values] = 'Accessory'
				AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
			GROUP BY tl.TrackingLocationName, tr.TestName
		)
		SELECT *
		FROM data
		ORDER BY TrackingLocationName, TestName
	END
	ELSE IF (@BasedOn = '# Worked On Component')
	BEGIN
		WITH data AS 
		(
			SELECT tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
			FROM TrackingLocations tl WITH(NOLOCK)
				LEFT OUTER JOIN TrackingLocationsHosts tlh WITH(NOLOCK) ON tl.ID = tlh.TrackingLocationID
				INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID
				INNER JOIN TestRecordsXTrackingLogs trtl WITH(NOLOCK) ON trtl.TrackingLogID = dtl.ID
				INNER JOIN TestRecords tr WITH(NOLOCK) ON trtl.TestRecordID = tr.ID
				INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
				INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
				INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
				INNER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND l.LookupID=b.ProductTypeID
			WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
				AND dtl.InTime BETWEEN @StartDate AND @EndDate AND l.[Values] = 'Component'
				AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
			GROUP BY tl.TrackingLocationName, tr.TestName
		)
		SELECT *
		FROM data
		ORDER BY TrackingLocationName, TestName
	END
	ELSE IF (@BasedOn = '# Worked On Handheld')
	BEGIN
		WITH data AS 
		(
			SELECT tl.TrackingLocationName, tr.TestName, (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) As Count
			FROM TrackingLocations tl WITH(NOLOCK)
				LEFT OUTER JOIN TrackingLocationsHosts tlh WITH(NOLOCK) ON tl.ID = tlh.TrackingLocationID
				INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID
				INNER JOIN TestRecordsXTrackingLogs trtl WITH(NOLOCK) ON trtl.TrackingLogID = dtl.ID
				INNER JOIN TestRecords tr WITH(NOLOCK) ON trtl.TestRecordID = tr.ID
				INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = tr.TestUnitID
				INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
				INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
				INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
				INNER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND l.LookupID=b.ProductTypeID
			WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
				AND dtl.InTime BETWEEN @StartDate AND @EndDate AND l.[Values] = 'Handheld'
				AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND b.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
			GROUP BY tl.TrackingLocationName, tr.TestName
		)
		SELECT *
		FROM data
		ORDER BY TrackingLocationName, TestName
	END
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
	CREATE TABLE #results (TestID INT)
	CREATE TABLE #exceptions (ID INT, BatchUnitNumber INT, ReasonForRequest INT, ProductGroupName NVARCHAR(150), JobName NVARCHAR(150), TestStageName NVARCHAR(150), TestName NVARCHAR(150), LastUser NVARCHAR(150), TestStageID INT, TestUnitID INT, ProductTypeID INT, AccessoryGroupID INT, ProductID INT, ProductType NVARCHAR(150), AccessoryGroupName NVARCHAR(150), TestID INT)
	
	SELECT * INTO #view FROM vw_GetTaskInfo WITH(NOLOCK) WHERE BatchID=@BatchID and Processorder > -1 AND (Testtype=1 or TestID=1029)
	
	SELECT @QRANumber = QRANumber, @ProductID = ProductID, @ProductTypeID=ProductTypeID, @AccessoryGroupID = AccessoryGroupID FROM Batches WITH(NOLOCK) WHERE ID=@BatchID
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
	
	--Get Batch Exceptions
	insert into #exceptions (ID, BatchUnitNumber, ReasonForRequest, ProductGroupName, JobName, TestStageName, TestName, LastUser, TestStageID, TestUnitID, ProductTypeID, AccessoryGroupID, ProductID, ProductType, AccessoryGroupName, TestID)
	exec [dbo].[remispTestExceptionsGetBatchOnlyExceptions] @QraNumber = @QRANumber
	
	--Get Product Exceptions
	insert into #exceptions (ID, BatchUnitNumber, ReasonForRequest, ProductGroupName, JobName, TestStageName, TestName, LastUser, TestStageID, TestUnitID, ProductTypeID, AccessoryGroupID, ProductID, ProductType, AccessoryGroupName, TestID)
	exec [dbo].[remispTestExceptionsGetProductExceptions] @ProductID = @ProductID, @recordCount = null, @startrowindex =-1, @maximumrows=-1
	
	--Get non product exceptions
	insert into #exceptions (ID, BatchUnitNumber, ReasonForRequest, ProductGroupName, JobName, TestStageName, TestName, LastUser, TestStageID, TestUnitID, ProductTypeID, AccessoryGroupID, ProductID, ProductType, AccessoryGroupName, TestID)
	exec [dbo].[remispTestExceptionsGetProductExceptions] @ProductID = 0, @recordCount = null, @startrowindex =-1, @maximumrows=-1
	
	--Remove product exceptions where it's not the current product type or accessorygroup
	DELETE FROM #exceptions
	WHERE ProductTypeID <> @ProductTypeID OR AccessoryGroupID <>  @AccessoryGroupID OR TestStageID IN (SELECT ID FROM TestStages WHERE TestStageType=4)
		OR TestStageID NOT IN (SELECT TestStageID FROM #view)
		
	UPDATE #exceptions SET BatchUnitNumber=0 WHERE BatchUnitNumber IS NULL
		
	SET @query = 'INSERT INTO #results
	SELECT DISTINCT TestID, TName AS [' + @QRANumber + '],
		(
			CASE WHEN
				(
					CASE 
						WHEN TestStageType = 1 THEN 
							' + CONVERT(VARCHAR, (@UnitCount * @StageCount)) + ' 
						ELSE ' + CONVERT(VARCHAR, (@UnitCount * @StageCount2)) + ' 
					END - (ISNULL((SELECT SUM(val)
					FROM
					(
						SELECT COUNT(DISTINCT TestStageID) * ' + CONVERT(VARCHAR, (@UnitCount)) + ' AS val 
						FROM #exceptions 
						WHERE 
							(
								((TestID=i.TestID OR TestID IS NULL) AND TestUnitID IS NULL)
								OR
								((TestID=i.TestID OR TestID IS NULL) AND TestUnitID IS NOT NULL)
							)
						GROUP BY BatchUnitNumber, TestStageID
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
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesSelectBatchesNotInREMSTAR]'
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectBatchesNotInREMSTAR]
AS
select QRANumber, BatchUnitNumber, tl.TrackingLocationName,dtl.InTime, dtl.InUser,
	(select AssignedTo 
	from TaskAssignments as ta WITH(NOLOCK)
		INNER JOIN TestStages ts WITH(NOLOCK) ON ta.TaskID = ts.ID AND ts.TestStageName=b.TestStageName 
		INNER JOIN Jobs j WITH(NOLOCK) ON j.ID = ts.JobID AND j.JobName = b.JobName
	where ta.BatchID = b.ID and ta.Active=1) as ActiveTaskAssignee
FROM TestUnits tu WITH(NOLOCK)
	INNER JOIN Batches b WITH(NOLOCK) ON b.ID = tu.BatchID 
	INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON tu.ID = dtl.TestUnitID
	INNER JOIN TrackingLocations tl WITH(NOLOCK) ON dtl.TrackingLocationID = tl.id
	INNER JOIN TrackingLocationTypes tlt WITH(NOLOCK) ON tlt.ID = tl.TrackingLocationTypeID AND tlt.ID != 103 --external location
where dtl.OutTime is null and dtl.ID = (select max(id) from DeviceTrackingLog where DeviceTrackingLog.testunitid = tu.id)
	and tl.TestCenterLocationID = 76
	and tl.id NOT IN(25,81)
order by QRANumber, BatchUnitNumber, dtl.InTime
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesActiveSelectByJob]'
GO
ALTER PROCEDURE [dbo].[remispBatchesActiveSelectByJob]
	@JobName NVARCHAR(400),
	@RecordCount int = NULL OUTPUT,
	@sortExpression varchar(100) = null,
	@direction varchar(100) = 'asc'
AS
	IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (select  COUNT(*) 
							from 
							(
								select DISTINCT b.id
								FROM  Batches AS b 
								INNER JOIN DeviceTrackingLog AS dtl
								INNER JOIN TestUnits AS tu ON dtl.TestUnitID = tu.ID ON b.id = tu.BatchID --batches where there's a tracking log                      
								WHERE  b.BatchStatus NOT IN (5,8) AND b.Jobname=@JobName AND dtl.OutTime IS NULL AND dtl.OutUser IS NULL
							)as records)  --and the tracking log has not been 'scanned' out
		RETURN
	END
	
	SELECT ROW_NUMBER() OVER 
		(ORDER BY 
			case when @sortExpression='qra' and @direction='asc' then qranumber end,
			case when @sortExpression='qra' and @direction='desc' then qranumber end desc,
			case when @sortExpression='teststage' and @direction='asc' then b.teststagename end,
			case when @sortExpression='teststage' and @direction='desc' then b.teststagename end desc,
			case when @sortExpression='purpose' and @direction='asc' then requestpurpose end,
			case when @sortExpression='purpose' and @direction='desc' then requestpurpose end desc,
			case when @sortExpression='job' and @direction='asc' then jobname end,
			case when @sortExpression='job' and @direction='desc' then jobname end desc,
			case when @sortExpression='productgroup' and @direction='asc' then productgroupname end asc,
			case when @sortExpression='productgroup' and @direction='desc' then productgroupname end desc,
			case when @sortExpression='priority' and @direction='asc' then Priority end asc,
			case when @sortExpression='priority' and @direction='desc' then Priority end desc,
			case when @sortExpression='batchstatus' and @direction='asc' then batchstatus end,
			case when @sortExpression='batchstatus' and @direction='desc' then batchstatus end desc,
			case when @sortExpression is null then Priority end desc		
		) AS Row, 
		BatchStatus,Comment,ConcurrencyID,ID,
		JobName,LastUser,Priority,ProductGroupName,QRANumber,
		RequestPurpose,TestCenterLocation,TestStageName,ProductType, AccessoryGroupName,ProductID,
		RFBands, TestStageCompletionStatus,testunitcount,RQID As ReqID,
		(
			testunitcount -
			(select COUNT(*) 
			from TestUnits as tu
				INNER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			where dtl.OutTime IS null and tu.BatchID = b.ID)
		) as HasUnitsToReturnToRequestor,
		(CASE WHEN WILocation IS NULL THEN NULL ELSE WILocation END) AS jobWILocation,
		(
			select AssignedTo 
			from TaskAssignments as ta
				--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
				INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=TestStageName 
				--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
				INNER JOIN Jobs j ON j.ID = ts.JobID AND j.JobName = JobName
			where ta.BatchID = b.ID and ta.Active=1
		) as ActiveTaskAssignee, CONVERT(BIT,0) AS HasBatchSpecificExceptions, AccessoryGroupID,ProductTypeID, TestCenterLocationID
		
	FROM
	(
		SELECT DISTINCT b.ID, 
			b.QRANumber, 
			b.Comment,
			b.RequestPurpose, 
			b.Priority,
			b.TestStageName, 
			b.BatchStatus, 
			p.ProductGroupName, 
			b.ProductTypeID,
			b.AccessoryGroupID,
			l.[Values] AS AccessoryGroupName,
			l2.[Values] AS ProductType,
			l3.[Values] AS TestCenterLocation,
			p.ID as ProductID,
			b.JobName, 
			b.LastUser, 
			b.TestCenterLocationID,
			b.ConcurrencyID,
			(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
			b.TestStageCompletionStatus,
			j.WILocation,
			b.RQID,
			(select count(*) from testunits where testunits.batchid = b.id) As testunitcount
		FROM Batches AS b 
			INNER JOIN DeviceTrackingLog AS dtl 
			INNER JOIN TestUnits AS tu ON dtl.TestUnitID = tu.ID ON b.id = tu.batchid --batches where there's a tracking log
			inner join Products p on p.ID=b.ProductID
			LEFT OUTER JOIN Jobs j ON j.JobName = b.JobName
			LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID
			LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID
			LEFT OUTER JOIN Lookups l3 ON l3.Type='TestCenter' AND b.TestCenterLocationID=l3.LookupID  
		WHERE b.BatchStatus NOT IN (5,8) AND b.Jobname=@JobName AND dtl.OutTime IS NULL AND dtl.OutUser IS NULL
	)as b
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
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
	DECLARE @FalseBit BIT
	SET @FalseBit = CONVERT(BIT, 0)
	SET @query = ''	
	SET @query2 = ''
	
	SET @query = 'SELECT b.QRANumber, tu.BatchUnitNumber, ts.TestStageName AS TestStageName, rm.MeasurementValue AS MeasurementValue, rm.LowerLimit, rm.UpperLimit, 
		r.ID AS ResultID, b.ID AS BatchID, pd.ProductGroupName, pd.ID AS ProductID
	FROM Relab.Results r WITH(NOLOCK)
		INNER JOIN TestUnits tu WITH(NOLOCK) ON r.TestUnitID=tu.ID
		INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID
		INNER JOIN Relab.ResultsMeasurements rm WITH(NOLOCK) ON r.ID=rm.ResultID
		INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
		LEFT OUTER JOIN Relab.ResultsParameters p WITH(NOLOCK) ON p.ResultMeasurementID=rm.ID
		INNER JOIN Products pd WITH(NOLOCK) ON pd.ID = b.ProductID
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


	SET @query2 += ' AND ISNULL(rm.Archived,0)=' + CONVERT(VARCHAR, @FalseBit) + ' AND rm.PassFail=' + CONVERT(VARCHAR, @FalseBit) + '
	ORDER BY QRANumber, BatchUnitNumber, TestStageName'
	
	print @query
	print @query2
	
	EXEC(@query + @query2)
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Relab].[remispResultsGraph]'
GO
ALTER PROCEDURE Relab.remispResultsGraph @MeasurementTypeID INT, @batchIDs NVARCHAR(MAX), @UnitIDs NVARCHAR(MAX), @TestID INT, @ParameterName NVARCHAR(255)=NULL, @ParameterValue NVARCHAR(250)=NULL, @ShowUpperLowerLimits INT = 1, @Xaxis INT, @PlotValue INT, @IncludeArchived INT = 0, @Stages NVARCHAR(MAX)
AS
BEGIN
	DECLARE @COUNT INT
	DECLARE @LoopValue NVARCHAR(500)
	DECLARE @ID INT
	DECLARE @query VARCHAR(MAX)
	DECLARE @query2 VARCHAR(MAX)
	CREATE TABLE #batches (id INT)
	CREATE TABLE #units (id INT)
	CREATE TABLE #stages (id INT)
	CREATE TABLE #Graph (RowID INT, YAxis NVARCHAR(500), XAxis NVARCHAR(500), LoopValue NVARCHAR(500), LowerLimit NVARCHAR(255), UpperLimit NVARCHAR(255), QRANumber NVARCHAR(11))
	EXEC (@batchIDs)
	EXEC (@UnitIDs)
	EXEC (@Stages)
	SET @query = ''	
	SET @query2 = ''
	SELECT @COUNT = COUNT(*) FROM #batches
	
	/*@Xaxis
	Units: 0
	Stages: 1
	Parameter: 2
	*/
	/*@PlotValue
	Units: 0
	Stages: 1
	*/

	IF (@Xaxis=0)
	BEGIN
		SET @query = 'INSERT INTO #Graph SELECT ROW_NUMBER() OVER (ORDER BY rm.MeasurementValue) AS RowID, rm.MeasurementValue AS YAxis, 
		CASE WHEN '''+ ISNULL(@ParameterName,'')+''' = '''' THEN CONVERT(VARCHAR,tu.BatchUnitNumber) 
		WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN CONVERT(VARCHAR,tu.BatchUnitNumber) 
		ELSE CONVERT(VARCHAR,tu.BatchUnitNumber) +'': '' + Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' = '''' THEN ''V'' ELSE ''N'' END) END AS XAxis, 
		' + CASE WHEN @IncludeArchived = 1 THEN ' CASE WHEN ' + CONVERT(VARCHAR, @COUNT) + ' > 1 THEN Batches.QRANumber + '' '' ELSE '''' END + SUBSTRING(j.JobName, 0, CHARINDEX('' '', j.Jobname, 0)) + '' '' + ts.TestStageName + convert(varchar,rm.ReTestNum) ' 
		ELSE ' CASE WHEN ' + CONVERT(VARCHAR, @COUNT) + ' > 1 THEN Batches.QRANumber + '' '' ELSE '''' END + SUBSTRING(j.JobName, 0, CHARINDEX('' '', j.Jobname, 0)) + '' '' + ts.TestStageName ' END + ' AS LoopValue, 
		rm.LowerLimit, rm.UpperLimit, Batches.QRANumber '
	END
	ELSE IF (@Xaxis=1)
	BEGIN
		SET @query = 'INSERT INTO #Graph SELECT ROW_NUMBER() OVER (ORDER BY rm.MeasurementValue) AS RowID, rm.MeasurementValue AS YAxis, 
		CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' = '''' THEN SUBSTRING(j.JobName, 0, CHARINDEX('' '', j.Jobname, 0)) + '' '' + CONVERT(VARCHAR,ts.TestStageName) ELSE SUBSTRING(j.JobName, 0, CHARINDEX('' '', j.Jobname, 0)) + '' '' + CONVERT(VARCHAR,ts.TestStageName) +'': '' + ISNULL(Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' = '''' THEN ''V'' ELSE ''N'' END), '''') END AS XAxis, 
		' + CASE WHEN @IncludeArchived = 1 THEN ' convert(varchar,tu.BatchUnitNumber) + convert(varchar,rm.ReTestNum) ' ELSE ' convert(varchar,tu.BatchUnitNumber) ' END + ' AS LoopValue, 
		rm.LowerLimit, rm.UpperLimit, Batches.QRANumber '
	END
	ELSE IF (@Xaxis=2 AND @PlotValue = 1)
	BEGIN
		SET @query = 'INSERT INTO #Graph SELECT ROW_NUMBER() OVER (ORDER BY rm.MeasurementValue) AS RowID, rm.MeasurementValue AS YAxis,
		SUBSTRING(j.JobName, 0, CHARINDEX('' '', j.Jobname, 0)) + '' '' + ts.TestStageName + '':'' + CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN ''V'' ELSE ''N'' END) 
		ELSE Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN ''V'' ELSE ''N'' END) +'': '' + Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' = '''' THEN ''V'' ELSE ''N'' END) END AS XAxis, 
		' + CASE WHEN @IncludeArchived = 1 THEN ' tu.BatchUnitNumber + convert(varchar,rm.ReTestNum) ' ELSE ' tu.BatchUnitNumber ' END + ' AS LoopValue, 
		rm.LowerLimit, rm.UpperLimit, Batches.QRANumber '
	END
	ELSE IF (@Xaxis=2 AND @PlotValue = 0)
	BEGIN
		SET @query = 'INSERT INTO #Graph SELECT ROW_NUMBER() OVER (ORDER BY rm.MeasurementValue) AS RowID, rm.MeasurementValue AS YAxis, 
			convert(varchar,tu.BatchUnitNumber) + '': '' + Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN ''V'' ELSE ''N'' END) AS XAxis, 
			' + CASE WHEN @IncludeArchived = 1 THEN ' SUBSTRING(j.JobName, 0, CHARINDEX('' '', j.Jobname, 0)) + '' '' + ts.TestStageName + convert(varchar,rm.ReTestNum) ' ELSE ' SUBSTRING(j.JobName, 0, CHARINDEX('' '', j.Jobname, 0)) + '' '' + ts.TestStageName ' END + ' AS LoopValue, 
			rm.LowerLimit, rm.UpperLimit, Batches.QRANumber '
	END
	
	SET @query += 'FROM Relab.Results r WITH(NOLOCK)
		INNER JOIN #units u WITH(NOLOCK) ON u.id=r.TestUnitID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON u.ID=tu.ID
		INNER JOIN Relab.ResultsMeasurements rm WITH(NOLOCK) ON r.ID=rm.ResultID
		INNER JOIN #batches b WITH(NOLOCK) ON tu.batchID=b.ID
		INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
		INNER JOIN #stages s WITH(NOLOCK) ON s.ID = ts.ID
		INNER JOIN Batches WITH(NOLOCK) ON Batches.ID=b.ID
		INNER JOIN Jobs j WITH(NOLOCK) ON j.ID=ts.JobID
	WHERE rm.MeasurementTypeID='+CONVERT(VARCHAR,@MeasurementTypeID)+' AND r.TestID='+CONVERT(VARCHAR,@TestID)+' AND MeasurementValue IS NOT NULL '
	
	IF (@Xaxis=2)
		BEGIN
			IF (@ParameterName IS NOT NULL)
				SET @query2 = ' AND (Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterName,'')+''' <> '''' THEN ''N'' ELSE ''V'' END)='''+ ISNULL(@ParameterName,'')+''') '
			
			IF (@ParameterValue IS NOT NULL)
				SET @query2 = ' AND (Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN ''V'' ELSE ''N'' END)='''+ ISNULL(@ParameterValue,'')+''') '
		END
	ELSE
		BEGIN
			IF (@ParameterName IS NOT NULL)
				SET @query2 = ' AND (Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterName,'')+''' <> '''' THEN ''N'' ELSE ''V'' END)='''+ ISNULL(@ParameterName,'')+''') '
			IF (@ParameterValue IS NOT NULL)
				SET @query2 = ' AND (Relab.ResultsParametersNameComma(rm.ID, CASE WHEN '''+ ISNULL(@ParameterValue,'')+''' <> '''' THEN ''V'' ELSE ''N'' END)='''+ ISNULL(@ParameterValue,'')+''') '
		END

	SET @query2 += ' AND (' + CONVERT(varchar, @IncludeArchived) + ' = 1 OR (' + CONVERT(varchar, @IncludeArchived) + ' = 0 AND ISNULL(rm.Archived,0)=0)) 
	ORDER BY LoopValue'
	
	print @query
	print @query2
	
	EXEC(@query + @query2)
	
	UPDATE #Graph SET YAxis=1 WHERE YAxis IN ('True','Pass')
	UPDATE #Graph SET YAxis=0 WHERE YAxis IN ('Fail','False')
		
	select UpperLimit, LowerLimit, COUNT(*) as va
	into #GraphLimits
	FROM #Graph
	GROUP BY UpperLimit, LowerLimit
			
	IF (@@ROWCOUNT = 1)
	BEGIN
		IF (@ShowUpperLowerLimits = 1)
		BEGIN
			IF ((SELECT COUNT(*) FROM #Graph WHERE LowerLimit IS NOT NULL AND ISNUMERIC(LowerLimit)=1 AND LoopValue = (SELECT MIN(LoopValue) FROM #Graph)) > 0)
			BEGIN
				SELECT DISTINCT ROUND(Lowerlimit, 3) AS YAxis, XAxis, (LoopValue + ' Lower Specification Limit') AS LoopValue 
				FROM #Graph
				WHERE LowerLimit IS NOT NULL AND ISNUMERIC(LowerLimit)=1 AND LoopValue = (SELECT MIN(LoopValue) FROM #Graph)
			END
			
			IF ((SELECT COUNT(*) FROM #Graph WHERE Upperlimit IS NOT NULL AND ISNUMERIC(Upperlimit)=1 AND LoopValue = (SELECT MIN(LoopValue) FROM #Graph)) > 0)
			BEGIN
				SELECT DISTINCT ROUND(Upperlimit, 3) AS YAxis, XAxis, (LoopValue + ' Upper Specification Limit') AS LoopValue 
				FROM #Graph
				WHERE Upperlimit IS NOT NULL AND ISNUMERIC(Upperlimit)=1 AND LoopValue = (SELECT MIN(LoopValue) FROM #Graph)
			END
		END	
	END
	
	DECLARE select_cursor CURSOR FOR SELECT DISTINCT LoopValue FROM #Graph
	OPEN select_cursor

	FETCH NEXT FROM select_cursor INTO @LoopValue

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT DISTINCT ROUND(YAxis, 3) AS YAxis, XAxis, LoopValue, LowerLimit, UpperLimit, QRANumber
		FROM #Graph 
		WHERE LoopValue=@LoopValue AND ISNUMERIC(YAxis)=1 
		ORDER BY 2
		
		FETCH NEXT FROM select_cursor INTO @LoopValue
	END
	
	CLOSE select_cursor
	DEALLOCATE select_cursor
	
	DROP TABLE #Graph
	DROP TABLE #batches
	DROP TABLE #units
	DROP TABLE #stages
	DROP TABLE #GraphLimits
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering permissions on [dbo].[remispDeviceTrackingLogDeleteSingleItem]'
GO
GRANT EXECUTE ON  [dbo].[remispDeviceTrackingLogDeleteSingleItem] TO [remi]
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