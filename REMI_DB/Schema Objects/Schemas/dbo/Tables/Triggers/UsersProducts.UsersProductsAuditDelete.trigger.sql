CREATE TRIGGER [dbo].[UsersProductsAuditDelete]
   ON  UsersProducts
    for  delete
AS 
BEGIN
 SET NOCOUNT ON;
 
  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here
	
insert into UsersProductsaudit (ProductID,UserID,Action, UserName)
	Select productID, UserID, 'D', lastuser 
	from deleted

END

GO


