CREATE PROCEDURE [dbo].[remispDeviceTrackingLogSelectLastLogByTestUnitID]
	
	
	/*	=============================================================
	'   NAME:                	remispDeviceTrackingLogSelectLastLogByTestUnitID
	'   DATE CREATED:       	22 May 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves 1 item from table: DeviceTrackingLog with the newest InTime
	'   IN:        TestUnitID         
	'   OUT: 		ID, TrackingLocationId, InTime, OutTime, InUser, OutUser, ConcurrencyID        
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/

	@TestUnitID int
	
	AS

	SELECT  top(1)  DeviceTrackingLog.ID, DeviceTrackingLog.TestUnitID, DeviceTrackingLog.TrackingLocationID, DeviceTrackingLog.InTime, DeviceTrackingLog.OutTime,
	                       DeviceTrackingLog.InUser, DeviceTrackingLog.OutUser, DeviceTrackingLog.ConcurrencyID, TestUnits.BatchUnitNumber,Batches.QRANumber, 
	                       TrackingLocations.TrackingLocationName
	FROM         DeviceTrackingLog INNER JOIN
	                      TestUnits ON DeviceTrackingLog.TestUnitID = TestUnits.ID INNER JOIN
	                      Batches ON TestUnits.BatchID = Batches.ID inner join
	                      TrackingLocations on TrackingLocationID = TrackingLocations.id
	WHERE     (TestUnitID = @TestUnitID)
	order by devicetrackinglog.intime desc
