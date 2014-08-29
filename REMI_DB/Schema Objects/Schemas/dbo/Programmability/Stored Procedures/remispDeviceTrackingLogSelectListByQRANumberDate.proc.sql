CREATE PROCEDURE [dbo].[remispDeviceTrackingLogSelectListByQRANumberDate]
/*	'===============================================================
	'   NAME:                	remispDeviceTrackingLogSelectListByQRANumberDate
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

	
@QRANumber nvarchar(11) = null,
@Date as datetime = '05/22/1983'
	AS
	declare @batchID int
	set @batchID = (select ID from Batches as b where QRANumber = @QRANumber)
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
	 ( dtl.TestUnitID = tu.ID 
	 and tu.BatchID = @batchid 
	 and b.ID = @BatchID
	 and dtl.TrackingLocationID = tl.id)
and (dtl.InTime > @Date) 

	order by  dtl.intime desc
