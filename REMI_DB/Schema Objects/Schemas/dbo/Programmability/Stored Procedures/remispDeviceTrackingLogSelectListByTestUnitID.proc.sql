CREATE PROCEDURE [dbo].[remispDeviceTrackingLogSelectListByTestUnitID]
/*	'===============================================================
	'   NAME:                	remispDeviceTrackingLogSelectListByTestUnitID
	'   DATE CREATED:       	22 April 2009
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

	@StartRowIndex int = -1,
	@MaximumRows int = -1,
	@RecordCount int = NULL OUTPUT,
@TestUnitID int
	AS

	IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (SELECT COUNT(*) FROM DeviceTrackingLog WHERE TestUnitID = @TestUnitID)
		RETURN
	END

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
	FROM DeviceTrackingLog as dtl, Batches as b, TestUnits as tu, TrackingLocations as tl
	where dtl.TestUnitID = tu.ID and b.ID = tu.BatchID and tl.ID = dtl.TrackingLocationID) AS DeviceTrackingLogRows
	WHERE 
		((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) 
			OR @startRowIndex = -1 OR @maximumRows = -1) AND TestUnitID = @TestUnitID 	
			order by InTime desc
			--order by case when OutTime is null then 0 else 1 end desc ,outtime, intime

