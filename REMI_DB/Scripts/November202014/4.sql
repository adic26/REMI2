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
CREATE TABLE [Req].[ReqFieldDataAudit](
	[ReqFieldDataAuditID] [INT] NOT NULL,
	[RequestID] [int] NOT NULL,
	[ReqFieldSetupID] [int] NOT NULL,
	[Value] [nvarchar](4000) NOT NULL,
	[InsertTime] [DateTime] NOT NULL,
	[Action] [char](1) NOT NULL,
	[UserName] [nvarchar](255) NOT NULL,
 CONSTRAINT [PK_ReqFieldDataAuditID] PRIMARY KEY CLUSTERED 
(
	[ReqFieldDataAuditID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE Req.ReqFieldData ADD LastUser NVARCHAR(255) NULL
GO
ALTER TABLE Req.ReqFieldData ADD InsertTime DateTime NULL
GO
CREATE TRIGGER [Req].[ReqFieldDataAuditInsertUpdate] ON  [Req].[ReqFieldData] after insert, update
AS 
BEGIN
SET NOCOUNT ON;
 
Declare @action char(1)
DECLARE @count INT
  
--check if this is an insert or an update

If Exists(Select * From Inserted) and Exists(Select * From Deleted) --Update, both tables referenced
begin
	Set @action= 'U'
end
else
begin
	If Exists(Select * From Inserted) --insert, only one table referenced
	Begin
		Set @action= 'I'
	end
	if not Exists(Select * From Inserted) and not Exists(Select * From Deleted)--nothing changed, get out of here
	Begin
		RETURN
	end
end

select @count= count(*) from
(
   select Value from Inserted
   except
   select Value from Deleted
) a

if ((@count) >0)
begin
	insert into Req.ReqFieldDataAudit (RequestID,ReqFieldSetupID,Value,InsertTime,Action, UserName)
	Select RequestID,ReqFieldSetupID,Value,InsertTime, @action,lastuser from inserted
END
END
GO
UPDATE Lookups
SET Lookups.Description = Lookups.[Values]
WHERE LookupTypeID in (SELECT LookupTypeID FROM LookupType WHERE Name='RequestPurpose') AND Lookups.Description IS NULL

SELECT * INTO #lookups FROM Lookups WHERE LookupTypeID in (SELECT LookupTypeID FROM LookupType WHERE Name='RequestPurpose')

UPDATE Lookups
SET Description = [Values]
WHERE LookupTypeID in (SELECT LookupTypeID FROM LookupType WHERE Name='RequestPurpose')

UPDATE l
SET l.[Values] = l2.description
FROM Lookups l
	INNER JOIN #lookups l2 ON l2.lookupid=l.LookupID
WHERE l.LookupTypeID in (SELECT LookupTypeID FROM LookupType WHERE Name='RequestPurpose')

IF NOT EXISTS (SELECT 1 FROM Lookups WHERE Description='Internal Use Only - Carrier Requirement' AND LookupTypeID in (SELECT LookupTypeID FROM LookupType WHERE Name='RequestPurpose'))
BEGIN
	DECLARE @id INT
	DECLARE @typeid INT
	SELECT @typeid=LookupTypeID FROM LookupType WHERE Name='RequestPurpose'
	SELECT @id=MAX(lookupid)+1 FROM Lookups
	INSERT INTO Lookups (LookupID,LookupTypeID, [Values],Description,IsActive,ParentID)
	VALUES (@id, @typeid, 'Internal Use Only - Carrier Requirement', 'IUOCR', 1, NULL)
END
ELSE
BEGIN
	UPDATE Lookups
	SET Description='IUOCR'
	WHERE LookupTypeID in (SELECT LookupTypeID FROM LookupType WHERE Name='RequestPurpose') AND Description='Internal Use Only - Carrier Requirement'
END

SELECT * FROM Lookups WHERE LookupTypeID in (SELECT LookupTypeID FROM LookupType WHERE Name='RequestPurpose')

DROP TABLE #lookups
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
	batchesrows.TestStageCompletionStatus,testunitcount,
	(CASE WHEN batchesrows.WILocation IS NULL THEN NULL ELSE batchesrows.WILocation END) AS jobWILocation,
	(testUnitCount -
		(select COUNT(*) 
			  from TestUnits as tu WITH(NOLOCK)
			  INNER JOIN DeviceTrackingLog as dtl WITH(NOLOCK) ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			  where dtl.OutTime IS null and tu.BatchID = batchesrows.ID)
	) as HasUnitsToReturnToRequestor,
	ISNULL(
			(SELECT AssignedTo 
			FROM TaskAssignments ta WITH(NOLOCK)
				--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
				INNER JOIN TestStages ts WITH(NOLOCK) ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
				--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
				INNER JOIN Jobs j WITH(NOLOCK) ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
			WHERE ta.BatchID = BatchesRows.ID and ta.Active=1), 
			(SELECT AssignedTo 
			FROM TaskAssignments ta WITH(NOLOCK)
			WHERE ta.Active=1 AND ISNULL(ta.taskID,0) = 0 AND ta.BatchID = BatchesRows.ID)
		) as ActiveTaskAssignee, CONVERT(BIT,0) AS HasBatchSpecificExceptions,
	batchesrows.ProductTypeID,batchesrows.AccessoryGroupID,batchesrows.RQID As ReqID, batchesrows.TestCenterLocationID,
	AssemblyNumber, AssemblyRevision, HWRevision, PartName, ReportRequiredBy, ReportApprovedDate, IsMQual, JobID, MechanicalTools, BatchesRows.RequestPurposeID,
	BatchesRows.PriorityID, DepartmentID, Department, Requestor
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
			RequestPurposeID, PriorityID, DepartmentID, Department, Requestor
		FROM 
		(
			SELECT DISTINCT b.ID, 
				b.QRANumber, 
				b.Comment,
				b.RequestPurpose As RequestPurposeID, 
				b.Priority AS PriorityID,
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
				b.ReportApprovedDate, b.IsMQual, j.ID AS JobID, MechanicalTools, l4.[Values] As RequestPurpose, l5.[Values] As Priority, b.DepartmentID, l6.[Values] AS Department,
				b.Requestor
			FROM Batches AS b WITH(NOLOCK)
				LEFT OUTER JOIN Jobs as j WITH(NOLOCK) on b.jobname = j.JobName 
				inner join TestStages as ts WITH(NOLOCK) on j.ID = ts.JobID
				inner join Tests as t WITH(NOLOCK) on ts.TestID = t.ID
				inner join DeviceTrackingLog AS dtl WITH(NOLOCK) 
				INNER JOIN TrackingLocations AS tl WITH(NOLOCK) ON dtl.TrackingLocationID = tl.ID
				INNER JOIN TrackingLocationTypes as tlt WITH(NOLOCK) on tl.TrackingLocationTypeID = tlt.id 
				inner join TestUnits AS tu WITH(NOLOCK) ON dtl.TestUnitID = tu.ID on tu.CurrentTestName = t.TestName and b.id = tu.batchid  --batches where there's a tracking log
				INNER JOIN Products p WITH(NOLOCK) ON b.ProductID=p.id
				LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON b.AccessoryGroupID=l2.LookupID  
				LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON b.TestCenterLocationID=l3.LookupID  
				LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON b.RequestPurpose=l4.LookupID   
				LEFT OUTER JOIN Lookups l5 WITH(NOLOCK) ON b.Priority=l5.LookupID
				LEFT OUTER JOIN Lookups l6 WITH(NOLOCK) ON b.DepartmentID=l6.LookupID
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
	ISNULL(
			(SELECT AssignedTo 
			FROM TaskAssignments ta WITH(NOLOCK)
				--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
				INNER JOIN TestStages ts WITH(NOLOCK) ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
				--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
				INNER JOIN Jobs j WITH(NOLOCK) ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
			WHERE ta.BatchID = BatchesRows.ID and ta.Active=1), 
			(SELECT AssignedTo 
			FROM TaskAssignments ta WITH(NOLOCK)
			WHERE ta.Active=1 AND ISNULL(ta.taskID,0) = 0 AND ta.BatchID = BatchesRows.ID)
		) as ActiveTaskAssignee,
	CONVERT(BIT,0) AS HasBatchSpecificExceptions,
	batchesrows.AccessoryGroupID,batchesrows.ProductTypeID,BatchesRows.RQID As ReqID, AssemblyNumber, AssemblyRevision, HWRevision, PartName, ReportRequiredBy, 
	ReportApprovedDate, IsMQual, JobID, ExecutiveSummary, MechanicalTools, batchesrows.RequestPurposeID, batchesrows.PriorityID, DepartmentID, Department, Requestor
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
					 ExecutiveSummary, MechanicalTools, RequestPurposeID, PriorityID, DepartmentID, Department, Requestor
                      from
				(SELECT DISTINCT 
                      b.ID, 
                      b.QRANumber, 
                      b.Comment,
                      b.RequestPurpose As RequestPurposeID, 
                      b.Priority AS PriorityID,
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
					  ExecutiveSummary, MechanicalTools, l4.[Values] AS RequestPurpose, l5.[Values] AS Priority, b.DepartmentID, l6.[Values] AS Department, b.Requestor
				FROM Batches AS b 
					INNER JOIN DeviceTrackingLog AS dtl WITH(NOLOCK) 
					INNER JOIN TrackingLocations AS tl WITH(NOLOCK) ON dtl.TrackingLocationID = tl.ID 
					INNER JOIN TestUnits AS tu WITH(NOLOCK) ON dtl.TestUnitID = tu.ID ON b.id = tu.batchid --batches where there's a tracking log
					inner join Products p WITH(NOLOCK) on p.ID=b.ProductID
					LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = b.JobName
					LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON b.ProductTypeID=l.LookupID  
					LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON b.AccessoryGroupID=l2.LookupID 
					LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON b.TestCenterLocationID=l3.LookupID 
					LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON b.RequestPurpose=l4.LookupID   
					LEFT OUTER JOIN Lookups l5 WITH(NOLOCK) ON b.Priority=l5.LookupID
					LEFT OUTER JOIN Lookups l6 WITH(NOLOCK) ON b.DepartmentID=l6.LookupID
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
	@Priority NVARCHAR(150) = 'NotSet', 
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
	@reportApprovedDate datetime = null,
	@reportRequiredBy datetime = null,
	--@partName nvarchar(500) = null,
	--@assemblyNumber nvarchar(500) = null,
	--@assemblyRevision nvarchar(500) = null,
	@reqStatus nvarchar(500) = null,
	@cprNumber nvarchar(500) = null,
	@pmNotes nvarchar(500) = null,
	@MechanicalTools NVARCHAR(10),
	@RequestPurposeID int = 0,
	@PriorityID INT = 0,
	@DepartmentID INT = 0,
	@Department NVARCHAR(150) = NULL,
	@ExecutiveSummary NVARCHAR(4000) = NULL
	AS
	DECLARE @ProductID INT
	DECLARE @ProductTypeID INT
	DECLARE @AccessoryGroupID INT
	DECLARE @TestCenterLocationID INT
	DECLARE @ReturnValue int
	DECLARE @maxid int
	DECLARE @LookupTypeID INT
	
	IF NOT EXISTS (SELECT 1 FROM Products WHERE LTRIM(RTRIM(ProductGroupName))= LTRIM(RTRIM(@ProductGroupName)))
	BEGIn
		INSERT INTO Products (ProductGroupName) Values (LTRIM(RTRIM(@ProductGroupName)))
	END
	
	IF NOT EXISTS (SELECT 1 FROM Lookups l INNER JOIN LookupType lt ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='ProductType' AND LTRIM(RTRIM([Values])) = LTRIM(RTRIM(@ProductType)))
	BEGIN
		SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='ProductType'
		SELECT @maxid = MAX(LookupID)+1 FROM Lookups
		INSERT INTO Lookups (LookupID, LookupTypeID, [Values]) Values (@maxid, @LookupTypeID, LTRIM(RTRIM(@ProductType)))
	END
	
	IF LTRIM(RTRIM(@AccessoryGroupName)) <> '' AND NOT EXISTS (SELECT 1 FROM Lookups l INNER JOIN LookupType lt ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='AccessoryType' AND LTRIM(RTRIM([Values])) = LTRIM(RTRIM(@AccessoryGroupName)))
	BEGIN
		SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='AccessoryType'
		SELECT @maxid = MAX(LookupID)+1 FROM Lookups
		INSERT INTO Lookups (LookupID, LookupTypeID, [Values]) Values (@maxid, @LookupTypeID, LTRIM(RTRIM(@AccessoryGroupName)))
	END
	
	IF LTRIM(RTRIM(@TestCenterLocation)) <> '' AND NOT EXISTS (SELECT 1 FROM Lookups l INNER JOIN LookupType lt ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='TestCenter' AND LTRIM(RTRIM([Values])) = LTRIM(RTRIM(@TestCenterLocation)))
	BEGIN
		SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='TestCenter'
		SELECT @maxid = MAX(LookupID)+1 FROM Lookups
		INSERT INTO Lookups (LookupID, LookupTypeID, [Values]) Values (@maxid, @LookupTypeID, LTRIM(RTRIM(@TestCenterLocation)))
	END

	IF LTRIM(RTRIM(@Department)) <> '' AND NOT EXISTS (SELECT 1 FROM Lookups l INNER JOIN LookupType lt ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='Department' AND LTRIM(RTRIM([Values])) = LTRIM(RTRIM(@Department)))
	BEGIN
		SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='Department'
		SELECT @maxid = MAX(LookupID)+1 FROM Lookups
		INSERT INTO Lookups (LookupID, LookupTypeID, [Values]) Values (@maxid, @LookupTypeID, LTRIM(RTRIM(@Department)))
	END

	IF LTRIM(RTRIM(@RequestPurpose)) <> '' AND NOT EXISTS (SELECT 1 FROM Lookups l INNER JOIN LookupType lt ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='RequestPurpose' AND (LTRIM(RTRIM([Values])) = LTRIM(RTRIM(@RequestPurpose)) OR LTRIM(RTRIM([Description]))=LTRIM(RTRIM(@RequestPurpose))))
	BEGIN
		SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='RequestPurpose'
		SELECT @maxid = MAX(LookupID)+1 FROM Lookups
		INSERT INTO Lookups (LookupID, LookupTypeID, [Values]) Values (@maxid, @LookupTypeID, LTRIM(RTRIM(@RequestPurpose)))
	END

	IF LTRIM(RTRIM(@Priority)) <> '' AND NOT EXISTS (SELECT 1 FROM Lookups l INNER JOIN LookupType lt ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='Priority' AND LTRIM(RTRIM([Values])) = LTRIM(RTRIM(@Priority)))
	BEGIN
		SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='Priority'
		SELECT @maxid = MAX(LookupID)+1 FROM Lookups
		INSERT INTO Lookups (LookupID, LookupTypeID, [Values]) Values (@maxid, @LookupTypeID, LTRIM(RTRIM(@Priority)))
	END

	SELECT @RequestPurposeID = LookupID FROM Lookups l INNER JOIN LookupType lt ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='RequestPurpose' AND ([Values] = @RequestPurpose OR [Description] = @RequestPurpose)
	SELECT @PriorityID = LookupID FROM Lookups l INNER JOIN LookupType lt ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='Priority' AND [Values] = @Priority
	SELECT @ProductID = ID FROM Products WITH(NOLOCK) WHERE LTRIM(RTRIM(ProductGroupName))= LTRIM(RTRIM(@ProductGroupName))
	SELECT @ProductTypeID = LookupID FROM Lookups l WITH(NOLOCK) INNER JOIN LookupType lt WITH(NOLOCK) ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='ProductType' AND LTRIM(RTRIM([Values]))= LTRIM(RTRIM(@ProductType))
	SELECT @AccessoryGroupID = LookupID FROM Lookups l WITH(NOLOCK) INNER JOIN LookupType lt WITH(NOLOCK) ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='AccessoryType' AND LTRIM(RTRIM([Values]))= LTRIM(RTRIM(@AccessoryGroupName))
	SELECT @TestCenterLocationID = LookupID FROM Lookups l WITH(NOLOCK) INNER JOIN LookupType lt WITH(NOLOCK) ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='TestCenter' AND LTRIM(RTRIM([Values]))= LTRIM(RTRIM(@TestCenterLocation))
	SELECT @DepartmentID = LookupID FROM Lookups l WITH(NOLOCK) INNER JOIN LookupType lt WITH(NOLOCK) ON l.LookupTypeID=lt.LookupTypeID WHERE lt.Name='Department' AND LTRIM(RTRIM([Values]))= LTRIM(RTRIM(@Department))
		
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
		reportApprovedDate,
		reportRequiredBy,
		trsStatus,
		cprNumber,
		pmNotes,
		ProductID, MechanicalTools, DepartmentID, ExecutiveSummary ) 
		VALUES 
		(@QRANumber, 
		@PriorityID, 
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
		@reportApprovedDate,
		@reportRequiredBy,
		@reqStatus,
		@cprNumber,
		@pmNotes,
		@ProductID, @MechanicalTools, @DepartmentID,@ExecutiveSummary)

		SELECT @ReturnValue = SCOPE_IDENTITY()
	END
	ELSE -- Exisiting Item
	BEGIN
		UPDATE Batches SET 
		QRANumber = @QRANumber, 
		Priority = @PriorityID, 
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
		reportApprovedDate=@reportApprovedDate,
		reportRequiredBy=@reportRequiredBy,
		trsStatus=@reqStatus,
		cprNumber=@cprNumber,
		pmNotes=@pmNotes ,
		ProductID=@ProductID,
		MechanicalTools = @MechanicalTools, DepartmentID = @DepartmentID,ExecutiveSummary=@ExecutiveSummary
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
PRINT N'Altering [Req].[RequestFieldSetup]'
GO
ALTER PROCEDURE [Req].[RequestFieldSetup] @RequestTypeID INT, @IncludeArchived BIT = 0, @RequestNumber NVARCHAR(12) = NULL
AS
BEGIN
	DECLARE @RequestID INT
	DECLARE @RequestType NVARCHAR(150)
	SET @RequestID = 0
	SET @IncludeArchived=0

	SELECT @RequestType=lrt.[values] FROM Req.RequestType rt INNER JOIN Lookups lrt ON lrt.LookupID=rt.TypeID WHERE rt.RequestTypeID=@RequestTypeID

	IF (@RequestNumber IS NOT NULL)
		BEGIN
			SELECT @RequestID = RequestID FROM Req.Request WHERE RequestNumber=@RequestNumber
		END
	ELSE
		BEGIN
			SELECT @RequestNumber = REPLACE(RequestNumber, @RequestType + '-' + Right(Year(getDate()),2) + '-', '') + 1 
			FROM Req.Request 
			WHERE RequestNumber LIKE @RequestType + '-' + Right(Year(getDate()),2) + '-%'
			
			IF (LEN(@RequestNumber) < 4)
			BEGIN
				SET @RequestNumber = REPLICATE('0', 4-LEN(@RequestNumber)) + @RequestNumber
			END
		
			IF (@RequestNumber IS NULL)
				SET @RequestNumber = '0001'
		
			SET @RequestNumber = @RequestType + '-' + Right(Year(getDate()),2) + '-' + @RequestNumber
		END

	SELECT rfs.ReqFieldSetupID, @RequestType AS RequestType, rfs.Name, lft.[Values] AS FieldType, rfs.FieldTypeID, 
			lvt.[Values] AS ValidationType, rfs.FieldValidationID, ISNULL(rfs.IsRequired, 0) AS IsRequired, rfs.DisplayOrder, 
			rfs.ColumnOrder, ISNULL(rfs.Archived, 0) AS Archived, rfs.Description, rfs.OptionsTypeID, @RequestTypeID AS RequestTypeID,
			@RequestNumber AS RequestNumber, @RequestID AS RequestID, rfd.Value, rfm.IntField, rfm.ExtField,
			CASE WHEN rfm.ID IS NOT NULL THEN 1 ELSE 0 END AS InternalField,
			CASE WHEN @RequestID = 0 THEN CONVERT(BIT, 1) ELSE CONVERT(BIT, 0) END AS NewRequest, Req.RequestType.IsExternal AS IsFromExternalSystem
	FROM Req.RequestType
		INNER JOIN Lookups lrt ON lrt.LookupID=Req.RequestType.TypeID
		INNER JOIN Req.ReqFieldSetup rfs ON rfs.RequestTypeID=Req.RequestType.RequestTypeID                  
		INNER JOIN Lookups lft ON lft.LookupID=rfs.FieldTypeID
		LEFT OUTER JOIN Lookups lvt ON lvt.LookupID=rfs.FieldValidationID
		LEFT OUTER JOIN Req.ReqFieldSetupRole ON Req.ReqFieldSetupRole.ReqFieldSetupID=rfs.ReqFieldSetupID
		LEFT OUTER JOIN Req.Request ON RequestNumber=@RequestNumber
		LEFT OUTER JOIN Req.ReqFieldData rfd ON rfd.ReqFieldSetupID=rfs.ReqFieldSetupID AND rfd.RequestID=Req.Request.RequestID
		LEFT OUTER JOIN Req.ReqFieldMapping rfm ON rfm.RequestTypeID=Req.RequestType.RequestTypeID AND rfm.ExtField=rfs.Name AND ISNULL(rfm.IsActive, 0) = 1
	WHERE (lrt.[Values] = @RequestType) AND
		(
			(@IncludeArchived = 1)
			OR
			(@IncludeArchived = 0 AND ISNULL(rfs.Archived, 0) = 0)
		)
	ORDER BY ISNULL(rfs.DisplayOrder, 0) ASC
END
GO
GRANT EXECUTE ON [Req].[RequestFieldSetup] TO REMI
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
	@Revision NVARCHAR(10) = NULL,
	@DepartmentID INT = NULL
AS
	DECLARE @TestName NVARCHAR(400)
	DECLARE @TestStageName NVARCHAR(400)
	DECLARE @HasBatchSpecificExceptions BIT
	SET @HasBatchSpecificExceptions = CONVERT(BIT, 0)
	
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
		ISNULL(
			(SELECT AssignedTo 
			FROM TaskAssignments ta WITH(NOLOCK)
				--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
				INNER JOIN TestStages ts WITH(NOLOCK) ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
				--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
				INNER JOIN Jobs j WITH(NOLOCK) ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
			WHERE ta.BatchID = BatchesRows.ID and ta.Active=1), 
			(SELECT AssignedTo 
			FROM TaskAssignments ta WITH(NOLOCK)
			WHERE ta.Active=1 AND ISNULL(ta.taskID,0) = 0 AND ta.BatchID = BatchesRows.ID)
		) as ActiveTaskAssignee,
		@HasBatchSpecificExceptions AS HasBatchSpecificExceptions, batchesrows.ProductTypeID,batchesrows.AccessoryGroupID, BatchesRows.CPRNumber, BatchesRows.RelabJobID, 
		BatchesRows.TestCenterLocation, AssemblyNumber, AssemblyRevision, HWRevision, PartName, ReportRequiredBy, ReportApprovedDate, IsMQual, JobID, DateCreated, ContinueOnFailures,
		MechanicalTools, BatchesRows.RequestPurpose, BatchesRows.PriorityID, DepartmentID, Department, Requestor
	FROM     
		(
			SELECT DISTINCT b.BatchStatus,b.Comment, b.teststagecompletionstatus,b.ConcurrencyID,b.ID,b.JobName,b.LastUser,b.Priority AS PriorityID,b.ProductTypeID,
				b.AccessoryGroupID,p.ID As ProductID,p.ProductGroupName As ProductGroup,b.QRANumber,b.RequestPurpose As RequestPurposeID,b.TestCenterLocationID,b.TestStageName,
				j.WILocation,(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
				l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, l3.[Values] As TestCenterLocation,
				b.CPRNumber,b.RelabJobID, b.RQID, b.AssemblyNumber, b.AssemblyRevision,b.HWRevision, b.PartName, b.ReportRequiredBy, 
				b.ReportApprovedDate, b.IsMQual, j.ID AS JobID, b.DateCreated, j.ContinueOnFailures, MechanicalTools, l4.[Values] As RequestPurpose, l5.[Values] As Priority, 
				ISNULL(b.[Order], 100) As PriorityOrder, b.DepartmentID, l6.[Values] AS Department, b.Requestor
			FROM Batches as b WITH(NOLOCK)
				inner join Products p WITH(NOLOCK) on b.ProductID=p.id 
				LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
				LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON b.AccessoryGroupID=l2.LookupID  
				LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON b.TestCenterLocationID=l3.LookupID
				INNER JOIN TestStages ts WITH(NOLOCK) ON ts.TestStageName=b.TestStageName
				LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON b.RequestPurpose=l4.LookupID
				LEFT OUTER JOIN Lookups l5 WITH(NOLOCK) ON b.Priority=l5.LookupID
				LEFT OUTER JOIN Lookups l6 WITH(NOLOCK) ON b.DepartmentID=l6.LookupID
			WHERE ((BatchStatus NOT IN (SELECT ID FROM #ExBatchStatus) OR @ExcludedStatus IS NULL) AND (BatchStatus = @Status OR @Status IS NULL))
				AND (p.ID = @ProductID OR @ProductID IS NULL)
				AND (b.Priority = @Priority OR @Priority IS NULL)
				AND (b.ProductTypeID = @ProductTypeID OR @ProductTypeID IS NULL)
				AND (b.AccessoryGroupID = @AccessoryGroupID OR @AccessoryGroupID IS NULL)
				AND (b.TestCenterLocationID = @GeoLocationID OR @GeoLocationID IS NULL)
				AND (b.DepartmentID = @DepartmentID OR @DepartmentID IS NULL)
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
					(@BatchStart IS NOT NULL AND @BatchEnd IS NOT NULL AND b.ID IN (Select distinct batchid FROM BatchesAudit WITH(NOLOCK) WHERE InsertTime BETWEEN @BatchStart AND @BatchEnd))
				)
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@ExecutingUserID)))
		)AS BatchesRows		
	ORDER BY BatchesRows.PriorityOrder ASC, BatchesRows.QRANumber DESC
	
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
		ISNULL(
			(SELECT AssignedTo 
			FROM TaskAssignments ta WITH(NOLOCK)
				--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
				INNER JOIN TestStages ts WITH(NOLOCK) ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
				--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
				INNER JOIN Jobs j WITH(NOLOCK) ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
			WHERE ta.BatchID = BatchesRows.ID and ta.Active=1), 
			(SELECT AssignedTo 
			FROM TaskAssignments ta WITH(NOLOCK)
			WHERE ta.Active=1 AND ISNULL(ta.taskID,0) = 0 AND ta.BatchID = BatchesRows.ID)
		) as ActiveTaskAssignee,
		CONVERT(BIT, 0) AS HasBatchSpecificExceptions, batchesrows.ProductTypeID, batchesrows.AccessoryGroupID, AssemblyNumber, AssemblyRevision, HWRevision, PartName, 
		ReportRequiredBy, ReportApprovedDate, IsMQual, JobID, ExecutiveSummary, MechanicalTools, BatchesRows.RequestPurposeID, BatchesRows.PriorityID, DepartmentID, Department, Requestor
	FROM     
		(
			SELECT ROW_NUMBER() OVER (ORDER BY b.ID) AS Row, 
			b.BatchStatus,b.Comment, b.teststagecompletionstatus,b.ConcurrencyID,b.ID,b.JobName,b.LastUser,b.Priority As PriorityID,p.ProductGroupName,b.ProductTypeID,b.AccessoryGroupID,p.ID as ProductID,
			b.QRANumber, b.RequestPurpose As RequestPurposeID,b.TestCenterLocationID,b.TestStageName, j.WILocation,
			(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
			l2.[Values] As AccessoryGroupName, l.[Values] As ProductType,b.RQID,l3.[Values] As TestCenterLocation,
			b.AssemblyNumber, b.AssemblyRevision,b.HWRevision, b.PartName, b.ReportRequiredBy, b.ReportApprovedDate, b.IsMQual, j.ID AS JobID, ExecutiveSummary, 
			MechanicalTools, l4.[Values] As RequestPurpose, l5.[Values] As Priority, b.DepartmentID, l6.[Values] AS Department, b.Requestor
			FROM Batches as b WITH(NOLOCK)
				inner join Products p WITH(NOLOCK) on p.ID=b.ProductID
				LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs
				LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON b.ProductTypeID=l.LookupID 
				LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON b.AccessoryGroupID=l2.LookupID 
				LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON b.TestCenterLocationID=l3.LookupID
				LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON b.RequestPurpose=l4.LookupID
				LEFT OUTER JOIN Lookups l5 WITH(NOLOCK) ON b.Priority=l5.LookupID
				LEFT OUTER JOIN Lookups l6 WITH(NOLOCK) ON b.DepartmentID=l6.LookupID
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
	BatchesRows.LastUser,BatchesRows.Priority AS PriorityID,p.ProductGroupName,BatchesRows.QRANumber,BatchesRows.RequestPurpose As RequestPurposeID,batchesrows.ProductTypeID,batchesrows.AccessoryGroupID,
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
	ISNULL(
			(SELECT AssignedTo 
			FROM TaskAssignments ta WITH(NOLOCK)
				--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
				INNER JOIN TestStages ts WITH(NOLOCK) ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName AND ts.JobID = j.ID
			WHERE ta.BatchID = BatchesRows.ID and ta.Active=1), 
			(SELECT AssignedTo 
			FROM TaskAssignments ta WITH(NOLOCK)
			WHERE ta.Active=1 AND ISNULL(ta.taskID,0) = 0 AND ta.BatchID = BatchesRows.ID)
		) as ActiveTaskAssignee,
	BatchesRows.CPRNumber, l.[Values] AS ProductType, l2.[Values] As AccessoryGroupName,
	(
		SELECT TOP 1 CONVERT(BIT, 1) FROM TestExceptions WITH(NOLOCK) WHERE LookupID=3 AND Value IN (SELECT ID FROM TestUnits WITH(NOLOCK) WHERE BatchID=BatchesRows.ID)
    ) AS HasBatchSpecificExceptions,BatchesRows.RQID As ReqID, AssemblyNumber, AssemblyRevision, HWRevision, PartName, ReportRequiredBy, ReportApprovedDate,
	IsMQual, j.ID AS JobID, ExecutiveSummary, MechanicalTools, l4.[Values] AS RequestPurpose, l5.[Values] AS Priority, BatchesRows.OrientationID,
	BatchesRows.DepartmentID, l6.[Values] AS Department, BatchesRows.Requestor
	from Batches as BatchesRows WITH(NOLOCK)
		LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = BatchesRows.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
		INNER JOIN Products p WITH(NOLOCK) ON BatchesRows.productID=p.ID
		LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON BatchesRows.ProductTypeID=l.LookupID  
		LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON BatchesRows.AccessoryGroupID=l2.LookupID  
		LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON BatchesRows.TestCenterLocationID=l3.LookupID  
		LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON BatchesRows.RequestPurpose=l4.LookupID  
		LEFT OUTER JOIN Lookups l5 WITH(NOLOCK) ON BatchesRows.Priority=l5.LookupID
		LEFT OUTER JOIN Lookups l6 WITH(NOLOCK) ON BatchesRows.DepartmentID=l6.LookupID
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
		ISNULL(
			(SELECT AssignedTo 
			FROM TaskAssignments ta WITH(NOLOCK)
				--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
				INNER JOIN TestStages ts WITH(NOLOCK) ON ta.TaskID = ts.ID AND ts.TestStageName=BatchesRows.TestStageName 
				--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
				INNER JOIN Jobs j WITH(NOLOCK) ON j.ID = ts.JobID AND j.JobName = BatchesRows.JobName
			WHERE ta.BatchID = BatchesRows.ID and ta.Active=1), 
			(SELECT AssignedTo 
			FROM TaskAssignments ta WITH(NOLOCK)
			WHERE ta.Active=1 AND ISNULL(ta.taskID,0) = 0 AND ta.BatchID = BatchesRows.ID)
		) as ActiveTaskAssignee,
		CONVERT(BIT,0) AS HasBatchSpecificExceptions, BatchesRows.AccessoryGroupID,BatchesRows.ProductTypeID,
		AssemblyNumber, AssemblyRevision, HWRevision, PartName, ReportRequiredBy, ReportApprovedDate, IsMQual, JobID, ExecutiveSummary, MechanicalTools,
		BatchesRows.RequestPurposeID, BatchesRows.PriorityID, DepartmentID, Department, Requestor
	FROM     
		(
			SELECT ROW_NUMBER() OVER (ORDER BY b.ID) AS Row, 
				b.BatchStatus,b.Comment,
				b.teststagecompletionstatus,b.ConcurrencyID,b.ID,b.JobName,b.LastUser,b.Priority AS PriorityID,p.ProductGroupName,b.ProductTypeID, b.AccessoryGroupID,p.ID As ProductID,b.QRANumber,
				b.RequestPurpose AS RequestPurposeID,b.TestCenterLocationID,b.TestStageName, j.WILocation,
				(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
				l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, b.RQID, l3.[Values] As TestCenterLocation,
				b.AssemblyNumber, b.AssemblyRevision, b.HWRevision, b.PartName, b.ReportRequiredBy, b.ReportApprovedDate, b.IsMQual, j.ID AS JobID, 
				ExecutiveSummary, MechanicalTools, l4.[Values] As RequestPurpose, l5.[Values] As Priority, b.DepartmentID, l6.[Values] AS Department, b.Requestor
			FROM Batches as b
				inner join Products p WITH(NOLOCK) on p.ID=b.ProductID
				LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
				LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON b.AccessoryGroupID=l2.LookupID
				LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON b.TestCenterLocationID=l3.LookupID    
				LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON b.RequestPurpose=l4.LookupID 
				LEFT OUTER JOIN Lookups l5 WITH(NOLOCK) ON b.Priority=l5.LookupID
				LEFT OUTER JOIN Lookups l6 WITH(NOLOCK) ON b.DepartmentID=l6.LookupID
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
PRINT N'Creating [Req].[RequestGet]'
GO
create PROCEDURE [Req].[RequestGet] @RequestTypeID INT, @Department NVARCHAR(150)
AS
BEGIN
	DECLARE @Count INT
	DECLARE @rows VARCHAR(8000)
	DECLARE @sql VARCHAR(8000)
	SELECT @rows=  ISNULL(STUFF(
		( 
		SELECT DISTINCT '],[' + rfm.IntField
		FROM Req.ReqFieldSetup rfs
			INNER JOIN Req.ReqFieldMapping rfm ON rfm.ExtField = rfs.Name AND rfm.RequestTypeID=@RequestTypeID
		WHERE rfs.RequestTypeID=@RequestTypeID
		ORDER BY '],[' +  rfm.IntField
		FOR XML PATH('')), 1, 2, '') + ']','[na]')
		
	SELECT @Count = COUNT(*)
	FROM Req.Request r
		INNER JOIN Req.ReqFieldData rfd ON rfd.RequestID=r.RequestID
		INNER JOIN Req.ReqFieldSetup rfs ON rfs.ReqFieldSetupID=rfd.ReqFieldSetupID
		INNER JOIN Req.RequestType rt ON rt.RequestTypeID=rfs.RequestTypeID
	WHERE rt.RequestTypeID=@RequestTypeID

	IF (@Count > 0)
	BEGIN
		SET @sql = 'SELECT RequestID, RequestNumber AS RequestNumber, [RequestStatus] AS STATUS, [ProductGroup] AS PRODUCT, [ProductType] AS PRODUCTTYPE,
			[AccessoryGroup] AS ACCESSORYGROUPNAME, [TestCenterLocation] AS TESTCENTER, [Department] AS DEPARTMENT, [SampleSize] AS SAMPLESIZE,
			[RequestedTest] AS Job, [RequestPurpose] AS PURPOSE, [CPRNumber] AS CPR, [ReportRequiredBy] AS [Report Required By],
			[Priority] AS PRIORITY, [Requestor] AS REQUESTOR, [DateCreated] AS CRE_DATE
			FROM 
				(
				SELECT r.RequestID, r.RequestNumber, rfd.Value, rfm.IntField
				FROM Req.Request r
					INNER JOIN Req.ReqFieldData rfd ON rfd.RequestID=r.RequestID
					INNER JOIN Req.ReqFieldSetup rfs ON rfs.ReqFieldSetupID=rfd.ReqFieldSetupID
					INNER JOIN Req.RequestType rt ON rt.RequestTypeID=rfs.RequestTypeID
					INNER JOIN Req.ReqFieldMapping rfm ON rfm.ExtField = rfs.Name
				WHERE rt.RequestTypeID=' + CONVERT(NVARCHAR, @RequestTypeID) + '
				) req PIVOT (MAX(Value) FOR IntField IN (' + @rows + ')) AS pvt
			WHERE [Department] = ''' + @Department + ''' AND
				[RequestStatus] IN (''Submitted'',''PM Review'',''Assigned'') '

		PRINT @sql
		EXEC (@sql)
	END
END
GO
GRANT EXECUTE ON [Req].[RequestGet] TO REMI
GO
create PROCEDURE dbo.[remispTests] @TrackingLocationID INT, @JobID INT
AS
BEGIN	
	SELECT test.TestName, test.ProcessOrder
	INTO #tests
	FROM (
	SELECT t.TestName, ts.ProcessOrder
	FROM Tests t
	INNER JOIN TrackingLocationsForTests tlft ON t.ID = tlft.TestID
	INNER JOIN TrackingLocationTypes tlt ON tlt.ID = tlft.TrackingLocationtypeID
	INNER JOIN TrackingLocations tl ON tl.TrackingLocationTypeID = tlt.ID
	INNER JOIN TestStages ts ON ts.TestID = t.ID AND ts.JobID=@jobID AND t.TestType NOT IN (1, 3)
	WHERE ISNULL(t.IsArchived, 0)=0 AND tl.ID = @TrackingLocationID
	UNION
	SELECT t2.TestName, 0 AS ProcessOrder
	FROM Tests t2
	INNER JOIN TrackingLocationsForTests tlft ON t2.ID = tlft.TestID
	INNER JOIN TrackingLocationTypes tlt ON tlt.ID = tlft.TrackingLocationtypeID
	INNER JOIN TrackingLocations tl ON tl.TrackingLocationTypeID = tlt.ID
	WHERE ISNULL(t2.IsArchived, 0)=0 AND tl.ID = @TrackingLocationID AND t2.TestType IN (1, 3)
	) test
	ORDER BY test.ProcessOrder
	
	SELECT TestName FROM #tests
	
	DROP TABLE #tests
END
GO
GRANT EXECUTE ON dbo.[remispTests] TO Remi
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering permissions on [Req].[RequestGet]'
GO
GRANT EXECUTE ON  [Req].[RequestGet] TO [remi]
GO
CREATE TABLE [Req].[RequestTypeAccess](
	[RequestTypeAccessID] [int] IDENTITY(1,1) NOT NULL,
	[RequestTypeID] [int] NOT NULL,
	[LookupID] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
 CONSTRAINT [PK_RequestTypeAccess] PRIMARY KEY CLUSTERED 
(
	[RequestTypeAccessID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [Req].[RequestTypeAccess]  WITH CHECK ADD  CONSTRAINT [FK_RequestTypeAccess_Lookups] FOREIGN KEY([LookupID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO
ALTER TABLE [Req].[RequestTypeAccess] CHECK CONSTRAINT [FK_RequestTypeAccess_Lookups]
GO
ALTER TABLE [Req].[RequestTypeAccess]  WITH CHECK ADD  CONSTRAINT [FK_RequestTypeAccess_RequestType] FOREIGN KEY([RequestTypeID])
REFERENCES [Req].[RequestType] ([RequestTypeID])
GO
ALTER TABLE [Req].[RequestTypeAccess] CHECK CONSTRAINT [FK_RequestTypeAccess_RequestType]
GO
ALTER TABLE [Req].[RequestTypeAccess] ADD  CONSTRAINT [DF_RequestTypeAccess_IsActive]  DEFAULT ((0)) FOR [IsActive]
GO
DECLARE @LookupID INT
DECLARE @RequestTypeID INT
SELECT @LookupID=LookupID FROM Lookups WHERE LookupTypeID IN (SELECT LookupTypeID FROM LookupType WHERE Name='Department') AND [Values]='Product Validation'
SELECT @RequestTypeID=RequestTypeID FROM Req.RequestType WHERE TypeID IN (SELECT LookupID FROM Lookups WHERE [Values]='QRA' AND LookupTypeID IN (SELECT LookupTypeID FROM LookupType WHERE Name='RequestType'))

INSERT INTO Req.RequestTypeAccess (RequestTypeID, LookupID, IsActive) VALUES (@RequestTypeID, @LookupID, 1)
GO
create PROCEDURE Req.remispGetRequestTypes @UserName NVARCHAR(255)
AS
BEGIN
	SELECT lt.[Values] AS RequestType, l.[Values] AS Department, rta.IsActive
	FROM Req.RequestTypeAccess rta
		INNER JOIN Lookups l ON rta.LookupID=l.LookupID
		INNER JOIN Req.RequestType rt ON rt.RequestTypeID=rta.RequestTypeID
		INNER JOIN Lookups lt ON rt.TypeID=lt.LookupID
		INNER JOIN UserDetails ud ON ud.LookupID = l.LookupID
		INNER JOIN Users u ON u.ID=ud.UserID
	WHERE u.LDAPLogin=@UserName
END
GO
GRANT EXECUTE ON Req.remispGetRequestTypes TO REMI
GO
IF EXISTS (SELECT * FROM #tmpErrors) ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT>0 BEGIN
PRINT 'The database update succeeded'
ROLLBACK TRANSACTION
END
ELSE PRINT 'The database update failed'
GO
DROP TABLE #tmpErrors
GO