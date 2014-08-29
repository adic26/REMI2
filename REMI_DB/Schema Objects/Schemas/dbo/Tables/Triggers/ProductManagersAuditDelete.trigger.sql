-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[ProductManagersAuditDelete]
   ON  [dbo].[ProductManagers]
    for  delete
AS 
BEGIN
 SET NOCOUNT ON;
 
  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here
	
insert into ProductManagersaudit (
	ProductID,
	ProductManagerName,
	UserID,
	Action)
	Select 
	productID,
	UserID,
	lastuser,
'D' from deleted

END
