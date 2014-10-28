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
		BatchesRows.TestCenterLocation,BatchesRows.TestStageName,BatchesRows.TestStageCompletionStatus, testUnitCount, 
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
		CONVERT(BIT,0) AS HasBatchSpecificExceptions, batchesrows.ProductTypeID,batchesrows.AccessoryGroupID,BatchesRows.RQID AS ReqID,
		AssemblyNumber, AssemblyRevision, HWRevision, PartName, ReportRequiredBy, ReportApprovedDate, JobID
	FROM     
		(
			SELECT ROW_NUMBER() OVER (ORDER BY b.ID) AS Row, 
				b.BatchStatus,b.Comment,
				b.teststagecompletionstatus,b.ConcurrencyID,b.ID,b.JobName,b.LastUser,b.Priority,b.ProductTypeID,b.AccessoryGroupID,p.ID As ProductID,
				p.ProductGroupName,b.QRANumber,b.RequestPurpose,b.TestCenterLocation,b.TestStageName,j.WILocation,
				(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
				l.[Values] As ProductType, l2.[Values] As AccessoryGroupName,b.RQID,
				AssemblyNumber, AssemblyRevision, HWRevision, PartName, ReportRequiredBy, ReportApprovedDate, j.ID AS JobID
			FROM Batches as b
				inner join Products p on b.ProductID=p.id 
				LEFT OUTER JOIN Jobs j ON j.JobName = b.JobName -- BatchesRows.JobName can be missing record in Jobs table. This is why we use LEFT OUTER JOIN. This will return NULL if such a case occurs.
				LEFT OUTER JOIN Lookups l ON b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 ON b.AccessoryGroupID=l2.LookupID  
			WHERE (b.ID = @ID or @ID is null) AND (BatchStatus = @Status or @Status is null) 
				AND (QRANumber LIKE '%' + @QRANumber + '%' OR @QRANumber IS NULL)
				AND (p.ProductGroupName = @ProductGroupName OR @ProductGroupName IS NULL)
		)AS BatchesRows		
	WHERE (Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) OR @startRowIndex is null OR @maximumRows is null
	RETURN
GO
GRANT EXECUTE ON remispBatchesSearchList TO Remi
GO