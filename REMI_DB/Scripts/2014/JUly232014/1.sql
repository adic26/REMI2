/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        (local).REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 7/18/2014 8:12:19 AM

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
alter table Lookups add Description NVARCHAR(200) NULL
go
insert into aspnet_Permissions (Permission, ApplicationId) values ('HasBatchSetupAuthority','892170d7-f95a-4ae1-a7e7-c1994d392790')
go
declare @permissionid uniqueidentifier
select @permissionid=permissionid from aspnet_Permissions where Permission='HasBatchSetupAuthority'
insert into aspnet_PermissionsInRoles (RoleID,PermissionID) values ('94135D25-304B-412C-B4CB-BAA12516D0F0',@permissionid)
insert into aspnet_PermissionsInRoles (RoleID,PermissionID) values ('6AA3911E-F98C-408D-8F18-DB954FDBE62B',@permissionid)
go


declare @lookupID INT
select @lookupID = MAX(lookupid) + 1 from Lookups
insert into Lookups (LookupID, IsActive,Type,[Values], Description) Values (@lookupID, 1, 'RequestPurpose', 'PCQ','Design/Process/Part Change Qualification')
update Batches set RequestPurpose=@lookupID WHERE RequestPurpose=4
SET @LookupID = @lookupID+1
insert into Lookups (LookupID, IsActive,Type,[Values], Description) Values (@lookupID, 1, 'RequestPurpose', 'NPQ','New Product Qualification')
update Batches set RequestPurpose=@lookupID WHERE RequestPurpose=1
SET @LookupID = @lookupID+1
insert into Lookups (LookupID, IsActive,Type,[Values], Description) Values (@lookupID, 1, 'RequestPurpose', 'OMM','Outsourced Manufacturing Monitoring')
update Batches set RequestPurpose=@lookupID WHERE RequestPurpose=8
SET @LookupID = @lookupID+1
insert into Lookups (LookupID, IsActive,Type,[Values], Description) Values (@lookupID, 1, 'RequestPurpose', 'OMQ','Outsourced Manufacturing Qualification')
update Batches set RequestPurpose=@lookupID WHERE RequestPurpose=6
SET @LookupID = @lookupID+1
insert into Lookups (LookupID, IsActive,Type,[Values], Description) Values (@lookupID, 1, 'RequestPurpose', 'ORMAQ','Outsourced RMA Qualification')
update Batches set RequestPurpose=@lookupID WHERE RequestPurpose=10
SET @LookupID = @lookupID+1
insert into Lookups (LookupID, IsActive,Type,[Values], Description) Values (@lookupID, 1, 'RequestPurpose', 'ORQ','Outsourced Repair Qualification')
update Batches set RequestPurpose=@lookupID WHERE RequestPurpose=7
SET @LookupID = @lookupID+1
insert into Lookups (LookupID, IsActive,Type,[Values], Description) Values (@lookupID, 1, 'RequestPurpose', 'PRM','Production Reliability Monitoring')
update Batches set RequestPurpose=@lookupID WHERE RequestPurpose=2
SET @LookupID = @lookupID+1
insert into Lookups (LookupID, IsActive,Type,[Values], Description) Values (@lookupID, 1, 'RequestPurpose', 'RMAQ','RMA Qualification')
update Batches set RequestPurpose=@lookupID WHERE RequestPurpose=9
SET @LookupID = @lookupID+1
insert into Lookups (LookupID, IsActive,Type,[Values], Description) Values (@lookupID, 1, 'RequestPurpose', 'SQ','Supplier Qualification')
update Batches set RequestPurpose=@lookupID WHERE RequestPurpose=5
SET @LookupID = @lookupID+1
insert into Lookups (LookupID, IsActive,Type,[Values], Description) Values (@lookupID, 1, 'RequestPurpose', 'SS','Storage')
update Batches set RequestPurpose=@lookupID WHERE RequestPurpose=12
SET @LookupID = @lookupID+1
insert into Lookups (LookupID, IsActive,Type,[Values], Description) Values (@lookupID, 1, 'RequestPurpose', 'CFE','Component Focused Evaluation')
update Batches set RequestPurpose=@lookupID WHERE RequestPurpose=13
SET @LookupID = @lookupID+1
insert into Lookups (LookupID, IsActive,Type,[Values], Description) Values (@lookupID, 1, 'RequestPurpose', 'CR','Carrier Requirement')
update Batches set RequestPurpose=@lookupID WHERE RequestPurpose=14
SET @LookupID = @lookupID+1
insert into Lookups (LookupID, IsActive,Type,[Values], Description) Values (@lookupID, 1, 'RequestPurpose', 'CTR','Custom Test Request')
update Batches set RequestPurpose=@lookupID WHERE RequestPurpose=15
SET @LookupID = @lookupID+1
insert into Lookups (LookupID, IsActive,Type,[Values], Description) Values (@lookupID, 1, 'RequestPurpose', 'TD','Test Development')
update Batches set RequestPurpose=@lookupID WHERE RequestPurpose=16
SET @LookupID = @lookupID+1
insert into Lookups (LookupID, IsActive,Type,[Values], Description) Values (@lookupID, 1, 'RequestPurpose', 'IUO','Internal Use Only')
update Batches set RequestPurpose=@lookupID WHERE RequestPurpose=11
SET @LookupID = @lookupID+1
insert into Lookups (LookupID, IsActive,Type,[Values], Description) Values (@lookupID, 0, 'RequestPurpose', 'OQ','Outsourcing Qualification')
insert into Lookups (LookupID, IsActive,Type,[Values], Description) Values (0,1,'NotSet','NotSet',NULL)
update Batches set RequestPurpose=0 WHERE RequestPurpose=3
go
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
	batchesrows.TestStageCompletionStatus,testunitcount,
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
	batchesrows.ProductTypeID,batchesrows.AccessoryGroupID,batchesrows.RQID As ReqID, batchesrows.TestCenterLocationID,
	AssemblyNumber, AssemblyRevision, HWRevision, PartName, ReportRequiredBy, ReportApprovedDate, IsMQual, JobID, MechanicalTools, BatchesRows.RequestPurposeID
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
			b.TestStageCompletionStatus,
			(select count(*) from testunits WITH(NOLOCK) where testunits.batchid = b.id) as testUnitCount,
			b.WILocation,b.RQID, b.AssemblyNumber, b.AssemblyRevision,b.HWRevision, b.PartName, b.ReportRequiredBy, b.ReportApprovedDate, b.IsMQual, JobID, MechanicalTools,
			RequestPurposeID
		FROM 
		(
			SELECT DISTINCT b.ID, 
				b.QRANumber, 
				b.Comment,
				b.RequestPurpose As RequestPurposeID, 
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
				b.TestStageCompletionStatus, j.WILocation,b.RQID, b.AssemblyNumber, b.AssemblyRevision,b.HWRevision, b.PartName, b.ReportRequiredBy, 
				b.ReportApprovedDate, b.IsMQual, j.ID AS JobID, MechanicalTools, l4.[Values] As RequestPurpose
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
				LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON l4.Type='RequestPurpose' AND b.RequestPurpose=l4.LookupID   
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
PRINT N'Altering [dbo].[remispGetLookups]'
GO
ALTER PROCEDURE [dbo].[remispGetLookups] @Type NVARCHAR(150), @ProductID INT = NULL
AS
BEGIN
	SELECT 0 AS LookupID, @Type AS Type, '' As LookupType, CONVERT(BIT, 0) As HasAccess, NULL AS Description
	UNION
	SELECT Lookups.LookupID, Type, [Values] As LookupType, CASE WHEN pl.ID IS NOT NULL THEN CONVERT(BIT, 1) ELSE CONVERT(BIT, 0) END As HasAccess, Description
	FROM Lookups
		LEFT OUTER JOIN ProductLookups pl ON pl.ProductID=@ProductID AND Lookups.LookupID=pl.LookupID
	WHERE Type=@Type AND IsActive=1
	ORDER By LookupType
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
				 batchesrows.TestStageCompletionStatus,testunitcount,
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
	batchesrows.AccessoryGroupID,batchesrows.ProductTypeID,BatchesRows.RQID As ReqID, AssemblyNumber, AssemblyRevision, HWRevision, PartName, ReportRequiredBy, 
	ReportApprovedDate, IsMQual, JobID, ExecutiveSummary, MechanicalTools, batchesrows.RequestPurposeID
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
                      b.TestStageCompletionStatus,
					 (select count(*) from testunits WITH(NOLOCK) where testunits.batchid = b.id) as testUnitCount,
					 b.WILocation, b.RQID, b.AssemblyNumber, b.AssemblyRevision,b.HWRevision, b.PartName, b.ReportRequiredBy, b.ReportApprovedDate, b.IsMQual, JobID,
					 ExecutiveSummary, MechanicalTools, RequestPurposeID
                      from
				(SELECT DISTINCT 
                      b.ID, 
                      b.QRANumber, 
                      b.Comment,
                      b.RequestPurpose As RequestPurposeID, 
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
                      b.TestStageCompletionStatus,
                      j.WILocation,
					  b.RQID, b.AssemblyNumber, b.AssemblyRevision,b.HWRevision, b.PartName, b.ReportRequiredBy, b.ReportApprovedDate, b.IsMQual, j.ID As JobID,
					  ExecutiveSummary, MechanicalTools, l4.[Values] AS RequestPurpose
				FROM Batches AS b 
                      INNER JOIN DeviceTrackingLog AS dtl WITH(NOLOCK) 
                      INNER JOIN TrackingLocations AS tl WITH(NOLOCK) ON dtl.TrackingLocationID = tl.ID 
                      INNER JOIN TestUnits AS tu WITH(NOLOCK) ON dtl.TestUnitID = tu.ID ON b.id = tu.batchid --batches where there's a tracking log
                      inner join Products p WITH(NOLOCK) on p.ID=b.ProductID
					  LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = b.JobName
					  LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
					LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID 
					LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.Type='TestCenter' AND b.TestCenterLocationID=l3.LookupID 
					LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON l4.Type='RequestPurpose' AND b.RequestPurpose=l4.LookupID   
WHERE     tl.id = @TrackingLocationId AND dtl.OutTime IS NULL AND dtl.OutUser IS NULL)as b) as batchesrows
	WHERE
	 ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) 
			OR @startRowIndex = -1 OR @maximumRows = -1) 
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[remispBatchesInsertUpdateSingleItem]'
GO
ALTER PROCEDURE [dbo].[remispBatchesInsertUpdateSingleItem]
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
	@RequestPurpose nvarchar(200),
	@LastUser nvarchar(255),
	@ConcurrencyID rowversion OUTPUT,
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
	@pmNotes nvarchar(500) = null,
	@IsMQual bit = 0,
	@MechanicalTools NVARCHAR(10),
	@RequestPurposeID int = 0
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
	
	IF @RequestPurposeID = 0
	BEGIN
		SELECT @RequestPurposeID = LookupID FROM Lookups WHERE Type='RequestPurpose' AND [Values] = @RequestPurpose
	END

	SELECT @ProductID = ID FROM Products WITH(NOLOCK) WHERE LTRIM(RTRIM(ProductGroupName))= LTRIM(RTRIM(@ProductGroupName))
	SELECT @ProductTypeID = LookupID FROM Lookups WITH(NOLOCK) WHERE Type='ProductType' AND LTRIM(RTRIM([Values]))= LTRIM(RTRIM(@ProductType))
	SELECT @AccessoryGroupID = LookupID FROM Lookups WITH(NOLOCK) WHERE Type='AccessoryType' AND LTRIM(RTRIM([Values]))= LTRIM(RTRIM(@AccessoryGroupName))
	SELECT @TestCenterLocationID = LookupID FROM Lookups WITH(NOLOCK) WHERE Type='TestCenter' AND LTRIM(RTRIM([Values]))= LTRIM(RTRIM(@TestCenterLocation))
		
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
		ProductID, IsMQual, MechanicalTools ) 
		VALUES 
		(@QRANumber, 
		@Priority, 
		@BatchStatus, 
		@JobName,
		@TestStageName,
		@ProductTypeID,
		@AccessoryGroupID,
		@TestCenterLocationID,
		@RequestPurposeID,
		@Comment,
		@LastUser,
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
		@ProductID, @IsMQual, @MechanicalTools )

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
		RequestPurpose=@RequestPurposeID,
		Comment = @Comment, 
		LastUser = @LastUser,
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
		ProductID=@ProductID,
		IsMQual = @IsMQual,
		MechanicalTools = @MechanicalTools
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
	@BatchEnd DateTime = NULL,
	@TestStage NVARCHAR(400) = NULL,
	@TestStageType INT = NULL,
	@excludedTestStageType INT = NULL,
	@ExcludedStatus INT = NULL,
    @TrackingLocationFunction INT = NULL,
	@NotInTrackingLocationFunction INT  = NULL,
	@Revision NVARCHAR(10) = NULL
AS
	DECLARE @TestName NVARCHAR(400)
	DECLARE @TestStageName NVARCHAR(400)
	
	SELECT @TestName = TestName FROM Tests WITH(NOLOCK) WHERE ID=@TestID 
	SELECT @TestStageName = TestStageName FROM TestStages WITH(NOLOCK) WHERE ID=@TestStageID
	CREATE TABLE #ExTestStageType (ID INT)
	CREATE TABLE #ExBatchStatus (ID INT)
	
	IF (@TestStageName IS NOT NULL)
		SET @TestStage = NULL
	
	IF convert(VARCHAR,(@excludedTestStageType & 1) / 1) = 1
	BEGIN
		INSERT INTO #ExTestStageType VALUES (1)
	END
	IF convert(VARCHAR,(@excludedTestStageType & 2) / 2) = 1
	BEGIN
		INSERT INTO #ExTestStageType VALUES (2)
	END
	IF convert(VARCHAR,(@excludedTestStageType & 4) / 4) = 1
	BEGIN
		INSERT INTO #ExTestStageType VALUES (3)
	END
	IF convert(VARCHAR,(@excludedTestStageType & 8) / 8) = 1
	BEGIN
		INSERT INTO #ExTestStageType VALUES (4)
	END
	IF convert(VARCHAR,(@excludedTestStageType & 16) / 16) = 1
	BEGIN
		INSERT INTO #ExTestStageType VALUES (5)
	END
		
	IF convert(VARCHAR,(@ExcludedStatus & 1) / 1) = 1
	BEGIN
		INSERT INTO #ExBatchStatus VALUES (1)
	END
	IF convert(VARCHAR,(@ExcludedStatus & 2) / 2) = 1
	BEGIN
		INSERT INTO #ExBatchStatus VALUES (2)
	END
	IF convert(VARCHAR,(@ExcludedStatus & 4) / 4) = 1
	BEGIN
		INSERT INTO #ExBatchStatus VALUES (3)
	END
	IF convert(VARCHAR,(@ExcludedStatus & 8) / 8) = 1
	BEGIN
		INSERT INTO #ExBatchStatus VALUES (4)
	END
	IF convert(VARCHAR,(@ExcludedStatus & 16) / 16) = 1
	BEGIN
		INSERT INTO #ExBatchStatus VALUES (5)
	END
	IF convert(VARCHAR,(@ExcludedStatus & 32) / 32) = 1
	BEGIN
		INSERT INTO #ExBatchStatus VALUES (6)
	END
	IF convert(VARCHAR,(@ExcludedStatus & 64) / 64) = 1
	BEGIN
		INSERT INTO #ExBatchStatus VALUES (7)
	END
	IF convert(VARCHAR,(@ExcludedStatus & 128) / 128) = 1
	BEGIN
		INSERT INTO #ExBatchStatus VALUES (8)
	END
		
	SELECT TOP 100 BatchesRows.BatchStatus,BatchesRows.Comment,BatchesRows.ConcurrencyID,BatchesRows.ID,BatchesRows.JobName,
		BatchesRows.LastUser,BatchesRows.Priority,BatchesRows.ProductGroup As ProductGroupName,batchesrows.ProductType,batchesrows.AccessoryGroupName,batchesrows.ProductID, 
		BatchesRows.QRANumber,BatchesRows.RequestPurposeID, BatchesRows.TestCenterLocationID,BatchesRows.TestStageName, BatchesRows.TestStageCompletionStatus, testUnitCount, 
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
		CONVERT(BIT,0) AS HasBatchSpecificExceptions, batchesrows.ProductTypeID,batchesrows.AccessoryGroupID, BatchesRows.CurrentTest, BatchesRows.CPRNumber, BatchesRows.RelabJobID, 
		BatchesRows.TestCenterLocation, AssemblyNumber, AssemblyRevision, HWRevision, PartName, ReportRequiredBy, ReportApprovedDate, IsMQual, JobID, DateCreated, ContinueOnFailures,
		MechanicalTools, BatchesRows.RequestPurpose
	FROM     
		(
			SELECT DISTINCT b.BatchStatus,b.Comment, b.teststagecompletionstatus,b.ConcurrencyID,b.ID,b.JobName,b.LastUser,b.Priority,b.ProductTypeID,b.AccessoryGroupID,p.ID As ProductID,
				p.ProductGroupName As ProductGroup,b.QRANumber,b.RequestPurpose As RequestPurposeID,b.TestCenterLocationID,b.TestStageName,j.WILocation,
				(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
				l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, l3.[Values] As TestCenterLocation,
				(
					SELECT top(1) tu.CurrentTestName as CurrentTestName 
					FROM TestUnits AS tu, DeviceTrackingLog AS dtl 
					where tu.ID = dtl.TestUnitID 
					and tu.CurrentTestName is not null
					and (dtl.OutUser IS NULL) AND tu.BatchID=b.ID
				) As CurrentTest, b.CPRNumber,b.RelabJobID, b.RQID, b.AssemblyNumber, b.AssemblyRevision,b.HWRevision, b.PartName, b.ReportRequiredBy, 
				b.ReportApprovedDate, b.IsMQual, j.ID AS JobID, b.DateCreated, j.ContinueOnFailures, MechanicalTools, l4.[Values] As RequestPurpose
			FROM Batches as b WITH(NOLOCK)
				inner join Products p WITH(NOLOCK) on b.ProductID=p.id 
				LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
				LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID  
				LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.Type='TestCenter' AND b.TestCenterLocationID=l3.LookupID
				INNER JOIN TestStages ts WITH(NOLOCK) ON ts.TestStageName=b.TestStageName
				LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON l4.Type='RequestPurpose' AND b.RequestPurpose=l4.LookupID
			WHERE ((BatchStatus NOT IN (SELECT ID FROM #ExBatchStatus) OR @ExcludedStatus IS NULL) AND (BatchStatus = @Status OR @Status IS NULL))
				AND (p.ID = @ProductID OR @ProductID IS NULL)
				AND (b.Priority = @Priority OR @Priority IS NULL)
				AND (b.ProductTypeID = @ProductTypeID OR @ProductTypeID IS NULL)
				AND (b.AccessoryGroupID = @AccessoryGroupID OR @AccessoryGroupID IS NULL)
				AND (b.TestCenterLocationID = @GeoLocationID OR @GeoLocationID IS NULL)
				AND (b.JobName = @JobName OR @JobName IS NULL)
				AND (b.RequestPurpose = @RequestReason OR @RequestReason IS NULL)
				AND (b.MechanicalTools = @Revision OR @Revision IS NULL)
				AND 
				(
					(@TestStage IS NULL AND (b.TestStageName = @TestStageName OR @TestStageName IS NULL))
					OR
					(b.TestStageName = @TestStage AND @TestStageName IS NULL)
				)
				AND ((ts.TestStageType NOT IN (SELECT ID FROM #ExTestStageType) OR @excludedTestStageType IS NULL) AND (ts.TestStageType = @TestStageType OR @TestStageType IS NULL))
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
						b.ID IN (SELECT DISTINCT tu.BatchID
						FROM TrackingLocations tl WITH(NOLOCK)
							INNER JOIN devicetrackinglog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID --AND dtl.OutTime IS NULL
								AND dtl.InTime BETWEEN @BatchStart AND @BatchEnd
						INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID=dtl.TestUnitID
						WHERE TrackingLocationTypeID=@TrackingLocationID)
					)
				)
				AND
				(
					@TrackingLocationFunction IS NULL
					OR
					(
						b.ID IN (select DISTINCT tu.BatchID
						from TrackingLocations tl WITH(NOLOCK)
						inner join devicetrackinglog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID AND dtl.OutTime IS NULL
						inner join TestUnits tu WITH(NOLOCK) on tu.ID=dtl.TestUnitID
						INNER JOIN TrackingLocationTypes tlt WITH(NOLOCK) ON tlt.ID = tl.TrackingLocationTypeID
						where tlt.TrackingLocationFunction=@TrackingLocationFunction)
					)
				)
				AND
				(
					@NotInTrackingLocationFunction IS NULL
					OR
					(
						b.ID IN (select DISTINCT tu.BatchID
						from TrackingLocations tl WITH(NOLOCK)
						inner join devicetrackinglog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID AND dtl.OutTime IS NULL
						inner join TestUnits tu WITH(NOLOCK) on tu.ID=dtl.TestUnitID
						INNER JOIN TrackingLocationTypes tlt WITH(NOLOCK) ON tlt.ID = tl.TrackingLocationTypeID
						where tlt.TrackingLocationFunction NOT IN (@NotInTrackingLocationFunction))
					)
				)
				AND 
				(
					(@BatchStart IS NULL AND @BatchEnd IS NULL)
					OR
					(b.ID IN (Select distinct batchid FROM BatchesAudit WITH(NOLOCK) WHERE InsertTime BETWEEN @BatchStart AND @BatchEnd))
				)
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@ExecutingUserID)))
		)AS BatchesRows		
	ORDER BY BatchesRows.QRANumber DESC
	
	DROP TABLE #ExTestStageType
	DROP TABLE #ExBatchStatus
	RETURN
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
		BatchesRows.TestCenterLocation,BatchesRows.TestStageName, BatchesRows.TestStageCompletionStatus, 
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
		CONVERT(BIT, 0) AS HasBatchSpecificExceptions, batchesrows.ProductTypeID, batchesrows.AccessoryGroupID, AssemblyNumber, AssemblyRevision, HWRevision, PartName, 
		ReportRequiredBy, ReportApprovedDate, IsMQual, JobID, ExecutiveSummary, MechanicalTools, BatchesRows.RequestPurposeID
	FROM     
		(
			SELECT ROW_NUMBER() OVER (ORDER BY b.ID) AS Row, 
			b.BatchStatus,b.Comment, b.teststagecompletionstatus,b.ConcurrencyID,b.ID,b.JobName,b.LastUser,b.Priority,p.ProductGroupName,b.ProductTypeID,b.AccessoryGroupID,p.ID as ProductID,
			b.QRANumber, b.RequestPurpose As RequestPurposeID,b.TestCenterLocationID,b.TestStageName, j.WILocation,
			(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
			l2.[Values] As AccessoryGroupName, l.[Values] As ProductType,b.RQID,l3.[Values] As TestCenterLocation,
			b.AssemblyNumber, b.AssemblyRevision,b.HWRevision, b.PartName, b.ReportRequiredBy, b.ReportApprovedDate, b.IsMQual, j.ID AS JobID, ExecutiveSummary, 
			MechanicalTools, l4.[Values] As RequestPurpose
			FROM Batches as b WITH(NOLOCK)
				inner join Products p WITH(NOLOCK) on p.ID=b.ProductID
				LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs
				LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID  
				LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.Type='TestCenter' AND b.TestCenterLocationID=l3.LookupID   
				LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON l4.Type='RequestPurpose' AND b.RequestPurpose=l4.LookupID
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
	BatchesRows.LastUser,BatchesRows.Priority,p.ProductGroupName,BatchesRows.QRANumber,BatchesRows.RequestPurpose As RequestPurposeID,batchesrows.ProductTypeID,batchesrows.AccessoryGroupID,
	batchesrows.ProductID,BatchesRows.TestCenterLocationID,
	l3.[Values] AS TestCenterLocation,BatchesRows.TestStageName,
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
    ) AS HasBatchSpecificExceptions,BatchesRows.RQID As ReqID, AssemblyNumber, AssemblyRevision, HWRevision, PartName, ReportRequiredBy, ReportApprovedDate,
	IsMQual, j.ID AS JobID, ExecutiveSummary, MechanicalTools, l4.[Values] AS RequestPurpose
	from Batches as BatchesRows WITH(NOLOCK)
		LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = BatchesRows.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
		INNER JOIN Products p WITH(NOLOCK) ON BatchesRows.productID=p.ID
		LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND BatchesRows.ProductTypeID=l.LookupID  
		LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.Type='AccessoryType' AND BatchesRows.AccessoryGroupID=l2.LookupID  
		LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.Type='TestCenter' AND BatchesRows.TestCenterLocationID=l3.LookupID  
		LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON l4.Type='RequestPurpose' AND BatchesRows.RequestPurpose=l4.LookupID  
	WHERE QRANumber = @QRANumber

select bc.DateAdded, bc.ID, bc.[Text], bc.LastUser from BatchComments as bc WITH(NOLOCK) where BatchID = @batchid and Active = 1 order by DateAdded desc;
	RETURN
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
		BatchesRows.QRANumber,BatchesRows.RequestPurpose, BatchesRows.TestCenterLocation,BatchesRows.TestStageName, BatchesRows.TestStageCompletionStatus, 
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
		CONVERT(BIT,0) AS HasBatchSpecificExceptions, BatchesRows.AccessoryGroupID,BatchesRows.ProductTypeID,
		AssemblyNumber, AssemblyRevision, HWRevision, PartName, ReportRequiredBy, ReportApprovedDate, IsMQual, JobID, ExecutiveSummary, MechanicalTools,
		BatchesRows.RequestPurposeID
	FROM     
		(
			SELECT ROW_NUMBER() OVER (ORDER BY b.ID) AS Row, 
				b.BatchStatus,b.Comment,
				b.teststagecompletionstatus,b.ConcurrencyID,b.ID,b.JobName,b.LastUser,b.Priority,p.ProductGroupName,b.ProductTypeID, b.AccessoryGroupID,p.ID As ProductID,b.QRANumber,
				b.RequestPurpose AS RequestPurposeID,b.TestCenterLocationID,b.TestStageName, j.WILocation,
				(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
				l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, b.RQID, l3.[Values] As TestCenterLocation,
				b.AssemblyNumber, b.AssemblyRevision, b.HWRevision, b.PartName, b.ReportRequiredBy, b.ReportApprovedDate, b.IsMQual, j.ID AS JobID, 
				ExecutiveSummary, MechanicalTools, l4.[Values] As RequestPurpose
			FROM Batches as b
				inner join Products p WITH(NOLOCK) on p.ID=b.ProductID
				LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
				LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID
				LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.Type='TestCenter' AND b.TestCenterLocationID=l3.LookupID    
				LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON l4.Type='RequestPurpose' AND b.RequestPurpose=l4.LookupID 
			WHERE BatchStatus NOT IN(5,7) and Requestor = @Requestor
		) AS BatchesRows
WHERE (Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) OR @startRowIndex is null OR @maximumRows is null
order by BatchesRows.QRANumber
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
		select ROW_NUMBER() over (order by p.ProductGroupName desc)as row, pvt.ID, b.QRANumber, ISNULL(tu.Batchunitnumber, 0) as batchunitnumber, pvt.[ReasonForRequest] As ReasonForRequestID, p.ProductGroupName,
		(select jobname from jobs,TestStages where teststages.id =pvt.TestStageid and Jobs.ID = TestStages.jobid) as jobname, 
		(select teststagename from teststages WITH(NOLOCK) where teststages.id =pvt.TestStageid) as teststagename, 
		t.TestName,pvt.TestStageID, pvt.TestUnitID,
		(select top 1 LastUser from TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS LastUser,
		(select top 1 ConcurrencyID from TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS ConcurrencyID,
		pvt.ProductTypeID, pvt.AccessoryGroupID, pvt.ProductID, l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, pvt.IsMQual, 
		l3.[Values] As TestCenter, l3.[LookupID] AS TestCenterID, l4.[Values] As ReasonForRequest
		FROM vw_ExceptionsPivoted as pvt WITH(NOLOCK)
			LEFT OUTER JOIN Tests t WITH(NOLOCK) ON pvt.Test = t.ID
			LEFT OUTER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID = pvt.TestUnitID
			LEFT OUTER JOIN Batches b WITH(NOLOCK) ON tu.BatchID = b.ID
			LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND l.LookupID=pvt.ProductTypeID
			LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.Type='AccessoryType' AND l2.LookupID=pvt.AccessoryGroupID
			LEFT OUTER JOIN Products p WITH(NOLOCK) ON p.ID=pvt.ProductID
			LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.Type='TestCenter' AND l3.LookupID=pvt.TestCenterID
			LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON l4.Type='RequestPurpose' AND l4.LookupID=pvt.ReasonForRequest
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
ALTER procedure [dbo].[remispTestExceptionsGetBatchExceptions] @qraNumber nvarchar(11) = null
AS
--get any for the product
select distinct pvt.id, null as batchunitnumber, pvt.ReasonForRequest AS ReasonForRequestID,p.ProductGroupName,b.JobName, ts.teststagename
, t.TestName, (SELECT TOP 1 LastUser FROM TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS LastUser,
(SELECT TOP 1 ConcurrencyID FROM TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS ConcurrencyID,
pvt.TestStageID, pvt.TestUnitID, pvt.ProductTypeID, pvt.AccessoryGroupID, pvt.ProductID,
l2.[Values] As AccessoryGroupName, l.[Values] As ProductType, pvt.IsMQual, l3.[Values] As TestCenter, l3.[LookupID] As TestCenterID,
l4.[Values] AS ReasonForRequest
FROM vw_ExceptionsPivoted as pvt
	LEFT OUTER JOIN Tests t WITH(NOLOCK) ON pvt.Test = t.ID
	LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND l.LookupID=pvt.ProductTypeID
	LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.Type='AccessoryType' AND l2.LookupID=pvt.AccessoryGroupID
	LEFT OUTER JOIN Products p WITH(NOLOCK) ON p.ID=pvt.ProductID
	LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.Type='TestCenter' AND l3.LookupID=pvt.TestCenterID
	LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON l4.Type='RequestPurpose' AND l4.LookupID=pvt.ReasonForRequest
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
select distinct pvt.id, tu.BatchUnitNumber, pvt.ReasonForRequest AS ReasonForRequestID,p.ProductGroupName,b.JobName, 
(select teststagename from teststages WITH(NOLOCK) where teststages.id =pvt.TestStageid) as teststagename, t.testname,
(SELECT TOP 1 LastUser FROM TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS LastUser,
(SELECT TOP 1 ConcurrencyID FROM TestExceptions WITH(NOLOCK) WHERE ID=pvt.ID) AS ConcurrencyID
, pvt.TestStageID, pvt.TestUnitID, pvt.ProductTypeID, pvt.AccessoryGroupID,pvt.ProductID,
l2.[Values] As AccessoryGroupName, l.[Values] As ProductType, pvt.IsMQual, l3.[Values] As TestCenter, l3.[LookupID] As TestCenterID,
l4.[Values] AS ReasonForRequest
FROM vw_ExceptionsPivoted as pvt
	LEFT OUTER JOIN Tests t WITH(NOLOCK) ON pvt.Test = t.ID
	LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND l.LookupID=pvt.ProductTypeID
	LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.Type='AccessoryType' AND l2.LookupID=pvt.AccessoryGroupID
	LEFT OUTER JOIN Products p WITH(NOLOCK) ON p.ID=pvt.ProductID
	LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.Type='TestCenter' AND l3.LookupID=pvt.TestCenterID
	LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON l4.Type='RequestPurpose' AND l4.LookupID=pvt.ReasonForRequest
	INNER JOIN testunits tu WITH(NOLOCK) ON tu.ID=pvt.TestUnitID
	INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID
WHERE b.QRANumber = @qranumber and tu.batchid = b.id and pvt.TestUnitID = tu.id
order by pvt.TestUnitID desc,TestName
GO
GRANT EXECUTE ON remispTestExceptionsGetBatchExceptions TO Remi
GO
ALTER TABLE [dbo].[Batches]  WITH CHECK ADD  CONSTRAINT [FK_Batches_RequestPurpose] FOREIGN KEY([RequestPurpose])
REFERENCES [dbo].[Lookups] ([LookupID])
GO
ALTER TABLE [dbo].[Batches] CHECK CONSTRAINT [FK_Batches_RequestPurpose]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
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