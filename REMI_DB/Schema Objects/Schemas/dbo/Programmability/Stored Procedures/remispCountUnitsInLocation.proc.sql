ALTER procedure remispCountUnitsInLocation @startDate datetime, @endDate datetime, @geoGraphicalLocation int, @FilterBasedOnQraNumber bit, @LookupID INT
AS
BEGIN
	DECLARE @startYear int = Right(year( @StartDate), 2);
	DECLARE @endYear int = Right(year( @EndDate), 2);

	IF @geoGraphicalLocation = 0
		SET @geoGraphicalLocation = NULL

	SELECT tl.TrackingLocationName, count(tu.id) as CountedUnits 
	FROM TestUnits tu WITH(NOLOCK), trackinglocations tl WITH(NOLOCK), DeviceTrackingLog dtl WITH(NOLOCK), Batches b WITH(NOLOCK)
	WHERE tu.ID = dtl.TestUnitID AND dtl.TrackingLocationID = tl.ID AND dtl.OutUser IS NULL AND tu.BatchID = b.id
		AND dtl.InTime > @StartDate AND dtl.InTime < @EndDate 
		AND (@FilterBasedOnQraNumber = 0 OR (Convert(int , SUBSTRING(b.QRANumber, 5, 2)) >= @startYear
		AND Convert(int , SUBSTRING(b.QRANumber, 5, 2)) <= @endYear))
		AND (b.ProductID = @LookupID OR @LookupID = 0)
		AND (b.TestCenterLocationID = @geoGraphicalLocation OR @geoGraphicalLocation IS NULL) 
	GROUP BY TrackingLocationName 
	UNION ALL
	SELECT 'Total', count(tu.id) AS CountedUnits 
	FROM TestUnits tu, trackinglocations tl, DeviceTrackingLog dtl, Batches b
	WHERE tu.ID = dtl.TestUnitID AND dtl.TrackingLocationID = tl.ID AND dtl.OutUser IS NULL AND tu.BatchID = b.id
		AND dtl.InTime > @StartDate AND dtl.InTime < @EndDate 
		AND (@FilterBasedOnQraNumber = 0 or (Convert(int , SUBSTRING(b.QRANumber, 5, 2)) >= @startYear
		AND Convert(INT, SUBSTRING(b.QRANumber, 5, 2)) <= @endYear))
		AND (b.ProductID = @LookupID or @LookupID = 0)
		AND (b.TestCenterLocationID  = @geoGraphicalLocation OR @geoGraphicalLocation IS NULL)
	order by TrackingLocationName ASC
END
GO
GRANT EXECUTE On remispCountUnitsInLocation TO Remi
GO