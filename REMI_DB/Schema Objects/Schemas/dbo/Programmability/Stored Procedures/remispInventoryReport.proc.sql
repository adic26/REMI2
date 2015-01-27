ALTER procedure [dbo].[remispInventoryReport]
	@StartDate datetime,
	@EndDate datetime,
	@FilterBasedOnQraNumber bit,
	@geographicallocation INT = NULL
AS

IF @geographicallocation = 0
	SET @geographicallocation = NULL

declare @startYear int = Right(year( @StartDate), 2);
declare @endYear int = Right(year( @EndDate), 2);
declare @AverageTestUnitsPerBatch int = -1

declare @TotalBatches int = (select COUNT(*) from BatchesAudit  where 
 BatchesAudit.InsertTime >= @StartDate and BatchesAudit.InsertTime <= @EndDate and BatchesAudit.Action = 'I' 
 and (@FilterBasedOnQraNumber = 0 or (Convert(int , SUBSTRING(BatchesAudit.QRANumber, 5, 2)) >= @startYear
 and Convert(int , SUBSTRING(BatchesAudit.QRANumber, 5, 2)) <= @endYear))
 and (@geographicallocation IS NULL or BatchesAudit.TestCenterLocationID = @geographicallocation)
 );

declare @TotalTestUnits int =(select COUNT(*) as TotalTestUnits from TestUnitsAudit, batchesaudit  where 
 TestUnitsAudit.InsertTime >= @StartDate and TestUnitsAudit.InsertTime <= @EndDate and TestUnitsAudit.Action = 'I' 
 and BatchesAudit.InsertTime >= @StartDate and BatchesAudit.InsertTime <= @EndDate and BatchesAudit.Action = 'I' 
 and (@FilterBasedOnQraNumber = 0 or (Convert(int , SUBSTRING(batchesaudit.QRANumber, 5, 2)) >= @startYear
 and Convert(int , SUBSTRING(batchesaudit.QRANumber, 5, 2)) <= @endYear))
and TestUnitsAudit.BatchID = Batchesaudit.batchID 
and (@geographicallocation IS NULL or batchesaudit.TestCenterLocationID = @geographicallocation)
);

if @TotalBatches != 0
begin
 set @AverageTestUnitsPerBatch = @totaltestunits / @totalbatches;
end

select @TotalBatches as TotalBatches, @TotalTestUnits as TotalTestUnits, @AverageTestUnitsPerBatch as AverageUnitsPerBatch;

select lp.[Values] as ProductGroup, COUNT( distinct BatchesAudit.id) as TotalBatches,
COUNT(TestUnits.ID) as TotalTestUnits 
from BatchesAudit,testunits , Products p
	INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
where p.ID=BatchesAudit.ProductID and 
BatchesAudit.InsertTime >= @StartDate and BatchesAudit.InsertTime <= @EndDate and BatchesAudit.Action = 'I' 
and (@FilterBasedOnQraNumber = 0 or (Convert(int , SUBSTRING(BatchesAudit.QRANumber, 5, 2)) >= @startYear
and Convert(int , SUBSTRING(BatchesAudit.QRANumber, 5, 2)) <= @endYear)) 
and (BatchesAudit.TestCenterLocationID = @geographicallocation or @geographicallocation IS NULL)
and BatchesAudit.BatchID = TestUnits.BatchID 
group by lp.[Values];
GO
GRANT EXECUTE ON remispInventoryReport TO Remi
GO