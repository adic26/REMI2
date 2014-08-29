ALTER PROCEDURE [dbo].[remispBatchesSelectHeldBatches]
	@TestCentreLocation INT =null,
	@RecordCount int = NULL OUTPUT,
	@sortExpression varchar(100) = null,
	@direction varchar(100) = 'asc',
	@ByPassProductCheck INT = 0,
	@UserID int
	AS
	SELECT ROW_NUMBER() OVER (ORDER BY 
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
		BatchStatus,Comment,ConcurrencyID,b.ID,
		JobName,LastUser,Priority,ProductGroupName,QRANumber,
		RequestPurpose,TestCenterLocation,TestStageName,ProductType, AccessoryGroupName,productID,
		TestStageCompletionStatus, (select count(*) from testunits WITH(NOLOCK) where testunits.batchid = b.id) as testunitcount,
		(CASE WHEN WILocation IS NULL THEN NULL ELSE WILocation END) AS jobWILocation,			
		((select count(*) from testunits WITH(NOLOCK) where testunits.batchid = b.id)  -
		(select COUNT(*) 
			from TestUnits as tu WITH(NOLOCK)
			INNER JOIN DeviceTrackingLog as dtl WITH(NOLOCK) ON dtl.TestUnitID = tu.ID AND dtl.TrackingLocationID = 81
			where dtl.OutTime IS null and tu.BatchID = b.ID)
		) as HasUnitsToReturnToRequestor,
		(select AssignedTo 
		from TaskAssignments as ta WITH(NOLOCK)
			--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
			INNER JOIN TestStages ts WITH(NOLOCK) ON ta.TaskID = ts.ID AND ts.TestStageName=TestStageName 
			--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
			INNER JOIN Jobs j WITH(NOLOCK) ON j.ID = ts.JobID AND j.JobName = j.JobName
		where ta.BatchID = b.ID and ta.Active=1  ) as ActiveTaskAssignee, CONVERT(BIT,0) AS HasBatchSpecificExceptions,
		ProductTypeID, AccessoryGroupID,RQID As ReqID, TestCenterLocationID,
		AssemblyNumber, AssemblyRevision, HWRevision, PartName, ReportRequiredBy, ReportApprovedDate, IsMQual, JobID
	FROM
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
                b.TestStageCompletionStatus,
                j.WILocation,b.RQID, b.AssemblyNumber, b.AssemblyRevision,b.HWRevision, b.PartName, b.ReportRequiredBy, b.ReportApprovedDate, b.IsMQual, j.ID AS JobID
			FROM Batches AS b WITH(NOLOCK)
				 INNER JOIN Products p WITH(NOLOCK) on b.ProductID=p.id
				 LEFT OUTER JOIN Jobs j WITH(NOLOCK) ON j.JobName = b.JobName
				 LEFT OUTER JOIN Lookups l WITH(NOLOCK) ON l.Type='ProductType' AND l.LookupID=b.ProductTypeID
				 LEFT OUTER JOIN Lookups l2 WITH(NOLOCK) ON l2.Type='AccessoryType' AND l2.LookupID=b.AccessoryGroupID
				 LEFT OUTER JOIN Lookups l3 WITH(NOLOCK) ON l3.Type='TestCenter' AND b.TestCenterLocationID=l3.LookupID  
			WHERE (b.TestCenterLocationID = @TestCentreLocation or @TestCentreLocation is null) and (b.BatchStatus = 1 or b.BatchStatus = 3) 
				AND (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND p.ID IN (SELECT ProductID FROM UsersProducts WITH(NOLOCK) WHERE UserID=@UserID)))
		)as b
order by QRANumber desc
GO
GRANT EXECUTE ON remispBatchesSelectHeldBatches TO Remi
GO