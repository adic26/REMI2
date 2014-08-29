CREATE PROCEDURE [dbo].[remispDeviceTrackingLogSelectListByTestRecordID]
/*	'===============================================================
	'   NAME:                	remispDeviceTrackingLogSelectListByTestRecordID
	'   DATE CREATED:       	22 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves paged data from table: DeviceTrackingLog OR the number of records in the table
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/


	@TestRecordID int
	AS

		SELECT 
		ID,
		TestUnitId, 
		TrackingLocationId, 
		InTime, 
		OutTime, 
		InUser, 
		OutUser,
		ConcurrencyID ,
		BatchUnitNumber,
		QRANumber, 
	    TrackingLocationName       
	FROM     
		(SELECT ROW_NUMBER() OVER (ORDER BY dtl.ID) AS Row, 
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
	FROM DeviceTrackingLog as dtl, Batches as b, TestUnits as tu, TrackingLocations as tl, TestRecordsXTrackingLogs as trxtl
	where dtl.TestUnitID = tu.ID 
	and b.ID = tu.BatchID 
	and tl.ID = dtl.TrackingLocationID 
	and trxtl.TestRecordID = @TestRecordID 
	and trxtl.TrackingLogID = dtl.id) AS DeviceTrackingLogRows
	
			order by InTime desc


