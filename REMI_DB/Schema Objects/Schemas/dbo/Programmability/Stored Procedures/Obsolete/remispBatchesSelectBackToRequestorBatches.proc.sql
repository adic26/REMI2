ALTER PROCEDURE [dbo].[remispBatchesSelectBackToRequestorBatches]
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
	batchesrows.TestStageCompletionStatus, testUnitCount,jobwilocation, 
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
	batchesrows.ProductTypeID,batchesrows.AccessoryGroupID,batchesrows.RQID AS ReqID, AssemblyNumber, AssemblyRevision, HWRevision, PartName, ReportRequiredBy, ReportApprovedDate
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
		b.TestStageCompletionStatus,
		(select count(*) from testunits where testunits.batchid = b.id) as testUnitCount,
		(select Jobs.WILocation from Jobs where Jobs.JobName = b.jobname) as jobWILocation,
		RQID, AssemblyNumber, AssemblyRevision, HWRevision, PartName, ReportRequiredBy, ReportApprovedDate
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
			b.TestStageCompletionStatus,b.RQID, AssemblyNumber, AssemblyRevision, HWRevision, PartName, ReportRequiredBy, ReportApprovedDate
		FROM Batches AS b 
			INNER JOIN DeviceTrackingLog AS dtl
			INNER JOIN TrackingLocations AS tl ON dtl.TrackingLocationID = tl.ID
			INNER JOIN TestUnits AS tu ON dtl.TestUnitID = tu.ID ON b.id = tu.batchid --batches where there's a tracking log
			inner join Products p on p.ID=b.ProductID
			LEFT OUTER JOIN Lookups l ON b.ProductTypeID=l.LookupID  
			LEFT OUTER JOIN Lookups l2 ON b.AccessoryGroupID=l2.LookupID  
		WHERE (tl.id != 81 AND dtl.OutTime IS NULL AND dtl.OutUser IS NULL) and b.BatchStatus = 8
	)as b
) as batchesrows	
WHERE ((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) OR @startRowIndex = -1 OR @maximumRows = -1) 
order by QRANumber desc
GO
GRANT EXECUTE ON remispBatchesSelectBackToRequestorBatches TO Remi