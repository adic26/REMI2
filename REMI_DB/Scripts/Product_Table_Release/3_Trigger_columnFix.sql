/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        ci0000001593275\SQLDeveloper.REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 3/18/2013 10:05:10 AM

*/
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
PRINT N'Dropping index [IX_Batches_BatchStatus] from [dbo].[Batches]'
GO
DROP INDEX [IX_Batches_BatchStatus] ON [dbo].[Batches]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[ProductManagersAudit]'
GO
ALTER TABLE [dbo].[ProductManagersAudit] ALTER COLUMN [_productGroupName] [nvarchar] (800) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[ProductManagers]'
GO
ALTER TABLE [dbo].[ProductManagers] ALTER COLUMN [_productGroup] [nvarchar] (800) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[Batches]'
GO
ALTER TABLE [dbo].[Batches] ALTER COLUMN [_ProductGroupName] [nvarchar] (800) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating index [IX_Batches_BatchStatus] on [dbo].[Batches]'
GO
CREATE NONCLUSTERED INDEX [IX_Batches_BatchStatus] ON [dbo].[Batches] ([BatchStatus]) INCLUDE ([_ProductGroupName], [ID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[TrackingLocationsHosts]'
GO
ALTER TABLE [dbo].[TrackingLocationsHosts] ADD
[ID] [int] NOT NULL IDENTITY(1, 1)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[ProductConfiguration]'
GO
ALTER TABLE [dbo].[ProductConfiguration] ALTER COLUMN [_ProductGroupName] [nvarchar] (150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[ProductConfigurationAudit]'
GO
ALTER TABLE [dbo].[ProductConfigurationAudit] ALTER COLUMN [_ProductGroupName] [nvarchar] (150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[BatchesAudit]'
GO
ALTER TABLE [dbo].[BatchesAudit] ALTER COLUMN [_ProductGroupName] [nvarchar] (800) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[ProductSettings]'
GO
ALTER TABLE [dbo].[ProductSettings] ALTER COLUMN [_ProductGroupName] [nvarchar] (800) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[ProductSettingsAudit]'
GO
ALTER TABLE [dbo].[ProductSettingsAudit] ALTER COLUMN [_ProductGroupName] [nvarchar] (800) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering trigger [dbo].[BatchesAuditDelete] on [dbo].[Batches]'
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[BatchesAuditDelete]
   ON  [dbo].[Batches]
    for  delete
AS 
BEGIN
 SET NOCOUNT ON;
 
	Declare @Insert Bit
	Declare @Delete Bit
	Declare @Action char(1)

  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here
	
insert into batchesaudit (
BatchId, 
QRAnumber, 
Priority, 
BatchStatus, 
JobName, 
--ProductGroupName,
ProductType,
AccessoryGroupName,
TeststageName, 
Comment, 
TestCenterLocation,
RequestPurpose,
TestStagecompletionStatus,
UserName,
RFBands,
productid,
Action)
 Select 
 ID, 
 QRAnumber, 
 Priority, 
BatchStatus, 
JobName,  
--ProductGroupName,
ProductType,
AccessoryGroupName,
TeststageName, 
Comment, 
TestCenterLocation,
RequestPurpose,
TestStagecompletionStatus,
LastUser,
RFBands,productid,
'D' from deleted

END

GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering trigger [dbo].[BatchesAuditInsertUpdate] on [dbo].[Batches]'
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[BatchesAuditInsertUpdate]
   ON  [dbo].[Batches]
    after insert,update
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
	   select QRAnumber, Priority, BatchStatus, JobName, ProductType, AccessoryGroupName, TeststageName, TestCenterLocation, RequestPurpose, TestStagecompletionStatus, Comment, RFBands, ProductID from Inserted
	   except
	   select QRAnumber, Priority, BatchStatus, JobName, ProductType, AccessoryGroupName, TeststageName, TestCenterLocation, RequestPurpose, TestStagecompletionStatus, Comment, RFBands, ProductID from Deleted
	) a

	if ((@count) >0)
	begin
		insert into batchesaudit (
			BatchId, 
			QRAnumber, 
			Priority, 
			BatchStatus, 
			JobName, 
			ProductType,
			AccessoryGroupName,
			TeststageName, 
			TestCenterLocation,
			RequestPurpose,
			TestStagecompletionStatus,
			Comment, 
			UserName,
			RFBands,
			ProductID,
			batchesaudit.Action)
		Select 
			ID, 
			QRAnumber, 
			Priority, 
			BatchStatus, 
			JobName,  
			ProductType,
			AccessoryGroupName,
			TeststageName, 
			TestCenterLocation,
			RequestPurpose,
			TestStagecompletionStatus,
			Comment, 
			LastUser,
			RFBands,
			productID,
			@Action from inserted
	END
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering trigger [dbo].[ProductConfigurationAuditDelete] on [dbo].[ProductConfiguration]'
GO
ALTER TRIGGER [dbo].[ProductConfigurationAuditDelete]
   ON  [dbo].[ProductConfiguration]
    for  delete
AS 
BEGIN
 SET NOCOUNT ON;
 
  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here
	
insert into ProductConfigurationAudit (ProductConfigID, ParentID, ViewOrder, NodeName, TestID, ProductID, Action, UserName)
Select ID, ParentID, ViewOrder, NodeName, TestID, ProductID, 'D', LastUser
from deleted

END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering trigger [dbo].[ProductConfigurationAuditInsertUpdate] on [dbo].[ProductConfiguration]'
GO
ALTER TRIGGER [dbo].[ProductConfigurationAuditInsertUpdate]
   ON  [dbo].[ProductConfiguration]
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
   select ParentID, ViewOrder, NodeName, TestID, ProductID from Inserted
   except
   select ParentID, ViewOrder, NodeName, TestID, ProductID from Deleted
) a

if ((@count) >0)
begin
	insert into ProductConfigurationAudit (productConfigID, ParentID, ViewOrder, NodeName, TestID, ProductID, Action, UserName)
	Select ID, ParentID, ViewOrder, NodeName, TestID, ProductID, @action, LastUser
	from inserted
END
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering trigger [dbo].[ProductManagersAuditDelete] on [dbo].[ProductManagers]'
GO
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
	UserName,
	Action)
	Select 
	productID,
	UserName,
	lastuser,
'D' from deleted

END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering trigger [dbo].[ProductManagersAuditInsertUpdate] on [dbo].[ProductManagers]'
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
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
   select ProductID, UserName from Inserted
   except
   select ProductID, UserName from Deleted
) a

if ((@count) >0)
begin
	insert into ProductManagersaudit (
		ProductID,
		ProductManagerName,
		UserName,
		Action)
		Select 
		ProductID,
		UserName,
		lastuser,
	@action from inserted
END
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering trigger [dbo].[ProductSettingsAuditDelete] on [dbo].[ProductSettings]'
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[ProductSettingsAuditDelete]
   ON  [dbo].[ProductSettings]
    for  delete
AS 
BEGIN
 SET NOCOUNT ON;
 
  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here
	
insert into ProductSettingsAudit (
	ProductSettingsId, 
	ProductID,
	KeyName, 
	ValueText,	
	DefaultValue,
	Action)
	Select 
	Id, 
	ProductID,
	KeyName, 
	ValueText,
	DefaultValue,
'D' from deleted

END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering trigger [dbo].[ProductSettingsAuditInsertUpdate] on [dbo].[ProductSettings]'
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[ProductSettingsAuditInsertUpdate]
   ON  [dbo].[ProductSettings]
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
   select ProductID, KeyName, ValueText, DefaultValue from Inserted
   except
   select ProductID, KeyName, ValueText, DefaultValue from Deleted
) a

if ((@count) >0)
begin
	insert into ProductSettingsAudit (
			ProductSettingsId, 
		ProductID,
		KeyName, 
		ValueText,
		DefaultValue,	
		Action)
		Select 
		Id, 
		ProductID,
		KeyName, 
		DefaultValue,
		ValueText,	
	@action from inserted
END
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
IF EXISTS (SELECT * FROM #tmpErrors) ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT>0 BEGIN
PRINT 'The database update succeeded'
commit TRANSACTION
END
ELSE PRINT 'The database update failed'
GO
DROP TABLE #tmpErrors
GO
