-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[UsersAuditDelete]
   ON  [dbo].[Users]
    for  delete
AS 
BEGIN
 SET NOCOUNT ON;
 
  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here
	
insert into Usersaudit (UserId, LDAPLogin, BadgeNumber,Username,Action,IsActive, DefaultPage, ByPassProduct)
Select Id, LDAPLogin, BadgeNumber,lastuser,'D',IsActive, DefaultPage, ByPassProduct
from deleted
END
GO