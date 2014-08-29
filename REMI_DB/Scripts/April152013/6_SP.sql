/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        ci0000001593275\SQLDeveloper.REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 4/8/2013 11:08:31 AM

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
PRINT N'Altering [dbo].[remispGetEnvironmentalStressSchedule]'
GO
ALTER procedure [dbo].[remispGetEnvironmentalStressSchedule] @startDate as datetime = null, @tltID as int = null, @GeoLocationID INT=null
AS
if @startdate is null
begin
	set @startdate = getutcdate()
end

select tl.trackinglocationname,dtl.intime,dtl.inuser, l.[Values] AS geolocationname,(select qranumber from batches, testunits where testunits.id = dtl.testunitid 
and batches.id = testunits.batchid) as QRANumber,tu.batchunitnumber, 
(Select DATEADD(hour, tests.duration, dtl.intime) from tests where testname = tu.currenttestname) as outtime
from DeviceTrackingLog as dtl
INNER JOIN TrackingLocations as tl ON dtl.trackinglocationid = tl.id
INNER JOIN TrackingLocationTypes as tlt ON tl.TrackingLocationTypeID = tlt.ID
INNER JOIN testunits as tu ON tu.id = dtl.testunitid 
INNER JOIN Lookups l ON l.Type='TestCenter' AND l.LookupID=tl.TestCenterLocationID
where dtl.OutTime is null  
and tlt.TrackingLocationFunction = 4 and (tlt.ID = @tltID or @tltid is null) 
and (tl.TestCenterLocationID = @GeoLocationID or @GeoLocationID is null)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTrackingLocationsSelectForTest]'
GO
ALTER PROCEDURE [dbo].[remispTrackingLocationsSelectForTest]
/*	'===============================================================
	'   NAME:                	remispTrackingLocationsSelectForTest
	'   DATE CREATED:       	19 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves data from table: TrackingLocations
	'   VERSION: 1           
	'   COMMENTS:            
  	'   MODIFIED ON:         
	'   MODIFIED BY:       
	'   REASON MODIFICATION: 
	'===============================================================*/
	@TestID integer,
	@CurrentTLID int
AS
	declare @currentGeoLocation INT = (select TestCenterLocationID from TrackingLocations where ID = @currentTLID)

	select tl.TrackingLocationName,(SELECT COUNT(dtl.ID)  --available to take units
		                    FROM TestUnits AS tu, DeviceTrackingLog AS dtl 
		                                          where tu.ID = dtl.TestUnitID 
		                                          and dtl.TrackingLocationID = tl.ID 
		                                          and (dtl.OutUser IS NULL)) as CurrentCount , (SELECT top(1) tu.CurrentTestName as CurrentTestName --and currently doing the same test, or not doing any test 
		                    FROM TestUnits AS tu, DeviceTrackingLog AS dtl 
		                                          where tu.ID = dtl.TestUnitID 
		                                          and tu.CurrentTestName is not null
		                                          and dtl.TrackingLocationID = tl.ID 
		                                          and (dtl.OutUser IS NULL)) as currenttestname from TrackingLocations as tl, TrackingLocationTypes as tlt, Tests as t where
tl.TrackingLocationTypeID = (select top(1) tlfort.TrackingLocationtypeID  from TrackingLocationsForTests as tlfort where TestID = @testid)
and tlt.ID = tl.TrackingLocationTypeID
and t.ID = @testid
and tl.ID != @currentTLID
and tl.TestCenterLocationID = @currentGeoLocation --close to us
and  (SELECT     COUNT(dtl.ID)  --available to take units
		                    FROM TestUnits AS tu, DeviceTrackingLog AS dtl 
		                                          where tu.ID = dtl.TestUnitID 
		                                          and dtl.TrackingLocationID = tl.ID 
		                                          and (dtl.OutUser IS NULL)) < tlt.UnitCapacity
and ((SELECT top(1) tu.CurrentTestName as CurrentTestName --and currently doing the same test, or not doing any test 
		                    FROM TestUnits AS tu, DeviceTrackingLog AS dtl 
		                                          where tu.ID = dtl.TestUnitID 
		                                          and tu.CurrentTestName is not null
		                                          and dtl.TrackingLocationID = tl.ID 
		                                          and (dtl.OutUser IS NULL)) = t.TestName or (SELECT top(1) tu.CurrentTestName as CurrentTestName
		                    FROM TestUnits AS tu, DeviceTrackingLog AS dtl 
		                                          where tu.ID = dtl.TestUnitID 
		                                          and tu.CurrentTestName is not null
		                                          and dtl.TrackingLocationID = tl.ID 
		                                          and (dtl.OutUser IS NULL)) is null) order by tl.TrackingLocationName
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
		INNER JOIN Tests t ON pvt.Test = t.ID
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
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispGetLookups]'
GO
ALTER PROCEDURE [dbo].[remispGetLookups] @Type NVARCHAR(150)
AS
BEGIN
	SELECT 0 AS LookupID, @Type AS Type, '' As LookupType
	UNION
	SELECT LookupID, Type, [Values] As LookupType
	FROM Lookups
	WHERE Type=@Type AND IsActive=1
	ORDER By LookupType
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTrackingLocationsGetSpecificLocationForUsersTestCenter]'
GO
ALTER procedure [dbo].[remispTrackingLocationsGetSpecificLocationForUsersTestCenter] @username nvarchar(255), @locationname nvarchar(500)
AS
declare @selectedID int

select top(1) @selectedID = tl.ID 
from TrackingLocations as tl
	INNER JOIN Lookups l ON l.Type='TestCenter' AND tl.TestCenterLocationID=l.LookupID
	INNER JOIN Users as u ON u.TestCentre = l.[Values]
	INNER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
where TrackingLocationName = @locationname and u.LDAPLogin = @username

return @selectedid
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
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
		BatchesRows.ProductTypeID,batchesrows.AccessoryGroupID, BatchesRows.TestCenterLocationID
	FROM     
		(
			SELECT ROW_NUMBER() OVER (ORDER BY b.ID) AS Row, 
				b.BatchStatus,b.Comment,(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
				b.ConcurrencyID,b.ID,b.TestStageCompletionStatus,b.JobName,
				b.LastUser,b.Priority,p.ProductGroupName,b.QRANumber,b.RequestPurpose,b.ProductTypeID,b.AccessoryGroupID,p.ID As ProductID,
				b.TestCenterLocationID,b.TestStageName,
				(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount, j.WILocation,
				l.[Values] As ProductType, l2.[Values] As AccessoryGroupName,b.RQID, l3.[Values] As TestCenterLocation
			FROM Batches as b 
				inner join Products p on b.ProductID=p.id
				LEFT OUTER JOIN Jobs j ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
				LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID  
				LEFT OUTER JOIN Lookups l3 ON l3.Type='TestCenter' AND b.TestCenterLocationID=l3.LookupID  
			WHERE (b.BatchStatus NOT IN(5,7) or @GetAllBatches =1) AND p.ID = @ProductID and (AccessoryGroupID = @AccessoryGroupID or @AccessoryGroupID is null)
		) AS BatchesRows
	WHERE (Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) OR @startRowIndex is null OR @maximumRows is null
	RETURN
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispProductGroupConfiguration]'
GO
ALTER PROCEDURE [dbo].[remispProductGroupConfiguration] @productID INT, @TestID INT AS
BEGIN
	DECLARE @rows VARCHAR(8000)
	DECLARE @rows2 VARCHAR(8000)
	DECLARE @query VARCHAR(4000)
	DECLARE @id INT
	CREATE TABLE #results (idkey [int] IDENTITY(1,1),  NodeName varchar(150), ID int, ParentID int, Example varchar(800), Attribute varchar(800), Closing varchar(800))
	CREATE TABLE #results2 (idkey [int] IDENTITY(1,1),  NodeName varchar(150), ID int, ParentID int, Example varchar(800), Attribute varchar(800), Closing varchar(800))

	IF NOT EXISTS (SELECT 1 FROM ProductConfiguration WHERE ProductID=@productID AND TestID=@TestID)
	BEGIN
		SELECT TOP 1 @productID = ProductID
		FROM ProductConfiguration
		WHERE TestID=@TestID
	END

	SELECT @rows=  ISNULL(STUFF(
	( 
	SELECT DISTINCT '],[' + l.[Values] 
	FROM    ProductConfiguration pc
	inner join ProductConfigValues val on pc.ID = val.ProductConfigID and ISNULL(isattribute,0)=0
	inner join Lookups l on val.LookupID=l.LookupID
	where TestID=@TestID and ProductID=@productID
	ORDER BY '],[' +  l.[Values]
	FOR XML PATH('')), 1, 2, '') + ']','[na]')
	
	SELECT @rows2=  ISNULL(STUFF(
	( 
	SELECT DISTINCT '],[' + l.[Values] 
	FROM    ProductConfiguration pc
	inner join ProductConfigValues val on pc.ID = val.ProductConfigID and ISNULL(isattribute,0)=1
	inner join Lookups l on val.LookupID=l.LookupID
	where TestID=@TestID and ProductID=@productID
	ORDER BY '],[' +  l.[Values]
	FOR XML PATH('')), 1, 2, '') + ']','[na]')
		
	SET @query = '
	select NodeName, ID, ParentID, 
	(
		SELECT pvt.* 
		FROM
		(
			SELECT  l.[Values], val.Value
			FROM ProductConfiguration pc
			inner join ProductConfigValues val on pc.ID=val.ProductConfigID and ISNULL(isattribute,0)=0
			inner join Lookups l on val.LookupID=l.LookupID
			where TestID=''' + CONVERT(varchar,@TestID) + ''' and ProductID=''' + CONVERT(varchar,@productID) + ''' and productconfiguration.ID=pc.ID
		)t
		PIVOT (max(Value) FOR t.[Values]
		IN ('+@rows+')) AS pvt
		for xml Path('''')
	) as example,
	(
		select ''<'' + productconfiguration.NodeName + '' '' + cast
		(
			(select CAST
				(
					(SELECT pvt.*
					FROM
						(
							SELECT  l.[Values], val.Value
							FROM ProductConfiguration pc
							inner join ProductConfigValues val on pc.ID=val.ProductConfigID and ISNULL(isattribute,0)= 1
							inner join Lookups l on val.LookupID=l.LookupID
							where TestID=''' + CONVERT(varchar,@TestID) + ''' and ProductID=''' + CONVERT(varchar,@productID) + ''' and productconfiguration.ID=pc.ID
						)t
					PIVOT (max(Value) FOR t.[Values]
					IN ('+@rows2+')) AS pvt
					for xml Path(''Attribute''))
				as xml)
			).query(''for $i in /Attribute/* return concat(local-name($i), "=""", data($i), """")'')
		as nvarchar(max)) + '' />''
	) AS Attribute, ''</'' + productconfiguration.NodeName + ''>'' AS Closing
	from productconfiguration
	where TestID=''' + CONVERT(varchar,@TestID) + ''' and ProductID=''' + CONVERT(varchar,@productID) + '''
	ORDER BY ViewOrder'

	INSERT INTO #results
		EXECUTE (@query)	

	SELECT @id= MIN(idkey) FROM #results WHERE ParentID IS NOT NULL

	IF EXISTS (SELECT idkey FROM #results WHERE ParentID IS NULL)
		INSERT INTO #results2 SELECT NodeName, ID, ParentID, Example, Attribute, Closing FROM #results WHERE ParentID IS NULL

	WHILE (@id is not null)
	BEGIN
		IF EXISTS (SELECT idkey FROM #results WHERE idkey=@id)
			INSERT INTO #results2 SELECT NodeName, ID, ParentID, Example, Attribute, Closing FROM #results WHERE idkey=@id

		SELECT @id= MIN(idkey) FROM #results WHERE idkey > @id AND ParentID IS NOT NULL
	END

	SELECT idkey, 
		CASE WHEN Attribute IS NOT NULL AND Example IS NULL AND EXISTS (SELECT 1 FROM #results2 r WHERE r.ParentID=#results2.ID) THEN REPLACE(REPLACE(Attribute,' />',''),'<','') 
		WHEN Attribute IS NOT NULL AND Example IS NULL THEN Attribute 
		WHEN Attribute IS NOT NULL AND Example IS NOT NULL THEN NULL 		
		ELSE NodeName END AS NodeName, ID, ParentID, 
		CASE WHEN Closing IS NOT NULL AND Attribute IS NOT NULL THEN REPLACE(Attribute,'/','') + Example + Closing 
		ELSE Example END As Example
	FROM #results2

	DROP TABLE #results
	DROP TABLE #results2
END
GO
GRANT EXECUTE ON remispProductGroupConfiguration TO REMI
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
				b.TestCenterLocationID,
				l3.[Values] As TestCenterLocation,
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
				LEFT OUTER JOIN Lookups l3 ON l3.Type='TestCenter' AND b.TestCenterLocationID=l3.LookupID  
			WHERE (b.TestCenterLocationID = @TestCentreLocation or @TestCentreLocation is null) and j.TechnicalOperationsTest = 1 and j.MechanicalTest=0 and  tlt.TrackingLocationFunction= 4  and t.ResultBasedOntime = 1 AND dtl.OutTime IS NULL AND dtl.OutUser IS NULL
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
	@TestCentreLocation INT =null,
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
	batchesrows.ProductType, batchesrows.AccessoryGroupName, batchesrows.TestCenterLocationID
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
			TestCenterLocationID,
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
					FROM Batches AS b
						inner join Products p on p.ID=b.ProductID
						LEFT OUTER JOIN Jobs j ON j.JobName = b.JobName
						LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
						LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID  
						LEFT OUTER JOIN Lookups l3 ON l3.Type='TestCenter' AND b.TestCenterLocationID=l3.LookupID  
					WHERE (b.TestCenterLocationID = @TestCentreLocation or @TestCentreLocation is null) and (b.TestStageName = 'Report') and (b.BatchStatus != 5)
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
select distinct pvt.id, null as batchunitnumber, pvt.ReasonForRequest,p.ProductGroupName,b.JobName, ts.teststagename
, t.TestName, (SELECT TOP 1 LastUser FROM TestExceptions WHERE ID=pvt.ID) AS LastUser,
(SELECT TOP 1 ConcurrencyID FROM TestExceptions WHERE ID=pvt.ID) AS ConcurrencyID,
pvt.TestStageID, pvt.TestUnitID, pvt.ProductTypeID, pvt.AccessoryGroupID, pvt.ProductID,
l2.[Values] As AccessoryGroupName, l.[Values] As ProductType
FROM vw_ExceptionsPivoted as pvt
	LEFT OUTER JOIN Tests t ON pvt.Test = t.ID
	LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND l.LookupID=pvt.ProductTypeID
	LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND l2.LookupID=pvt.AccessoryGroupID
	LEFT OUTER JOIN Products p ON p.ID=pvt.ProductID
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
select distinct pvt.id, tu.BatchUnitNumber, pvt.ReasonForRequest,p.ProductGroupName,b.JobName, 
(select teststagename from teststages where teststages.id =pvt.TestStageid) as teststagename, t.testname,
(SELECT TOP 1 LastUser FROM TestExceptions WHERE ID=pvt.ID) AS LastUser,
(SELECT TOP 1 ConcurrencyID FROM TestExceptions WHERE ID=pvt.ID) AS ConcurrencyID
, pvt.TestStageID, pvt.TestUnitID, pvt.ProductTypeID, pvt.AccessoryGroupID,pvt.ProductID,
l2.[Values] As AccessoryGroupName, l.[Values] As ProductType
FROM vw_ExceptionsPivoted as pvt
	LEFT OUTER JOIN Tests t ON pvt.Test = t.ID
	LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND l.LookupID=pvt.ProductTypeID
	LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND l2.LookupID=pvt.AccessoryGroupID
	LEFT OUTER JOIN Products p ON p.ID=pvt.ProductID
	, Batches as b, testunits tu 
where b.QRANumber = @qranumber and tu.batchid = b.id and pvt.TestUnitID = tu.id
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispGetProductConfigurationDetails]'
GO
ALTER PROCEDURE [dbo].[remispGetProductConfigurationDetails] @ProductID INT
AS
BEGIN	
	SELECT pc.ID, pc.ParentId AS ParentID, pc.ViewOrder, pc.NodeName, pcv.ID AS ProdConfID, l.[Values] As LookupName, 
		l.LookupID, Value As LookupValue, ISNULL(pcv.IsAttribute, 0) AS IsAttribute
	FROM ProductConfiguration pc
		INNER JOIN ProductConfigValues pcv ON pc.ID = pcv.ProductConfigID
		INNER JOIN Lookups l ON l.LookupID = pcv.LookupID
	WHERE pcv.ProductConfigID=@ProductID
	ORDER BY pc.ViewOrder	
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispSaveProductConfigurationDetails]'
GO
ALTER PROCEDURE [dbo].[remispSaveProductConfigurationDetails] @productID INT, @configID INT, @lookupID INT, @lookupValue NVARCHAR(200), @TestID INT, @productGroupNameID INT, @LastUser NVARCHAR(255), @IsAttribute BIT = 0
AS
BEGIN	
	If ((@configID IS NULL OR @configID = 0 OR NOT EXISTS (SELECT 1 FROM ProductConfigValues WHERE ID=@configID)) AND @lookupValue IS NOT NULL AND LTRIM(RTRIM(@lookupValue)) <> '' AND @LookupID IS NOT NULL AND @LookupID > 0 AND EXISTS(SELECT 1 FROM ProductConfiguration WHERE ID=@productID))
	BEGIN
		INSERT INTO ProductConfigValues (Value, LookupID, ProductConfigID, LastUser, IsAttribute)
		VALUES (@lookupValue, @LookupID, @productID, @LastUser, ISNULL(@IsAttribute,0))
	END
	ELSE IF (@configID > 0)
	BEGIN
		UPDATE ProductConfigValues
		SET Value=@lookupValue, LookupID=@LookupID, LastUser=@LastUser, ProductConfigID=@productID, IsAttribute=ISNULL(@IsAttribute,0)
		WHERE ID=@configID
	END
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispCopyTestConfiguration]'
GO
ALTER PROCEDURE [dbo].[remispCopyTestConfiguration] @ProductID INT, @TestID INT, @copyFromProductID INT, @LastUser NVARCHAR(255)
AS
BEGIN
	BEGIN TRANSACTION
	
	DECLARE @FromCount INT
	DECLARE @ToCount INT
	DECLARE @max INT
	SET @max = (SELECT MAX(ID) +1 FROM ProductConfiguration)
	
	SELECT @FromCount = COUNT(*) FROM ProductConfiguration WHERE TestID=@TestID AND ProductID=@copyFromProductID
	
	SELECT tempID=IDENTITY (int, 1, 1), CONVERT(int,ID) As ID, ParentId, ViewOrder, NodeName, @TestID AS TestID, @ProductID AS ProductID, @LastUser AS LastUser, 0 AS newproID, NULL AS newParentID
	INTO #ProductConfiguration
	FROM ProductConfiguration
	WHERE TestID=@TestID AND ProductID=@copyFromProductID
	
	UPDATE #ProductConfiguration SET newproID=@max+tempid
	
	UPDATE #ProductConfiguration 
	SET #ProductConfiguration.newParentID = pc2.newproID
	FROM #ProductConfiguration
		LEFT OUTER JOIN #ProductConfiguration pc2 ON #ProductConfiguration.ParentID=pc2.ID
		
	SET Identity_Insert ProductConfiguration ON
	
	INSERT INTO ProductConfiguration (ID, ParentId, ViewOrder, NodeName, TestID, ProductID, LastUser)
	SELECT newproID, newParentId, ViewOrder, NodeName, TestID, ProductID, LastUser
	FROM #ProductConfiguration
	
	SET Identity_Insert ProductConfiguration OFF
	
	SELECT @ToCount = COUNT(*) FROM ProductConfiguration WHERE TestID=@TestID AND ProductID=@ProductID

	IF (@FromCount = @ToCount)
	BEGIN
		SELECT @FromCount = COUNT(*) FROM ProductConfiguration pc INNER JOIN ProductConfigValues pcv ON pc.ID=pcv.ProductConfigID WHERE TestID=@TestID AND ProductID=@copyFromProductID
	
		INSERT INTO ProductConfigValues (Value, LookupID, ProductConfigID, LastUser, IsAttribute)
		SELECT Value, LookupID, #ProductConfiguration.newproID AS ProductConfigID, @LastUser AS LastUser, IsAttribute
		FROM ProductConfigValues
			INNER JOIN ProductConfiguration ON ProductConfigValues.ProductConfigID=ProductConfiguration.ID
			INNER JOIN #ProductConfiguration ON ProductConfiguration.ID=#ProductConfiguration.ID	
			
		SELECT @ToCount = COUNT(*) FROM ProductConfiguration pc INNER JOIN ProductConfigValues pcv ON pc.ID=pcv.ProductConfigID WHERE TestID=@TestID AND ProductID=@ProductID
		
		IF (@FromCount <> @ToCount)
		BEGIN
			GOTO HANDLE_ERROR
		END
		GOTO HANDLE_SUCESS
	END
	ELSE
	BEGIN
		GOTO HANDLE_ERROR
	END
	
	HANDLE_SUCESS:
		IF @@TRANCOUNT > 0
			COMMIT TRANSACTION
			RETURN	
	
	HANDLE_ERROR:
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION
			RETURN	
    
END
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
(CASE WHEN BatchesRows.WILocation IS NULL THEN NULL ELSE BatchesRows.WILocation END) AS jobWILocation,BatchesRows.TestCenterLocationID,
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
					  TestCenterLocationID,
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
                      INNER JOIN DeviceTrackingLog AS dtl 
                      INNER JOIN TrackingLocations AS tl ON dtl.TrackingLocationID = tl.ID 
                      INNER JOIN TestUnits AS tu ON dtl.TestUnitID = tu.ID ON b.id = tu.batchid --batches where there's a tracking log
                      inner join Products p on p.ID=b.ProductID
					  LEFT OUTER JOIN Jobs j ON j.JobName = b.JobName
					  LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
					LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID 
					LEFT OUTER JOIN Lookups l3 ON l3.Type='TestCenter' AND b.TestCenterLocationID=l3.LookupID   
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
	@TestCenterLocation as INT= null,
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
	and (@TestCenterLocation is null or TestCenterLocationID = @TestCenterLocation)) as batchcount)
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
				case when @sortExpression='testcenter' and @direction='asc' then TestCenterLocationID end,
				case when @sortExpression='testcenter' and @direction='desc' then TestCenterLocationID end desc,
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
		b.TestCenterLocationID,
		b.TestCenterLocation,
		b.RequestPurpose,
		(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = b.ProductGroupName)  end) as rfBands,
		b.TestStageCompletionStatus,
		(select COUNT (*) from TestUnits as tu where tu.id = b.ID) as testunitcount
		FROM 
		(
			select distinct b.*, p.ProductGroupName, l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, l3.[Values] As TestCenterLocation
			from Batches as b
				INNER JOIN TestStages as ts ON (ts.TestStageName = b.TestStageName)
				INNER JOIN TestUnits as tu ON (tu.BatchID = b.ID)
				INNER JOIN Products p ON p.ID=b.ProductID
				LEFT OUTER JOIN Jobs j ON (j.JobName = b.JobName)
				LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID  
				LEFT OUTER JOIN Lookups l3 ON l3.Type='TestCenter' AND b.TestCenterLocationID=l3.LookupID 
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
				and (@TestCenterLocation is null or TestCenterLocationID = @TestCenterLocation)
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
	@testLocationID INT
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
	INNER JOIN TestUnits tu ON b.ID = tu.BatchID
	INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus = 8 and ba.inserttime between @startdate and @enddate
	INNER JOIN BatchesAudit ba2 WITH(NOLOCK) ON b.ID = ba2.BatchID AND ba2.BatchStatus <> 8 and ba2.inserttime between @startdate and @enddate
	INNER JOIN Products p ON p.ID=b.ProductID
WHERE (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
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
	and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
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
WHERE (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
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
WHERE ba.inserttime between @startdate and @enddate and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
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
WHERE ba.inserttime between @startdate and @enddate and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
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
	and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
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
	and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
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
	and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
GROUP BY p.productgroupname
ORDER BY p.productgroupname

SELECT (CASE WHEN @reportBasedOn=1 THEN COUNT(DISTINCT b.ID) ELSE COUNT(distinct tu.id) END) AS [# Worked On Component], p.productgroupname
FROM Batches b WITH(NOLOCK)
	INNER JOIN BatchesAudit ba WITH(NOLOCK) ON b.ID = ba.BatchID AND ba.BatchStatus=2 --InProgress
	INNER JOIN TestUnits tu WITH(NOLOCK) ON b.ID = tu.BatchID
	INNER JOIN Products p ON p.ID=b.ProductID
	INNER JOIN Lookups l ON b.ProductTypeID = l.LookupID AND l.Type='ProductType'
WHERE ba.inserttime between @startdate and @enddate AND l.[Values] = 'Component'
	and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
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
	and (b.TestCenterLocationID = @testLocationID or @testLocationID is null) 
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
	select ROW_NUMBER() over (order by p.ProductGroupName desc)as row, pvt.ID, null as batchunitnumber, pvt.[ReasonForRequest], p.ProductGroupName,
	(select jobname from jobs,TestStages where teststages.id =pvt.TestStageid and Jobs.ID = TestStages.jobid) as jobname, 
	(select teststagename from teststages where teststages.id =pvt.TestStageid) as teststagename, 
	t.TestName,pvt.TestStageID, pvt.TestUnitID,
	(select top 1 LastUser from TestExceptions WHERE ID=pvt.ID) AS LastUser,
	(select top 1 ConcurrencyID from TestExceptions WHERE ID=pvt.ID) AS ConcurrencyID,
	pvt.ProductTypeID, pvt.AccessoryGroupID, pvt.ProductID, l.[Values] As ProductType, l2.[Values] As AccessoryGroupName
	FROM vw_ExceptionsPivoted as pvt
		LEFT OUTER JOIN Tests t ON pvt.Test = t.ID
		LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND l.LookupID=pvt.ProductTypeID
		LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND l2.LookupID=pvt.AccessoryGroupID
		LEFT OUTER JOIN Products p ON p.ID=pvt.ProductID
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
PRINT N'Altering [dbo].[remispUsersSelectListByTestCentre]'
GO
ALTER PROCEDURE [dbo].[remispUsersSelectListByTestCentre] @TestLocation INT, @RecordCount int = NULL OUTPUT
AS
	DECLARE @ConCurID timestamp
	DECLARE @TestCenter NVARCHAR(200)

	SELECT @TestCenter = [Values] FROM Lookups WHERE LookupID=@TestLocation

	IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (SELECT COUNT(*) FROM Users WHERE TestCentre=@TestCenter)
		RETURN
	END

	SELECT UsersRows.BadgeNumber,UsersRows.ConcurrencyID,UsersRows.ID,usersrows.TestCentre, UsersRows.LastUser,UsersRows.LDAPLogin,UsersRows.Row   
	FROM     
		(
			SELECT ROW_NUMBER() OVER (ORDER BY ID) AS Row, Users.BadgeNumber,Users.ConcurrencyID,Users.ID,Users.LastUser,Users.LDAPLogin, Users.TestCentre
			FROM Users
			WHERE TestCentre=@TestCenter
		) AS UsersRows
	WHERE UsersRows.TestCentre = @TestCenter
	order by LDAPLogin
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
	@TestCenterLocation as Int= null,
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
			and (@TestCenterLocation is null or TestCenterLocationID = @TestCenterLocation)) as batchcount)
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
		) AS HasBatchSpecificExceptions, BatchesRows.TestCenterLocationID
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
				case when @sortExpression='testcenter' and @direction='asc' then TestCenterLocationID end,
				case when @sortExpression='testcenter' and @direction='desc' then TestCenterLocationID end desc,
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
			b.TestCenterLocationID,
			b.TestCenterLocation,
			b.RequestPurpose,
			b.WILocation,
			(case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = b.ProductGroupName)  end) as rfBands,
			b.TestStageCompletionStatus,
			(select COUNT (*) from TestUnits as tu where tu.id = b.ID) as testunitcount,b.RQID,
			JobID
			FROM
			(
				select distinct b.* ,p.ProductGroupName,j.WILocation, l.[Values] As ProductType, l2.[Values] As AccessoryGroupName,j.ID As JobID, l3.[Values] As TestCenterLocation
				from Batches as b--, TestStages as ts, TestUnits as tu, Jobs j--, Products p
					LEFT OUTER join TestStages ts ON ts.TestStageName = b.TestStageName and ts.TestStageType =  @GetBatchesAtEnvStages
					LEFT OUTER join TestUnits tu ON tu.BatchID = b.ID
					LEFT OUTER JOIN Products p ON p.ID = b.ProductID
					LEFT OUTER join Jobs j ON j.JobName =b.JobName and ts.JobID = j.ID
					LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
					LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID  
				LEFT OUTER JOIN Lookups l3 ON l3.Type='TestCenter' AND b.TestCenterLocationID=l3.LookupID 
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
				and (@TestCenterLocation is null or TestCenterLocationID = @TestCenterLocation)
			) as b
		) AS BatchesRows 
	WHERE
		(
			(Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) 
			OR 
			@startRowIndex = -1 OR @maximumRows = -1
		) order by row		
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
		LEFT OUTER JOIN Tests t ON pvt.Test = t.ID
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
				--ELSE
				--BEGIN
				--	INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 5, @TestName, @LastUser)
				--END
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
	@AccessoryGroupID INT = NULL
AS		
	DECLARE @ReturnValue int
	declare @testUnitID int
	declare @ValidInputParams int = 1
	declare @TestStageID int
	--DECLARE @ProductGroupName NVARCHAR(800)
	
	--IF (@ProductID IS NOT NULL AND @ProductID > 0)
	--BEGIN
	--	SELECT @ProductGroupName = ProductGroupName FROM Products WHERE ID=@ProductID
	--END
	--ELSE
	--BEGIN
	--	SET @ProductGroupName = NULL
	--END
	
	--Get the test stage id
	set @TestStageID = (select ts.id from TestStages as ts, Jobs as j where j.JobName = @JobName and ts.JobID = j.ID and ts.TestStageName = @TestStageName)
	PRINT 'TestStageID: ' + CONVERT(NVARCHAR, ISNULL(@TestStageID, ''))
		
	--test if item exists in db already

	set @ReturnValue = (SELECT DISTINCT pvt.ID
	FROM vw_ExceptionsPivoted as pvt
		LEFT OUTER JOIN Tests t ON pvt.Test = t.ID
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
				--ELSE
				--BEGIN
				--	INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 5, @TestName, @LastUser)
				--END
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

		--IF (@ProductGroupName IS NOT NULL)
		--BEGIN
		--	PRINT 'Inserting ProductGroupName'
		--	INSERT INTO TestExceptions (ID, LookupID, Value, LastUser) VALUES (@ID, 1, @ProductGroupName, @LastUser)
		--END

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

	SELECT @ProductID = ID FROM Products WHERE LTRIM(RTRIM(ProductGroupName))= LTRIM(RTRIM(@ProductGroupName))
	SELECT @ProductTypeID = LookupID FROM Lookups WHERE Type='ProductType' AND LTRIM(RTRIM([Values]))= LTRIM(RTRIM(@ProductType))
	SELECT @AccessoryGroupID = LookupID FROM Lookups WHERE Type='AccessoryType' AND LTRIM(RTRIM([Values]))= LTRIM(RTRIM(@AccessoryGroupName))
	SELECT @TestCenterLocationID = LookupID FROM Lookups WHERE Type='TestCenter' AND LTRIM(RTRIM([Values]))= LTRIM(RTRIM(@TestCenterLocation))
	
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
		--@ProductGroupName, 
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
		--ProductGroupName = @ProductGroupName, 
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
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestExceptionsDeleteProductGroupException]'
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
		INNER JOIN Tests t ON pvt.Test = t.ID
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
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTestExceptionsGetBatchOnlyExceptions]'
GO
ALTER procedure [dbo].[remispTestExceptionsGetBatchOnlyExceptions] @qraNumber nvarchar(11) = null
AS
select distinct pvt.id, null as batchunitnumber, pvt.ReasonForRequest,p.ProductGroupName,b.JobName, ts.teststagename
, t.testname, (SELECT TOP 1 LastUser FROM TestExceptions WHERE ID=pvt.ID) AS LastUser,
(SELECT TOP 1 ConcurrencyID FROM TestExceptions WHERE ID=pvt.ID) AS ConcurrencyID, pvt.TestStageID, pvt.TestUnitID ,
pvt.ProductTypeID, pvt.AccessoryGroupID, pvt.ProductID, l.[Values] As ProductType, l2.[Values] As AccessoryGroupName
FROM vw_ExceptionsPivoted as pvt
	LEFT OUTER JOIN Tests t ON pvt.Test = t.ID
	LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND l.LookupID=pvt.ProductTypeID
	LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND l2.LookupID=pvt.AccessoryGroupID
	LEFT OUTER JOIN Products p ON p.ID=pvt.ProductID
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
select distinct pvt.id, tu.BatchUnitNumber, pvt.ReasonForRequest, p.ProductGroupName,b.JobName, 
(select teststagename from teststages where teststages.id =pvt.TestStageid) as teststagename, t.testname,
(SELECT TOP 1 LastUser FROM TestExceptions WHERE ID=pvt.ID) AS LastUser,
(SELECT TOP 1 ConcurrencyID FROM TestExceptions WHERE ID=pvt.ID) AS ConcurrencyID, 
pvt.TestStageID, pvt.TestUnitID,pvt.ProductTypeID, pvt.AccessoryGroupID, pvt.ProductID, l.[Values] As ProductType, l2.[Values] As AccessoryGroupName
FROM vw_ExceptionsPivoted as pvt
	LEFT OUTER JOIN Tests t ON pvt.Test = t.ID
	LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND l.LookupID=pvt.ProductTypeID
	LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND l2.LookupID=pvt.AccessoryGroupID
	LEFT OUTER JOIN Products p ON p.ID=pvt.ProductID
	INNER JOIN testunits tu ON tu.ID=pvt.TestUnitID
	INNER JOIN Batches as b ON b.ID=tu.BatchID
where b.QRANumber = @qranumber and tu.batchid = b.id and pvt.TestUnitID = tu.id
order by pvt.TestUnitID desc,TestName
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesSearch]'
GO
ALTER PROCEDURE [dbo].[remispBatchesSearch]
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
	
	SELECT @TestName = TestName FROM Tests WHERE ID=@TestID 
	SELECT @TestStageName = TestStageName FROM TestStages WHERE ID=@TestStageID 
		
	SELECT TOP 100 BatchesRows.row,BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,BatchesRows.JobName,
		BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroup As ProductGroupName,batchesrows.ProductType,batchesrows.AccessoryGroupName,batchesrows.ProductID, BatchesRows.QRANumber,BatchesRows.RequestPurpose,
		BatchesRows.TestCenterLocationID,BatchesRows.TestStageName,BatchesRows.RFBands, BatchesRows.TestStageCompletionStatus, testUnitCount, 
		(CASE WHEN BatchesRows.WILocation IS NULL THEN NULL ELSE BatchesRows.WILocation END) AS jobWILocation, batchesrows.RQID AS ReqID,
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
			FROM Batches as b
				inner join Products p on b.ProductID=p.id 
				LEFT OUTER JOIN Jobs j ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
				LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID  
				LEFT OUTER JOIN Lookups l3 ON l3.Type='TestCenter' AND b.TestCenterLocationID=l3.LookupID  
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
						FROM TestUnits AS tu, DeviceTrackingLog AS dtl 
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
						FROM TestUnits as tu, devicetrackinglog as dtl, TrackingLocations as tl, Users u
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
						select top 1 tu.BatchID
						from TrackingLocations tl
						inner join devicetrackinglog dtl ON tl.ID=dtl.TrackingLocationID
						inner join TestUnits tu on tu.ID=dtl.TestUnitID
						where TrackingLocationTypeID=@TrackingLocationID
					) = b.ID
				)
				AND b.ID IN (Select distinct batchid FROM BatchesAudit WHERE InsertTime BETWEEN @BatchStart AND @BatchEnd)
		)AS BatchesRows		
	WHERE (Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) OR @startRowIndex is null OR @maximumRows is null
	ORDER BY BatchesRows.QRANumber
	RETURN
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
		INNER JOIN Tests t ON pvt.Test = t.ID
	where [ProductID]=@ProductID AND [TestStageID] IS NULL AND [Test] IS NOT NULL
	
	SELECT TestName AS Name, (CASE WHEN (SELECT TOP 1 ExceptionID FROM @testUnitExemptions WHERE exTestName = t.TestName) IS NOT NULL THEN 'True' ELSE 'False' END ) AS TestUnitException
	FROM Tests t
	WHERE t.TestType = 1
	ORDER BY TestName
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispGetEstimatedTSTime]'
GO
ALTER PROCEDURE [dbo].[remispGetEstimatedTSTime] @BatchID INT, @TestStageName NVARCHAR(400), @JobName NVARCHAR(400), @TSTimeLeft REAL OUTPUT, @JobTimeLeft REAL OUTPUT
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
	DECLARE @TSName NVARCHAR(400)
	SET @TSTimeLeft = 0
	SET @JobTimeLeft = 0

	SELECT ID AS TestUnitID
	INTO #tempUnits
	FROM TestUnits WITH(NOLOCK)
	WHERE BatchID=@BatchID
	ORDER BY TestUnitID	

	SELECT IDENTITY(INT, 1, 1) AS ID, tname, resultbasedontime,expectedDuration, processorder, tsname
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
			SELECT @tname =tname, @resultbasedontime=resultbasedontime,@expectedDuration=expectedDuration, @ProcessOrder=processorder, @TSName=tsname
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
		batchesrows.ProductID,BatchesRows.TestCenterLocationID,
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
			b.RequestPurpose,b.TestCenterLocationID,b.TestStageName, j.WILocation,
			(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
			l2.[Values] As AccessoryGroupName, l.[Values] As ProductType,b.RQID,l3.[Values] As TestCenterLocation
			FROM Batches as b
				inner join Products p on p.ID=b.ProductID
				LEFT OUTER JOIN Jobs j ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs
				LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID  
				LEFT OUTER JOIN Lookups l3 ON l3.Type='TestCenter' AND b.TestCenterLocationID=l3.LookupID  
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
	batchesrows.ProductID,BatchesRows.TestCenterLocationID,
	l3.[Values] AS TestCenterLocation,BatchesRows.TestStageName,
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
		LEFT OUTER JOIN Lookups l3 ON l3.Type='TestCenter' AND BatchesRows.TestCenterLocationID=l3.LookupID  
	WHERE QRANumber = @QRANumber

select bc.DateAdded, bc.ID, bc.[Text], bc.LastUser from BatchComments as bc where BatchID = @batchid and Active = 1 order by DateAdded desc;
	RETURN
GO
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
	@TestCentreLocation INT =null,
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
	BatchesRows.AccessoryGroupID,BatchesRows.ProductTypeID,BatchesRows.RQID As ReqID, batchesrows.TestCenterLocationID
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
					  TestCenterLocationID,
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
					  l3.[Values] As TestCenterLocation,
					  b.ProductTypeID,
					  b.AccessoryGroupID,
					  p.ID As ProductID,
                      b.JobName, 
                      b.LastUser, 
                      b.TestCenterLocationID,
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
					LEFT OUTER JOIN Lookups l3 ON l3.Type='TestCenter' AND b.TestCenterLocationID=l3.LookupID  
WHERE   (b.TestCenterLocationID = @TestCentreLocation or @TestCentreLocation is null) and j.TechnicalOperationsTest = 1 and j.MechanicalTest=1 and  tlt.TrackingLocationFunction= 4  AND dtl.OutTime IS NULL AND dtl.OutUser IS NULL)as b) as batchesrows
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
	@TestCentreLocation INT =null,
	@RecordCount int = NULL OUTPUT,
	@sortExpression varchar(100) = null,
	@direction varchar(100) = 'desc'
AS
IF @TestCentreLocation = 0 
BEGIN
	SET @TestCentreLocation = NULL
END

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
					LEFT OUTER JOIN Lookups l3 ON l3.Type='TestCenter' AND b.TestCenterLocationID=l3.LookupID  	
				WHERE (b.TestCenterLocationID = @TestCentreLocation or @TestCentreLocation is null) and b.BatchStatus = 8
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
	@TestCentreLocation INT =null,
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
	BatchesRows.ProductTypeID, batchesrows.AccessoryGroupID,BatchesRows.RQID As ReqID, batchesrows.TestCenterLocationID
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
					  TestCenterLocationID,
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
					  l3.[Values] As TestCenterLocation,
					  p.ID As productID,
                      b.JobName, 
                      b.LastUser, 
                      b.TestCenterLocationID,
                      b.ConcurrencyID,
                      (case when b.RFBands IS null then (select rfbands.RFBands from RFBands where rfbands.ProductGroupName = p.ProductGroupName)  end) as rfBands,
                      b.TestStageCompletionStatus,
                      j.WILocation,b.RQID                     
FROM Batches AS b
	 inner join Products p on b.ProductID=p.id
	 LEFT OUTER JOIN Jobs j ON j.JobName = b.JobName
	 LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND l.LookupID=b.ProductTypeID
	 LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND l2.LookupID=b.AccessoryGroupID
	 LEFT OUTER JOIN Lookups l3 ON l3.Type='TestCenter' AND b.TestCenterLocationID=l3.LookupID  
WHERE (b.TestCenterLocationID = @TestCentreLocation or @TestCentreLocation is null) and (b.BatchStatus = 1 or b.BatchStatus = 3) )as b) as batchesrows
 	WHERE
	 ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) 
			OR @startRowIndex = -1 OR @maximumRows = -1) order by QRANumber desc
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispInventoryReport]'
GO
ALTER procedure [dbo].[remispInventoryReport]
	@StartDate datetime,
	@EndDate datetime,
	@FilterBasedOnQraNumber bit,
	@geographicallocation INT = NULL
AS

IF @geographicallocation = 0
	SET @geographicallocation = NULL

declare @startYear int = Right(year( @StartDate), 2);
declare @endYear int = Right(year( @EndDate), 2);
declare @AverageTestUnitsPerBatch int = -1

declare @TotalBatches int = (select COUNT(*) from BatchesAudit  where 
 BatchesAudit.InsertTime >= @StartDate and BatchesAudit.InsertTime <= @EndDate and BatchesAudit.Action = 'I' 
 and (@FilterBasedOnQraNumber = 0 or (Convert(int , SUBSTRING(BatchesAudit.QRANumber, 5, 2)) >= @startYear
 and Convert(int , SUBSTRING(BatchesAudit.QRANumber, 5, 2)) <= @endYear))
 and (@geographicallocation IS NULL or BatchesAudit.TestCenterLocationID = @geographicallocation)
 );

declare @TotalTestUnits int =(select COUNT(*) as TotalTestUnits from TestUnitsAudit, batchesaudit  where 
 TestUnitsAudit.InsertTime >= @StartDate and TestUnitsAudit.InsertTime <= @EndDate and TestUnitsAudit.Action = 'I' 
 and BatchesAudit.InsertTime >= @StartDate and BatchesAudit.InsertTime <= @EndDate and BatchesAudit.Action = 'I' 
 and (@FilterBasedOnQraNumber = 0 or (Convert(int , SUBSTRING(batchesaudit.QRANumber, 5, 2)) >= @startYear
 and Convert(int , SUBSTRING(batchesaudit.QRANumber, 5, 2)) <= @endYear))
and TestUnitsAudit.BatchID = Batchesaudit.batchID 
and (@geographicallocation IS NULL or batchesaudit.TestCenterLocationID = @geographicallocation)
);

if @TotalBatches != 0
begin
 set @AverageTestUnitsPerBatch = @totaltestunits / @totalbatches;
end

select @TotalBatches as TotalBatches, @TotalTestUnits as TotalTestUnits, @AverageTestUnitsPerBatch as AverageUnitsPerBatch;

select products.ProductGroupName as ProductGroup, COUNT( distinct BatchesAudit.id) as TotalBatches,
COUNT(TestUnits.ID) as TotalTestUnits 
from BatchesAudit,testunits , Products 
where Products.ID=BatchesAudit.ProductID and 
BatchesAudit.InsertTime >= @StartDate and BatchesAudit.InsertTime <= @EndDate and BatchesAudit.Action = 'I' 
and (@FilterBasedOnQraNumber = 0 or (Convert(int , SUBSTRING(BatchesAudit.QRANumber, 5, 2)) >= @startYear
and Convert(int , SUBSTRING(BatchesAudit.QRANumber, 5, 2)) <= @endYear)) 
and (BatchesAudit.TestCenterLocationID = @geographicallocation or @geographicallocation IS NULL)
and BatchesAudit.BatchID = TestUnits.BatchID 
group by productgroupname;
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispCountUnitsInLocation]'
GO
ALTER procedure [dbo].[remispCountUnitsInLocation]
@startDate datetime,
@endDate datetime,
@geoGraphicalLocation int,
@FilterBasedOnQraNumber bit,
@productID INT
AS
declare @startYear int = Right(year( @StartDate), 2);
declare @endYear int = Right(year( @EndDate), 2);

IF @geoGraphicalLocation = 0
	SET @geoGraphicalLocation = NULL

select tl.TrackingLocationName, count(tu.id) as CountedUnits 
from TestUnits as tu, trackinglocations as tl, DeviceTrackingLog as dtl, Batches as b,Products p 
where tu.ID = dtl.TestUnitID and dtl.TrackingLocationID = tl.ID and dtl.OutUser is null and tu.BatchID = b.id
and dtl.InTime > @StartDate and dtl.InTime < @EndDate 
and (@FilterBasedOnQraNumber = 0 or (Convert(int , SUBSTRING(b.QRANumber, 5, 2)) >= @startYear
and Convert(int , SUBSTRING(b.QRANumber, 5, 2)) <= @endYear))
and (p.ID = @productID or @productID = 0)
and (b.TestCenterLocationID = @geoGraphicalLocation or @geoGraphicalLocation IS NULL) and p.ID=b.ProductID
group by TrackingLocationName 
union all
select 'Total', count(tu.id) as CountedUnits 
from TestUnits as tu, trackinglocations as tl, DeviceTrackingLog as dtl, Batches as b, Products p 
where tu.ID = dtl.TestUnitID and dtl.TrackingLocationID = tl.ID and dtl.OutUser is null and tu.BatchID = b.id
and dtl.InTime > @StartDate and dtl.InTime < @EndDate 
and (@FilterBasedOnQraNumber = 0 or (Convert(int , SUBSTRING(b.QRANumber, 5, 2)) >= @startYear
and Convert(int , SUBSTRING(b.QRANumber, 5, 2)) <= @endYear))
and (p.ID = @productID or @productID = 0)
and (b.TestCenterLocationID  = @geoGraphicalLocation or @geoGraphicalLocation IS NULL)
and p.ID=b.ProductID
order by TrackingLocationName asc
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispTrackingLocationsSearchFor]'
GO
ALTER PROCEDURE [dbo].[remispTrackingLocationsSearchFor]
/*	'===============================================================
	'   NAME:                	remispTrackingLocationsSearchFor
	'   DATE CREATED:       	21 Oct 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves paged data from table: TrackingLocations OR the number of records in the table
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/
@RecordCount int = NULL OUTPUT,
@ID int = null,
@TrackingLocationName nvarchar(400)= null, 
@GeoLocationID INT= null, 
@Status int = null,
@TrackingLocationTypeID int= null,
@TrackingLocationTypeName nvarchar(400)=null,
@TrackingLocationFunction int = null,
@HostName nvarchar(255) = null
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
	)
	RETURN
END

SELECT DISTINCT tl.ID, tl.TrackingLocationName, tl.TestCenterLocationID, CASE WHEN tlh.Status IS NULL THEN 3 ELSE tlh.Status END AS Status, tl.LastUser, tlh.HostName,
	tl.ConcurrencyID, tl.comment,l3.[Values] AS GeoLocationName,
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
	ISNULL(tl.Decommissioned, 0) AS Decommissioned
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
			tlh.HostName='all'
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
	ORDER BY ISNULL(tl.Decommissioned, 0), tl.TrackingLocationName
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
		batchesrows.testUnitCount,BatchesRows.RQID As ReqID,batchesrows.TestCenterLocationID,
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
				b.RequestPurpose,b.TestCenterLocationID,b.TestStageName, j.WILocation,
				(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
				l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, b.RQID, l3.[Values] As TestCenterLocation
			FROM Batches as b
				inner join Products p on p.ID=b.ProductID
				LEFT OUTER JOIN Jobs j ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
				LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID
				LEFT OUTER JOIN Lookups l3 ON l3.Type='TestCenter' AND b.TestCenterLocationID=l3.LookupID    
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
PRINT N'Altering [dbo].[remispTrackingLocationsInsertUpdateSingleItem]'
GO
ALTER PROCEDURE [dbo].[remispTrackingLocationsInsertUpdateSingleItem]
/*	'===============================================================
	'   NAME:                	remispTrackingLocationsInsertUpdateSingleItem
	'   DATE CREATED:       	20 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Creates or updates an item in a table: TrackingLocations
	'   IN:        ID, TrackingLocationName, UnitCapacity, TrackingLocationType, GeoLocationId,  InsertUser, UpdateUser, Visible      
	'   OUT: 		ID, ConcurrencyID         
	'   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
	@ID int OUTPUT,
	@trackingLocationName nvarchar(400),
	@TrackingLocationTypeID int, 
	@GeoLocationID INT, 
	@ConcurrencyID rowversion OUTPUT,
	@Status int,
	@LastUser nvarchar(255),
	@Comment nvarchar(1000) = null,
	@HostName nvarchar(255) = null,
	@Decommissioned BIT = 0
	AS

	DECLARE @ReturnValue int
	declare @AlreadyExists as integer 
	IF (@ID IS NULL) -- New Item
	BEGIN

	IF (@ID IS NULL) -- New Item
	BEGIN
		set @AlreadyExists = (select ID from TrackingLocations 
		where TrackingLocationName = @trackingLocationName and TestCenterLocationID = @GeoLocationID)

		if (@AlreadyExists is not null) 
			return -1
		end

		PRINT 'INSERTING'

		INSERT INTO TrackingLocations (TrackingLocationName, TestCenterLocationID, TrackingLocationTypeID, LastUser, Comment, Decommissioned)
		VALUES (@TrackingLocationname, @GeoLocationID, @TrackingLocationtypeID, @LastUser, @Comment, @Decommissioned)
			
		SELECT @ReturnValue = SCOPE_IDENTITY()

		INSERT INTO TrackingLocationsHosts (TrackingLocationID, HostName, LastUser, Status) VALUES (@ReturnValue, @HostName, @LastUser, @Status)
	END
	ELSE -- Exisiting Item
	BEGIN
		PRINT 'UDPATING TrackingLocations'
		
		UPDATE TrackingLocations 
		SET TrackingLocationName=@TrackingLocationName, 
			TestCenterLocationID=@GeoLocationID, 
			TrackingLocationTypeID=@TrackingLocationtypeID,
			LastUser = @LastUser,
			Comment = @Comment,
			Decommissioned = @Decommissioned
		WHERE ID = @ID AND ConcurrencyID = @ConcurrencyID
		
		SELECT @ReturnValue = @ID
	END

	SET @ConcurrencyID = (SELECT ConcurrencyID FROM TrackingLocations WHERE ID = @ReturnValue)
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
PRINT N'Altering [dbo].[RemispGetTestCountByType]'
GO
ALTER PROCEDURE [dbo].[RemispGetTestCountByType] @StartDate DateTime = NULL, @EndDate DateTime = NULL, @ReportBasedOn INT = NULL, @GeoLocationID INT, @GroupByType INT = 1, @BasedOn NVARCHAR(60)
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
				AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
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
				AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
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
				AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
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
				AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
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
				AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
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
				AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
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
				AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
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
				AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
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
				AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
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
				AND (@GeoLocationID IS NULL OR tl.TestCenterLocationID = @GeoLocationID)
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
PRINT N'Altering [dbo].[remispBatchesSelectBatchesNotInREMSTAR]'
GO
ALTER PROCEDURE [dbo].[remispBatchesSelectBatchesNotInREMSTAR]
AS
select QRANumber, BatchUnitNumber, tl.TrackingLocationName,dtl.InTime, dtl.InUser,
	(select AssignedTo 
	from TaskAssignments as ta
		INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=b.TestStageName 
		INNER JOIN Jobs j ON j.ID = ts.JobID AND j.JobName = b.JobName
	where ta.BatchID = b.ID and ta.Active=1) as ActiveTaskAssignee
FROM TestUnits tu
	INNER JOIN Batches b ON b.ID = tu.BatchID 
	INNER JOIN DeviceTrackingLog dtl ON tu.ID = dtl.TestUnitID
	INNER JOIN TrackingLocations tl ON dtl.TrackingLocationID = tl.id
	INNER JOIN TrackingLocationTypes tlt ON tlt.ID = tl.TrackingLocationTypeID AND tlt.ID != 103 --external location
where dtl.OutTime is null and dtl.ID = (select max(id) from DeviceTrackingLog where DeviceTrackingLog.testunitid = tu.id)
and tl.TestCenterLocationID = (SELECT LookupID FROM Lookups WHERE Type='TestCenter' AND [values] = 'Cambridge')
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
		) as ActiveTaskAssignee, CONVERT(BIT,0) AS HasBatchSpecificExceptions, batchesrows.AccessoryGroupID,batchesrows.ProductTypeID, BatchesRows.TestCenterLocationID
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
			TestCenterLocationID,
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
				l3.[Values] AS TestCenterLocation,
				p.ID as ProductID,
				b.JobName, 
				b.LastUser, 
				b.TestCenterLocationID,
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
				LEFT OUTER JOIN Lookups l3 ON l3.Type='TestCenter' AND b.TestCenterLocationID=l3.LookupID  
			WHERE b.BatchStatus NOT IN (5,8) AND b.Jobname=@JobName AND dtl.OutTime IS NULL AND dtl.OutUser IS NULL
		)as b
	) as batchesrows 	
	WHERE ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) OR @startRowIndex = -1 OR @maximumRows = -1) 
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering permissions on [dbo].[remispGetEnvironmentalStressSchedule]'
GO
GRANT EXECUTE ON  [dbo].[remispGetEnvironmentalStressSchedule] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispTrackingLocationsSearchFor]'
GO
GRANT EXECUTE ON  [dbo].[remispTrackingLocationsSearchFor] TO [remi]
GO
PRINT N'Altering permissions on [dbo].[remispTrackingLocationsInsertUpdateSingleItem]'
GO
GRANT EXECUTE ON  [dbo].[remispTrackingLocationsInsertUpdateSingleItem] TO [remi]
GO
ALTER PROCEDURE [dbo].remispProductConfigurationUpload AS
BEGIN
	CREATE TABLE #temp2 (ID INT, ParentID INT, NodeType INT, LocalName NVARCHAR(100), Text NVARCHAR(100), ID_temp INT IDENTITY(1,1), ID_NEW INT, ParentID_NEW INT)
	DECLARE @ProductID INT
	DECLARE @TestID INT
	DECLARE @MaxID INT
	DECLARE @MaxLookupID INT
	DECLARE @idoc INT
	DECLARE @ID INT
	DECLARE @xml XML
	DECLARE @LastUser NVARCHAR(255)

	IF ((SELECT COUNT(*) FROM ProductConfigurationUpload WHERE ISNULL(IsProcessed,0)=0)=0)
		RETURN

	SELECT TOP 1 @ID=ID, @xml =ProductConfigXML, @ProductID=ProductID, @TestID=TestID, @LastUser=LastUser
	FROM ProductConfigurationUpload 
	WHERE ISNULL(IsProcessed,0)=0

	exec sp_xml_preparedocument @idoc OUTPUT, @xml
	
	SELECT @MaxID = ISNULL(MAX(ID),0)+1 FROM ProductConfiguration
	SELECT @MaxLookupID = MAX(LookupID)+1 FROM Lookups

	SELECT * 
	INTO #temp
	FROM OPENXML(@idoc, '/')

	INSERT INTO #temp2 (ID, ParentID, NodeType, LocalName, Text, ParentID_NEW)
	SELECT ID, ParentID, NodeType, LocalName, '' AS Text, 0 AS ParentID_NEW
	FROM #temp 
	WHERE NodeType=1 AND (SELECT COUNT(ParentID) FROM #temp t WHERE t.ParentID=#temp.ID)>1
	UNION
	SELECT ID, ParentID, NodeType, LocalName, '' AS Text, 0 AS ParentID_NEW
	FROM #temp 
	WHERE NodeType=1 AND (SELECT COUNT(*) FROM #temp t1 WHERE t1.NodeType=1 AND t1.ParentID=#temp.ID  GROUP BY t1.ParentID )=1
	UNION
	SELECT ID, ParentID, NodeType, LocalName, '' AS Text, 0 AS ParentID_NEW
	FROM #temp 
	WHERE NodeType=1 AND (SELECT COUNT(ParentID) FROM #temp t WHERE t.ParentID=#temp.ID)=1
	
	UPDATE #temp2
	SET ID_NEW = ID_temp + @MaxID

	UPDATE #temp2
	SET ParentID_NEW = (SELECT t.ID_NEW FROM #temp2 t WHERE #temp2.ParentID=t.ID)
	WHERE #temp2.ParentID IS NOT NULL

	SET IDENTITY_INSERT ProductConfiguration ON

	INSERT INTO ProductConfiguration (ID, ParentId, ViewOrder, NodeName, TestID, LastUser, ProductID)
	SELECT ID_NEW, CASE WHEN ParentID_NEW = 0 THEN NULL ELSE ParentID_NEW END, ROW_NUMBER() OVER (ORDER BY id) AS ViewOrder, LocalName, @TestID, @LastUser, @ProductID
	FROM #temp2
	ORDER BY ID, parentid

	SET IDENTITY_INSERT ProductConfiguration OFF
	
	SELECT DISTINCT 0 AS LookupID, 'Configuration' AS Type, LTRIM(RTRIM(LocalName)) AS LocalName, IDENTITY(int,1,1) As ID
	INTO #temp3
	FROM #temp 
	WHERE NodeType=2 AND LocalName NOT IN (SELECT Lookups.[Values] FROM Lookups WHERE Type='Configuration')

	UPDATE #temp3 SET LookupID=ID+@MaxLookupID

	insert into Lookups (LookupID, Type, [Values])
	select LookupID, Type, localname as [Values] from #temp3
	

	INSERT INTO ProductConfigValues (Value, LookupID, ProductConfigID, LastUser, IsAttribute)
	SELECT (SELECT t2.Text FROM #temp t2 WHERE t2.NodeType=3 AND t2.ParentID=#temp.ID) AS Value, 
		CASE WHEN #temp.NodeType=2 THEN (SELECT LookupID FROM Lookups WHERE Type='Configuration' AND [values]=#temp.LocalName) ELSE NULL END As LookupID, 
		(SELECT ID_NEW FROM #temp2 WHERE #temp.ParentID=#temp2.ID) AS ProductConfigID, @LastUser As LastUser, 1 AS IsAttribute
	FROM #temp
	WHERE #temp.NodeType=2

	INSERT INTO ProductConfigValues (Value, LookupID, ProductConfigID, LastUser, IsAttribute)
	SELECT #temp.Text AS Value, (SELECT Lookups.LookupID FROM #temp t INNER JOIN Lookups ON Type='Configuration' AND [Values]=t.LocalName WHERE t.NodeType=1 AND t.id=#temp.parentid) AS LookupID,
		(SELECT #temp2.ID_NEW 
		FROM #temp2 	
			INNER JOIN #temp t1 ON t1.NodeType=1 AND #temp2.ID=t1.parentid
		WHERE #temp.ParentID=t1.ID) AS ProductConfigID, 
		@LastUser As LastUser, 0 AS IsAttribute
	FROM #temp
	WHERE NodeType=3 AND ParentID NOT IN (Select ID FROM #temp WHERE #temp.NodeType=2)

	DROP TABLE #temp2
	DROP TABLE #temp
	DROP TABLE #temp3
	
	UPDATE ProductConfigurationUpload SET IsProcessed=1 WHERE ID=@ID
END
GO
GRANT EXECUTE ON remispProductConfigurationUpload TO Remi
GO
CREATE PROCEDURE [dbo].remispProductConfigurationProcess @ProductID INT, @TestID INT, @XML AS NTEXT, @LastUser As NVARCHAR(255)
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM ProductConfigurationUpload WHERE TestID=@TestID AND ProductID=@ProductID)
		INSERT INTO ProductConfigurationUpload (ProductConfigXML, ProductID, TestID, LastUser) Values (CONVERT(XML, @XML), @ProductID, @TestID, @LastUser)
END
GO
GRANT EXECUTE ON remispProductConfigurationProcess TO REMI
GO
ALTER PROCEDURE [dbo].[remispTrackingLocationsHostID] @ComputerName NVARCHAR(255), @TrackingLocationID INT
AS
BEGIN
	DECLARE @ID INT
	SET @ID = 0

	SELECT @ID=ID FROM TrackingLocationsHosts WHERE HostName=@ComputerName AND TrackingLocationID=@TrackingLocationID

	Return @ID
END
GRANT EXECUTE ON remispTrackingLocationsHostID TO Remi
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