SET NUMERIC_ROUNDABORT OFF
GO
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#tmpErrors')) DROP TABLE #tmpErrors
GO
CREATE TABLE #tmpErrors (Error int)
GO
SET XACT_ABORT ON
GO
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO
BEGIN TRANSACTION
GO
exec sp_RENAME 'ProductManagers', '_ProductManagers'
GO
exec sp_RENAME 'ProductManagersAudit', '_ProductManagersAudit'
GO
PRINT N'Altering [dbo].[aspnet_Roles]'
GO
ALTER TABLE [dbo].[aspnet_Roles] ADD
[hasProductCheck] [bit] NULL
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[Users]'
GO
ALTER TABLE [dbo].[Users] ADD
[ByPassProduct] [int] NULL
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[UsersAudit]'
GO
ALTER TABLE [dbo].[UsersAudit] ADD
[ByPassProduct] [int] NULL
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering trigger [dbo].[UsersAuditDelete] on [dbo].[Users]'
GO
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
	
insert into Usersaudit (
	UserId, 
	LDAPLogin, 
	BadgeNumber,
	TestCentreID,
	Username,	
	Action,
	IsActive, DefaultPage, ByPassProduct)
	Select 
	Id, 
	LDAPLogin, 
	BadgeNumber,
	TestCentreID,
	lastuser,
	'D',
	IsActive, DefaultPage, ByPassProduct
	from deleted
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering trigger [dbo].[UsersAuditInsertUpdate] on [dbo].[Users]'
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
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
   select LDAPLogin, BadgeNumber, TestCentreID, IsActive, DefaultPage, ByPassProduct from Inserted
   except
   select LDAPLogin, BadgeNumber, TestCentreID, IsActive, DefaultPage, ByPassProduct from Deleted
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
		IsActive, DefaultPage, ByPassProduct)
		Select 
		Id, 
		LDAPLogin, 
		BadgeNumber,
		TestCentreID,
		lastuser,
		@action, 
		IsActive, DefaultPage, ByPassProduct
		from inserted
	END
END
GO
alter table usertraining drop column _UserName
GO
alter table usertraining add LevelLookupID INT NULL
GO
ALTER TABLE [dbo].[UserTraining] ADD CONSTRAINT [FK_UserTraining_LookupsLevel] FOREIGN KEY ([LevelLookupID]) REFERENCES [dbo].[Lookups] ([LookupID])
GO
alter PROCEDURE [dbo].[remispGetUserTraining] @UserID INT
AS
BEGIN
	SELECT UserTraining.ID, UserID, DateAdded, Lookups.LookupID, Lookups.[Values] AS TrainingOption, 
		CASE WHEN ID IS NOT NULL THEN CONVERT(BIT,1) ELSE CONVERT(BIT, 0) END AS IsTrained,
		ll.[Values] As Level, UserTraining.LevelLookupID
	FROM Lookups
		LEFT OUTER JOIN UserTraining ON UserTraining.LookupID=Lookups.LookupID AND UserTraining.UserID=@UserID
		LEFT OUTER JOIN Lookups ll ON ll.LookupID=UserTraining.LevelLookupID AND ll.Type='Level'
	WHERE Lookups.Type='Training'
	ORDER BY Lookups.[Values]
END
GO
GRANT EXECUTE ON  [dbo].[remispGetUserTraining] TO [remi]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
IF EXISTS (SELECT * FROM #tmpErrors) ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT>0 BEGIN
PRINT 'The database update succeeded'
ROLLBACK TRANSACTION
END
ELSE PRINT 'The database update failed'
GO
DROP TABLE #tmpErrors
GO