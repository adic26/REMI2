ALTER TRIGGER [dbo].[TrackingLocationsHostsAuditDelete]
   ON  dbo.TrackingLocationsHosts
    for  delete
AS 
BEGIN
 SET NOCOUNT ON;
 
  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here
	
insert into TrackingLocationsHostsaudit (TrackingLocationId, HostName, Action, UserName)
Select TrackingLocationId, HostName, 'D', LastUser from deleted

END