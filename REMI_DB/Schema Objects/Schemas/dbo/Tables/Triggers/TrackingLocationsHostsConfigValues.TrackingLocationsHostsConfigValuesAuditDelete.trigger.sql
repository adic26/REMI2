CREATE TRIGGER [dbo].[TrackingLocationsHostsConfigValuesAuditDelete]
   ON  [dbo].[TrackingLocationsHostsConfigValues]
    for  delete
AS 
BEGIN
 SET NOCOUNT ON;
 
  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here
	
insert into TrackingLocationsHostsConfigValuesAudit (HostConfigID, Value, LookupID, TrackingConfigID, LastUser, IsAttribute, Action)
Select ID, Value, LookupID, TrackingConfigID, LastUser, IsAttribute, 'D' from deleted

END


GO