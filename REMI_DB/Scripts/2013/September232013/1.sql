/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        CI0000001593275.REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 9/18/2013 8:50:43 AM

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
PRINT N'Dropping [dbo].[remispSetProductGroupRFBand]'
GO
DROP PROCEDURE [dbo].[remispSetProductGroupRFBand]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Dropping [dbo].[remispTestRecordsSearchFor]'
GO
DROP PROCEDURE [dbo].[remispTestRecordsSearchFor]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestRecordsInsertUpdateSingleItem]'
GO
ALTER PROCEDURE [dbo].[remispTestRecordsInsertUpdateSingleItem]
	@ID int OUTPUT,	
	@TestUnitID int,
	@TestStageName nvarchar(400),
	@JobName nvarchar(400),
	@TestName nvarchar(400),
	@FailDocRQID int = null,
	@Status int,
	@ResultSource int = null,
	@FailDocNumber nvarchar(500) = null,
	@RelabVersion int,	
	@Comment nvarchar(1000)=null,
	@ConcurrencyID rowversion OUTPUT,
	@LastUser nvarchar(255),
	@TestID INT = NULL,
	@TestStageID INT = NULL
AS
BEGIN
	DECLARE @JobID INT
	DECLARE @ReturnValue INT
	
	IF (@ID is null or @ID <=0 ) --no dupes allowed here!
	BEGIN
		SET @ID = (SELECT ID FROM TestRecords WITH(NOLOCK) WHERE TestStageName = @TestStageName AND JobName = @JobName AND testname=@TestName AND testunitid=@TestUnitID)
	END
	
	if (@TestID is null and @TestName is not null)
	begin
		SELECT @TestID=ID FROM Tests WITH(NOLOCK) WHERE TestName=@TestName
	END

	if (@TestStageID is null and @TestStageName is not null)
	begin
		SELECT @JobID=ID FROM Jobs WITH(NOLOCK) WHERE JobName=@JobName
		SELECT @TestStageID=ID FROM TestStages WITH(NOLOCK) WHERE JobID=@JobID AND TestStageName=@TestStageName
	END

	IF (@ID IS NULL) -- New Item
	BEGIN
		INSERT INTO TestRecords (TestUnitID, Status, FailDocNumber, TestStageName, JobName, TestName, RelabVersion, LastUser, Comment,
			ResultSource, FailDocRQID, TestID, TestStageID)
		VALUES (@TestUnitID, @Status, @FailDocNumber, @TestStageName, @JobName, @TestName, @RelabVersion, @lastUser, @Comment,
			@ResultSource, @FailDocRQID, @TestID, @TestStageID)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE -- Exisiting Item
	BEGIN
		UPDATE TestRecords 
		SET TestUnitID = @TestUnitID, 
			Status = @Status, 
			FailDocNumber = @FailDocNumber,
			TestStageName = @TestStageName,
			JobName = @JobName,
			TestName = @TestName,
			RelabVersion = @RelabVersion,
			lastuser = @LastUser,
			Comment = @Comment,
			ResultSource = @ResultSource,
			FailDocRQID = @FailDocRQID,
			TestID=@TestID,
			TestStageID=@TestStageID
		WHERE ID = @ID AND ConcurrencyID = @ConcurrencyID

		SELECT @ReturnValue = @ID
	END

	SET @ConcurrencyID = (SELECT ConcurrencyID FROM TestRecords WHERE ID = @ReturnValue)
	SET @ID = @ReturnValue
	
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
PRINT N'Altering [dbo].[remispTestExceptionsGetTestUnitTable]'
GO
ALTER PROCEDURE [dbo].[remispTestExceptionsGetTestUnitTable]
/*	'===============================================================
	'   NAME:                	remispTestExceptionsGetTestUnitTable
	'   DATE CREATED:       	09 Oct 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves a list of test names / boolean
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/
	@QRANumber nvarchar(11) = null,
	@BatchunitNumber int = null,
	@TestStageName nvarchar(400) = null,
	@TestStageID INT = NULL
AS
	declare @pid int
	declare @testunitid int
	declare @TestStageType int
		
	--get the test unit id
	if @QRANumber is not null and @BatchUnitNumber is not null
	begin
		set @testUnitID = (select tu.Id from TestUnits tu WITH(NOLOCK) INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID where b.QRANumber = @QRANumber AND tu.batchunitnumber = @Batchunitnumber)
		PRINT 'TestUnitID: ' + CONVERT(NVARCHAR, ISNULL(@testUnitID,''))
	end
		
	--get the product group name for the test unit's batch
	set @pid= (select p.ID from Batches as b, TestUnits as tu, products p where b.id = tu.BatchID and tu.ID= @testunitid and p.id=b.productID)
	PRINT 'ProductID: ' + CONVERT(NVARCHAR, ISNULL(@pid,''))

	if (@TestStageID is null and @TestStageName is not null)
	begin
		set @TestStageID = (select ts.ID from Teststages as ts,jobs as j, Batches as b, TestUnits as tu
		where ts.TestStageName = @TestStageName and ts.JobID = j.id 
			and j.jobname = b.jobname 
			and tu.ID = @testunitid
			and b.ID = tu.BatchID)
	END

	PRINT 'TestStageID: ' + CONVERT(NVARCHAR, ISNULL(@TestStageID,''))

	--set up the required tables
	declare @testUnitExemptions table (exTestName nvarchar(255))

	insert into @testunitexemptions
	SELECT DISTINCT TestName
	FROM vw_ExceptionsPivoted as pvt
		INNER JOIN Tests t WITH(NOLOCK) ON pvt.Test = t.ID
	where (
			(pvt.TestUnitID = @TestUnitID and pvt.ProductID is null) 
			or 
			(pvt.TestUnitID is null and pvt.ProductID = @pid)
		  ) and( pvt.TestStageID = @TestStageID or @TestStageID is null)

	SELECT TestName AS Name, (CASE WHEN (SELECT exTestName FROM @testUnitExemptions WHERE exTestName = t.TestName) IS NOT NULL THEN 'True' ELSE 'False' END ) AS TestUnitException
	FROM Tests t WITH(NOLOCK), teststages ts WITH(NOLOCK)
	WHERE --where teststage type is environmental, the test name and test stage id's match
	ts.id = @TeststageID  and ((ts.TestStageType = 2  and ts.TestID = t.id) or
	--test stage type = incoming eval and test type is parametric
	( ts.TestStageType = 3 and t.testtype = 3) or
	--OR where test stage type is parametric and test type is also parametric (ie get all the measurment tests)
	(( ts.TeststageType = 1 ) and t.TestType = 1))
	ORDER BY TestName
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestRecordsSelectOne]'
GO
ALTER PROCEDURE [dbo].[remispTestRecordsSelectOne] @ID int= null
AS
BEGIN	
	SELECT tr.Comment,tr.ConcurrencyID,tr.FailDocNumber,tr.ID,tr.JobName,tr.LastUser,tr.ResultSource,tr.RelabVersion,tr.Status,tr.TestName,tr.TestStageName,tr.TestUnitID, b.QRANumber, tu.BatchUnitNumber
	,(Select sum(datediff(MINUTE,dtl.intime,(case when (dtl.OutTime IS null) then GETUTCDATE() else dtl.outtime  end ))) 
	 from Testrecordsxtrackinglogs as trXtl, DeviceTrackingLog as dtl where trXtl.TestRecordID = tr.id and dtl.ID = trXtl.TrackingLogID
	) as TotalTestTimeMinutes
	,(select COUNT (*) as NumberOfTests from Testrecordsxtrackinglogs as trXtl, DeviceTrackingLog as dtl where trXtl.TestRecordID = tr.id and dtl.ID = trXtl.TrackingLogID
	) as NumberOfTests, tr.TestID, tr.TestStageID
	FROM TestRecords tr WITH(NOLOCK)
		INNER JOIN testunits tu WITH(NOLOCK) ON tu.ID=tr.TestUnitID
		INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
	WHERE tr.ID = @id
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTaskAssignmentGetListForBatch]'
GO
ALTER PROCEDURE [dbo].[remispTaskAssignmentGetListForBatch] @qranumber nvarchar(255)
AS
BEGIN
	SELECT ts.ID as TaskID, ts.TestStageName as TaskName, ta.AssignedTo, ta.AssignedBy, ta.AssignedOn, ta.BatchID, b.ID
	FROM TestStages ts
		INNER JOIN jobs j ON j.id = ts.JobID
		INNER JOIN Batches b ON b.JobName = j.JobName
		LEFT OUTER JOIN TaskAssignments ta ON ta.TaskID = ts.id AND ta.Active = 1 AND ta.BatchID = b.ID
	WHERE b.QRANumber = @qranumber
	ORDER BY ts.ProcessOrder ASC
	
	SELECT * FROM Batches WHERE QRANumber = @qranumber
END
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
					AND (ISNUMERIC(MeasurementValue) > 0 OR MeasurementValue IN ('Fail', 'False', 'Pass', 'True'))
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
PRINT N'Altering [dbo].[remispTestExceptionsGetBatchExceptions]'
GO
ALTER procedure [dbo].[remispTestExceptionsGetBatchExceptions] @qraNumber nvarchar(11) = null
AS
--get any for the product
select distinct pvt.id, null as batchunitnumber, pvt.ReasonForRequest,p.ProductGroupName,b.JobName, ts.teststagename
, t.TestName, (SELECT TOP 1 LastUser FROM TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS LastUser,
(SELECT TOP 1 ConcurrencyID FROM TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS ConcurrencyID,
pvt.TestStageID, pvt.TestUnitID, pvt.ProductTypeID, pvt.AccessoryGroupID, pvt.ProductID,
l2.[Values] As AccessoryGroupName, l.[Values] As ProductType
FROM vw_ExceptionsPivoted as pvt
	LEFT OUTER JOIN Tests t WITH(NOLOCK) ON pvt.Test = t.ID
	LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND l.LookupID=pvt.ProductTypeID
	LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.Type='AccessoryType' AND l2.LookupID=pvt.AccessoryGroupID
	LEFT OUTER JOIN Products p WITH(NOLOCK) ON p.ID=pvt.ProductID
	, Batches as b, teststages ts WITH(NOLOCK), Jobs j WITH(NOLOCK)
where b.QRANumber = @qranumber 
	and (ts.JobID = j.ID or j.ID is null)
	and (b.JobName = j.JobName or j.JobName is null)
	and pvt.TestUnitID is null
	and (ts.id = pvt.teststageid or pvt.TestStageID is null)
	and 
	(
		(pvt.ProductID = b.ProductID and pvt.ReasonForRequest is null) 
		or 
		(pvt.ProductID = b.ProductID and pvt.ReasonForRequest = b.RequestPurpose)
		or
		(pvt.ProductID is null and pvt.ReasonForRequest = b.RequestPurpose)
		or
		(pvt.ProductID is null and pvt.ReasonForRequest is null)
	)
	AND
	(
		(pvt.AccessoryGroupID IS NULL)
		OR
		(pvt.AccessoryGroupID IS NOT NULL AND pvt.AccessoryGroupID = b.AccessoryGroupID)
	)
	AND
	(
		(pvt.ProductTypeID IS NULL)
		OR
		(pvt.ProductTypeID IS NOT NULL AND pvt.ProductTypeID = b.ProductTypeID)
	)

union all

--then get any for the test units.
select distinct pvt.id, tu.BatchUnitNumber, pvt.ReasonForRequest,p.ProductGroupName,b.JobName, 
(select teststagename from teststages WITH(NOLOCK) where teststages.id =pvt.TestStageid) as teststagename, t.testname,
(SELECT TOP 1 LastUser FROM TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS LastUser,
(SELECT TOP 1 ConcurrencyID FROM TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS ConcurrencyID
, pvt.TestStageID, pvt.TestUnitID, pvt.ProductTypeID, pvt.AccessoryGroupID,pvt.ProductID,
l2.[Values] As AccessoryGroupName, l.[Values] As ProductType
FROM vw_ExceptionsPivoted as pvt
	LEFT OUTER JOIN Tests t WITH(NOLOCK) ON pvt.Test = t.ID
	LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND l.LookupID=pvt.ProductTypeID
	LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.Type='AccessoryType' AND l2.LookupID=pvt.AccessoryGroupID
	LEFT OUTER JOIN Products p WITH(NOLOCK) ON p.ID=pvt.ProductID
	, Batches b WITH(NOLOCK), testunits tu WITH(NOLOCK) 
WHERE b.QRANumber = @qranumber and tu.batchid = b.id and pvt.TestUnitID = tu.id
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestUnitsAvailable]'
GO
ALTER PROCEDURE [dbo].[remispTestUnitsAvailable] @QRANumber NVARCHAR(11)
AS
BEGIN
	SELECT tu.BatchUnitNumber
	FROM Batches b WITH(NOLOCK)
		INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID=tu.BatchID
	WHERE QRANumber=@QRANumber
		AND tu.ID NOT IN (SELECT dtl.TestUnitID
					FROM DeviceTrackingLog dtl WITH(NOLOCK)
						INNER JOIN TrackingLocations tl WITH(NOLOCK) ON dtl.TrackingLocationID=tl.ID AND tl.ID NOT IN (25,81)
					WHERE TestUnitID = 214734 AND OutTime IS NULL)
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestExceptionsGetProductExceptions]'
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
	(select jobname from jobs WITH(NOLOCK),TestStages WITH(NOLOCK) where teststages.id =pvt.TestStageid and Jobs.ID = TestStages.jobid) as jobname, 
	(select teststagename from teststages WITH(NOLOCK) where teststages.id =pvt.TestStageid) as teststagename, 
	t.TestName,pvt.TestStageID, pvt.TestUnitID,
	(select top 1 LastUser from TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS LastUser,
	pvt.ProductTypeID, pvt.AccessoryGroupID, pvt.ProductID, l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, t.ID AS TestID
	FROM vw_ExceptionsPivoted as pvt
		LEFT OUTER JOIN Tests t WITH(NOLOCK) ON pvt.Test = t.ID
		LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND l.LookupID=pvt.ProductTypeID
		LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.Type='AccessoryType' AND l2.LookupID=pvt.AccessoryGroupID
		LEFT OUTER JOIN Products p WITH(NOLOCK) ON p.ID=pvt.ProductID
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
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestExceptionsDelete]'
GO
ALTER PROCEDURE [dbo].[remispTestExceptionsDelete] @id int, @lastuser nvarchar(255)
AS
BEGIN	
	update TestExceptions set LastUser = @lastuser where ID= @id

	delete from TestExceptions where TestExceptions.ID = @id
	
	return @id
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestExceptionsInsertTestUnitException]'
GO
ALTER PROCEDURE [dbo].[remispTestExceptionsInsertTestUnitException]
/*	'===============================================================
	'   NAME:                	remispTestExceptionsInsertTestUnitException
	'   DATE CREATED:       	22 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Creates an item in a table: TestUnitTestExceptions
	'   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
	@QRANumber nvarchar(11),
	@BatchUnitNumber int,
	@TestName nvarchar(400) = null,
	@TestStageName nvarchar(400) = null,
	@LastUser nvarchar(255),
	@TestStageID int = null,
	@testunitid int = null,
	@ProductTypeID INT = NULL,
	@AccessoryGroupID INT = NULL,
	@TestID INT = NULL
AS		
	DECLARE @ReturnValue int	
	
	--get the test unit id
	if @testunitid is  null and (@QRANumber is not null and @BatchUnitNumber is not null)
	begin
		set @testUnitID = (select tu.Id from TestUnits tu WITH(NOLOCK) INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID where b.QRANumber = @QRANumber AND tu.batchunitnumber = @Batchunitnumber)

		PRINT 'TestUnitID: ' + CONVERT(NVARCHAR, ISNULL(@testUnitID,''))
	end	
		
	--Get the test stage id
	if (@teststageid is null and @TestStageName is not null)
	begin
		set @TestStageID = (select ts.ID from TestStages as ts, TestUnits as tu,Jobs as j, Batches as b 
		where tu.ID=@testUnitID and b.ID=tu.BatchID and ts.TestStageName = @TestStageName and ts.JobID = j.ID and
		j.JobName = b.jobname)
		
		PRINT 'TestStageID: ' + CONVERT(NVARCHAR, ISNULL(@TestStageID,''))
	end 
	
	set @ReturnValue = (SELECT DISTINCT pvt.ID
	FROM vw_ExceptionsPivoted as pvt
		LEFT OUTER JOIN Tests t WITH(NOLOCK) ON pvt.Test = t.ID
	where (testunitid = @testunitid)
	and 
	(
		TestStageID = @TestStageID 
		or
		(@TestStageID is null and TestStageID is null)
	)
	and 
	(
		(t.TestName = @testname AND @TestID IS NULL)
		or 
		(@TestName is null and TestName is null AND @TestID IS NULL)
		OR
		(t.ID = @TestID AND @TestID IS NOT NULL)
	)
	)
	
	IF (@ReturnValue IS NULL) -- if it doesnt already exist then add it
	BEGIN
		PRINT 'INSERTING'
		DECLARE @ID INT
		SELECT @ID = MAX(ID)+1 FROM TestExceptions
		PRINT @ID
		
		IF (@TestID IS NOT NULL)
		BEGIN
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 5, @TestID, @LastUser)
		END
		ELSE IF (@TestName IS NOT NULL)
		BEGIN
			PRINT 'Inserting TestName'
			DECLARE @tID INT
			IF ((SELECT COUNT(*) FROM Tests WITH(NOLOCK) WHERE TestName=@TestName) = 1)
			BEGIN
				SELECT @tID = ID FROM Tests WITH(NOLOCK) WHERE TestName=@TestName
				INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 5, @tID, @LastUser)
			END
			ELSE
			BEGIN
				IF (@TestStageID IS NOT NULL AND EXISTS (SELECT TestID FROM TestStages WITH(NOLOCK) WHERE ID=@TestStageID AND TestID IS NOT NULL))
				BEGIN
					SET @tID = (SELECT TestID FROM TestStages WITH(NOLOCK) WHERE ID=@TestStageID AND TestID IS NOT NULL)
					INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 5, @tID, @LastUser)
				END
			END
		END

		IF (@TestStageID IS NOT NULL)
		BEGIN
			PRINT 'Inserting TestStageID'
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 4, @TestStageID, @LastUser)
		END
		
		IF (@TestUnitID IS NOT NULL)
		BEGIN
			PRINT 'Inserting TestUnitID'
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 3, @TestUnitID, @LastUser)
		END

		IF (@ProductTypeID IS NOT NULL AND @ProductTypeID > 0)
		BEGIN
			PRINT 'Inserting ProductType'
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 6, @ProductTypeID, @LastUser)
		END

		IF (@AccessoryGroupID IS NOT NULL AND @AccessoryGroupID > 0)
		BEGIN
			PRINT 'Inserting AccessoryGroupName'
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 7, @AccessoryGroupID, @LastUser)
		END

		SET @ReturnValue = @ID		
	ENd
		
	IF (@@ERROR != 0)
	BEGIN
		RETURN -1
	END
	ELSE
	BEGIN
		RETURN @returnvalue
	END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestExceptionsInsertProductGroupException]'
GO
ALTER PROCEDURE [dbo].[remispTestExceptionsInsertProductGroupException]
/*	'===============================================================
	'   NAME:                	remispTestExceptionsInsertProductGroupException
	'   DATE CREATED:       	22 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Creates an item in a table: TestUnitTestExceptions
	'   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
	@ReasonForRequest int = null,
	@TestName nvarchar(400) = null,
	@TestStageName nvarchar(400) = null,
	@JobName nvarchar(400)=null,
	@ProductID INT=null,
	@LastUser nvarchar(255),
	@ProductTypeID INT = NULL,
	@AccessoryGroupID INT = NULL,
	@TestStageID int = null,
	@TestID INT = null
AS		
	DECLARE @ReturnValue int
	declare @testUnitID int
	declare @ValidInputParams int = 1
	
	if (@teststageid is null and @TestStageName is not null)
	begin
		set @TestStageID = (select ts.id from TestStages as ts, Jobs as j where j.JobName = @JobName and ts.JobID = j.ID and ts.TestStageName = @TestStageName)
	end

	PRINT 'TestStageID: ' + CONVERT(NVARCHAR, ISNULL(@TestStageID, ''))
		
	--test if item exists in db already

	set @ReturnValue = (SELECT DISTINCT pvt.ID
	FROM vw_ExceptionsPivoted as pvt
		LEFT OUTER JOIN Tests t WITH(NOLOCK) ON pvt.Test = t.ID
	where (ReasonForRequest = @ReasonForRequest)
		and (TestStageID = @TestStageID)
		and (testname = @testname OR t.ID = @TestID)
		and (ProductID = @ProductID))

	IF (@ReturnValue IS NULL) -- if it doesnt already exist then add it
	BEGIN
		PRINT 'INSERTING'
		DECLARE @ID INT
		SELECT @ID = MAX(ID)+1 FROM TestExceptions
		PRINT @ID

		IF (@TestID IS NOT NULL)
		BEGIN
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 5, @TestID, @LastUser)
		END
		ELSE IF (@TestName IS NOT NULL)
		BEGIN
			PRINT 'Inserting TEST'
			DECLARE @tID INT
			IF ((SELECT COUNT(*) FROM Tests WITH(NOLOCK) WHERE TestName=@TestName) = 1)
			BEGIN
				SELECT @tID = ID FROM Tests WITH(NOLOCK) WHERE TestName=@TestName
				INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 5, @tID, @LastUser)
			END
			ELSE
			BEGIN
				IF (@TestStageID IS NOT NULL AND EXISTS (SELECT TestID FROM TestStages WITH(NOLOCK) WHERE ID=@TestStageID AND TestID IS NOT NULL))
				BEGIN
					SET @tID = (SELECT TestID FROM TestStages WITH(NOLOCK) WHERE ID=@TestStageID AND TestID IS NOT NULL)
					INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 5, @tID, @LastUser)
				END
			END
		END

		IF (@TestStageID IS NOT NULL)
		BEGIN
			PRINT 'Inserting TestStage'
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 4, @TestStageID, @LastUser)
		END

		IF (@ReasonForRequest IS NOT NULL)
		BEGIN
			PRINT 'Inserting ReasonForRequest'
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 2, @ReasonForRequest, @LastUser)
		END

		IF (@ProductID > 0)
		BEGIN
			PRINT 'Inserting ProductID'
			DECLARE @LookupID INT
			SELECT @LookupID=LookupID FROM Lookups WHERE Type='Exceptions' AND [Values]='ProductID'
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, @LookupID, @ProductID, @LastUser)
		END

		IF (@ProductTypeID IS NOT NULL AND @ProductTypeID > 0)
		BEGIN
			PRINT 'Inserting ProductType'
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 6, @ProductTypeID, @LastUser)
		END

		IF (@AccessoryGroupID IS NOT NULL AND @AccessoryGroupID > 0)
		BEGIN
			PRINT 'Inserting AccessoryGroupName'
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 7, @AccessoryGroupID, @LastUser)
		END		

		SET @ReturnValue = @ID
	END
	
	IF (@@ERROR != 0)
	BEGIN
		RETURN -1
	END
	ELSE
	BEGIN
		RETURN @ReturnValue
	END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestExceptionsGetBatchOnlyExceptions]'
GO
ALTER procedure [dbo].[remispTestExceptionsGetBatchOnlyExceptions] @qraNumber nvarchar(11) = null
AS
select distinct pvt.id, null as batchunitnumber, pvt.ReasonForRequest,p.ProductGroupName,b.JobName, ts.teststagename
, t.testname, (SELECT TOP 1 LastUser FROM TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS LastUser,
pvt.TestStageID, pvt.TestUnitID ,
pvt.ProductTypeID, pvt.AccessoryGroupID, pvt.ProductID, l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, t.ID AS TestID
FROM vw_ExceptionsPivoted as pvt
	LEFT OUTER JOIN Tests t WITH(NOLOCK) ON pvt.Test = t.ID
	LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND l.LookupID=pvt.ProductTypeID
	LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.Type='AccessoryType' AND l2.LookupID=pvt.AccessoryGroupID
	LEFT OUTER JOIN Products p WITH(NOLOCK) ON p.ID=pvt.ProductID
	, Batches as b, teststages ts WITH(NOLOCK), Jobs j WITH(NOLOCK) 
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
(select teststagename from teststages WITH(NOLOCK) where teststages.id =pvt.TestStageid) as teststagename, t.testname,
(SELECT TOP 1 LastUser FROM TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS LastUser,
pvt.TestStageID, pvt.TestUnitID,pvt.ProductTypeID, pvt.AccessoryGroupID, pvt.ProductID, l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, t.ID AS TestID
FROM vw_ExceptionsPivoted as pvt
	LEFT OUTER JOIN Tests t WITH(NOLOCK) ON pvt.Test = t.ID
	LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND l.LookupID=pvt.ProductTypeID
	LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.Type='AccessoryType' AND l2.LookupID=pvt.AccessoryGroupID
	LEFT OUTER JOIN Products p WITH(NOLOCK) ON p.ID=pvt.ProductID
	INNER JOIN testunits tu WITH(NOLOCK) ON tu.ID=pvt.TestUnitID
	INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID
where b.QRANumber = @qranumber and tu.batchid = b.id and pvt.TestUnitID = tu.id
order by pvt.TestUnitID desc,TestName
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestExceptionsGetProductGroupTable]'
GO
ALTER PROCEDURE [dbo].[remispTestExceptionsGetProductGroupTable]
/*	'===============================================================
'   NAME:                	remispTestExceptionsGetProductGroupTable
'   DATE CREATED:       	09 Oct 2009
'   CREATED BY:          	Darragh O'Riordan
'   FUNCTION:            	Retrieves a list of test names / boolean
'   VERSION: 1           
'   COMMENTS:            
'   MODIFIED ON:         
'   MODIFIED BY:         
'   REASON MODIFICATION: 
'===============================================================*/
	@ProductID INT
AS
	declare @testUnitExemptions table (exTestName nvarchar(255), ExceptionID int)
	
	insert into @testunitexemptions
	SELECT TestName, pvt.ID
	FROM vw_ExceptionsPivoted as pvt
		INNER JOIN Tests t WITH(NOLOCK) ON pvt.Test = t.ID
	where [ProductID]=@ProductID AND [TestStageID] IS NULL AND [Test] IS NOT NULL
	
	SELECT TestName AS Name, (CASE WHEN (SELECT TOP 1 ExceptionID FROM @testUnitExemptions WHERE exTestName = t.TestName) IS NOT NULL THEN 'True' ELSE 'False' END ) AS TestUnitException
	FROM Tests t WITH(NOLOCK)
	WHERE t.TestType = 1
	ORDER BY TestName
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestsAddTrackingLocationForTest]'
GO
ALTER PROCEDURE [dbo].[remispTestsAddTrackingLocationForTest] @TestID int, @TrackingLocationTypeID int
AS
declare @ID int

Set @id = (select ID from TrackingLocationsForTests where testid = @TestID and TrackingLocationtypeID = @TrackingLocationtypeID)
	
	DECLARE @ReturnValue int

	IF (@ID IS NULL) -- New Item so insert it
	BEGIN
		INSERT INTO TrackingLocationsForTests (TestID, TrackingLocationtypeid)
		VALUES (@TestID, @TrackingLocationtypeID)

		SELECT @ReturnValue = SCOPE_IDENTITY()
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
PRINT N'Altering [dbo].[remispTestSelectApplicableTrackingLocationTypes]'
GO
ALTER PROCEDURE [dbo].[remispTestSelectApplicableTrackingLocationTypes] @TestID int
AS
BEGIN
	SELECT tlt.id, tlt.TrackingLocationTypeName    
	FROM trackinglocationtypes as tlt, TrackingLocationsForTests as tlfort
	WHERE tlfort.testid = @testid and tlt.ID = tlfort.TrackingLocationtypeID
	ORDER BY tlt.TrackingLocationTypeName asc
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispRolePermissions]'
GO
ALTER PROCEDURE [dbo].[remispRolePermissions]
AS
BEGIN
	DECLARE @rows VARCHAR(8000)
	DECLARE @query VARCHAR(4000)
	SELECT @rows=  ISNULL(STUFF(
	( 
	SELECT DISTINCT '],[' + r.RoleName
	FROM  dbo.aspnet_Roles r WITH(NOLOCK)
	ORDER BY '],[' +  r.RoleName
	FOR XML PATH('')), 1, 2, '') + ']','[na]')


	SET @query = '
		SELECT *
		FROM
		(
			SELECT CASE WHEN pr.PermissionID IS NOT NULL THEN 1 ELSE NULL END As Row, p.Permission, r.RoleName
			FROM dbo.aspnet_Roles r WITH(NOLOCK)
				LEFT OUTER JOIN dbo.aspnet_PermissionsInRoles pr WITH(NOLOCK) on r.RoleId=pr.RoleID
				INNER JOIN dbo.aspnet_Permissions p WITH(NOLOCK) on pr.PermissionID=p.PermissionID
			WHERE p.Permission IS NOT NULL
		)r
		PIVOT 
		(
			MAX(row) 
			FOR RoleName 
				IN ('+@rows+')
		) AS pvt'
	EXECUTE (@query)
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering permissions on [dbo].[remispTestsAddTrackingLocationForTest]'
GO
GRANT EXECUTE ON  [dbo].[remispTestsAddTrackingLocationForTest] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispTestSelectApplicableTrackingLocationTypes]'
GO
GRANT EXECUTE ON  [dbo].[remispTestSelectApplicableTrackingLocationTypes] TO [remi]
GO
ALTER PROCEDURE Relab.remispGetTestsByBatches @BatchIDs NVARCHAR(MAX)
AS
BEGIN
	CREATE Table #batches(id int) 
	EXEC(@BatchIDs)
	DECLARE @Count INT
	
	SELECT @Count = COUNT(*) FROM #batches WITH(NOLOCK)
	
	SELECT DISTINCT TestID, tname
	FROM dbo.vw_GetTaskInfo i WITH(NOLOCK)
	WHERE i.processorder > -1 AND (i.Testtype=1 or i.TestID=1029) AND i.BatchID IN (SELECT id FROM #batches)
	GROUP BY TestID, tname
	HAVING COUNT(DISTINCT BatchID) >= @Count
	ORDER BY tname
	
	DROP TABLE #batches
END
GO
GRANT EXECUTE ON Relab.remispGetTestsByBatches TO REMI
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