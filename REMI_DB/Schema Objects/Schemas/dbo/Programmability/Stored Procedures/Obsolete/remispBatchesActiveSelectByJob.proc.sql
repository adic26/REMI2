ALTER PROCEDURE [dbo].[remispBatchesActiveSelectByJob]
	@JobName NVARCHAR(400),
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
		BatchStatus,Comment,ConcurrencyID,ID, JobName,LastUser,Priority,ProductGroupName,QRANumber,	RequestPurpose,TestCenterLocation,TestStageName,ProductType, AccessoryGroupName,ProductID,
		TestStageCompletionStatus,testunitcount,RQID As ReqID,
		(
			testunitcount -
			(select COUNT(*) 
			from TestUnits as tu
				INNER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			where dtl.OutTime IS null and tu.BatchID = b.ID)
		) as HasUnitsToReturnToRequestor,
		(CASE WHEN WILocation IS NULL THEN NULL ELSE WILocation END) AS jobWILocation,
		(
			select DISTINCT TOP 1 AssignedTo 
			from TaskAssignments as ta
				--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
				INNER JOIN TestStages ts ON ta.TaskID = ts.ID AND ts.TestStageName=TestStageName 
				--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
				INNER JOIN Jobs j ON j.ID = ts.JobID AND j.JobName = JobName
			where ta.BatchID = b.ID and ta.Active=1
		) as ActiveTaskAssignee, CONVERT(BIT,0) AS HasBatchSpecificExceptions, AccessoryGroupID,ProductTypeID, TestCenterLocationID,
		AssemblyNumber, AssemblyRevision, HWRevision, PartName, ReportRequiredBy, ReportApprovedDate, IsMQual, JobID
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
			b.TestStageCompletionStatus,
			j.WILocation,
			b.RQID,
			(select count(*) from testunits where testunits.batchid = b.id) As testunitcount,
			b.AssemblyNumber, b.AssemblyRevision,b.HWRevision, b.PartName, b.ReportRequiredBy, b.ReportApprovedDate, b.IsMQual, j.ID AS JobID
		FROM Batches AS b 
			INNER JOIN DeviceTrackingLog AS dtl ON dtl.OutTime IS NULL AND dtl.OutUser IS NULL
			INNER JOIN TestUnits AS tu ON dtl.TestUnitID = tu.ID AND b.id = tu.batchid --batches where there's a tracking log
			inner join Products p on p.ID=b.ProductID
			LEFT OUTER JOIN Jobs j ON j.JobName = b.JobName
			LEFT OUTER JOIN Lookups l ON b.ProductTypeID=l.LookupID
			LEFT OUTER JOIN Lookups l2 ON b.AccessoryGroupID=l2.LookupID
			LEFT OUTER JOIN Lookups l3 ON b.TestCenterLocationID=l3.LookupID  
		WHERE b.BatchStatus NOT IN (5,8) AND b.Jobname=@JobName
	)as b
GO
GRANT EXECUTE ON  [dbo].[remispBatchesActiveSelectByJob] TO [remi]
GO