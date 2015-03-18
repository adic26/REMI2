/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        (local).REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 12/2/2013 8:54:50 AM

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
alter table batches add DateCreated DateTime DEFAULT(getdate())
go
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
	@NotInTrackingLocationFunction INT  = NULL	
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
		BatchesRows.QRANumber,BatchesRows.RequestPurpose, BatchesRows.TestCenterLocationID,BatchesRows.TestStageName, BatchesRows.TestStageCompletionStatus, testUnitCount, 
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
		BatchesRows.TestCenterLocation, AssemblyNumber, AssemblyRevision, HWRevision, PartName, ReportRequiredBy, ReportApprovedDate, IsMQual, JobID, DateCreated
	FROM     
		(
			SELECT DISTINCT b.BatchStatus,b.Comment, b.teststagecompletionstatus,b.ConcurrencyID,b.ID,b.JobName,b.LastUser,b.Priority,b.ProductTypeID,b.AccessoryGroupID,p.ID As ProductID,
				p.ProductGroupName As ProductGroup,b.QRANumber,b.RequestPurpose,b.TestCenterLocationID,b.TestStageName,j.WILocation,
				(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
				l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, l3.[Values] As TestCenterLocation,
				(
					SELECT top(1) tu.CurrentTestName as CurrentTestName 
					FROM TestUnits AS tu, DeviceTrackingLog AS dtl 
					where tu.ID = dtl.TestUnitID 
					and tu.CurrentTestName is not null
					and (dtl.OutUser IS NULL) AND tu.BatchID=b.ID
				) As CurrentTest, b.CPRNumber,b.RelabJobID, b.RQID, b.AssemblyNumber, b.AssemblyRevision,b.HWRevision, b.PartName, b.ReportRequiredBy, 
				b.ReportApprovedDate, b.IsMQual, j.ID AS JobID, b.DateCreated
			FROM Batches as b WITH(NOLOCK)
				inner join Products p WITH(NOLOCK) on b.ProductID=p.id 
				LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
				LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID  
				LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.Type='TestCenter' AND b.TestCenterLocationID=l3.LookupID
				INNER JOIN TestStages ts WITH(NOLOCK) ON ts.TestStageName=b.TestStageName
			WHERE ((BatchStatus NOT IN (SELECT ID FROM #ExBatchStatus) OR @ExcludedStatus IS NULL) AND (BatchStatus = @Status OR @Status IS NULL))
				AND (p.ID = @ProductID OR @ProductID IS NULL)
				AND (b.Priority = @Priority OR @Priority IS NULL)
				AND (b.ProductTypeID = @ProductTypeID OR @ProductTypeID IS NULL)
				AND (b.AccessoryGroupID = @AccessoryGroupID OR @AccessoryGroupID IS NULL)
				AND (b.TestCenterLocationID = @GeoLocationID OR @GeoLocationID IS NULL)
				AND (b.JobName = @JobName OR @JobName IS NULL)
				AND (b.RequestPurpose = @RequestReason OR @RequestReason IS NULL)
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
						b.ID IN (select DISTINCT tu.BatchID
						from TrackingLocations tl WITH(NOLOCK)
						inner join devicetrackinglog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID AND dtl.OutTime IS NULL
						inner join TestUnits tu WITH(NOLOCK) on tu.ID=dtl.TestUnitID
						where TrackingLocationTypeID=@TrackingLocationID)
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
		b.TestCenterLocationID,
		ts.ID AS CurrentTestStageID
	FROM TestUnits as tu WITH(NOLOCK) 
		INNER JOIN Batches as b WITH(NOLOCK) on b.ID = tu.batchid
		LEFT OUTER JOIN devicetrackinglog as dtl WITH(NOLOCK) on dtl.TestUnitID =tu.id 
			AND dtl.id = (SELECT  top(1)  DeviceTrackingLog.ID from DeviceTrackingLog WITH(NOLOCK) WHERE (TestUnitID = tu.id) ORDER BY devicetrackinglog.intime desc)
		LEFT OUTER JOIN TrackingLocations as tl WITH(NOLOCK) on dtl.TrackingLocationID = tl.ID
		INNER JOIN Jobs j ON j.JobName=b.JobName
		LEFT OUTER JOIN TestStages ts ON ts.TestStageName=tu.CurrentTestStageName AND ts.JobID=j.ID
	 where b.ID = tu.BatchID and (b.QRANumber = @qranumber)
END
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