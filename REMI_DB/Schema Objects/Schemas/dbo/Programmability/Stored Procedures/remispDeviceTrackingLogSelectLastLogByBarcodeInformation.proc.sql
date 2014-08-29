CREATE PROCEDURE [dbo].[remispDeviceTrackingLogSelectLastLogByBarcodeInformation]
	
	
	/*	=============================================================
	'   NAME:                	remispDeviceTrackingLogSelectLastLogByBarcodeInformation
	'   DATE CREATED:       	22 May 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves 1 item from table: DeviceTrackingLog with the newest InTime
	'   IN:        QRANumber, BatchUnitNumber          
	'   OUT: 		ID, TrackingLocationId, InTime, OutTime, InUser, OutUser, ConcurrencyID        
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/

	@QRANumber nvarchar(11),
	@BatchUnitNumber int

	AS

	SELECT  top(1)  DeviceTrackingLog.ID, DeviceTrackingLog.TestUnitID, DeviceTrackingLog.TrackingLocationID, DeviceTrackingLog.InTime, DeviceTrackingLog.OutTime,
	                       DeviceTrackingLog.InUser, DeviceTrackingLog.OutUser, DeviceTrackingLog.ConcurrencyID, TestUnits.BatchUnitNumber,Batches.QRANumber, TrackingLocations.TrackingLocationName
	FROM         DeviceTrackingLog INNER JOIN
	                      TestUnits ON DeviceTrackingLog.TestUnitID = TestUnits.ID INNER JOIN
	                      Batches ON TestUnits.BatchID = Batches.ID inner join
	                      TrackingLocations on TrackingLocationID = TrackingLocations.id
	WHERE     (Batches.QRANumber = @QRANumber) AND (TestUnits.BatchUnitNumber = @batchunitnumber)
		order by intime desc

