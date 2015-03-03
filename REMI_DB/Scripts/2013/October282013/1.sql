/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        CI0000001593275.REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 10/22/2013 1:49:00 PM

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
PRINT N'Altering [dbo].[vw_ExceptionsPivoted]'
GO
ALTER VIEW [dbo].[vw_ExceptionsPivoted]
AS
SELECT pvt.ID, pvt.[41] AS ProductID, pvt.[2] AS ReasonForRequest, pvt.[3] AS TestUnitID, pvt.[4] AS TestStageID, pvt.[5] AS Test, pvt.[6] AS ProductTypeID, pvt.[7] AS AccessoryGroupID,
	pvt.[3516] AS TestCenterID, pvt.[3517] As IsMQual
FROM 
(SELECT ID, Value, TestExceptions.LookupID as Look
FROM TestExceptions) te
PIVOT (MAX(Value) FOR Look IN ([41],[2],[3],[4],[5],[6],[7],[3516],[3517])) as pvt
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
l2.[Values] As AccessoryGroupName, l.[Values] As ProductType, pvt.IsMQual, l3.[Values] As TestCenter, l3.[LookupID] As TestCenterID
FROM vw_ExceptionsPivoted as pvt
	LEFT OUTER JOIN Tests t WITH(NOLOCK) ON pvt.Test = t.ID
	LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND l.LookupID=pvt.ProductTypeID
	LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.Type='AccessoryType' AND l2.LookupID=pvt.AccessoryGroupID
	LEFT OUTER JOIN Products p WITH(NOLOCK) ON p.ID=pvt.ProductID
	LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.Type='TestCenter' AND l3.LookupID=pvt.TestCenterID
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
	AND
	(
		(pvt.TestCenterID IS NULL)
		OR
		(pvt.TestCenterID IS NOT NULL AND pvt.TestCenterID = b.TestCenterLocationID)
	)
	AND
	(
		(pvt.IsMQual IS NULL)
		OR
		(pvt.IsMQual IS NOT NULL AND pvt.IsMQual = b.IsMQual)
	)

union all

--then get any for the test units.
select distinct pvt.id, tu.BatchUnitNumber, pvt.ReasonForRequest,p.ProductGroupName,b.JobName, 
(select teststagename from teststages WITH(NOLOCK) where teststages.id =pvt.TestStageid) as teststagename, t.testname,
(SELECT TOP 1 LastUser FROM TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS LastUser,
(SELECT TOP 1 ConcurrencyID FROM TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS ConcurrencyID
, pvt.TestStageID, pvt.TestUnitID, pvt.ProductTypeID, pvt.AccessoryGroupID,pvt.ProductID,
l2.[Values] As AccessoryGroupName, l.[Values] As ProductType, pvt.IsMQual, l3.[Values] As TestCenter, l3.[LookupID] As TestCenterID
FROM vw_ExceptionsPivoted as pvt
	LEFT OUTER JOIN Tests t WITH(NOLOCK) ON pvt.Test = t.ID
	LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND l.LookupID=pvt.ProductTypeID
	LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.Type='AccessoryType' AND l2.LookupID=pvt.AccessoryGroupID
	LEFT OUTER JOIN Products p WITH(NOLOCK) ON p.ID=pvt.ProductID
	LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.Type='TestCenter' AND l3.LookupID=pvt.TestCenterID
	, Batches b WITH(NOLOCK), testunits tu WITH(NOLOCK) 
WHERE b.QRANumber = @qranumber and tu.batchid = b.id and pvt.TestUnitID = tu.id
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
	AccessoryGroupID, ProductID, ProductType, AccessoryGroupName, TestID, IsMQual, TestCenter, TestCenterID
from 
(
	select ROW_NUMBER() over (order by p.ProductGroupName desc)as row, pvt.ID, null as batchunitnumber, pvt.[ReasonForRequest], p.ProductGroupName,
	(select jobname from jobs WITH(NOLOCK),TestStages WITH(NOLOCK) where teststages.id =pvt.TestStageid and Jobs.ID = TestStages.jobid) as jobname, 
	(select teststagename from teststages WITH(NOLOCK) where teststages.id =pvt.TestStageid) as teststagename, 
	t.TestName,pvt.TestStageID, pvt.TestUnitID,
	(select top 1 LastUser from TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS LastUser,
	pvt.ProductTypeID, pvt.AccessoryGroupID, pvt.ProductID, l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, t.ID AS TestID,
	pvt.IsMQual, l3.[Values] As TestCenter, l3.[LookupID] As TestCenterID
	FROM vw_ExceptionsPivoted as pvt
		LEFT OUTER JOIN Tests t WITH(NOLOCK) ON pvt.Test = t.ID
		LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND l.LookupID=pvt.ProductTypeID
		LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.Type='AccessoryType' AND l2.LookupID=pvt.AccessoryGroupID
		LEFT OUTER JOIN Products p WITH(NOLOCK) ON p.ID=pvt.ProductID
		LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.Type='TestCenter' AND l3.LookupID=pvt.TestCenterID
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
	@TestID INT = null,
	@TestCenterID INT = NULL,
	@IsMQual BIT  = NULL
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

		IF (@TestCenterID IS NOT NULL AND @TestCenterID > 0)
		BEGIN
			PRINT 'Inserting TestCenterID'
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 3516, @TestCenterID, @LastUser)
		END

		IF (@IsMQual IS NOT NULL)
		BEGIN
			PRINT 'Inserting IsMQual'
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 3517, @IsMQual, @LastUser)
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
pvt.ProductTypeID, pvt.AccessoryGroupID, pvt.ProductID, l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, t.ID AS TestID,
pvt.IsMQual, l3.[Values] As TestCenter, l3.[LookupID] As TestCenterID
FROM vw_ExceptionsPivoted as pvt
	LEFT OUTER JOIN Tests t WITH(NOLOCK) ON pvt.Test = t.ID
	LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND l.LookupID=pvt.ProductTypeID
	LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.Type='AccessoryType' AND l2.LookupID=pvt.AccessoryGroupID
	LEFT OUTER JOIN Products p WITH(NOLOCK) ON p.ID=pvt.ProductID
	LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.Type='TestCenter' AND l3.LookupID=pvt.TestCenterID
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
	AND
	(
		(b.TestCenterLocationID IS NOT NULL AND b.TestCenterLocationID = pvt.TestCenterID)
		OR
		pvt.TestCenterID IS NULL
	)
	AND
	(
		(b.IsMQual IS NOT NULL AND b.IsMQual = pvt.IsMQual)
		OR
		pvt.IsMQual IS NULL
	)

union all

--get any for the test units.
select distinct pvt.id, tu.BatchUnitNumber, pvt.ReasonForRequest, p.ProductGroupName,b.JobName, 
(select teststagename from teststages WITH(NOLOCK) where teststages.id =pvt.TestStageid) as teststagename, t.testname,
(SELECT TOP 1 LastUser FROM TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS LastUser,
pvt.TestStageID, pvt.TestUnitID,pvt.ProductTypeID, pvt.AccessoryGroupID, pvt.ProductID, l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, t.ID AS TestID,
pvt.IsMQual, l3.[Values] As TestCenter, l3.[LookupID] As TestCenterID
FROM vw_ExceptionsPivoted as pvt
	LEFT OUTER JOIN Tests t WITH(NOLOCK) ON pvt.Test = t.ID
	LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND l.LookupID=pvt.ProductTypeID
	LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.Type='AccessoryType' AND l2.LookupID=pvt.AccessoryGroupID
	LEFT OUTER JOIN Products p WITH(NOLOCK) ON p.ID=pvt.ProductID
	INNER JOIN testunits tu WITH(NOLOCK) ON tu.ID=pvt.TestUnitID
	INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID
	LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.Type='TestCenter' AND l3.LookupID=pvt.TestCenterID
where b.QRANumber = @qranumber and tu.batchid = b.id and pvt.TestUnitID = tu.id
order by pvt.TestUnitID desc,TestName
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[vw_GetTaskInfo]'
GO
ALTER VIEW [dbo].[vw_GetTaskInfo]
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
					AND 
					(
						NOT EXISTS 
						(
							SELECT DISTINCT 1
							FROM vw_ExceptionsPivoted as pvt WITH(NOLOCK)
							where pvt.ID IN (SELECT ID FROM TestExceptions WITH(NOLOCK) WHERE LookupID=3 AND Value = tu.ID) AND
							(
								(pvt.TestStageID IS NULL AND pvt.Test = t.ID ) 
								OR 
								(pvt.Test IS NULL AND pvt.TestStageID = ts.id) 
								OR 
								(pvt.TestStageID = ts.id AND pvt.Test = t.ID)
								OR
								(pvt.TestStageID IS NULL AND pvt.Test IS NULL)
							)
						)
					)
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
		WHERE NOT EXISTS 
			(
				SELECT DISTINCT 1
				FROM vw_ExceptionsPivoted as pvt WITH(NOLOCK)
				WHERE pvt.testunitid IS NULL 
					AND (pvt.Test = t.ID OR pvt.Test IS NULL)
					AND (pvt.teststageid IS NULL OR ts.id = pvt.teststageid)
					AND ( 
							(pvt.ProductID = p.ID AND pvt.reasonforrequest IS NULL)
							OR 
							(pvt.ProductID = p.ID AND pvt.reasonforrequest = b.requestpurpose ) 
							OR
							(pvt.ProductID IS NULL AND b.requestpurpose IS NOT NULL AND pvt.reasonforrequest = b.requestpurpose)
							OR
							(pvt.ProductID IS NULL AND pvt.reasonforrequest IS NULL)
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
					AND
						(
							(pvt.TestCenterID IS NULL)
							OR
							(pvt.TestCenterID IS NOT NULL AND pvt.TestCenterID = b.TestCenterLocationID)
						)
					AND
						(
							(pvt.IsMQual IS NULL)
							OR
							(pvt.IsMQual IS NOT NULL AND pvt.IsMQual = b.IsMQual)
						)
			)
	) AS unitData
WHERE TestUnitsForTest IS NOT NULL AND 
	(
		(ISNULL(RecordExists,0) > 0 AND IsArchived = 1 AND ISNULL(TestRecordExists, 0) > 0 AND TestIsArchived = 1)
		OR
		(ISNULL(IsArchived, 0) = 0 AND ISNULL(TestIsArchived, 0) = 0)
		OR
		(ISNULL(RecordExists,0) > 0 AND IsArchived = 0 AND ISNULL(TestRecordExists, 0) > 0 AND TestIsArchived = 1)
		OR
		(ISNULL(RecordExists,0) > 0 AND IsArchived = 1 AND ISNULL(TestRecordExists, 0) > 0 AND TestIsArchived = 0)
	)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestUnitsSelectListByLastUser]'
GO
ALTER PROCEDURE [dbo].[remispTestUnitsSelectListByLastUser] @UserID INT, @includeCompletedQRA BIT = 1
AS
	DECLARE @username NVARCHAR(255)
	SELECT @username = LDAPLogin FROM Users WHERE ID=@UserID

	SELECT 
	tu.ID,
	tu.batchid, 
	tu.BSN, 
	tu.BatchUnitNumber, 
	tu.CurrentTestStageName, 
	tu.CurrentTestName, 
	tu.AssignedTo,
	tu.ConcurrencyID,
	tu.LastUser,
	tu.Comment,
	b.QRANumber,
	dtl.ConcurrencyID as dtlCID,
	dtl.ID as dtlID,
	dtl.InTime as dtlInTime,
	dtl.InUser as dtlInUser,
	dtl.OutTime as dtlouttime,
	dtl.OutUser as dtloutuser,
	tl.TrackingLocationName,
	tl.ID as dtlTLID,
	b.TestCenterLocationID
	from TestUnits as tu, devicetrackinglog as dtl, Batches as b, TrackingLocations as tl  
	where tl.ID = dtl.TrackingLocationID and tu.id = dtl.testunitid and tu.batchid = b.id 
		and inuser = @username and outuser is null
		AND (
				(@includeCompletedQRA = 0 AND b.BatchStatus <> 5)
				OR
				(@includeCompletedQRA = 1)
			)
	order by QRANumber desc, BatchUnitNumber 
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestUnitsSearchFor]'
GO
ALTER PROCEDURE [dbo].[remispTestUnitsSearchFor] @QRANumber nvarchar(11) = null
AS
BEGIN
	SELECT 
		tu.ID,
		tu.batchid, 
		tu.BSN, 
		tu.BatchUnitNumber, 
		tu.CurrentTestStageName, 
		tu.CurrentTestName, 
		tu.AssignedTo,
		tu.ConcurrencyID,
		tu.LastUser,
		tu.Comment,
		b.QRANumber,
		dtl.ConcurrencyID as dtlCID,
		dtl.ID as dtlID,
		dtl.InTime as dtlInTime,
		dtl.InUser as dtlInUser,
		dtl.OutTime as dtlouttime,
		dtl.OutUser as dtloutuser,
		tl.TrackingLocationName,
		tl.ID as dtlTLID,
		b.TestCenterLocationID
	FROM TestUnits as tu WITH(NOLOCK) inner join Batches as b WITH(NOLOCK) on b.ID = tu.batchid
	left outer join devicetrackinglog as dtl WITH(NOLOCK) on dtl.TestUnitID =tu.id AND dtl.id = (SELECT  top(1)  DeviceTrackingLog.ID from DeviceTrackingLog WITH(NOLOCK)
	WHERE     (TestUnitID = tu.id)
	order by devicetrackinglog.intime desc)
	left outer join TrackingLocations as tl WITH(NOLOCK) on dtl.TrackingLocationID = tl.ID
	 where b.ID = tu.BatchID and (b.QRANumber = @qranumber)
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispExceptionSearch]'
GO
ALTER procedure [dbo].[remispExceptionSearch] @ProductID INT = 0, @AccessoryGroupID INT = 0, @ProductTypeID INT = 0, @TestID INT = 0, @TestStageID INT = 0, @JobName NVARCHAR(400) = NULL, 
	@IncludeBatches INT = 0, @RequestReason INT = 0, @TestCenterID INT = 0, @IsMQual INT = 0
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
	) as exceptionResults
	ORDER BY QRANumber, Batchunitnumber, TestName
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[vw_ExceptionsAuditPivoted]'
GO
ALTER VIEW [dbo].[vw_ExceptionsAuditPivoted]
AS
SELECT pvt.ID, pvt.[41] AS ProductID, pvt.[2] AS ReasonForRequest, pvt.[3] AS TestUnitID, pvt.[4] AS TestStageID, pvt.[5] AS Test, pvt.[6] AS ProductTypeID, pvt.[7] AS AccessoryGroupID,
	pvt.[3516] AS TestCenterID, pvt.[3517] As IsMQual
FROM 
(SELECT ID, Value, TestExceptionsAudit.LookupID as Look
FROM TestExceptionsAudit) te
PIVOT (MAX(Value) FOR Look IN ([41],[2],[3],[4],[5],[6],[7],[3516],[3517])) as pvt 
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
	CREATE TABLE #exceptions (ID INT, BatchUnitNumber INT, ReasonForRequest INT, ProductGroupName NVARCHAR(150), JobName NVARCHAR(150), TestStageName NVARCHAR(150), TestName NVARCHAR(150), LastUser NVARCHAR(150), TestStageID INT, TestUnitID INT, ProductTypeID INT, AccessoryGroupID INT, ProductID INT, ProductType NVARCHAR(150), AccessoryGroupName NVARCHAR(150), TestID INT, IsMQual INT, TestCenter NVARCHAR(MAX), TestCenterID INT)
	
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
GRANT EXECUTE ON [Relab].[remispOverallResultsSummary] TO Remi
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
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