/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        ci0000001593275\SQLDeveloper.REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 3/27/2013 10:37:47 AM

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
/*	'===============================================================
	'   NAME:                	remispBatchesSelectActiveBatchesForProductGroup
	'   DATE CREATED:       	12 May 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves data from table: Batches based on search criteria
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/
	@ProductID INT = null,
	@AccessoryGroupID INT = null,
	@StartRowIndex int = null,
	@MaximumRows int = null,
	@RecordCount int = null OUTPUT,
	@GetAllBatches int = 0
AS
	IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (SELECT COUNT(*) FROM Batches WHERE 		
		(Batches.BatchStatus NOT IN(5,7) or @GetAllBatches =1)
		AND productID = @ProductID
		and (AccessoryGroupID=@AccessoryGroupID or @AccessoryGroupID is null))
		RETURN
	END
	
	SELECT BatchesRows.row,BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,BatchesRows.JobName,
		BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,BatchesRows.ProductType,batchesrows.AccessoryGroupName,batchesrows.productid, BatchesRows.QRANumber,BatchesRows.RequestPurpose,
		BatchesRows.TestCenterLocation,BatchesRows.TestStageName, BatchesRows.RFBands, BatchesRows.TestStageCompletionStatus,
		testUnitCount,BatchesRows.RQID As ReqID,
		(CASE WHEN BatchesRows.WILocation IS NULL THEN NULL ELSE BatchesRows.WILocation END) AS jobWILocation,
		(testunitcount -
			(select COUNT(*) 
			from TestUnits as tu
			INNER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
		) as HasUnitsToReturnToRequestor,
		(select AssignedTo 
		from TaskAssignments as ta
			--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
			INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
			--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
			INNER JOIN Jobs j ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
		where ta.BatchID = BatchesRows.ID and ta.Active=1  ) as ActiveTaskAssignee, CONVERT(BIT,0) AS HasBatchSpecificExceptions,
		BatchesRows.ProductTypeID,batchesrows.AccessoryGroupID
	FROM     
		(
			SELECT ROW_NUMBER() OVER (ORDER BY b.ID) AS Row, 
				b.BatchStatus,b.Comment,(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
				b.ConcurrencyID,b.ID,b.TestStageCompletionStatus,b.JobName,
				b.LastUser,b.Priority,p.ProductGroupName,b.QRANumber,b.RequestPurpose,b.ProductTypeID,b.AccessoryGroupID,p.ID As ProductID,
				b.TestCenterLocation,b.TestStageName,
				(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount, j.WILocation,
				l.[Values] As ProductType, l2.[Values] As AccessoryGroupName,b.RQID
			FROM Batches as b 
				inner join Products p on b.ProductID=p.id
				LEFT OUTER JOIN Jobs j ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
				LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID  
			WHERE (b.BatchStatus NOT IN(5,7) or @GetAllBatches =1) AND p.ID = @ProductID and (AccessoryGroupID = @AccessoryGroupID or @AccessoryGroupID is null)
		) AS BatchesRows
	WHERE (Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) OR @startRowIndex is null OR @maximumRows is null
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
	@TestCentreLocation nvarchar(200) =null,
	@RecordCount int = NULL OUTPUT,
	@sortExpression varchar(100) = null,
	@direction varchar(100) = 'asc'
	AS
SELECT BatchesRows.Row, BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,
	BatchesRows.JobName,BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,batchesrows.ProductType,batchesrows.AccessoryGroupName,
	batchesrows.ProductID,batchesrows.QRANumber,
	BatchesRows.RequestPurpose,BatchesRows.TestCenterLocation,BatchesRows.TestStageName, 
	batchesrows.RFBands, batchesrows.TestStageCompletionStatus,testunitcount,
	(CASE WHEN batchesrows.WILocation IS NULL THEN NULL ELSE batchesrows.WILocation END) AS jobWILocation,
	(testUnitCount -
		(select COUNT(*) 
			  from TestUnits as tu
			  INNER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			  where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
	) as HasUnitsToReturnToRequestor,
	(select AssignedTo 
	from TaskAssignments as ta
		--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
		INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
		--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
		INNER JOIN Jobs j ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
	where ta.BatchID = BatchesRows.ID and ta.Active=1  ) as ActiveTaskAssignee, CONVERT(BIT,0) AS HasBatchSpecificExceptions,
	batchesrows.ProductTypeID,batchesrows.AccessoryGroupID,batchesrows.RQID As ReqID
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
			TestCenterLocation,
			LastUser, 
			ConcurrencyID,
			b.RFBands,
			b.TestStageCompletionStatus,
			(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
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
				b.TestCenterLocation,
				b.ConcurrencyID,
				(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
				b.TestStageCompletionStatus, j.WILocation,b.RQID
			FROM Batches AS b 
				LEFT OUTER JOIN Jobs as j on b.jobname = j.JobName 
				inner join TestStages as ts on j.ID = ts.JobID
				inner join Tests as t on ts.TestID = t.ID
				inner join DeviceTrackingLog AS dtl 
				INNER JOIN TrackingLocations AS tl ON dtl.TrackingLocationID = tl.ID
				INNER JOIN TrackingLocationTypes as tlt on tl.TrackingLocationTypeID = tlt.id 
				inner join TestUnits AS tu ON dtl.TestUnitID = tu.ID on tu.CurrentTestName = t.TestName and b.id = tu.batchid  --batches where there's a tracking log
				INNER JOIN Products p ON b.ProductID=p.id
				LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID  
			WHERE (b.TestCenterLocation = @TestCentreLocation or @TestCentreLocation is null) and j.TechnicalOperationsTest = 1 and j.MechanicalTest=0 and  tlt.TrackingLocationFunction= 4  and t.ResultBasedOntime = 1 AND dtl.OutTime IS NULL AND dtl.OutUser IS NULL
		)as b
	) as batchesrows
 	WHERE ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) OR @startRowIndex = -1 OR @maximumRows = -1) 
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesSelectBatchesForReport]'
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectBatchesForReport]
/*	'===============================================================
	'   NAME:                	remispBatchesSelectBatchesForReport
	'   DATE CREATED:       	12 Jul 2011
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retreives the batches where batch is having a report written
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/

	@StartRowIndex int = -1,
	@MaximumRows int = -1,
	@TestCentreLocation nvarchar(200) =null,
	@RecordCount int = NULL OUTPUT,
	@sortExpression varchar(100) = null,
	@direction varchar(100) = 'asc'
AS
SELECT BatchesRows.Row, BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,
	BatchesRows.JobName,BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,batchesrows.ProductTypeID,batchesrows.AccessoryGroupID,
	batchesrows.ProductID,batchesrows.QRANumber,batchesrows.RQID As ReqID,
	BatchesRows.RequestPurpose,BatchesRows.TestCenterLocation,BatchesRows.TestStageName, 
	batchesrows.RFBands, batchesrows.TestStageCompletionStatus, testunitcount,
	(CASE WHEN BatchesRows.WILocation IS NULL THEN NULL ELSE BatchesRows.WILocation END) AS jobWILocation,
	(
		testunitcount -
		(select COUNT(*) 
		from TestUnits as tu
			INNER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
		where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
	) as HasUnitsToReturnToRequestor,
	(select AssignedTo 
	from TaskAssignments as ta
		--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
		INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
		--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
		INNER JOIN Jobs j ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
	where ta.BatchID = BatchesRows.ID and ta.Active=1  ) as ActiveTaskAssignee, CONVERT(BIT,0) AS HasBatchSpecificExceptions,
	batchesrows.ProductType, batchesrows.AccessoryGroupName
	FROM     
		(
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
			ID, 
			QRANumber, 
			Comment,
			RequestPurpose, 
			Priority,
			TestStageName, 
			BatchStatus, 
			ProductGroupName, 
			productType,
			AccessoryGroupName,
			productTypeID,
			AccessoryGroupID,
			ProductID,
			JobName, 
			TestCenterLocation,
			LastUser, 
			ConcurrencyID,
			b.RFBands,
			b.TestStageCompletionStatus ,
			b.WILocation,
			(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
			b.RQID
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
						p.ID As ProductID,
						b.JobName, 
						b.LastUser, 
						b.TestCenterLocation,
						b.ConcurrencyID,
						(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
						b.TestStageCompletionStatus,
						j.WILocation,
						b.rqID
					FROM Batches AS b
						inner join Products p on p.ID=b.ProductID
						LEFT OUTER JOIN Jobs j ON j.JobName = b.JobName
						LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
						LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID  
					WHERE (b.TestCenterLocation = @TestCentreLocation or @TestCentreLocation is null) and (b.TestStageName = 'Report') and (b.BatchStatus != 5)
				)as b
		) as batchesrows
 	WHERE (
 			(Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) 
			OR @startRowIndex = -1 OR @maximumRows = -1
		  )
	order by QRANumber desc
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
select distinct pvt.id, null as batchunitnumber, pvt.ReasonForRequest,pvt.ProductGroupName,b.JobName, ts.teststagename
, t.TestName, (SELECT TOP 1 LastUser FROM TestExceptions WHERE ID=pvt.ID) AS LastUser,
(SELECT TOP 1 ConcurrencyID FROM TestExceptions WHERE ID=pvt.ID) AS ConcurrencyID,
pvt.TestStageID, pvt.TestUnitID, pvt.ProductTypeID, pvt.AccessoryGroupID, pvt.ProductID,
l2.[Values] As AccessoryGroupName, l.[Values] As ProductType
FROM vw_ExceptionsPivoted as pvt
	LEFT OUTER JOIN Tests t ON (pvt.Test = t.ID OR pvt.Test = t.TestName)
	LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND l.LookupID=pvt.ProductTypeID
	LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND l2.LookupID=pvt.AccessoryGroupID
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
select distinct pvt.id, tu.BatchUnitNumber, pvt.ReasonForRequest,pvt.ProductGroupName,b.JobName, 
(select teststagename from teststages where teststages.id =pvt.TestStageid) as teststagename, t.testname,
(SELECT TOP 1 LastUser FROM TestExceptions WHERE ID=pvt.ID) AS LastUser,
(SELECT TOP 1 ConcurrencyID FROM TestExceptions WHERE ID=pvt.ID) AS ConcurrencyID
, pvt.TestStageID, pvt.TestUnitID, pvt.ProductTypeID, pvt.AccessoryGroupID,pvt.ProductID,
l2.[Values] As AccessoryGroupName, l.[Values] As ProductType
FROM vw_ExceptionsPivoted as pvt
	LEFT OUTER JOIN Tests t ON (pvt.Test = t.ID OR pvt.Test = t.TestName)
	LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND l.LookupID=pvt.ProductTypeID
	LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND l2.LookupID=pvt.AccessoryGroupID
	, Batches as b, testunits tu 
where b.QRANumber = @qranumber and tu.batchid = b.id and pvt.TestUnitID = tu.id
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesSelectListAtTrackingLocation]'
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectListAtTrackingLocation]
/*	'===============================================================
	'   NAME:                	remispBatchesSelectListAtTrackingLocation
	'   DATE CREATED:       	20 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves paged data from table: Batches
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/


	@TrackingLocationID int,
	@StartRowIndex int = -1,
	@MaximumRows int = -1,
	@RecordCount int = NULL OUTPUT,
	@sortExpression varchar(100) = null,
	@direction varchar(100) = 'asc'
	AS
	
IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (select  COUNT(*) from (select DISTINCT b.id	FROM  Batches AS b INNER JOIN
                      DeviceTrackingLog AS dtl INNER JOIN
                      TrackingLocations AS tl ON dtl.TrackingLocationID = tl.ID INNER JOIN
                      TestUnits AS tu ON dtl.TestUnitID = tu.ID ON b.id = tu.BatchID --batches where there's a tracking log
                      
				WHERE  tl.id = @TrackingLocationID AND dtl.OutTime IS NULL AND dtl.OutUser IS NULL)as records)  --and the tracking log has not been 'scanned' out
		RETURN
	END
SELECT BatchesRows.Row, BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,
				 BatchesRows.JobName,BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,BatchesRows.QRANumber,
				 BatchesRows.RequestPurpose,BatchesRows.TestCenterLocation,BatchesRows.TestStageName,batchesrows.ProductType, batchesrows.AccessoryGroupName,Batchesrows.ProductID,
				 batchesrows.RFBands, batchesrows.TestStageCompletionStatus,testunitcount,
				 (testunitcount -
			   (select COUNT(*) 
			  from TestUnits as tu
			  INNER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			  where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
			  ) as HasUnitsToReturnToRequestor,
(CASE WHEN BatchesRows.WILocation IS NULL THEN NULL ELSE BatchesRows.WILocation END) AS jobWILocation,
	 (select AssignedTo 
	from TaskAssignments as ta
		--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
		INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
		--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
		INNER JOIN Jobs j ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
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
                      TestCenterLocation,
                      LastUser, 
                      ConcurrencyID,
                      b.RFBands,
                      b.TestStageCompletionStatus,
				 (select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
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
					  p.ID As ProductID,
                      b.JobName, 
                      b.LastUser, 
                      b.TestCenterLocation,
                      b.ConcurrencyID,
                      (case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
                      b.TestStageCompletionStatus,
                      j.WILocation,
					  b.RQID
FROM Batches AS b 
                      INNER JOIN DeviceTrackingLog AS dtl 
                      INNER JOIN TrackingLocations AS tl ON dtl.TrackingLocationID = tl.ID 
                      INNER JOIN TestUnits AS tu ON dtl.TestUnitID = tu.ID ON b.id = tu.batchid --batches where there's a tracking log
                      inner join Products p on p.ID=b.ProductID
					  LEFT OUTER JOIN Jobs j ON j.JobName = b.JobName
					  LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
						LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID  
WHERE     tl.id = @TrackingLocationId AND dtl.OutTime IS NULL AND dtl.OutUser IS NULL)as b) as batchesrows
	WHERE
	 ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) 
			OR @startRowIndex = -1 OR @maximumRows = -1) 
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesSelectDailyListQRAListOnly]'
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectDailyListQRAListOnly]
	@StartRowIndex int = -1,
	@MaximumRows int = -1,
	@RecordCount int = NULL OUTPUT,
	@ProductID INT = null,
	@sortExpression varchar(100) = null,
	@GetBatchesAtEnvStages int = 1,
	@direction varchar(100) = 'desc',
	@TestCenterLocation as nvarchar(255)= null,
	@GetOperationsTests as bit = 0,
	@GetTechnicalOperationsTests as bit = 1,
	@TestStageCompletion as int	 = null
AS

IF (@RecordCount IS NOT NULL)
BEGIN
	SET @RecordCount = (select COUNT(*) from (SELECT distinct b.* FROM Batches as b, TestStages as ts, TestUnits as tu, Jobs as j, Products p where 
	( ts.TestStageName = b.TestStageName) 
	and tu.BatchID = b.id
	and ts.JobID = j.id
	and j.JobName = b.JobName
	and ((j.OperationsTest = @getoperationstests and @GetOperationsTests = 1)
	or (j.TechnicalOperationsTest = @GetTechnicalOperationsTests and @GetTechnicalOperationsTests = 1 ))
	and ((b.batchstatus=2 or b.BatchStatus = 4) and (ts.TestStageType =  @GetBatchesAtEnvStages))
	and (@ProductID is null or p.ID = @ProductID)
	and ((@TestStageCompletion is null or b.TestStageCompletionStatus = @TestStageCompletion)
	or  (@TestStageCompletion = 2 and (b.TestStageCompletionStatus = 2 or b.TestStageCompletionStatus = 3)))
	and (@TestCenterLocation is null or TestCenterLocation = @TestCenterLocation)) as batchcount)
	RETURN
END

SELECT BatchesRows.QRANumber
FROM (
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
				case when @sortExpression='productgroup' and @direction='asc' then b.productgroupname end asc,
				case when @sortExpression='productgroup' and @direction='desc' then b.productgroupname end desc,
				case when @sortExpression='priority' and @direction='asc' then Priority end asc,
				case when @sortExpression='priority' and @direction='desc' then Priority end desc,
				case when @sortExpression='batchstatus' and @direction='asc' then batchstatus end,
				case when @sortExpression='batchstatus' and @direction='desc' then batchstatus end desc,
				case when @sortExpression='testcenter' and @direction='asc' then testcenterlocation end,
				case when @sortExpression='testcenter' and @direction='desc' then testcenterlocation end desc,
				case when @sortExpression is null then (cast(priority as varchar(10)) + qranumber) end desc
		) AS Row, 
		b.ID,
		b.QRANumber, 
		b.Priority, 
		b.TestStageName,
		b.BatchStatus, 
		b.ProductGroupName,
		b.ProductTypeID,
		b.AccessoryGroupID,
		b.ProductType,
		b.AccessoryGroupName,
		b.ProductID,
		b.Jobname,
		b.LastUser,
		b.ConcurrencyID,
		b.Comment,
		b.TestCenterLocation,
		b.RequestPurpose,
		(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = b.ProductGroupName)  end) as rfBands,
		b.TestStageCompletionStatus,
		(select COUNT (*) from TestUnits as tu where tu.id = b.ID) as testunitcount
		FROM 
		(
			select distinct b.*, p.ProductGroupName, l.[Values] As ProductType, l2.[Values] As AccessoryGroupName
			from Batches as b
				INNER JOIN TestStages as ts ON (ts.TestStageName = b.TestStageName)
				INNER JOIN TestUnits as tu ON (tu.BatchID = b.ID)
				INNER JOIN Products p ON p.ID=b.ProductID
				LEFT OUTER JOIN Jobs j ON (j.JobName = b.JobName)
				LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID  
			WHERE ts.JobID = j.ID and (b.batchstatus=2) and (ts.TestStageType =  @GetBatchesAtEnvStages) and (@ProductID is null or p.ID = @ProductID)	
					and
					(
						(j.OperationsTest = @getoperationstests and @GetOperationsTests = 1)
						or 
						(j.TechnicalOperationsTest = @GetTechnicalOperationsTests and @GetTechnicalOperationsTests = 1 )
					)			
				and
				(
					(@TestStageCompletion is null or b.TestStageCompletionStatus = @TestStageCompletion)
					or
					(@TestStageCompletion = 2 and (b.TestStageCompletionStatus = 2 or b.TestStageCompletionStatus = 3))
				)
				and (@TestCenterLocation is null or TestCenterLocation = @TestCenterLocation)
		) as b
	) AS BatchesRows 
WHERE (
		(Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) 
		OR @startRowIndex = -1 OR @maximumRows = -1
	  ) order by row
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
	@testLocationName NVARCHAR(400)
AS
SET NOCOUNT ON

IF (@testLocationName = 'All Test Centers')
BEGIN
	SET @testLocationName = NULL
END

DECLARE @TrueBit BIT
SET @TrueBit = CONVERT(BIT, 1)

SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Completed Testing], p.ProductGroupName 
FROM Batches b WITH(NOLOCK)
	INNER JOIN TestUnits tu ON b.ID = tu.BatchID
	INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus = 8 and ba.inserttime between @startdate and @enddate
	INNER JOIN BatchesAudit ba2 WITH(NOLOCK) ON b.ID = ba2.BatchID AND ba2.BatchStatus <> 8 and ba2.inserttime between @startdate and @enddate
	INNER JOIN Products p ON p.ID=b.ProductID
WHERE (b.TestCenterLocation = @testLocationName or @testLocationName is null) 
GROUP BY p.productgroupname
ORDER BY p.productgroupname

SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# in Chamber], p.productgroupname 
FROM DeviceTrackingLog dtl WITH(NOLOCK)
	INNER JOIN TestUnits tu WITH(NOLOCK) ON dtl.TestUnitID = tu.ID
	INNER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
	INNER JOIN TrackingLocations tl WITH(NOLOCK) ON dtl.TrackingLocationID = tl.id
	INNER JOIN TrackingLocationTypes tlt WITH(NOLOCK) ON tl.TrackingLocationTypeID = tlt.ID AND tlt.TrackingLocationFunction = 4 --4 means chamber type device (environmentstressing)
	INNER JOIN Products p ON p.ID=b.ProductID
WHERE dtl.InTime BETWEEN @startdate AND @enddate
	and (b.TestCenterLocation = @testLocationName or @testLocationName is null) 
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
	INNER JOIN Products p ON p.ID=b.ProductID
WHERE (b.TestCenterLocation = @testLocationName or @testLocationName is null) 
GROUP BY ProductGroupName
ORDER BY p.productgroupname

SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Worked On Parametric], p.productgroupname
FROM Batches b WITH(NOLOCK)
	INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
	INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
	INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
	INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
	INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.TechnicalOperationsTest = @TrueBit
	INNER JOIN Products p ON p.ID=b.ProductID
WHERE ba.inserttime between @startdate and @enddate and (b.TestCenterLocation = @testLocationName or @testLocationName is null) 
GROUP BY p.productgroupname
ORDER BY p.productgroupname

SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Completed Parametric], p.productgroupname
FROM Batches b WITH(NOLOCK)
	INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus IN (5, 8)--Complete or TestingComplete
	INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
	INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
	INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
	INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.TechnicalOperationsTest = @TrueBit
	INNER JOIN Products p ON p.ID=b.ProductID
WHERE ba.inserttime between @startdate and @enddate and (b.TestCenterLocation = @testLocationName or @testLocationName is null) 
GROUP BY p.productgroupname
ORDER BY p.productgroupname

SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Worked On Drop/Tumble], p.productgroupname
FROM Batches b WITH(NOLOCK)
	INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
	INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
	INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = @TrueBit
	INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
	INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
	INNER JOIN Products p ON p.ID=b.ProductID
WHERE ba.inserttime between @startdate and @enddate
	and (b.TestCenterLocation = @testLocationName or @testLocationName is null) 
GROUP BY p.productgroupname
ORDER BY p.productgroupname

SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Completed Drop/Tumble], p.productgroupname
FROM Batches b WITH(NOLOCK)
	INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus IN (5, 8)--Complete or TestingComplete
	INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
	INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = @TrueBit
	INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
	INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
	INNER JOIN Products p ON p.ID=b.ProductID
WHERE ba.inserttime between @startdate and @enddate
	and (b.TestCenterLocation = @testLocationName or @testLocationName is null) 
GROUP BY p.productgroupname
ORDER BY p.productgroupname

SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Worked On Accessories], p.productgroupname
FROM Batches b WITH(NOLOCK)
	INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
	INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
	INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
	INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
	INNER JOIN Products p ON p.ID=b.ProductID
	INNER JOIN Lookups l ON b.ProductTypeID = l.LookupID AND l.Type='ProductType'
WHERE ba.inserttime between @startdate and @enddate AND l.[Values] = 'Accessory'
	and (b.TestCenterLocation = @testLocationName or @testLocationName is null) 
GROUP BY p.productgroupname
ORDER BY p.productgroupname

SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Worked On Component], p.productgroupname
FROM Batches b WITH(NOLOCK)
	INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
	INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
	INNER JOIN Products p ON p.ID=b.ProductID
	INNER JOIN Lookups l ON b.ProductTypeID = l.LookupID AND l.Type='ProductType'
WHERE ba.inserttime between @startdate and @enddate AND l.[Values] = 'Component'
	and (b.TestCenterLocation = @testLocationName or @testLocationName is null) 
GROUP BY p.productgroupname
ORDER BY p.productgroupname

SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Worked On Handheld], p.productgroupname
FROM Batches b WITH(NOLOCK)
	INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
	INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
	INNER JOIN TestRecords tr WITH(NOLOCK) ON tu.ID = tr.TestUnitID
	INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
	INNER JOIN Products p ON p.ID=b.ProductID
	INNER JOIN Lookups l ON b.ProductTypeID = l.LookupID AND l.Type='ProductType'
WHERE ba.inserttime between @startdate and @enddate	AND l.[Values] = 'Handheld'
	and (b.TestCenterLocation = @testLocationName or @testLocationName is null) 
GROUP BY p.productgroupname
ORDER BY p.productgroupname

SET NOCOUNT OFF
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
	pvt.ProductTypeID, pvt.AccessoryGroupID, pvt.ProductID, l.[Values] As ProductType, l2.[Values] As AccessoryGroupName
	FROM vw_ExceptionsPivoted as pvt
		LEFT OUTER JOIN Tests t ON (pvt.Test = t.ID OR pvt.Test = t.TestName)
		LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND l.LookupID=pvt.ProductTypeID
		LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND l2.LookupID=pvt.AccessoryGroupID
	WHERE pvt.TestUnitID IS NULL AND
			((pvt.[ProductID]=@ProductID) OR (@ProductID = 0 AND pvt.ProductGroupName IS NULL))) as exceptionResults
where ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) 
			OR @startRowIndex = -1 OR @maximumRows = -1)
ORDER BY TestName
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesSelectDailyList]'
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectDailyList]
	@StartRowIndex int = -1,
	@MaximumRows int = -1,
	@RecordCount int = NULL OUTPUT,
	@ProductID INT = null,
	@sortExpression varchar(100) = null,
	@GetBatchesAtEnvStages int = 1,
	@direction varchar(100) = 'desc',
	@TestCenterLocation as nvarchar(255)= null,
	@GetOperationsTests as bit = 0,
	@GetTechnicalOperationsTests as bit = 1,
	@TestStageCompletion as int = null
AS


	IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (select COUNT(*) from (SELECT distinct b.* FROM Batches as b, TestStages as ts, TestUnits as tu, Jobs as j, Products p where 
			( ts.TestStageName = b.TestStageName) 
			and tu.BatchID = b.id
			and ts.JobID = j.id
			and j.JobName = b.JobName
			and ((j.OperationsTest = @getoperationstests and @GetOperationsTests = 1)
			or (j.TechnicalOperationsTest = @GetTechnicalOperationsTests and @GetTechnicalOperationsTests = 1 ))
			and ((b.batchstatus=2 or b.BatchStatus = 4) and (ts.TestStageType =  @GetBatchesAtEnvStages))
			and (@ProductID is null or p.ID = @ProductID)
			and ((@TestStageCompletion is null or b.TestStageCompletionStatus = @TestStageCompletion)
			or  (@TestStageCompletion = 2 and (b.TestStageCompletionStatus = 2 or b.TestStageCompletionStatus = 3)))
			and (@TestCenterLocation is null or TestCenterLocation = @TestCenterLocation)) as batchcount)
		RETURN
	END
	
	SELECT BatchesRows.Row, BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,
		BatchesRows.JobName,BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,batchesrows.ProductType,batchesrows.AccessoryGroupName, BatchesRows.ProductID ,BatchesRows.QRANumber,
		BatchesRows.RequestPurpose,BatchesRows.TestCenterLocation,BatchesRows.TestStageName, BatchesRows.RFBands, BatchesRows.TestStageCompletionStatus,
		(select count(*) from testunits where testunits.batchid = BatchesRows.id) as testUnitCount,
		(CASE WHEN BatchesRows.WILocation IS NULL THEN NULL ELSE BatchesRows.WILocation END) AS jobWILocation,
		testunitcount,(testunitcount -
						(select COUNT(*) 
						from TestUnits as tu
						INNER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
						where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
					   ) as HasUnitsToReturnToRequestor,
		(select AssignedTo 
		from TaskAssignments as ta
		--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
		INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName AND BatchesRows.JobID = ts.JobID
		where ta.BatchID = BatchesRows.ID and ta.Active=1) as ActiveTaskAssignee, batchesrows.ProductTypeID,batchesrows.AccessoryGroupID,BatchesRows.RQID As ReqID,
		(
			SELECT TOP 1 CONVERT(BIT, 1) FROM TestExceptions WHERE LookupID=3 AND Value IN (SELECT ID FROM TestUnits WHERE BatchID=BatchesRows.ID)
		) AS HasBatchSpecificExceptions
	FROM
		(
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
				case when @sortExpression='testcenter' and @direction='asc' then testcenterlocation end,
				case when @sortExpression='testcenter' and @direction='desc' then testcenterlocation end desc,
				case when @sortExpression is null then (cast(priority as varchar(10)) + qranumber) end desc
			) AS Row, 
			b.ID,
			b.QRANumber, 
			b.Priority, 
			b.TestStageName,
			b.BatchStatus, 
			b.ProductGroupName,
			b.ProductTypeID,
			b.AccessoryGroupID,
			b.AccessoryGroupName,
			b.ProductType,
			b.ProductID As ProductID,
			b.Jobname,
			b.LastUser,
			b.ConcurrencyID,
			b.Comment,
			b.TestCenterLocation,
			b.RequestPurpose,
			b.WILocation,
			(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = b.ProductGroupName)  end) as rfBands,
			b.TestStageCompletionStatus,
			(select COUNT (*) from TestUnits as tu where tu.id = b.ID) as testunitcount,b.RQID,
			JobID
			FROM
			(
				select distinct b.* ,p.ProductGroupName,j.WILocation, l.[Values] As ProductType, l2.[Values] As AccessoryGroupName,j.ID As JobID
				from Batches as b--, TestStages as ts, TestUnits as tu, Jobs j--, Products p
					LEFT OUTER join TestStages ts ON ts.TestStageName = b.TestStageName and ts.TestStageType =  @GetBatchesAtEnvStages
					LEFT OUTER join TestUnits tu ON tu.BatchID = b.ID
					LEFT OUTER JOIN Products p ON p.ID = b.ProductID
					LEFT OUTER join Jobs j ON j.JobName =b.JobName and ts.JobID = j.ID
					LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
					LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID  
				WHERE --(ts.TestStageName = b.TestStageName) and (tu.BatchID = b.ID)	and (j.JobName =b.JobName )
				--and
				(
					(j.OperationsTest = @getoperationstests and @GetOperationsTests = 1)
					or
					(j.TechnicalOperationsTest = @GetTechnicalOperationsTests and @GetTechnicalOperationsTests = 1)
				)
				--and ts.JobID = j.ID
				--modified above to stop recieved batches (status=4) appearing in daily list				
				--and (ts.TestStageType =  @GetBatchesAtEnvStages)
				and (b.batchstatus=2)
				and (@ProductID is null or p.ID = @ProductID)
				and 
				(
					(@TestStageCompletion is null or b.TestStageCompletionStatus = @TestStageCompletion)
					or
					(@TestStageCompletion = 2 and (b.TestStageCompletionStatus = 2 or b.TestStageCompletionStatus = 3))
				)
				and (@TestCenterLocation is null or TestCenterLocation = @TestCenterLocation)
			) as b
		) AS BatchesRows 
	WHERE
		(
			(Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) 
			OR 
			@startRowIndex = -1 OR @maximumRows = -1
		) order by row		
GO
GRANT EXECUTE ON remispBatchesSelectDailyList TO Remi
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
	@AccessoryGroupID INT = NULL
AS		
	DECLARE @ReturnValue int	
	
	--get the test unit id
	if @testunitid is  null and (@QRANumber is not null and @BatchUnitNumber is not null)
	begin
		set @testUnitID = (select tu.Id from TestUnits as tu, Batches as b 
		where b.QRANumber = @QRANumber 
		AND tu.BatchID = b.ID AND tu.batchunitnumber = @Batchunitnumber)

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
		LEFT OUTER JOIN Tests t ON (pvt.Test = t.ID OR pvt.Test = t.TestName)
	where (testunitid = @testunitid)
	and (TestStageID = @TestStageID or (@TestStageID is null and TestStageID is null))
	and (t.TestName = @testname or (@TestName is null and TestName is null)))
	
	IF (@ReturnValue IS NULL) -- if it doesnt already exist then add it
	BEGIN
		PRINT 'INSERTING'
		DECLARE @ID INT
		SELECT @ID = MAX(ID)+1 FROM TestExceptions
		PRINT @ID
		
		IF (@TestName IS NOT NULL)
		BEGIN
			PRINT 'Inserting TestName'
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
PRINT N'Altering [dbo].[remispBatchesSearchList]'
GO
ALTER PROCEDURE [dbo].[remispBatchesSearchList]
/*	'===============================================================
	'   NAME:                	remispBatchesSearchList
	'   DATE CREATED:       	12 May 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves data from table: Batches based on search criteria
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/
	@ID int = Null,
	@Status int = null,
	@QRANumber nvarchar(11) = null,
	@ProductGroupName varchar(800) = null,
	@StartRowIndex int = null,
	@MaximumRows int = null,
	@RecordCount int = null OUTPUT
AS
	IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (SELECT COUNT(*) FROM Batches inner join Products p on p.ID=Batches.ProductID WHERE 		
		(Batches.ID = @ID or @ID is null) AND
		(BatchStatus = @Status or @Status is null) AND
		(QRANumber LIKE '%' + @QRANumber + '%' OR @QRANumber IS NULL)
		AND (p.ProductGroupName = @ProductGroupName OR @ProductGroupName IS NULL))
		RETURN
	END
	
	SELECT BatchesRows.row,BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,BatchesRows.JobName,
		BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,batchesrows.ProductType,batchesrows.AccessoryGroupName,batchesrows.ProductID, BatchesRows.QRANumber,BatchesRows.RequestPurpose,
		BatchesRows.TestCenterLocation,BatchesRows.TestStageName,BatchesRows.RFBands, BatchesRows.TestStageCompletionStatus, testUnitCount, 
		(CASE WHEN BatchesRows.WILocation IS NULL THEN NULL ELSE BatchesRows.WILocation END) AS jobWILocation,
		(testunitcount -
			(select COUNT(*) 
			from TestUnits as tu
			INNER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
		) as HasUnitsToReturnToRequestor,
		(select AssignedTo 
		from TaskAssignments as ta
			--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
			INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
			--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
			INNER JOIN Jobs j ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
		where ta.BatchID = BatchesRows.ID and ta.Active=1) as ActiveTaskAssignee,
		CONVERT(BIT,0) AS HasBatchSpecificExceptions, batchesrows.ProductTypeID,batchesrows.AccessoryGroupID,BatchesRows.RQID AS ReqID
	FROM     
		(
			SELECT ROW_NUMBER() OVER (ORDER BY b.ID) AS Row, 
				b.BatchStatus,b.Comment,(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
				b.teststagecompletionstatus,b.ConcurrencyID,b.ID,b.JobName,b.LastUser,b.Priority,b.ProductTypeID,b.AccessoryGroupID,p.ID As ProductID,
				p.ProductGroupName,b.QRANumber,b.RequestPurpose,b.TestCenterLocation,b.TestStageName,j.WILocation,
				(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
				l.[Values] As ProductType, l2.[Values] As AccessoryGroupName,b.RQID
			FROM Batches as b
				inner join Products p on b.ProductID=p.id 
				LEFT OUTER JOIN Jobs j ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
				LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID  
			WHERE (b.ID = @ID or @ID is null) AND (BatchStatus = @Status or @Status is null) 
				AND (QRANumber LIKE '%' + @QRANumber + '%' OR @QRANumber IS NULL)
				AND (p.ProductGroupName = @ProductGroupName OR @ProductGroupName IS NULL)
		)AS BatchesRows		
	WHERE (Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) OR @startRowIndex is null OR @maximumRows is null
	RETURN
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
	@AccessoryGroupID INT = NULL
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

	SELECT @ProductID = ID FROM Products WHERE LTRIM(RTRIM(ProductGroupName))= LTRIM(RTRIM(@ProductGroupName))
	SELECT @ProductTypeID = LookupID FROM Lookups WHERE Type='ProductType' AND LTRIM(RTRIM([Values]))= LTRIM(RTRIM(@ProductType))
	SELECT @AccessoryGroupID = LookupID FROM Lookups WHERE Type='AccessoryType' AND LTRIM(RTRIM([Values]))= LTRIM(RTRIM(@AccessoryGroupName))
	
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
		--ProductGroupName, 
		ProductTypeID,
		AccessoryGroupID,
		TestCenterLocation,
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
		--@ProductGroupName, 
		@ProductTypeID,
		@AccessoryGroupID,
		@TestCenterLocation,
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
		--ProductGroupName = @ProductGroupName, 
		ProductTypeID = @ProductTypeID,
		AccessoryGroupID = @AccessoryGroupID,
		TestCenterLocation=@TestCenterLocation,
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

	SET @ConcurrencyID = (SELECT ConcurrencyID FROM Batches WHERE ID = @ReturnValue)
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
GRANT EXECUTE ON remispBatchesInsertUpdateSingleItem TO Remi
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestExceptionsGetBatchOnlyExceptions]'
GO
ALTER procedure [dbo].[remispTestExceptionsGetBatchOnlyExceptions] @qraNumber nvarchar(11) = null
AS
select distinct pvt.id, null as batchunitnumber, pvt.ReasonForRequest,pvt.ProductGroupName,b.JobName, ts.teststagename
, t.testname, (SELECT TOP 1 LastUser FROM TestExceptions WHERE ID=pvt.ID) AS LastUser,
(SELECT TOP 1 ConcurrencyID FROM TestExceptions WHERE ID=pvt.ID) AS ConcurrencyID, pvt.TestStageID, pvt.TestUnitID ,
pvt.ProductTypeID, pvt.AccessoryGroupID, pvt.ProductID, l.[Values] As ProductType, l2.[Values] As AccessoryGroupName
FROM vw_ExceptionsPivoted as pvt
	LEFT OUTER JOIN Tests t ON (pvt.Test = t.ID OR pvt.Test = t.TestName)
	LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND l.LookupID=pvt.ProductTypeID
	LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND l2.LookupID=pvt.AccessoryGroupID
	, Batches as b, teststages as ts, Jobs as j 
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
select distinct pvt.id, tu.BatchUnitNumber, pvt.ReasonForRequest, pvt.ProductGroupName,b.JobName, 
(select teststagename from teststages where teststages.id =pvt.TestStageid) as teststagename, t.testname,
(SELECT TOP 1 LastUser FROM TestExceptions WHERE ID=pvt.ID) AS LastUser,
(SELECT TOP 1 ConcurrencyID FROM TestExceptions WHERE ID=pvt.ID) AS ConcurrencyID, 
pvt.TestStageID, pvt.TestUnitID,pvt.ProductTypeID, pvt.AccessoryGroupID, pvt.ProductID, l.[Values] As ProductType, l2.[Values] As AccessoryGroupName
FROM vw_ExceptionsPivoted as pvt
	LEFT OUTER JOIN Tests t ON (pvt.Test = t.ID OR pvt.Test = t.TestName)
	LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND l.LookupID=pvt.ProductTypeID
	LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND l2.LookupID=pvt.AccessoryGroupID
	INNER JOIN testunits tu ON tu.ID=pvt.TestUnitID
	INNER JOIN Batches as b ON b.ID=tu.BatchID
where b.QRANumber = @qranumber and tu.batchid = b.id and pvt.TestUnitID = tu.id
order by pvt.TestUnitID desc,TestName
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
		SET @RecordCount = (SELECT COUNT(*) FROM Batches WHERE BatchStatus NOT IN(5,7))	
		RETURN
	END
	
	SELECT BatchesRows.row,BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,BatchesRows.JobName,
		BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,BatchesRows.QRANumber,BatchesRows.RequestPurpose,batchesrows.ProductType, batchesrows.AccessoryGroupName,
		batchesrows.ProductID,
		BatchesRows.TestCenterLocation,BatchesRows.TestStageName,BatchesRows.RFBands, BatchesRows.TestStageCompletionStatus, 
		batchesrows.testUnitCount,BatchesRows.RQID As ReqID,
		(CASE WHEN BatchesRows.WILocation IS NULL THEN NULL ELSE BatchesRows.WILocation END) AS jobWILocation,
		(
			testunitcount -
			(select COUNT(*) 
			from TestUnits as tu
				INNER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
		) as HasUnitsToReturnToRequestor,
		(
			select AssignedTo 
			from TaskAssignments as ta
				--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
				INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
				--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
				INNER JOIN Jobs j ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
			where ta.BatchID = BatchesRows.ID and ta.Active=1
		) as ActiveTaskAssignee,
		CONVERT(BIT, 0) AS HasBatchSpecificExceptions, batchesrows.ProductTypeID, batchesrows.AccessoryGroupID
	FROM     
		(
			SELECT ROW_NUMBER() OVER (ORDER BY b.ID) AS Row, 
			b.BatchStatus,b.Comment,(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
			b.teststagecompletionstatus,b.ConcurrencyID,b.ID,b.JobName,b.LastUser,b.Priority,p.ProductGroupName,b.ProductTypeID,b.AccessoryGroupID,p.ID as ProductID,b.QRANumber,
			b.RequestPurpose,b.TestCenterLocation,b.TestStageName, j.WILocation,
			(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
			l2.[Values] As AccessoryGroupName, l.[Values] As ProductType,b.RQID
			FROM Batches as b
				inner join Products p on p.ID=b.ProductID
				LEFT OUTER JOIN Jobs j ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs
				LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID  
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
/*	'===============================================================
	'   NAME:                	remispBatchesSelectByQRANumber
	'   DATE CREATED:       	15 jun 2010
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves data from table: Batches based on qranumber
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION:	More efficient
	'===============================================================*/

	@QRANumber nvarchar(11) = null,
	@RecordCount int = null OUTPUT
AS
	IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (SELECT COUNT(*) FROM Batches WHERE 		
		
		QRANumber = @QRANumber)
		
		RETURN
	END
	declare @batchid int
	declare @jobname nvarchar(400)
	declare @teststagename nvarchar(400)
	select @batchid = id, @teststagename=TestStageName, @jobname = JobName from Batches where QRANumber = @QRANumber
	declare @testunitcount int = (select count(*) from testunits as tu where tu.batchid = @batchid)

	DECLARE @TSTimeLeft REAL
	DECLARE @JobTimeLeft REAL
	EXEC remispGetEstimatedTSTime @batchid,@teststagename,@jobname, @TSTimeLeft OUTPUT, @JobTimeLeft OUTPUT
	
	SELECT BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,BatchesRows.JobName,
	BatchesRows.LastUser,BatchesRows.Priority,p.ProductGroupName,BatchesRows.QRANumber,BatchesRows.RequestPurpose,batchesrows.ProductTypeID,batchesrows.AccessoryGroupID,
	batchesrows.ProductID,
	BatchesRows.TestCenterLocation,BatchesRows.TestStageName,
	(case when batchesrows.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
	BatchesRows.TestStageCompletionStatus, @testunitcount as testUnitCount,
	(CASE WHEN j.WILocation IS NULL THEN NULL ELSE j.WILocation END) AS jobWILocation,@TSTimeLeft AS EstTSCompletionTime,@JobTimeLeft AS EstJobCompletionTime, 
	(@testunitcount -
			  -- TrackingLocations was only used because we were testing based on string comparison and this isn't needed anymore because we are basing on ID which DeviceTrackingLog can be used.
              (select COUNT(*) 
			  from TestUnits as tu
			  INNER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			  where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
	) as HasUnitsToReturnToRequestor,	 
	(select AssignedTo 
	from TaskAssignments as ta
		--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
		INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName AND ts.JobID = j.ID
		--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
		--INNER JOIN Jobs j ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
	where ta.BatchID = BatchesRows.ID and ta.Active=1  ) as ActiveTaskAssignee
	,BatchesRows.CPRNumber, l.[Values] AS ProductType, l2.[Values] As AccessoryGroupName,
	(
		SELECT TOP 1 CONVERT(BIT, 1) FROM TestExceptions WHERE LookupID=3 AND Value IN (SELECT ID FROM TestUnits WHERE BatchID=BatchesRows.ID)
    ) AS HasBatchSpecificExceptions,BatchesRows.RQID As ReqID
	from Batches as BatchesRows
		LEFT OUTER JOIN Jobs j ON j.JobName = BatchesRows.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
		INNER JOIN Products p ON BatchesRows.productID=p.ID
		LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND BatchesRows.ProductTypeID=l.LookupID  
		LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND BatchesRows.AccessoryGroupID=l2.LookupID  
	WHERE QRANumber = @QRANumber

select bc.DateAdded, bc.ID, bc.[Text], bc.LastUser from BatchComments as bc where BatchID = @batchid and Active = 1 order by DateAdded desc;
	RETURN
GO
GRANT EXECUTE ON remispBatchesSelectByQRANumber TO Remi
Go
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesSelectInMechanicalTestBatches]'
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectInMechanicalTestBatches]
/*	'===============================================================
	'   NAME:                	remispBatchesSelectInMechanicalTestBatches
	'   DATE CREATED:       	08 Aug 2010
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retreives the batches in mechanical tests
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/
	@StartRowIndex int = -1,
	@MaximumRows int = -1,
	@TestCentreLocation nvarchar(200) =null,
	@RecordCount int = NULL OUTPUT,
	@sortExpression varchar(100) = null,
	@direction varchar(100) = 'asc'
AS
SELECT
						 BatchesRows.Row, BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,
				 BatchesRows.JobName,BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,BatchesRows.QRANumber,
				 BatchesRows.RequestPurpose,BatchesRows.TestCenterLocation,BatchesRows.TestStageName, BatchesRows.ProductType,batchesrows.AccessoryGroupName,batchesrows.ProductID,
				 batchesrows.RFBands, batchesrows.TestStageCompletionStatus,testunitcount, 
				(testunitcount -
				   (select COUNT(*) 
				  from TestUnits as tu
				  INNER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
				  where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
			  ) as HasUnitsToReturnToRequestor,
   (CASE WHEN batchesrows.WILocation IS NULL THEN NULL ELSE batchesrows.WILocation END) AS jobWILocation,
	 (select AssignedTo 
	from TaskAssignments as ta
		--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
		INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
		--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
		INNER JOIN Jobs j ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
	where ta.BatchID = BatchesRows.ID and ta.Active=1  ) as ActiveTaskAssignee, CONVERT(BIT,0) AS HasBatchSpecificExceptions,
	BatchesRows.AccessoryGroupID,BatchesRows.ProductTypeID,BatchesRows.RQID As ReqID
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
                      ProductTypeID,
                      AccessoryGroupID,
					  ProductType,
					  AccessoryGroupName,
					  ProductID,
                      JobName, 
                      TestCenterLocation,
                      LastUser, 
                      ConcurrencyID,
                      b.RFBands,
                      b.TestStageCompletionStatus,
				 (select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
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
					  l2.[Values] As AccessoryGroupName,
					  l.[Values] As ProductType,
					  b.ProductTypeID,
					  b.AccessoryGroupID,
					  p.ID As ProductID,
                      b.JobName, 
                      b.LastUser, 
                      b.TestCenterLocation,
                      b.ConcurrencyID,
                      (case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
                      b.TestStageCompletionStatus,
                      j.WILocation,b.RQID
FROM Batches AS b LEFT OUTER JOIN Jobs j ON j.JobName = b.JobName inner join
                      DeviceTrackingLog AS dtl INNER JOIN
                      TrackingLocations AS tl ON dtl.TrackingLocationID = tl.ID INNER JOIN
                   TrackingLocationTypes as tlt on tl.TrackingLocationTypeID = tlt.id inner join
                      TestUnits AS tu ON dtl.TestUnitID = tu.ID ON b.id = tu.batchid --batches where there's a tracking log
                      inner join Products p on p.ID=b.ProductID
                      LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
					LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID  
WHERE   (b.TestCenterLocation = @TestCentreLocation or @TestCentreLocation is null) and j.TechnicalOperationsTest = 1 and j.MechanicalTest=1 and  tlt.TrackingLocationFunction= 4  AND dtl.OutTime IS NULL AND dtl.OutUser IS NULL)as b) as batchesrows
WHERE ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) OR @startRowIndex = -1 OR @maximumRows = -1) 
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
	@TestCentreLocation nvarchar(200) =null,
	@RecordCount int = NULL OUTPUT,
	@sortExpression varchar(100) = null,
	@direction varchar(100) = 'desc'
AS
DECLARE @comments NVARCHAR(max) 
SELECT BatchesRows.Row, BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,
	BatchesRows.JobName,BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,BatchesRows.QRANumber,
	BatchesRows.RequestPurpose,BatchesRows.TestCenterLocation,BatchesRows.TestStageName, batchesrows.RFBands, 
	batchesrows.TestStageCompletionStatus,batchesrows.testUnitCount,BatchesRows.ProductType,batchesrows.AccessoryGroupName,BatchesRows.ProductID,
	batchesrows.HasUnitsToReturnToRequestor,
	batchesrows.jobWILocation
	,(select AssignedTo 
	from TaskAssignments as ta
		--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
		INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
		--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
		INNER JOIN Jobs j ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
	where ta.BatchID = BatchesRows.ID and ta.Active=1  ) as ActiveTaskAssignee,
	(select  bc.Text + '####' from BatchComments as bc 
	where bc.BatchID = batchesrows.ID and bc.Active = 1 for xml path('')) as BatchCommentsConcat, CONVERT(BIT,0) AS HasBatchSpecificExceptions,
	BatchesRows.ProductTypeID, BatchesRows.AccessoryGroupID,batchesrows.RQID As ReqID
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
				case when @sortExpression='testcenterlocation' and @direction='asc' then TestCenterLocation end,
				case when @sortExpression='testcenterlocation' and @direction='desc' then TestCenterLocation end desc,
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
				b.JobName, 
				b.LastUser, 
				b.TestCenterLocation,
				b.ConcurrencyID,
				(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
				b.TestStageCompletionStatus,
				(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
				(select Jobs.WILocation from Jobs where Jobs.JobName = b.jobname) as jobWILocation,
				(
					(select COUNT(*) from TestUnits as tu where tu.batchid = b.ID) -
					(
						select COUNT(*) 
						from TestUnits as tu, DeviceTrackingLog as dtl, TrackingLocations as tl 
						where dtl.TrackingLocationID = tl.ID and tu.BatchID = b.ID 
							and tl.ID = 81 and dtl.OutTime IS null and dtl.TestUnitID = tu.ID
					)
				) as HasUnitsToReturnToRequestor,b.RQID
				FROM Batches AS b
					INNER JOIN Products p ON b.ProductID=p.ID
					LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
					LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID  	
				WHERE (b.TestCenterLocation = @TestCentreLocation or @TestCentreLocation is null) and b.BatchStatus = 8
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
/*	'===============================================================
	'   NAME:                	remispBatchesSelectHeldBatches
	'   DATE CREATED:       	22 Sep 2010
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retreives the batches where status is held or quarantined
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/

	@StartRowIndex int = -1,
	@MaximumRows int = -1,
	@TestCentreLocation nvarchar(200) =null,
	@RecordCount int = NULL OUTPUT,
	@sortExpression varchar(100) = null,
	@direction varchar(100) = 'asc'
	AS
SELECT
						 BatchesRows.Row, BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,
				 BatchesRows.JobName,BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,BatchesRows.QRANumber,
				 BatchesRows.RequestPurpose,BatchesRows.TestCenterLocation,BatchesRows.TestStageName,batchesrows.ProductType, batchesrows.AccessoryGroupName,batchesrows.productID,
				 batchesrows.RFBands, batchesrows.TestStageCompletionStatus, testunitcount,
	(CASE WHEN batchesrows.WILocation IS NULL THEN NULL ELSE batchesrows.WILocation END) AS jobWILocation,			
(testunitcount -
		(select COUNT(*) 
		from TestUnits as tu
		INNER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
		where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
	) as HasUnitsToReturnToRequestor,
	(select AssignedTo 
	from TaskAssignments as ta
		--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
		INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
		--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
		INNER JOIN Jobs j ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
	where ta.BatchID = BatchesRows.ID and ta.Active=1  ) as ActiveTaskAssignee, CONVERT(BIT,0) AS HasBatchSpecificExceptions,
	BatchesRows.ProductTypeID, batchesrows.AccessoryGroupID,BatchesRows.RQID As ReqID
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
					  productID,
                      JobName, 
                      TestCenterLocation,
                      LastUser, 
                      ConcurrencyID,
                      b.RFBands,
                      b.TestStageCompletionStatus ,
                      (select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
                      b.WILocation,b.RQID
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
					  p.ID As productID,
                      b.JobName, 
                      b.LastUser, 
                      b.TestCenterLocation,
                      b.ConcurrencyID,
                      (case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
                      b.TestStageCompletionStatus,
                      j.WILocation,b.RQID                     
FROM         Batches AS b
	 inner join Products p on b.ProductID=p.id
	 LEFT OUTER JOIN Jobs j ON j.JobName = b.JobName
	 LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND l.LookupID=b.ProductTypeID
	 LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND l2.LookupID=b.AccessoryGroupID
WHERE   (b.TestCenterLocation = @TestCentreLocation or @TestCentreLocation is null) and (b.BatchStatus = 1 or b.BatchStatus = 3) )as b) as batchesrows
 	WHERE
	 ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) 
			OR @startRowIndex = -1 OR @maximumRows = -1) order by QRANumber desc

GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesSelectBackToRequestorBatches]'
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectBackToRequestorBatches]
/*	'===============================================================
	'   NAME:                	remispBatchesSelectBackToRequestorBatches
	'   DATE CREATED:       	07 Oct 2010
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retreives the batches where testing is complete and the batch is due to go back tot he requestor but has not been sent.
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/

	@StartRowIndex int = -1,
	@MaximumRows int = -1,
	@TestCentreLocation nvarchar(200) =null,
	@RecordCount int = NULL OUTPUT,
	@sortExpression varchar(100) = null,
	@direction varchar(100) = 'asc'
AS
SELECT BatchesRows.Row, BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,
	BatchesRows.JobName,BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,BatchesRows.QRANumber,
	BatchesRows.RequestPurpose,BatchesRows.TestCenterLocation,BatchesRows.TestStageName,batchesrows.ProductType, batchesrows.AccessoryGroupName,
	batchesrows.RFBands, batchesrows.TestStageCompletionStatus, testUnitCount,jobwilocation, 
	(
		testunitcount -
		(select COUNT(*) 
		from TestUnits as tu
			INNER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
		where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
	) as HasUnitsToReturnToRequestor,
	(select AssignedTo 
	from TaskAssignments as ta
		--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
		INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
		--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
		INNER JOIN Jobs j ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
	where ta.BatchID = BatchesRows.ID and ta.Active=1  ) as ActiveTaskAssignee,
	batchesrows.ProductTypeID,batchesrows.AccessoryGroupID,batchesrows.RQID AS ReqID
FROM     
(
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
		JobName, 
		TestCenterLocation,
		LastUser, 
		ConcurrencyID,
		b.RFBands,
		b.TestStageCompletionStatus,
		(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
		(select Jobs.WILocation from Jobs where Jobs.JobName = b.jobname) as jobWILocation,
		RQID
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
			l.[LookupID] As ProductType,
			l2.[LookupID] As AccessoryGroupName,
			b.JobName, 
			b.LastUser, 
			b.TestCenterLocation,
			b.ConcurrencyID,
			(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
			b.TestStageCompletionStatus,b.RQID
		FROM Batches AS b 
			INNER JOIN DeviceTrackingLog AS dtl
			INNER JOIN TrackingLocations AS tl ON dtl.TrackingLocationID = tl.ID
			INNER JOIN TestUnits AS tu ON dtl.TestUnitID = tu.ID ON b.id = tu.batchid --batches where there's a tracking log
			inner join Products p on p.ID=b.ProductID
			LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
			LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID  
		WHERE (tl.id != 81 AND dtl.OutTime IS NULL AND dtl.OutUser IS NULL) and b.BatchStatus = 8
	)as b
) as batchesrows	
WHERE ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) OR @startRowIndex = -1 OR @maximumRows = -1) 
order by QRANumber desc
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
		SET @RecordCount = (SELECT COUNT(*) FROM Batches WHERE BatchStatus NOT IN(5,7) and Requestor = @Requestor	)	
		RETURN
	END

	SELECT BatchesRows.row,BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,BatchesRows.JobName,
		BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,batchesrows.ProductType,batchesrows.AccessoryGroupName, batchesrows.ProductID,
		BatchesRows.QRANumber,BatchesRows.RequestPurpose,
		BatchesRows.TestCenterLocation,BatchesRows.TestStageName,BatchesRows.RFBands, BatchesRows.TestStageCompletionStatus, 
		batchesrows.testUnitCount,BatchesRows.RQID As ReqID,
		(CASE WHEN batchesrows.WILocation IS NULL THEN NULL ELSE batchesrows.WILocation END) AS jobWILocation,
		(
			testunitcount -
			(select COUNT(*) 
			from TestUnits as tu
				INNER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
		) as HasUnitsToReturnToRequestor,
		(
			select AssignedTo 
			from TaskAssignments as ta
				--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
				INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
				--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
				INNER JOIN Jobs j ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
			where ta.BatchID = BatchesRows.ID and ta.Active=1
		) as ActiveTaskAssignee,
		CONVERT(BIT,0) AS HasBatchSpecificExceptions, BatchesRows.AccessoryGroupID,BatchesRows.ProductTypeID
	FROM     
		(
			SELECT ROW_NUMBER() OVER (ORDER BY b.ID) AS Row, 
				b.BatchStatus,b.Comment,(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
				b.teststagecompletionstatus,b.ConcurrencyID,b.ID,b.JobName,b.LastUser,b.Priority,p.ProductGroupName,b.ProductTypeID, b.AccessoryGroupID,p.ID As ProductID,b.QRANumber,
				b.RequestPurpose,b.TestCenterLocation,b.TestStageName, j.WILocation,
				(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
				l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, b.RQID
			FROM Batches as b
				inner join Products p on p.ID=b.ProductID
				LEFT OUTER JOIN Jobs j ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
				LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID  
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
ALTER PROCEDURE [dbo].[RemispGetTestCountByType] @StartDate DateTime = NULL, @EndDate DateTime = NULL, @ReportBasedOn INT = NULL, @GeoLocationName NVARCHAR(200), @GroupByType INT = 1, @BasedOn NVARCHAR(60)
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
			FROM TrackingLocations tl
				LEFT OUTER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
				INNER JOIN DeviceTrackingLog dtl ON tl.ID=dtl.TrackingLocationID
				INNER JOIN TestRecordsXTrackingLogs trtl ON trtl.TrackingLogID = dtl.ID
				INNER JOIN TestRecords tr ON trtl.TestRecordID = tr.ID
				INNER JOIN TestUnits tu ON tu.ID = tr.TestUnitID
				INNER JOIN Batches b ON tu.BatchID = b.ID
				INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus = 8 and ba.inserttime between @startdate and @enddate
				INNER JOIN BatchesAudit ba2 WITH(NOLOCK) ON b.ID = ba2.BatchID AND ba2.BatchStatus <> 8 and ba2.inserttime between @startdate and @enddate
			WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
				AND dtl.InTime BETWEEN @StartDate AND @EndDate
				AND (@GeoLocationName IS NULL OR GeoLocationName = @GeoLocationName)
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
			FROM TrackingLocations tl
				INNER JOIN TrackingLocationTypes tlt WITH(NOLOCK) ON tl.TrackingLocationTypeID = tlt.ID AND tlt.TrackingLocationFunction = 4
				LEFT OUTER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
				INNER JOIN DeviceTrackingLog dtl ON tl.ID=dtl.TrackingLocationID
				INNER JOIN TestRecordsXTrackingLogs trtl ON trtl.TrackingLogID = dtl.ID
				INNER JOIN TestRecords tr ON trtl.TestRecordID = tr.ID
				INNER JOIN TestUnits tu ON tu.ID = tr.TestUnitID
				INNER JOIN Batches b ON tu.BatchID = b.ID
			WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
				AND dtl.InTime BETWEEN @StartDate AND @EndDate
				AND (@GeoLocationName IS NULL OR GeoLocationName = @GeoLocationName)
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
				INNER JOIN TestRecords tr ON xer.TestRecordID = tr.ID  
				INNER JOIN TestUnits tu ON tu.ID = tr.TestUnitID
				INNER JOIN TestRecordsXTrackingLogs trtl ON trtl.TestRecordID = tr.ID
				INNER JOIN DeviceTrackingLog dtl ON dtl.ID = trtl.TrackingLogID
				INNER JOIN TrackingLocations tl ON tl.ID = dtl.TrackingLocationID
				LEFT OUTER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
				INNER JOIN Batches b ON tu.BatchID = b.ID
			WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
				AND dtl.InTime BETWEEN @StartDate AND @EndDate
				AND (@GeoLocationName IS NULL OR GeoLocationName = @GeoLocationName)
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
			FROM TrackingLocations tl
				LEFT OUTER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
				INNER JOIN DeviceTrackingLog dtl ON tl.ID=dtl.TrackingLocationID
				INNER JOIN TestRecordsXTrackingLogs trtl ON trtl.TrackingLogID = dtl.ID
				INNER JOIN TestRecords tr ON trtl.TestRecordID = tr.ID
				INNER JOIN TestUnits tu ON tu.ID = tr.TestUnitID
				INNER JOIN Batches b ON tu.BatchID = b.ID
				INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
				INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
				INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.TechnicalOperationsTest = @TrueBit
			WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
				AND dtl.InTime BETWEEN @StartDate AND @EndDate
				AND (@GeoLocationName IS NULL OR GeoLocationName = @GeoLocationName)
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
			FROM TrackingLocations tl
				LEFT OUTER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
				INNER JOIN DeviceTrackingLog dtl ON tl.ID=dtl.TrackingLocationID
				INNER JOIN TestRecordsXTrackingLogs trtl ON trtl.TrackingLogID = dtl.ID
				INNER JOIN TestRecords tr ON trtl.TestRecordID = tr.ID
				INNER JOIN TestUnits tu ON tu.ID = tr.TestUnitID
				INNER JOIN Batches b ON tu.BatchID = b.ID
				INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus IN (5, 8)--Complete or TestingComplete
				INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
				INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.TechnicalOperationsTest = @TrueBit
			WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
				AND dtl.InTime BETWEEN @StartDate AND @EndDate
				AND (@GeoLocationName IS NULL OR GeoLocationName = @GeoLocationName)
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
			FROM TrackingLocations tl
				LEFT OUTER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
				INNER JOIN DeviceTrackingLog dtl ON tl.ID=dtl.TrackingLocationID
				INNER JOIN TestRecordsXTrackingLogs trtl ON trtl.TrackingLogID = dtl.ID
				INNER JOIN TestRecords tr ON trtl.TestRecordID = tr.ID
				INNER JOIN TestUnits tu ON tu.ID = tr.TestUnitID
				INNER JOIN Batches b ON tu.BatchID = b.ID
				INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
				INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = @TrueBit
				INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
			WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
				AND dtl.InTime BETWEEN @StartDate AND @EndDate
				AND (@GeoLocationName IS NULL OR GeoLocationName = @GeoLocationName)
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
			FROM TrackingLocations tl
				LEFT OUTER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
				INNER JOIN DeviceTrackingLog dtl ON tl.ID=dtl.TrackingLocationID
				INNER JOIN TestRecordsXTrackingLogs trtl ON trtl.TrackingLogID = dtl.ID
				INNER JOIN TestRecords tr ON trtl.TestRecordID = tr.ID
				INNER JOIN TestUnits tu ON tu.ID = tr.TestUnitID
				INNER JOIN Batches b ON tu.BatchID = b.ID
				INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus IN (5, 8)--Complete or TestingComplete
				INNER JOIN Jobs j WITH(NOLOCK) ON ba.JobName = j.JobName AND j.OperationsTest = @TrueBit
				INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
			WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
				AND dtl.InTime BETWEEN @StartDate AND @EndDate
				AND (@GeoLocationName IS NULL OR GeoLocationName = @GeoLocationName)
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
			FROM TrackingLocations tl
				LEFT OUTER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
				INNER JOIN DeviceTrackingLog dtl ON tl.ID=dtl.TrackingLocationID
				INNER JOIN TestRecordsXTrackingLogs trtl ON trtl.TrackingLogID = dtl.ID
				INNER JOIN TestRecords tr ON trtl.TestRecordID = tr.ID
				INNER JOIN TestUnits tu ON tu.ID = tr.TestUnitID
				INNER JOIN Batches b ON tu.BatchID = b.ID
				INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
				INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
				INNER JOIN Lookups l ON l.Type='ProductType' AND l.LookupID=b.ProductTypeID
			WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
				AND dtl.InTime BETWEEN @StartDate AND @EndDate AND l.[Values] = 'Accessory'
				AND (@GeoLocationName IS NULL OR GeoLocationName = @GeoLocationName)
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
			FROM TrackingLocations tl
				LEFT OUTER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
				INNER JOIN DeviceTrackingLog dtl ON tl.ID=dtl.TrackingLocationID
				INNER JOIN TestRecordsXTrackingLogs trtl ON trtl.TrackingLogID = dtl.ID
				INNER JOIN TestRecords tr ON trtl.TestRecordID = tr.ID
				INNER JOIN TestUnits tu ON tu.ID = tr.TestUnitID
				INNER JOIN Batches b ON tu.BatchID = b.ID
				INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
				INNER JOIN Lookups l ON l.Type='ProductType' AND l.LookupID=b.ProductTypeID
			WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
				AND dtl.InTime BETWEEN @StartDate AND @EndDate AND l.[Values] = 'Component'
				AND (@GeoLocationName IS NULL OR GeoLocationName = @GeoLocationName)
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
			FROM TrackingLocations tl
				LEFT OUTER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
				INNER JOIN DeviceTrackingLog dtl ON tl.ID=dtl.TrackingLocationID
				INNER JOIN TestRecordsXTrackingLogs trtl ON trtl.TrackingLogID = dtl.ID
				INNER JOIN TestRecords tr ON trtl.TestRecordID = tr.ID
				INNER JOIN TestUnits tu ON tu.ID = tr.TestUnitID
				INNER JOIN Batches b ON tu.BatchID = b.ID
				INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
				INNER JOIN TestRecordsAudit tra WITH(NOLOCK) ON tr.ID = tra.TestRecordId AND tra.inserttime between @startdate and @enddate
				INNER JOIN Lookups l ON l.Type='ProductType' AND l.LookupID=b.ProductTypeID
			WHERE tlh.Status=1 AND tl.TrackingLocationName NOT IN ('REMSTAR','Back to Requestor','Incoming Quarantine','Incoming Station 1','Incoming Station 2','Incoming Station 3','Florida Transit','Texas Transit','Chicago Transit','Ottawa Transit','Hungary Transit','Mexico Transit','Bochum Transit','Disposal','Incoming Station 1','Incoming Station 2','Incoming Station 4')
				AND dtl.InTime BETWEEN @StartDate AND @EndDate AND l.[Values] = 'Handheld'
				AND (@GeoLocationName IS NULL OR GeoLocationName = @GeoLocationName)
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
PRINT N'Altering [dbo].[remispBatchesActiveSelectByJob]'
GO
ALTER PROCEDURE [dbo].[remispBatchesActiveSelectByJob]
	@JobName NVARCHAR(400),
	@StartRowIndex int = -1,
	@MaximumRows int = -1,
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
	SELECT BatchesRows.Row, BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,
		BatchesRows.JobName,BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroupName,BatchesRows.QRANumber,
		BatchesRows.RequestPurpose,BatchesRows.TestCenterLocation,BatchesRows.TestStageName,batchesrows.ProductType, batchesrows.AccessoryGroupName,batchesrows.ProductID,
		batchesrows.RFBands, batchesrows.TestStageCompletionStatus,testunitcount,BatchesRows.RQID As ReqID,
		(
			testunitcount -
			(select COUNT(*) 
			from TestUnits as tu
				INNER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
		) as HasUnitsToReturnToRequestor,
		(CASE WHEN BatchesRows.WILocation IS NULL THEN NULL ELSE BatchesRows.WILocation END) AS jobWILocation,
		(
			select AssignedTo 
			from TaskAssignments as ta
				--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
				INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
				--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
				INNER JOIN Jobs j ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
			where ta.BatchID = BatchesRows.ID and ta.Active=1
		) as ActiveTaskAssignee, CONVERT(BIT,0) AS HasBatchSpecificExceptions, batchesrows.AccessoryGroupID,batchesrows.ProductTypeID
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
			ProductTypeID,
			AccessoryGroupID,
			ProductGroupName, 
			ProductType,
			AccessoryGroupName,
			ProductID,
			JobName, 
			TestCenterLocation,
			LastUser, 
			ConcurrencyID,
			b.RFBands,
			b.TestStageCompletionStatus,
			(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
			b.WILocation,
			RQID
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
				p.ID as ProductID,
				b.JobName, 
				b.LastUser, 
				b.TestCenterLocation,
				b.ConcurrencyID,
				(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
				b.TestStageCompletionStatus,
				j.WILocation,
				b.RQID
			FROM Batches AS b 
				INNER JOIN DeviceTrackingLog AS dtl 
				INNER JOIN TestUnits AS tu ON dtl.TestUnitID = tu.ID ON b.id = tu.batchid --batches where there's a tracking log
				inner join Products p on p.ID=b.ProductID
				LEFT OUTER JOIN Jobs j ON j.JobName = b.JobName
				LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID
				LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID
			WHERE b.BatchStatus NOT IN (5,8) AND b.Jobname=@JobName AND dtl.OutTime IS NULL AND dtl.OutUser IS NULL
		)as b
	) as batchesrows 	
	WHERE ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) OR @startRowIndex = -1 OR @maximumRows = -1) 
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesByProductView]'
GO
ALTER PROCEDURE [dbo].[remispBatchesByProductView]
/*	'===============================================================
	'   NAME:                	remispBatchesByProductView
	'   DATE CREATED:       	19 April 2011
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retreives  batches given a  product
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/
	--@ProductGroupName nvarchar(800) =null,
	@AccessoryGroupID INT =null,
	@TestCentreLocation nvarchar(200) = null
AS
select results.*, (ExpectedDuration - CurrentTestTime) as RemainingHours, DATEADD(HOUR,(ExpectedDuration - CurrentTestTime),GETUTCDATE()) as CanBeRemovedAt 
from 
(
	SELECT b.QRANumber as QRANumber, 
		tu.BatchUnitNumber,
		tu.AssignedTo,
		tl.TrackingLocationName,
		b.JobName,
		b.AccessoryGroupID,
		b.ProductTypeID,
		l2.[Values] As AccessoryGroupName,
		p.ProductGroupName,
		l.[Values] As ProductType,
		b.TestStageName,
		dtl.InTime,
		tr.id as TestRecordID ,                     
		case when (select Duration from BatchSpecificTestDurations 
		where TestID = t.id and BatchID = b.ID) is not null then 
		(select Duration from BatchSpecificTestDurations  
		where TestID = t.id and BatchID = b.ID) else t.Duration end as ExpectedDuration,
		(Select sum(datediff(Minute,dtl.intime,
		(case when (dtl.OutTime IS null) then GETUTCDATE() else dtl.outtime  end )) / 60.0)
		 from Testrecordsxtrackinglogs as trXtl, DeviceTrackingLog as dtl 
		 where trXtl.TestRecordID = tr.ID and dtl.ID = trXtl.TrackingLogID) as CurrentTestTime,
		 b.RQID AS ReqID
	FROM Batches AS b 
		INNER JOIN Jobs as j on b.jobname = j.JobName 
		inner join TestStages as ts on j.ID = ts.JobID
		inner join tests as t on ((ts.TestStagetype = 2 and t.id = ts.TestID )or (ts.teststagetype != 2 and t.testtype = ts.TestStageType)) 
		inner join DeviceTrackingLog AS dtl
		INNER JOIN TrackingLocations AS tl ON dtl.TrackingLocationID = tl.ID
		INNER JOIN TrackingLocationTypes as tlt on tl.TrackingLocationTypeID = tlt.id 
		inner join TestUnits AS tu ON dtl.TestUnitID = tu.ID on tu.CurrentTestName = t.TestName and b.id = tu.batchid 
		inner join testrecords as tr on tr.TestUnitID = tu.id and tr.TestName = t.TestName and tr.TestStageName = t.TestName
		inner join Products p on p.ID=b.ProductID
		LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
		LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID  
	WHERE (b.TestCenterLocation = @TestCentreLocation or @TestCentreLocation is null) and  (b.AccessoryGroupID = @AccessoryGroupID or @AccessoryGroupID is null) 
		and (b.BatchStatus = 2) --in progress batches
) as results
order by RemainingHours asc
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchGetViewBatch]'
GO
ALTER PROCEDURE [dbo].[remispBatchGetViewBatch] 
/*  '=============================================================== 
  '   NAME:                  remispBatchGetViewBatch 
  '   DATE CREATED:         29 April 2011 
  '   CREATED BY:            Darragh O'Riordan 
  '   FUNCTION:              Retrieves the data required to display a single batch
   '   VERSION: 1            
  '   COMMENTS:             
  '   MODIFIED ON:          
  '   MODIFIED BY:          
  '   REASON MODIFICATION:  
    '===============================================================*/ 
@qranumber nvarchar(11)
AS
DECLARE @BatchID INT
SELECT @BatchID=ID FROM Batches WHERE QRANumber=@qranumber
--select basic batch info 
EXEC Remispbatchesselectbyqranumber @QraNumber; 

EXEC remispBatchGetTaskInfo @BatchID; 

--get records and testunits 
EXEC Remisptestrecordsselectforbatch @qranumber;

EXEC Remisptestunitssearchfor @qranumber;  
GO
GRANT EXECUTE ON remispBatchGetViewBatch TO Remi
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispQRAEndOfYearClose]'
GO
ALTER PROCEDURE [dbo].[remispQRAEndOfYearClose]
AS
	BEGIN TRANSACTION

	BEGIN TRY
		DECLARE @query VARCHAR(MAX)
		DECLARE @subject VARCHAR(25)
		SET @subject = 'QRA Numbers Automatically Completed - ' + CONVERT(VARCHAR, DB_NAME())
		SET @query = ''

		SET @query = @query + '
		DECLARE @temp TABLE (QRANumber NVARCHAR(11))

		INSERT INTO @temp (QRANumber)
		SELECT QRANumber
		FROM Batches 
		WHERE QRANumber LIKE ''QRA-' + CONVERT(VARCHAR(2), RIGHT(YEAR(GETDATE()),2)-1) + '-%'' AND BatchStatus NOT IN (5,7)

		UPDATE Batches
		SET BatchStatus=5, LastUser=''AutoCloseUser''
		WHERE QRANumber LIKE ''QRA-' + CONVERT(VARCHAR(2), RIGHT(YEAR(GETDATE()),2)-1) + '-%'' AND BatchStatus NOT IN (5,7)'

		  EXEC msdb.dbo.sp_send_dbmail
				@execute_query_database='Remi',
				@recipients=N'reliabilityinfrastructure@rim.com,mmackenzie@rim.com',
				@body='The attached QRA''s have been automatically closed due to end of year', 
				@subject =@subject,
				@query =@query,
				@attach_query_result_as_file = 1,
				@query_attachment_filename ='QRANumbers.txt'

		  PRINT 'COMMIT TRANSACTION'
		  COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		  SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_SEVERITY() AS ErrorSeverity, ERROR_STATE() as ErrorState, ERROR_PROCEDURE() as ErrorProcedure, ERROR_LINE() as ErrorLine, ERROR_MESSAGE() as ErrorMessage

		  PRINT 'ROLLBACK TRANSACTION'
		  ROLLBACK TRANSACTION
	END CATCH

GO
ALTER PROCEDURE [dbo].[remispTestRecordsSelectForBatch]
/*	'===============================================================
	'   NAME:                	remispTestRecordsSearchFor
	'   DATE CREATED:       	9 Oct 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves data from table: TestRecords OR the number of records in the table
	'   IN:         JobXTestStageID, TestID, BatchID  Optional: RecordCount         
	'   OUT: 		List Of: ID, TestUnitID,TestStageID, JobID, FANumber,FARaisedBy, FARaisedOn, Status,FAPriority, ConcurrencyID              
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:
	'   MODIFIED BY:
	'   REASON MODIFICATION: 
	'===============================================================*/
@QRANumber nvarchar(11) = null
AS
BEGIN
	SELECT tr.FailDocRQID,tr.Comment,tr.ConcurrencyID,tr.FailDocNumber,tr.ID,tr.JobName,tr.ResultSource,tr.LastUser,tr.RelabVersion,tr.Status,tr.TestName,
		tr.TestStageName,tr.TestUnitID, b.QRANumber, tu.BatchUnitNumber,
	(
		Select sum(datediff(MINUTE,dtl.intime,(case when (dtl.OutTime IS null) then GETUTCDATE() else dtl.outtime  end ))) 
		from Testrecordsxtrackinglogs trXtl
			INNER JOIN DeviceTrackingLog dtl ON dtl.ID = trXtl.TrackingLogID
		where trXtl.TestRecordID = tr.id
	) as TotalTestTimeMinutes,
	(
		select COUNT (*)
		from Testrecordsxtrackinglogs as trXtl
			INNER JOIN DeviceTrackingLog as dtl ON dtl.ID = trXtl.TrackingLogID
		where trXtl.TestRecordID = tr.id
	) as NumberOfTests	
	FROM TestRecords as tr
		INNER JOIN testunits tu ON tu.ID = tr.TestUnitID
		INNER JOIN Batches b ON b.id = tu.batchid
	WHERE b.QRANumber = @QRANumber
END
GO
GRANT EXECUTE ON remispTestRecordsSelectForBatch TO Remi
GO
ALTER PROCEDURE [remispBatchGetTaskInfo] @BatchID INT
AS
BEGIN
	select * from vw_GetTaskInfo where BatchID = @BatchID order by ProcessOrder
END
GO
GRANT EXECUTE ON remispBatchGetTaskInfo TO Remi
GO
ALTER PROCEDURE remispGetEstimatedTSTime @BatchID INT, @TestStageName NVARCHAR(400), @JobName NVARCHAR(400), @TSTimeLeft REAL OUTPUT, @JobTimeLeft REAL OUTPUT
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @TestUnitID INT
	DECLARE @BatchUnitNumber INT
	DECLARE @ProcessOrder INT
	DECLARE @TaskID INT
	DECLARE @tname NVARCHAR(400)
	DECLARE @resultbasedontime INT
	DECLARE @TotalTestTimeMinutes BIGINT
	DECLARE @Status INT
	DECLARE @UnitTotalTime REAL
	DECLARE @expectedDuration REAL
	DECLARE @StressingTimeOverage REAL -- How much stressing time to minus from job remaining time
	DECLARE @TestType INT
	DECLARE @TSName NVARCHAR(400)
	SET @TSTimeLeft = 0
	SET @JobTimeLeft = 0
	SET @StressingTimeOverage = 0

	SELECT ID AS TestUnitID
	INTO #tempUnits
	FROM TestUnits WITH(NOLOCK)
	WHERE BatchID=@BatchID
	ORDER BY TestUnitID	
	
	SELECT IDENTITY(INT, 1, 1) AS ID, tname, resultbasedontime,expectedDuration, processorder, tsname, TestType
	INTO #Tasks
	FROM vw_GetTaskInfo WITH(NOLOCK)
	WHERE BatchID=@BatchID AND testtype IN (1,2)
	ORDER BY processorder
	
	DELETE FROM #Tasks WHERE processorder < (SELECT DISTINCT ProcessOrder FROM #Tasks WHERE tsname=@teststagename)

	SELECT @TestUnitID =MIN(TestUnitID) FROM #tempUnits
	
	--PRINT 'Current Test Stage: ' + @TestStageName

	WHILE (@TestUnitID IS NOT NULL)
	BEGIN
		--PRINT 'TestUnitID: ' + CONVERT(VARCHAR, @TestUnitID)
		SET @UnitTotalTime = 0		

		SELECT @TaskID = MIN(ID) FROM #Tasks
			
		WHILE (@TaskID IS NOT NULL)
		BEGIN
			SELECT @tname =tname, @resultbasedontime=resultbasedontime,@expectedDuration=expectedDuration, @ProcessOrder=processorder, @TSName=tsname,
				@TestType = TestType
			FROM #Tasks 
			WHERE ID = @TaskID
			
			--PRINT 'Loop Test Stage: ' + @TSName

			--Test has not been done so add expected duration to overall unit time.
			IF NOT EXISTS (SELECT TOP 1 1 FROM TestRecords WHERE JobName=@JobName AND TestStageName=@TSName AND TestUnitID=@TestUnitID AND TestName=@tname)
				BEGIN
					IF (@TSName = @TestStageName)
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
							from Testrecordsxtrackinglogs as trXtl
								INNER JOIN DeviceTrackingLog as dtl ON dtl.ID = trXtl.TrackingLogID
							where trXtl.TestRecordID = TestRecords.id
						)
					from TestRecords 
					where JobName=@JobName AND TestStageName=@TSName AND TestUnitID=@TestUnitID AND TestName=@tname
					
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
									IF (@TSName = @TestStageName)
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
								IF (@TSName = @TestStageName)
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
GRANT EXECUTE ON remispGetEstimatedTSTime TO Remi
GO
ALTER PROCEDURE [dbo].[remispTrackingLocationsInsertHost]
@ID int OUTPUT,
@HostName nvarchar(255),
@UserName nvarchar(255),
@Status int
AS
IF (LTRIM(RTRIM(@HostName)) = '')
BEGIN
	IF NOT EXISTS (SELECT 1 FROM TrackingLocationsHosts WHERE TrackingLocationID=@ID AND HostName=@HostName)
		BEGIN
			INSERT INTO TrackingLocationsHosts (TrackingLocationID, HostName, LastUser, Status) VALUES (@ID, @HostName, @UserName, @Status)
		END
	ELSE
		BEGIN
			UPDATE TrackingLocationsHosts
			SET Status=@Status
			WHERE TrackingLocationID=@ID AND HostName=@HostName
		END
END
SELECT @ID
GO
GRANT EXECUTE ON remispTrackingLocationsInsertHost TO Remi
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering permissions on [dbo].[remispBatchesSelectListAtTrackingLocation]'
GO
GRANT EXECUTE ON  [dbo].[remispBatchesSelectListAtTrackingLocation] TO [remi]
GO
ALTER PROCEDURE [dbo].[remispSaveLookup] @LookupType NVARCHAR(150), @Value NVARCHAR(150)
AS
BEGIN
	DECLARE @LookupID INT
	SELECT @LookupID = MAX(LookupID) + 1 FROM Lookups
	
	IF LTRIM(RTRIM(@Value)) <> '' AND NOT EXISTS (SELECT 1 FROM Lookups WHERE Type=@LookupType AND LTRIM(RTRIM([Values])) = LTRIM(RTRIM(@Value)))
	BEGIN
		INSERT INTO Lookups (LookupID, Type, [Values]) VALUES (@LookupID, @LookupType, LTRIM(RTRIM(@Value)))
	END
END
GO
GRANT EXECUTE ON remispSaveLookup TO Remi
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