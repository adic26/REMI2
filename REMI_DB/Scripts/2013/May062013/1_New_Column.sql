BEGIN TRAN

exec sp_rename 'ProductManagers.UserName', '_UserName', 'COLUMN'
GO
ALTER TABLE ProductManagers ADD UserID INT NULL
GO
exec sp_rename 'ProductManagersAudit.ProductManagerName', '_ProductManagerName', 'COLUMN'
GO
exec sp_rename 'Users.TestCentre', '_TestCentre', 'COLUMN'
GO
exec sp_rename 'UsersAudit.TestCentre', '_TestCentre', 'COLUMN'
GO
GO
ALTER TABLE Users ADD TestCentreID INT NULL
GO
ALTER TABLE UsersAudit ADD TestCentreID INT NULL
GO
ALTER TABLE ProductManagersAudit ADD UserID INT NULL
GO
exec sp_rename 'UserTraining.UserName', '_UserName', 'COLUMN'
GO
ALTER TABLE UserTraining ADD UserID INT NULL
GO
ALTER TABLE [dbo].[ProductManagers] ADD CONSTRAINT [FK_ProductManagers_Users] FOREIGN KEY ([UserID]) REFERENCES [dbo].[Users] ([ID])
GO
ALTER TABLE [dbo].[UserTraining] ADD CONSTRAINT [FK_UserTraining_Users] FOREIGN KEY ([UserID]) REFERENCES [dbo].[Users] ([ID])
GO
ALTER TRIGGER [dbo].[ProductManagersAuditDelete]
   ON  [dbo].[ProductManagers]
    for  delete
AS 
BEGIN
 SET NOCOUNT ON;
 
  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here
	
insert into ProductManagersaudit (ProductID,UserID,Action, UserName)
	Select productID, UserID, 'D', lastuser 
	from deleted

END
GO

ALTER TRIGGER [dbo].[ProductManagersAuditInsertUpdate]
   ON  [dbo].[ProductManagers]
    after insert, update
AS 
BEGIN
SET NOCOUNT ON;
 
Declare @action char(1)
DECLARE @count INT
  
--check if this is an insert or an update

If Exists(Select * From Inserted) and Exists(Select * From Deleted) --Update, both tables referenced
begin
	Set @action= 'U'
end
else
begin
	If Exists(Select * From Inserted) --insert, only one table referenced
	Begin
		Set @action= 'I'
	end
	if not Exists(Select * From Inserted) and not Exists(Select * From Deleted)--nothing changed, get out of here
	Begin
		RETURN
	end
end

select @count= count(*) from
(
   select ProductID, UserID from Inserted
   except
   select ProductID, UserID from Deleted
) a

if ((@count) >0)
begin
	insert into ProductManagersaudit (
		ProductID,
		UserID,
		UserName,
		Action)
		Select 
		ProductID,
		UserID,
		lastuser,
	@action from inserted
END
END
GO

ALTER TRIGGER [dbo].[UsersAuditDelete]
   ON  [dbo].[Users]
    for  delete
AS 
BEGIN
 SET NOCOUNT ON;
 
  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here
	
insert into Usersaudit (
	UserId, 
	LDAPLogin, 
	BadgeNumber,
	TestCentreID,
	Username,	
	Action,
	IsActive, DefaultPage)
	Select 
	Id, 
	LDAPLogin, 
	BadgeNumber,
	TestCentreID,
	lastuser,
	'D',
	IsActive, DefaultPage
	from deleted
END
GO

ALTER TRIGGER [dbo].[UsersAuditInsertUpdate]
   ON  [dbo].[Users]
    after insert, update
AS 
BEGIN
SET NOCOUNT ON;
Declare @action char(1)
DECLARE @count INT
  
--check if this is an insert or an update

If Exists(Select * From Inserted) and Exists(Select * From Deleted) --Update, both tables referenced
	begin
		Set @action= 'U'
	end
else
	begin
		If Exists(Select * From Inserted) --insert, only one table referenced
		Begin
			Set @action= 'I'
		end
		if not Exists(Select * From Inserted) and not Exists(Select * From Deleted)--nothing changed, get out of here
		Begin
			RETURN
		end
	end

--Only inserts records into the Audit table if the row was either updated or inserted and values actually changed.
select @count= count(*) from
(
   select LDAPLogin, BadgeNumber, TestCentreID, IsActive, DefaultPage from Inserted
   except
   select LDAPLogin, BadgeNumber, TestCentreID, IsActive, DefaultPage from Deleted
) a

if ((@count) >0)
	begin
		insert into Usersaudit (
		UserId, 
		LDAPLogin, 
		BadgeNumber,
		TestCentreID,
		Username,
		Action,
		IsActive, DefaultPage)
		Select 
		Id, 
		LDAPLogin, 
		BadgeNumber,
		TestCentreID,
		lastuser,
		@action, 
		IsActive, DefaultPage
		from inserted
	END
END

ROLLBACK TRAN