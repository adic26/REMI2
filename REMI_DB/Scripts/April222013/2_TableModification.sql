/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        ci0000001593275\SQLDeveloper.REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 4/17/2013 11:28:47 AM

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
PRINT N'Dropping index [IX_BatchesAudit_IT_BID_BS] from [dbo].[BatchesAudit]'
GO
DROP INDEX [IX_BatchesAudit_IT_BID_BS] ON [dbo].[BatchesAudit]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[ProductManagersAudit]'
GO
ALTER TABLE [dbo].[ProductManagersAudit] DROP
COLUMN [_productGroupName]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[ProductManagers]'
GO
ALTER TABLE [dbo].[ProductManagers] DROP
COLUMN [_productGroup]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[TrackingLocations]'
GO
ALTER TABLE [dbo].[TrackingLocations] DROP
COLUMN [_GeoLocationName],
COLUMN [_Status],
COLUMN [_HostName]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[Batches]'
GO
ALTER TABLE [dbo].[Batches] DROP
COLUMN [_ProductGroupName],
COLUMN [_TestCenterLocation],
COLUMN [_ProductType],
COLUMN [_AccessoryGroupName]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[ProductConfiguration]'
GO
ALTER TABLE [dbo].[ProductConfiguration] DROP
COLUMN [_productGroupName]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[ProductConfigurationAudit]'
GO
ALTER TABLE [dbo].[ProductConfigurationAudit] DROP
COLUMN [_productGroupName]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[ProductSettings]'
GO
ALTER TABLE [dbo].[ProductSettings] DROP
COLUMN [_productGroupName]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[BatchesAudit]'
GO
ALTER TABLE [dbo].[BatchesAudit] DROP
COLUMN [_ProductGroupName],
COLUMN [_TestCenterLocation],
COLUMN [_ProductType],
COLUMN [_AccessoryGroupName]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating index [IX_BatchesAudit_IT_BID_BS] on [dbo].[BatchesAudit]'
GO
CREATE NONCLUSTERED INDEX [IX_BatchesAudit_IT_BID_BS] ON [dbo].[BatchesAudit] ([InsertTime], [BatchID], [BatchStatus]) INCLUDE ([ProductTypeID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[ProductSettingsAudit]'
GO
ALTER TABLE [dbo].[ProductSettingsAudit] DROP
COLUMN [_productGroupName]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[TrackingLocationsAudit]'
GO
ALTER TABLE [dbo].[TrackingLocationsAudit] DROP
COLUMN [_GeoLocationName],
COLUMN [_Status],
COLUMN [_HostName]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering trigger [dbo].[TrackingLocationsHostsConfigurationAuditInsertUpdate] on [dbo].[TrackingLocationsHostsConfiguration]'
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[TrackingLocationsHostsConfigurationAuditInsertUpdate]
   ON  [dbo].[TrackingLocationsHostsConfiguration]
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
   select TrackingLocationHostID, ParentID, ViewOrder, NodeName from Inserted
   except
   select TrackingLocationHostID, ParentID, ViewOrder, NodeName from Deleted
) a


if ((@count) >0)
begin
	insert into TrackingLocationsHostsConfigurationAudit (TrackingConfigID, TrackingLocationHostID, ParentID, ViewOrder, NodeName, UserName, Action)
	Select ID, TrackingLocationHostID, ParentID, ViewOrder, NodeName, LastUser, @action from inserted
end

END

GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering trigger [dbo].[TrackingLocationsHostsConfigValuesAuditInsertUpdate] on [dbo].[TrackingLocationsHostsConfigValues]'
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[TrackingLocationsHostsConfigValuesAuditInsertUpdate]
   ON  [dbo].[TrackingLocationsHostsConfigValues]
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
   select Value, LookupID, TrackingConfigID, IsAttribute from Inserted
   except
   select Value, LookupID, TrackingConfigID, IsAttribute from Deleted
) a

if ((@count) >0)
begin
	insert into TrackingLocationsHostsConfigValuesAudit (HostConfigID, Value, LookupID, TrackingConfigID, LastUser, IsAttribute, Action)
	select ID, Value, LookupID, TrackingConfigID, LastUser, IsAttribute, @action from inserted
end

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
rollback TRANSACTION
END
ELSE PRINT 'The database update failed'
GO
DROP TABLE #tmpErrors
GO