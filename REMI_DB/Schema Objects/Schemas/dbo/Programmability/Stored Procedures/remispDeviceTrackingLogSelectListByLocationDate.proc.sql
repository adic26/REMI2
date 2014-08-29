CREATE PROCEDURE [dbo].[remispDeviceTrackingLogSelectListByLocationDate]
/*	'===============================================================
	'   NAME:                	remispDeviceTrackingLogSelectListByLocationDate
	'   DATE CREATED:       	1 Nov 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves paged data from table: DeviceTrackingLog OR the number of records in the table
	'   IN:         Tracking location id Optional: RecordCount         
	'   OUT: 		List Of: ID, TestUnitId, TrackingLocationId, InTime, OutTime, InUser, OutUser, ConcurrencyID              
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/

	
@TrackingLocationID int,
@Date as datetime
	AS
	SELECT 
		dtl.ID,
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
	FROM DeviceTrackingLog as dtl, Batches as b, TestUnits tu,TrackingLocations as tl
	WHERE 
	tl.id = @TrackingLocationID
	AND tu.BatchID = b.id and dtl.TestUnitID = tu.ID
	and tl.ID = dtl.TrackingLocationID
	and (dtl.InTime > @Date) 
	order by  dtl.intime desc

