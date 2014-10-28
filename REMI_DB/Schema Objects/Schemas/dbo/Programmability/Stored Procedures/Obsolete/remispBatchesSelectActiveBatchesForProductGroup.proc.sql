ALTER PROCEDURE [dbo].[remispBatchesSelectActiveBatchesForProductGroup]
	@ProductID INT = null,
	@AccessoryGroupID INT = null,
	@RecordCount int = null OUTPUT,
	@GetAllBatches int = 0
AS
	IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (SELECT COUNT(*) FROM Batches WITH(NOLOCK) WHERE 		
		(Batches.BatchStatus NOT IN(5,7) or @GetAllBatches =1)
		AND productID = @ProductID AND (AccessoryGroupID=@AccessoryGroupID or @AccessoryGroupID is null))
		RETURN
	END
	
	SELECT ROW_NUMBER() OVER (ORDER BY b.ID) AS Row, BatchStatus, b.Comment, b.ConcurrencyID, b.ID, j.JobName,
		b.LastUser, Priority, p.ProductGroupName, l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, productid, QRANumber, RequestPurpose,
		l3.[Values] As TestCenterLocation,TestStageName, TestStageCompletionStatus, (select count(*) from testunits WITH(NOLOCK) where testunits.batchid = b.id) AS TestUNitCount,
		RQID As ReqID,
		(CASE WHEN WILocation IS NULL THEN NULL ELSE WILocation END) AS jobWILocation,
		((select count(*) from testunits WITH(NOLOCK) where testunits.batchid = b.id) -
			(select COUNT(*) 
			from TestUnits as tu WITH(NOLOCK)
			INNER JOIN DeviceTrackingLog as dtl WITH(NOLOCK) ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			where dtl.OutTime IS null and tu.BatchID = b.ID)
		) as HasUnitsToReturnToRequestor,
		(select AssignedTo 
		from TaskAssignments as ta WITH(NOLOCK)
			--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
			INNER JOIN TestStages ts WITH(NOLOCK) ON ta.TaskID = ts.ID AND ts.TestStageName=b.TestStageName 
			--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
			INNER JOIN Jobs j WITH(NOLOCK) ON j.ID = ts.JobID AND j.JobName = j.JobName
		where ta.BatchID = b.ID and ta.Active=1  ) as ActiveTaskAssignee, CONVERT(BIT,0) AS HasBatchSpecificExceptions,
		ProductTypeID,AccessoryGroupID, TestCenterLocationID, AssemblyNumber, AssemblyRevision, HWRevision, PartName, ReportRequiredBy, ReportApprovedDate,
		IsMQual, j.ID AS JobID
	FROM Batches as b WITH(NOLOCK)
		inner join Products p WITH(NOLOCK) on b.ProductID=p.id
		LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
		LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON b.ProductTypeID=l.LookupID  
		LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON b.AccessoryGroupID=l2.LookupID  
		LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON b.TestCenterLocationID=l3.LookupID  
	WHERE (b.BatchStatus NOT IN(5,7) or @GetAllBatches =1) AND p.ID = @ProductID and (AccessoryGroupID = @AccessoryGroupID or @AccessoryGroupID is null)
	RETURN
GO
GRANT EXECUTE ON remispBatchesSelectActiveBatchesForProductGroup TO Remi
GO