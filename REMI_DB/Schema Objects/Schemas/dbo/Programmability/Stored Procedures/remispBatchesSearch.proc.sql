﻿ALTER PROCEDURE [dbo].[remispBatchesSearch]
	@ByPassProductCheck INT = 0,
	@ExecutingUserID int,
	@Status int = null,
	@Priority int = null,
	@UserID int = null,
	@TrackingLocationTypeID int = null,
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
	@DepartmentID INT = NULL,
	@OnlyHasResults INT = NULL,
	@JobID INT = 0,
	@TrackingLocationID INT = NULL,
	@Requestor NVARCHAR(255) = NULL
AS
	--SET FMTONLY OFF --Used when importing into the entity framework
	DECLARE @TestName NVARCHAR(400)
	DECLARE @TestStageName NVARCHAR(400)
	DECLARE @HasBatchSpecificExceptions BIT
	SET @HasBatchSpecificExceptions = CONVERT(BIT, 0)
	
	IF (@TestID IS NOT NULL)
	BEGIN
		SELECT @TestName = TestName FROM Tests WITH(NOLOCK) WHERE ID=@TestID 
	END
	
	IF (@TestStageID IS NOT NULL)
	BEGIN
		SELECT @TestStageName = TestStageName FROM TestStages WITH(NOLOCK) WHERE ID=@TestStageID
	END
	
	CREATE TABLE #ExTestStageType (ID INT)
	CREATE TABLE #ExBatchStatus (ID INT)
	
	IF (@TestStageName IS NOT NULL)
		SET @TestStage = NULL
	
	IF (@excludedTestStageType IS NOT NULL)
	BEGIN
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
	END
		
	IF (@ExcludedStatus IS NOT NULL)
	BEGIN
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
		MechanicalTools, BatchesRows.RequestPurpose, BatchesRows.PriorityID, DepartmentID, Department, Requestor, BatchesRows.TestStageID,
		BatchesRows.OrientationID
	FROM     
		(
			SELECT DISTINCT b.BatchStatus,b.Comment, b.teststagecompletionstatus,b.ConcurrencyID,b.ID,b.JobName,b.LastUser,b.Priority AS PriorityID,b.ProductTypeID,
				b.AccessoryGroupID,b.ProductID As ProductID,p.[Values] As ProductGroup,b.QRANumber,b.RequestPurpose As RequestPurposeID,b.TestCenterLocationID,b.TestStageName,
				j.WILocation,(select count(*) from testunits WITH(NOLOCK) where testunits.batchid = b.id) as testUnitCount,
				l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, l3.[Values] As TestCenterLocation,
				b.CPRNumber,b.RelabJobID, b.RQID, b.AssemblyNumber, b.AssemblyRevision,b.HWRevision, b.PartName, b.ReportRequiredBy, 
				b.ReportApprovedDate, b.IsMQual, j.ID AS JobID, b.DateCreated, j.ContinueOnFailures, MechanicalTools, l4.[Values] As RequestPurpose, l5.[Values] As Priority, 
				ISNULL(b.[Order], 100) As PriorityOrder, b.DepartmentID, l6.[Values] AS Department, b.Requestor, ts.ID AS TestStageID,
				b.OrientationID
			FROM Batches as b WITH(NOLOCK)
				INNER JOIN Lookups p WITH(NOLOCK) ON p.LookupID=b.ProductID
				LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
				LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON b.AccessoryGroupID=l2.LookupID  
				LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON b.TestCenterLocationID=l3.LookupID
				INNER JOIN TestStages ts WITH(NOLOCK) ON ts.TestStageName=b.TestStageName AND ts.JobID=j.ID
				LEFT OUTER JOIN Lookups l4 WITH(NOLOCK) ON b.RequestPurpose=l4.LookupID
				LEFT OUTER JOIN Lookups l5 WITH(NOLOCK) ON b.Priority=l5.LookupID
				LEFT OUTER JOIN Lookups l6 WITH(NOLOCK) ON b.DepartmentID=l6.LookupID
			WHERE
				(
					(ISNULL(@ExcludedStatus, 0) > 0 AND BatchStatus NOT IN (SELECT ID FROM #ExBatchStatus WITH(NOLOCK)))
					OR
					(ISNULL(@ExcludedStatus, 0) = 0)
				)
				AND
				(
					(ISNULL(@Status, 0) > 0 AND BatchStatus = @Status)
					OR
					(ISNULL(@Status, 0) = 0)
				)
				AND 
				(
					(ISNULL(@ProductID, 0) > 0 AND p.LookupID = @ProductID)
					OR 
					ISNULL(@ProductID, 0) = 0
				)
				AND 
				(
					(ISNULL(@Priority, 0) > 0 AND b.Priority = @Priority)
					OR 
					ISNULL(@Priority, 0) = 0
				)
				AND 
				(
					(ISNULL(@ProductTypeID, 0) > 0 AND b.ProductTypeID = @ProductTypeID)
					OR 
					ISNULL(@ProductTypeID, 0) = 0
				)
				AND 
				(
					(ISNULL(@AccessoryGroupID, 0) > 0 AND b.AccessoryGroupID = @AccessoryGroupID)
					OR 
					ISNULL(@AccessoryGroupID, 0) = 0
				)
				AND 
				(
					(ISNULL(@GeoLocationID, 0) > 0 AND b.TestCenterLocationID = @GeoLocationID)
					OR 
					ISNULL(@GeoLocationID, 0) = 0
				)
				AND 
				(
					(ISNULL(@DepartmentID, 0) > 0 AND b.DepartmentID = @DepartmentID)
					OR 
					ISNULL(@DepartmentID, 0) = 0
				)
				AND 
				(
					(ISNULL(@RequestReason, 0) > 0 AND b.RequestPurpose = @RequestReason)
					OR 
					ISNULL(@RequestReason, 0) = 0
				)
				AND 
				(
					(@Revision IS NOT NULL AND b.MechanicalTools = @Revision)
					OR 
					@Revision IS NULL
				)
				AND 
				(
					(@Requestor IS NOT NULL AND b.Requestor = @Requestor)
					OR 
					@Requestor IS NULL
				)
				AND 
				(
					(ISNULL(@JobID, 0) > 0 AND j.ID=@JobID)
					OR
					(ISNULL(@JobID, 0) = 0 AND @JobName IS NOT NULL AND b.JobName = @JobName)
					OR
					(@JobName IS NULL AND ISNULL(@JobID, 0) = 0)
				)
				AND 
				(
					(@TestStageName IS NOT NULL AND @TestStage IS NULL AND b.TestStageName = @TestStageName)
					OR
					(@TestStage IS NOT NULL AND b.TestStageName = @TestStage AND @TestStageName IS NULL)
					OR
					(@TestStageName IS NULL AND @TestStage IS NULL)
				)
				AND
				(
					(ISNULL(@excludedTestStageType, 0) > 0 AND ts.TestStageType NOT IN (SELECT ID FROM #ExTestStageType))
					OR
					(ISNULL(@excludedTestStageType, 0) = 0)
				)
				AND
				(
					(ISNULL(@TestStageType, 0) > 0 AND ts.TestStageType = @TestStageType)
					OR
					(ISNULL(@TestStageType, 0) = 0)
				)
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.LookupID IN (SELECT ud.LookupID FROM UserDetails ud WITH(NOLOCK) WHERE UserID=@ExecutingUserID)))
				AND 
				(
					(@BatchStart IS NULL AND @BatchEnd IS NULL)
					OR
					(@BatchStart IS NOT NULL AND @BatchEnd IS NOT NULL AND b.ID IN (Select distinct batchid FROM BatchesAudit WITH(NOLOCK) WHERE InsertTime BETWEEN @BatchStart AND @BatchEnd))
				)
				AND
				(
					(ISNULL(@OnlyHasResults, 0) = 0)
					OR
					(@OnlyHasResults = 1 AND EXISTS(SELECT TOP 1 1 FROM TestUnits tu WITH(NOLOCK) INNER JOIN Relab.Results r WITH(NOLOCK) ON r.TestUnitID=tu.ID WHERE tu.BatchID=b.ID))
				)
				AND
				(
					(@TestName IS NOT NULL AND (
						SELECT top(1) tu.CurrentTestName as CurrentTestName 
						FROM TestUnits AS tu WITH(NOLOCK), DeviceTrackingLog AS dtl WITH(NOLOCK)
						where tu.ID = dtl.TestUnitID 
						and tu.CurrentTestName is not null
						and (dtl.OutUser IS NULL) AND tu.BatchID=b.ID
					) = @TestName)
					OR 
					(@TestName IS NULL)
				)
				AND
				(
					(@UserID IS NOT NULL AND (
						SELECT top 1 u.id 
						FROM TestUnits as tu WITH(NOLOCK), devicetrackinglog as dtl WITH(NOLOCK), TrackingLocations as tl WITH(NOLOCK), Users u WITH(NOLOCK)
						WHERE tl.ID = dtl.TrackingLocationID and tu.id  = dtl.testunitid and tu.batchid = b.id and  inuser = u.LDAPLogin and outuser is null
					) = @UserID)
					OR
					(@UserID IS NULL)
				)
				AND
				(
					(ISNULL(@TrackingLocationFunction, 0) = 0)
					OR
					(ISNULL(@TrackingLocationFunction, 0) > 0 AND (
						b.ID IN (select DISTINCT tu.BatchID
						FROM TrackingLocations tl WITH(NOLOCK)
							INNER JOIN devicetrackinglog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID AND dtl.OutTime IS NULL
							INNER JOIN TestUnits tu WITH(NOLOCK) on tu.ID=dtl.TestUnitID
							INNER JOIN TrackingLocationTypes tlt WITH(NOLOCK) ON tlt.ID = tl.TrackingLocationTypeID
						where tlt.TrackingLocationFunction=@TrackingLocationFunction)
					))
				)
				AND
				(
					(ISNULL(@TrackingLocationTypeID, 0) = 0)
					OR
					(ISNULL(@TrackingLocationTypeID, 0) > 0 AND (
						b.ID IN (SELECT DISTINCT tu.BatchID
						FROM TrackingLocations tl WITH(NOLOCK)
							INNER JOIN devicetrackinglog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID --AND dtl.OutTime IS NULL
								AND dtl.InTime BETWEEN @BatchStart AND @BatchEnd
							INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID=dtl.TestUnitID
						WHERE TrackingLocationTypeID=@TrackingLocationTypeID)
					))
				)
				AND
				(
					(ISNULL(@TrackingLocationID, 0) = 0)
					OR
					(ISNULL(@TrackingLocationID, 0) > 0 AND (
						b.ID IN (SELECT DISTINCT tu.BatchID
						FROM TrackingLocations tl WITH(NOLOCK)
							INNER JOIN devicetrackinglog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID AND dtl.OutTime IS NULL
							INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID=dtl.TestUnitID
						WHERE tl.ID=@TrackingLocationID)
					))
				)
				AND
				(
					(ISNULL(@NotInTrackingLocationFunction, 0) = 0)
					OR
					(ISNULL(@NotInTrackingLocationFunction, 0) > 0 AND (
						b.ID IN (select DISTINCT tu.BatchID
						FROM TrackingLocations tl WITH(NOLOCK)
							INNER JOIN devicetrackinglog dtl WITH(NOLOCK) ON tl.ID=dtl.TrackingLocationID AND dtl.OutTime IS NULL
							INNER JOIN TestUnits tu WITH(NOLOCK) on tu.ID=dtl.TestUnitID
							INNER JOIN TrackingLocationTypes tlt WITH(NOLOCK) ON tlt.ID = tl.TrackingLocationTypeID
						where tlt.TrackingLocationFunction NOT IN (@NotInTrackingLocationFunction))
					))
				)
		)AS BatchesRows		
	ORDER BY BatchesRows.PriorityOrder ASC, BatchesRows.QRANumber DESC
	
	DROP TABLE #ExTestStageType
	DROP TABLE #ExBatchStatus
	RETURN
GO
GRANT EXECUTE ON remispBatchesSearch TO Remi
GO