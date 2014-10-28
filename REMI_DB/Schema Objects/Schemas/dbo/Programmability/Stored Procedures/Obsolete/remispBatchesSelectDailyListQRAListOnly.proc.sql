ALTER PROCEDURE [dbo].[remispBatchesSelectDailyListQRAListOnly]
	@StartRowIndex int = -1,
	@MaximumRows int = -1,
	@RecordCount int = NULL OUTPUT,
	@ProductID INT = null,
	@sortExpression varchar(100) = null,
	@GetBatchesAtEnvStages int = 1,
	@direction varchar(100) = 'desc',
	@TestCenterLocation as INT= null,
	@GetOperationsTests as bit = 0,
	@GetTechnicalOperationsTests as bit = 1,
	@TestStageCompletion as int	 = null
AS

IF (@RecordCount IS NOT NULL)
BEGIN
	SET @RecordCount = (select COUNT(*) from (SELECT distinct b.* FROM Batches as b, TestStages as ts, TestUnits as tu, Jobs as j, Products p where 
	( ts.TestStageName = b.TestStageName) 
	and tu.BatchID = b.id
	and ts.JobID = j.id
	and j.JobName = b.JobName
	and ((j.OperationsTest = @getoperationstests and @GetOperationsTests = 1)
	or (j.TechnicalOperationsTest = @GetTechnicalOperationsTests and @GetTechnicalOperationsTests = 1 ))
	and ((b.batchstatus=2 or b.BatchStatus = 4) and (ts.TestStageType =  @GetBatchesAtEnvStages))
	and (@ProductID is null or p.ID = @ProductID)
	and ((@TestStageCompletion is null or b.TestStageCompletionStatus = @TestStageCompletion)
	or  (@TestStageCompletion = 2 and (b.TestStageCompletionStatus = 2 or b.TestStageCompletionStatus = 3)))
	and (@TestCenterLocation is null or TestCenterLocationID = @TestCenterLocation)) as batchcount)
	RETURN
END

SELECT BatchesRows.QRANumber
FROM (
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
				case when @sortExpression='productgroup' and @direction='asc' then b.productgroupname end asc,
				case when @sortExpression='productgroup' and @direction='desc' then b.productgroupname end desc,
				case when @sortExpression='priority' and @direction='asc' then Priority end asc,
				case when @sortExpression='priority' and @direction='desc' then Priority end desc,
				case when @sortExpression='batchstatus' and @direction='asc' then batchstatus end,
				case when @sortExpression='batchstatus' and @direction='desc' then batchstatus end desc,
				case when @sortExpression='testcenter' and @direction='asc' then TestCenterLocationID end,
				case when @sortExpression='testcenter' and @direction='desc' then TestCenterLocationID end desc,
				case when @sortExpression is null then (cast(priority as varchar(10)) + qranumber) end desc
		) AS Row, 
		b.ID,
		b.QRANumber, 
		b.Priority, 
		b.TestStageName,
		b.BatchStatus, 
		b.ProductGroupName,
		b.ProductTypeID,
		b.AccessoryGroupID,
		b.ProductType,
		b.AccessoryGroupName,
		b.ProductID,
		b.Jobname,
		b.LastUser,
		b.ConcurrencyID,
		b.Comment,
		b.TestCenterLocationID,
		b.TestCenterLocation,
		b.RequestPurpose,
		b.TestStageCompletionStatus,
		(select COUNT (*) from TestUnits as tu where tu.id = b.ID) as testunitcount,
		AssemblyNumber, AssemblyRevision, HWRevision, PartName, ReportRequiredBy, ReportApprovedDate, IsMQual, JobID, ExecutiveSummary
		FROM 
		(
			select distinct b.*, p.ProductGroupName, l.[Values] As ProductType, l2.[Values] As AccessoryGroupName, l3.[Values] As TestCenterLocation, j.ID AS JobID
			from Batches as b
				INNER JOIN TestStages as ts ON (ts.TestStageName = b.TestStageName)
				INNER JOIN TestUnits as tu ON (tu.BatchID = b.ID)
				INNER JOIN Products p ON p.ID=b.ProductID
				LEFT OUTER JOIN Jobs j ON (j.JobName = b.JobName)
				LEFT OUTER JOIN Lookups l ON b.ProductTypeID=l.LookupID  
				LEFT OUTER JOIN Lookups l2 ON b.AccessoryGroupID=l2.LookupID  
				LEFT OUTER JOIN Lookups l3 ON b.TestCenterLocationID=l3.LookupID 
			WHERE ts.JobID = j.ID and (b.batchstatus=2) and (ts.TestStageType =  @GetBatchesAtEnvStages) and (@ProductID is null or p.ID = @ProductID)	
					and
					(
						(j.OperationsTest = @getoperationstests and @GetOperationsTests = 1)
						or 
						(j.TechnicalOperationsTest = @GetTechnicalOperationsTests and @GetTechnicalOperationsTests = 1 )
					)			
				and
				(
					(@TestStageCompletion is null or b.TestStageCompletionStatus = @TestStageCompletion)
					or
					(@TestStageCompletion = 2 and (b.TestStageCompletionStatus = 2 or b.TestStageCompletionStatus = 3))
				)
				and (@TestCenterLocation is null or TestCenterLocationID = @TestCenterLocation)
		) as b
	) AS BatchesRows 
WHERE (
		(Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) 
		OR @startRowIndex = -1 OR @maximumRows = -1
	  ) order by row
GO
GRANT EXECUTE ON remispBatchesSelectDailyListQRAListOnly TO Remi