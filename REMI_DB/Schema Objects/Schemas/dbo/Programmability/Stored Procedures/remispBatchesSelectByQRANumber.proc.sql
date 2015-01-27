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
	BatchesRows.LastUser,BatchesRows.Priority AS PriorityID,lp.[Values] AS ProductGroupName,BatchesRows.QRANumber,BatchesRows.RequestPurpose As RequestPurposeID,batchesrows.ProductTypeID,batchesrows.AccessoryGroupID,
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
		INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
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
GRANT EXECUTE ON remispBatchesSelectByQRANumber TO Remi
Go