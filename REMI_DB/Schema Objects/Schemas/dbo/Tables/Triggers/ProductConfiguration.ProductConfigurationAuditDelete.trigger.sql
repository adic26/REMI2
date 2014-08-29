alter TRIGGER [dbo].[ProductConfigurationAuditDelete]
   ON  [dbo].[ProductConfiguration]
    for  delete
AS 
BEGIN
 SET NOCOUNT ON;
 
  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here
	
insert into ProductConfigurationAudit (ProductConfigID, ParentID, ViewOrder, NodeName, UploadID, Action, UserName)
Select ID, ParentID, ViewOrder, NodeName, UploadID, 'D', LastUser
from deleted

END