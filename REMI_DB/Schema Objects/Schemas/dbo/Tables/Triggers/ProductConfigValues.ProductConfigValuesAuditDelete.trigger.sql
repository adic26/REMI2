alter TRIGGER [dbo].[ProductConfigValuesAuditDelete]
   ON  [dbo].[ProductConfigValues]
    for  delete
AS 
BEGIN
 SET NOCOUNT ON;
 
  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here
	
insert into ProductConfigValuesAudit (ProductConfigValueID, Value, LookupID, ProductGroupID, Action, UserName, IsAttribute)
Select ID, Value, LookupID, ProductConfigID, 'D', LastUser, IsAttribute
from deleted

END