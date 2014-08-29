ALTER PROCEDURE [dbo].[remispDeviceTrackingLogSelectListByProductDate]
/*	'===============================================================
	'   NAME:                	remispDeviceTrackingLogSelectListByProductDate
	'   DATE CREATED:       	1 Nov 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves paged data from table: DeviceTrackingLog OR the number of records in the table
	'   IN:         TestUnitID Optional: RecordCount         
	'   OUT: 		List Of: ID, TestUnitId, TrackingLocationId, InTime, OutTime, InUser, OutUser, ConcurrencyID              
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/
	@ProductID INT, @Date as datetime = '05/22/1983'
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
	WHERE b.ProductID = @ProductID and (dtl.InTime > @Date) 
	order by  dtl.intime desc
GO
GRANT EXECUTE ON remispDeviceTrackingLogSelectListByProductDate TO Remi