CREATE TRIGGER [dbo].[TrackingLocationsHostsConfigurationAuditDelete]
   ON  [dbo].[TrackingLocationsHostsConfiguration]
    for  delete
AS 
BEGIN
 SET NOCOUNT ON;
 
  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here
	
insert into TrackingLocationsHostsConfigurationaudit (TrackingConfigID, TrackingLocationHostID, ParentID, ViewOrder, NodeName, UserName, Action)
Select ID, TrackingLocationHostID, ParentID, ViewOrder, NodeName, LastUser, 'D' from deleted

END

GO