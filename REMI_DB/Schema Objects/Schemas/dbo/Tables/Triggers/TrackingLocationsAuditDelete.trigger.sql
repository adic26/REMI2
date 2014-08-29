-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[TrackingLocationsAuditDelete]
   ON  dbo.TrackingLocations
    for  delete
AS 
BEGIN
 SET NOCOUNT ON;
 
  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here
	
insert into TrackingLocationsaudit (
	TrackingLocationId, 
	TrackingLocationName, 
	TrackingLocationTypeID,
	TestCenterLocationID, 
	--Status,
	Comment,
	--HostName,
	Username,
	Action, IsMultiDeviceZone)
	Select 
	Id, 
	TrackingLocationName, 
	TrackingLocationTypeID,
	TestCenterLocationID, 
	--Status,
	Comment,
	--HostName,
	lastuser,
'D', IsMultiDeviceZone from deleted

END
