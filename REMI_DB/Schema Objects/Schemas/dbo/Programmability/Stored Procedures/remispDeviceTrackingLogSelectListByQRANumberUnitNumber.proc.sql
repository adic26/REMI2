CREATE PROCEDURE [dbo].[remispDeviceTrackingLogSelectListByQRANumberUnitNumber]
/*	'===============================================================
	'   NAME:                	remispDeviceTrackingLogSelectListByQRANumberUnitNumber
	'   DATE CREATED:       	22 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves paged data from table: DeviceTrackingLog OR the number of records in the table
	'   IN:         QRANumber, UnitNumber Optional: RecordCount         
	'   OUT: 		List Of: ID, TestUnitId, TrackingLocationId, InTime, OutTime, InUser, OutUser, ConcurrencyID              
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/
	@RecordCount int = NULL OUTPUT,
@QRANumber nvarchar(11),
@BatchUnitNumber int

	AS
	declare @TestUnitID int = 0
	SET @TestUnitID = (select tu.ID from TestUnits as tu, batches as b where tu.BatchUnitNumber = @BatchUnitNumber and b.QRANumber = @QRANumber and tu.BatchID = b.ID)
	
	IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (SELECT COUNT(*) FROM DeviceTrackingLog WHERE TestUnitID = @TestUnitID)
		RETURN
	END

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
	FROM DeviceTrackingLog as dtl, TestUnits as tu, TrackingLocations as tl, Batches as b
	WHERE 
		 TestUnitID = @TestUnitID and tl.ID = dtl.TrackingLocationID and b.ID = tu.BatchID and tu.ID = dtl.TestUnitID
		 order by intime desc

