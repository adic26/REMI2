ALTER VIEW [dbo].[vw_ExceptionsPivoted]
AS
SELECT pvt.ID, pvt.[41] AS ProductID, pvt.[1] As ProductGroupName, pvt.[2] AS ReasonForRequest, pvt.[3] AS TestUnitID, pvt.[4] AS TestStageID, pvt.[5] AS Test, pvt.[6] AS ProductType, pvt.[7] AS AccessoryGroupName
FROM 
(SELECT ID, Value, TestExceptions.LookupID as Look
FROM TestExceptions) te
PIVOT (MAX(Value) FOR Look IN ([41],[1],[2],[3],[4],[5],[6],[7])) as pvt
GO
ALTER procedure [dbo].[remispTestExceptionsGetBatchExceptions] @qraNumber nvarchar(11) = null
AS
--get any for the product
select distinct pvt.id, null as batchunitnumber, pvt.ReasonForRequest,pvt.ProductGroupName,b.JobName, ts.teststagename
, t.TestName, (SELECT TOP 1 LastUser FROM TestExceptions WHERE ID=pvt.ID) AS LastUser,
(SELECT TOP 1 ConcurrencyID FROM TestExceptions WHERE ID=pvt.ID) AS ConcurrencyID,
pvt.TestStageID, pvt.TestUnitID, pvt.ProductType, pvt.AccessoryGroupName, pvt.ProductID
FROM vw_ExceptionsPivoted as pvt
	LEFT OUTER JOIN Tests t ON (pvt.Test = t.ID OR pvt.Test = t.TestName)
	, Batches as b, teststages as ts, Jobs as j
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
		(pvt.AccessoryGroupName IS NULL)
		OR
		(pvt.AccessoryGroupName IS NOT NULL AND pvt.AccessoryGroupName = b.AccessoryGroupName)
	)
	AND
	(
		(pvt.ProductType IS NULL)
		OR
		(pvt.ProductType IS NOT NULL AND pvt.ProductType = b.ProductType)
	)

union all

--then get any for the test units.
select distinct pvt.id, tu.BatchUnitNumber, pvt.ReasonForRequest,pvt.ProductGroupName,b.JobName, 
(select teststagename from teststages where teststages.id =pvt.TestStageid) as teststagename, t.testname,
(SELECT TOP 1 LastUser FROM TestExceptions WHERE ID=pvt.ID) AS LastUser,
(SELECT TOP 1 ConcurrencyID FROM TestExceptions WHERE ID=pvt.ID) AS ConcurrencyID
, pvt.TestStageID, pvt.TestUnitID, pvt.ProductType, pvt.AccessoryGroupName,pvt.ProductID
FROM vw_ExceptionsPivoted as pvt
	LEFT OUTER JOIN Tests t ON (pvt.Test = t.ID OR pvt.Test = t.TestName)
	, Batches as b, testunits tu 
where b.QRANumber = @qranumber and tu.batchid = b.id and pvt.TestUnitID = tu.id
GO
GRANT EXECUTE ON remispTestExceptionsGetBatchExceptions TO Remi
GO
ALTER procedure [dbo].[remispTestExceptionsCopyExceptionsForProduct] 
	@oldProductID nvarchar(400),
	@newProductID nvarchar(400),
	@username nvarchar(255)
AS
DECLARE @MAX INT
DECLARE @LookupID INT
SELECT @MAX = MAX(ID) FROM TestExceptions

SELECT @LookupID = LookupID FROM Lookups WHERE Type='Exceptions' AND [Values]='ProductID'

SELECT pvt.ID, ROW_NUMBER() OVER( ORDER BY ID )  + @MAX AS NEW_ID
INTO #temp
FROM vw_ExceptionsPivoted as pvt 
WHERE ProductID=@oldProductID AND TestUnitID IS NULL

INSERT INTO TestExceptions (ID, LookupID, Value, LastUser)
SELECT NEW_ID as ID, LookupID, 
CASE WHEN LookupID=@LookupID THEN @newProductID ELSE Value END, @username
FROM TestExceptions te
	INNER JOIN #temp on te.ID=#temp.ID

DROP TABLE #temp
GO
GRANT EXECUTE On remispTestExceptionsCopyExceptionsForProduct TO Remi
GO
ALTER PROCEDURE [dbo].[remispTestExceptionsDeleteProductGroupException]
/*	'===============================================================
	'   NAME:                	remispTestExceptionsDeleteProductGroupException
	'   DATE CREATED:       	22 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	deletes an item from table: TestUnitTestExceptions
	'   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
		@ReasonForRequest int = null,
		@TestName nvarchar(400) = null,
		@TestStageName nvarchar(400) = null,
		@JobName nvarchar(400) = null,
		@ProductID INT=null,
		@LastUser nvarchar(255)
AS
	declare @TestUnitID as int 
	declare @TestStageId int
	
	--Get the test stage id
	if (@ProductID is not null and @teststagename is not null and @jobname is not null and @testUnitID is null)
	begin
		set @TestStageID = (select ts.id from TestStages as ts, Jobs as j where j.JobName = @JobName and ts.JobID = j.ID and ts.TestStageName = @TestStageName)
	end
	
	select @TestStageId AS TestStageID, @TestUnitID AS TestUnitID;

	SELECT DISTINCT pvt.ID
	INTO #temp
	FROM vw_ExceptionsPivoted pvt
		INNER JOIN Tests t ON (pvt.Test = t.ID OR pvt.Test = t.TestName)
	where (ReasonForRequest = @ReasonForRequest or (@ReasonForRequest is null and ReasonForRequest is null))
		and testname=@TestName 
		and (teststageid =@TestStageID or (@TestStageId is null and TestStageID is null))
		and ProductID = @ProductID

	PRINT 'SET The User who is deleting'
	UPDATE TestExceptions
	SET LastUser=@LastUser
	WHERE TestExceptions.ID IN (SELECT ID FROM #temp)
	
	PRINT 'Delete Exception'
	delete from TestExceptions WHERE TestExceptions.ID IN (SELECT ID FROM #temp)

	DROP TABLE #temp
GO
GRANT EXECUTE ON remispTestExceptionsDeleteProductGroupException TO Remi
GO
ALTER procedure [dbo].[remispTestExceptionsGetBatchOnlyExceptions] @qraNumber nvarchar(11) = null
AS
(select distinct pvt.id, null as batchunitnumber, pvt.ReasonForRequest,pvt.ProductGroupName,b.JobName, ts.teststagename
, t.testname, (SELECT TOP 1 LastUser FROM TestExceptions WHERE ID=pvt.ID) AS LastUser,
(SELECT TOP 1 ConcurrencyID FROM TestExceptions WHERE ID=pvt.ID) AS ConcurrencyID, pvt.TestStageID, pvt.TestUnitID ,
pvt.ProductType, pvt.AccessoryGroupName, pvt.ProductID
FROM vw_ExceptionsPivoted as pvt
	LEFT OUTER JOIN Tests t ON (pvt.Test = t.ID OR pvt.Test = t.TestName)
	, Batches as b, teststages as ts, Jobs as j 
where b.QRANumber = @qranumber 
and pvt.TestUnitID is null
and (ts.id = pvt.teststageid or pvt.TestStageID is null)
and (ts.JobID = j.ID or j.ID is null)
and (b.JobName = j.JobName or j.JobName is null)
and (
(pvt.ProductID is null and pvt.ReasonForRequest = b.RequestPurpose)
or 
(pvt.ProductID is null and pvt.ReasonForRequest is null)))

union all

--get any for the test units.
(select distinct pvt.id, tu.BatchUnitNumber, pvt.ReasonForRequest, pvt.ProductGroupName,b.JobName, 
(select teststagename from teststages where teststages.id =pvt.TestStageid) as teststagename, t.testname,
(SELECT TOP 1 LastUser FROM TestExceptions WHERE ID=pvt.ID) AS LastUser,
(SELECT TOP 1 ConcurrencyID FROM TestExceptions WHERE ID=pvt.ID) AS ConcurrencyID, 
pvt.TestStageID, pvt.TestUnitID,pvt.ProductType, pvt.AccessoryGroupName, pvt.ProductID
FROM vw_ExceptionsPivoted as pvt
	LEFT OUTER JOIN Tests t ON (pvt.Test = t.ID OR pvt.Test = t.TestName)
	, Batches as b, testunits tu
where b.QRANumber = @qranumber and tu.batchid = b.id and pvt.TestUnitID = tu.id)
order by TestName
GO
GRANT EXECUTE ON remispTestExceptionsGetBatchOnlyExceptions TO Remi
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
select *
from 
(
	select ROW_NUMBER() over (order by pvt.ProductGroupName desc)as row,
	pvt.ID,
	null as batchunitnumber, 
	pvt.[ReasonForRequest], pvt.ProductGroupName,
	(select jobname from jobs,TestStages where teststages.id =pvt.TestStageid and Jobs.ID = TestStages.jobid) as jobname, 
	(select teststagename from teststages where teststages.id =pvt.TestStageid) as teststagename, 
	t.TestName,pvt.TestStageID, pvt.TestUnitID,-- pvt.LastUser, pvt.concurrencyid
	(select top 1 LastUser from TestExceptions WHERE ID=pvt.ID) AS LastUser,
	(select top 1 ConcurrencyID from TestExceptions WHERE ID=pvt.ID) AS ConcurrencyID,
	pvt.ProductType, pvt.AccessoryGroupName, pvt.ProductID
	FROM vw_ExceptionsPivoted as pvt
		LEFT OUTER JOIN Tests t ON (pvt.Test = t.ID OR pvt.Test = t.TestName)
	WHERE pvt.TestUnitID IS NULL AND
			((pvt.[ProductID]=@ProductID) OR (@ProductID = 0 AND pvt.ProductGroupName IS NULL))) as exceptionResults
where ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) 
			OR @startRowIndex = -1 OR @maximumRows = -1)
ORDER BY TestName
GO
GRANT EXECUTE ON remispTestExceptionsGetProductExceptions TO Remi
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
		INNER JOIN Tests t ON (pvt.Test = t.ID OR pvt.Test = t.TestName)
	where [ProductID]=@ProductID AND [TestStageID] IS NULL AND [Test] IS NOT NULL
	
	SELECT TestName AS Name, (CASE WHEN (SELECT TOP 1 ExceptionID FROM @testUnitExemptions WHERE exTestName = t.TestName) IS NOT NULL THEN 'True' ELSE 'False' END ) AS TestUnitException
	FROM Tests t
	WHERE t.TestType = 1
	ORDER BY TestName
GO
GRANT EXECUTE On remispTestExceptionsGetProductGroupTable TO Remi
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
	@ProductType NVARCHAR(800) = NULL,
	@AccessoryGroupName NVARCHAR(800) = NULL
AS		
	DECLARE @ReturnValue int
	declare @testUnitID int
	declare @ValidInputParams int = 1
	declare @TestStageID int
	DECLARE @ProductGroupName NVARCHAR(800)
	
	IF (@ProductID IS NOT NULL AND @ProductID > 0)
	BEGIN
		SELECT @ProductGroupName = ProductGroupName FROM Products WHERE ID=@ProductID
	END
	ELSE
	BEGIN
		SET @ProductGroupName = NULL
	END
	
	--Get the test stage id
	set @TestStageID = (select ts.id from TestStages as ts, Jobs as j where j.JobName = @JobName and ts.JobID = j.ID and ts.TestStageName = @TestStageName)
	PRINT 'TestStageID: ' + CONVERT(NVARCHAR, ISNULL(@TestStageID, ''))
		
	--test if item exists in db already

	set @ReturnValue = (SELECT DISTINCT pvt.ID
	FROM vw_ExceptionsPivoted as pvt
		LEFT OUTER JOIN Tests t ON (pvt.Test = t.ID OR pvt.Test = t.TestName)
	where (ReasonForRequest = @ReasonForRequest)
		and (TestStageID = @TestStageID)
		and (testname = @testname)
		and (ProductID = @ProductID))

	IF (@ReturnValue IS NULL) -- if it doesnt already exist then add it
	BEGIN
		PRINT 'INSERTING'
		DECLARE @ID INT
		SELECT @ID = MAX(ID)+1 FROM TestExceptions
		PRINT @ID

		IF (@TestName IS NOT NULL)
		BEGIN
			PRINT 'Inserting TEST'
			DECLARE @tID INT
			IF ((SELECT COUNT(*) FROM Tests WHERE TestName=@TestName) = 1)
			BEGIN
				SELECT @tID = ID FROM Tests WHERE TestName=@TestName
				INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 5, @tID, @LastUser)
			END
			ELSE
			BEGIN
				IF (@TestStageID IS NOT NULL AND EXISTS (SELECT TestID FROM TestStages WHERE ID=@TestStageID AND TestID IS NOT NULL))
				BEGIN
					SET @tID = (SELECT TestID FROM TestStages WHERE ID=@TestStageID AND TestID IS NOT NULL)
					INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 5, @tID, @LastUser)
				END
				ELSE
				BEGIN
					INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 5, @TestName, @LastUser)
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

		IF (@ProductGroupName IS NOT NULL)
		BEGIN
			PRINT 'Inserting ProductGroupName'
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 1, @ProductGroupName, @LastUser)
		END

		IF (@ProductType IS NOT NULL)
		BEGIN
			PRINT 'Inserting ProductType'
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 6, @ProductType, @LastUser)
		END

		IF (@AccessoryGroupName IS NOT NULL)
		BEGIN
			PRINT 'Inserting AccessoryGroupName'
			INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 7, @AccessoryGroupName, @LastUser)
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
GRANT EXECUTE ON remispTestExceptionsInsertProductGroupException TO Remi
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
	@TestStageName nvarchar(400) = null
AS
	declare @pid int
	declare @testunitid int
	declare @TestStageType int
	declare @TestStageID int
		
	--get the test unit id
	if @QRANumber is not null and @BatchUnitNumber is not null
	begin
		set @testUnitID = (select tu.Id from TestUnits as tu, Batches as b where b.QRANumber = @QRANumber AND tu.BatchID = b.ID AND tu.batchunitnumber = @Batchunitnumber)
		PRINT 'TestUnitID: ' + CONVERT(NVARCHAR, ISNULL(@testUnitID,''))
	end
		
	--get the product group name for the test unit's batch
	set @pid= (select p.ID from Batches as b, TestUnits as tu, products p where b.id = tu.BatchID and tu.ID= @testunitid and p.id=b.productID)
	PRINT 'ProductID: ' + CONVERT(NVARCHAR, ISNULL(@pid,''))

	--Get the test stage id
	set @TestStageID = (select ts.ID from Teststages as ts,jobs as j, Batches as b, TestUnits as tu
	where ts.TestStageName = @TestStageName and ts.JobID = j.id 
		and j.jobname = b.jobname 
		and tu.ID = @testunitid
		and b.ID = tu.BatchID)

	PRINT 'TestStageID: ' + CONVERT(NVARCHAR, ISNULL(@TestStageID,''))

	--set up the required tables
	declare @testUnitExemptions table (exTestName nvarchar(255))

	insert into @testunitexemptions
	SELECT DISTINCT TestName
	FROM vw_ExceptionsPivoted as pvt
		INNER JOIN Tests t ON (pvt.Test = t.ID OR pvt.Test = t.TestName)
	where (
			(pvt.TestUnitID = @TestUnitID and pvt.ProductID is null) 
			or 
			(pvt.TestUnitID is null and pvt.ProductID = @pid)
		  ) and( pvt.TestStageID = @TestStageID or @TestStageID is null)

	SELECT TestName AS Name, (CASE WHEN (SELECT exTestName FROM @testUnitExemptions WHERE exTestName = t.TestName) IS NOT NULL THEN 'True' ELSE 'False' END ) AS TestUnitException
	FROM Tests t, teststages as ts
	WHERE --where teststage type is environmental, the test name and test stage id's match
	ts.id = @TeststageID  and ((ts.TestStageType = 2  and ts.TestID = t.id) or
	--test stage type = incoming eval and test type is parametric
	( ts.TestStageType = 3 and t.testtype = 3) or
	--OR where test stage type is parametric and test type is also parametric (ie get all the measurment tests)
	(( ts.TeststageType = 1 ) and t.TestType = 1))
	ORDER BY TestName
GO
GRANT EXECUTE On remispTestExceptionsGetTestUnitTable TO Remi
GO