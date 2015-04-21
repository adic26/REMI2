ALTER PROCEDURE [dbo].[remispDeviceTrackingLogSelectListByProductDate] @Lookupid INT, @Date as datetime = '05/22/1983'
AS
	SELECT dtl.ID,
		TestUnitId, 
		TrackingLocationId, 
		InTime, 
		OutTime, 
		InUser, 
		OutUser,
		dtl.ConcurrencyID,
		tu.BatchUnitNumber,
		b.QRANumber, 
		tl.TrackingLocationName
	FROM Batches as b
		INNER JOIN TestUnits tu ON tu.BatchID = b.id
		LEFT OUTER JOIN DeviceTrackingLog as dtl ON dtl.TestUnitID = tu.ID
		LEFT OUTER JOIN TrackingLocations as tl ON tl.ID = dtl.TrackingLocationID
	WHERE b.ProductID = @Lookupid and (dtl.InTime > @Date) 
	order by  dtl.intime desc
GO
GRANT EXECUTE ON remispDeviceTrackingLogSelectListByProductDate TO Remi