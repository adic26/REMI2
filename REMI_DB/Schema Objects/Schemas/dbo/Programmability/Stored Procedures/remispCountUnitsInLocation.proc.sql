ALTER procedure remispCountUnitsInLocation
@startDate datetime,
@endDate datetime,
@geoGraphicalLocation int,
@FilterBasedOnQraNumber bit,
@productID INT
AS
declare @startYear int = Right(year( @StartDate), 2);
declare @endYear int = Right(year( @EndDate), 2);

IF @geoGraphicalLocation = 0
	SET @geoGraphicalLocation = NULL

select tl.TrackingLocationName, count(tu.id) as CountedUnits 
from TestUnits as tu, trackinglocations as tl, DeviceTrackingLog as dtl, Batches as b,Products p 
where tu.ID = dtl.TestUnitID and dtl.TrackingLocationID = tl.ID and dtl.OutUser is null and tu.BatchID = b.id
and dtl.InTime > @StartDate and dtl.InTime < @EndDate 
and (@FilterBasedOnQraNumber = 0 or (Convert(int , SUBSTRING(b.QRANumber, 5, 2)) >= @startYear
and Convert(int , SUBSTRING(b.QRANumber, 5, 2)) <= @endYear))
and (p.ID = @productID or @productID = 0)
and (b.TestCenterLocationID = @geoGraphicalLocation or @geoGraphicalLocation IS NULL) and p.ID=b.ProductID
group by TrackingLocationName 
union all
select 'Total', count(tu.id) as CountedUnits 
from TestUnits as tu, trackinglocations as tl, DeviceTrackingLog as dtl, Batches as b, Products p 
where tu.ID = dtl.TestUnitID and dtl.TrackingLocationID = tl.ID and dtl.OutUser is null and tu.BatchID = b.id
and dtl.InTime > @StartDate and dtl.InTime < @EndDate 
and (@FilterBasedOnQraNumber = 0 or (Convert(int , SUBSTRING(b.QRANumber, 5, 2)) >= @startYear
and Convert(int , SUBSTRING(b.QRANumber, 5, 2)) <= @endYear))
and (p.ID = @productID or @productID = 0)
and (b.TestCenterLocationID  = @geoGraphicalLocation or @geoGraphicalLocation IS NULL)
and p.ID=b.ProductID
order by TrackingLocationName asc
GO
GRANT EXECUTE On remispCountUnitsInLocation TO Remi
GO