CREATE PROCEDURE [dbo].[remispDeviceTrackingLogSelectSingleItem]
/*	'===============================================================
	'   NAME:                	remispDeviceTrackingLogSelectSingleItem
	'   DATE CREATED:       	2 Nov 2009
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

@ID int
	AS

	SELECT 
		dtl.ID,
		TestUnitId, 
		TrackingLocationId, 
		InTime, 
		OutTime, 
		InUser, 
		OutUser,
		dtl.ConcurrencyID ,
		BatchUnitNumber,
		QRANumber, 
	    TrackingLocationName       

	FROM DeviceTrackingLog as dtl, Batches as b, TestUnits as tu, TrackingLocations as tl
	where dtl.TestUnitID = tu.ID and b.ID = tu.BatchID and tl.ID = dtl.TrackingLocationID and dtl.ID = @id
