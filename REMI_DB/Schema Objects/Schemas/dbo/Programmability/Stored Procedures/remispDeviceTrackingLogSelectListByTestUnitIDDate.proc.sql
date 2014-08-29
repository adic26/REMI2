CREATE PROCEDURE [dbo].[remispDeviceTrackingLogSelectListByTestUnitIDDate]
/*	'===============================================================
	'   NAME:                	remispDeviceTrackingLogSelectListByTestUnitIDDate
	'   DATE CREATED:       	13 Apr 2010
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves paged data from table: DeviceTrackingLog OR the number of records in the table
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/

	
@TestUnitID int,
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
	FROM DeviceTrackingLog as dtl,  TestUnits as tu, Batches as b, TrackingLocations as tl
	WHERE 
	 ( dtl.TestUnitID = @TestUnitID
	 and tu.ID = dtl.TestUnitID
	 and b.ID = tu.batchid
	 and dtl.TrackingLocationID = tl.id)
and (dtl.intime > @Date) 

	order by  dtl.intime desc
