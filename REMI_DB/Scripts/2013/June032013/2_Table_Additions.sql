/*
Run this script on:

        sqlqa10ykf\haqa1.RemiQA    -  This database will be modified

to synchronize it with:

        CI0000001593275\SQLDEVELOPER.REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.3.8 from Red Gate Software Ltd at 5/27/2013 6:00:38 PM

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
PRINT N'Creating schemata'
GO
CREATE SCHEMA [Relab]
AUTHORIZATION [dbo]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [Relab].[ResultsParameters]'
GO
CREATE TABLE [Relab].[ResultsParameters]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[ResultMeasurementID] [int] NOT NULL,
[ParameterName] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Value] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating primary key [PK_ResultsParameters] on [Relab].[ResultsParameters]'
GO
ALTER TABLE [Relab].[ResultsParameters] ADD CONSTRAINT [PK_ResultsParameters] PRIMARY KEY CLUSTERED  ([ID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [Relab].[ResultsMeasurements]'
GO
CREATE TABLE [Relab].[ResultsMeasurements]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[ResultID] [int] NOT NULL,
[MeasurementTypeID] [int] NOT NULL,
[LowerLimit] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UpperLimit] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MeasurementValue] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[MeasurementUnitTypeID] [int] NULL,
[File] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PassFail] [bit] NOT NULL
)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating primary key [PK_ResultsMeasurements] on [Relab].[ResultsMeasurements]'
GO
ALTER TABLE [Relab].[ResultsMeasurements] ADD CONSTRAINT [PK_ResultsMeasurements] PRIMARY KEY CLUSTERED  ([ID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [Relab].[ResultsHeader]'
GO
CREATE TABLE [Relab].[ResultsHeader]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[ResultID] [int] NOT NULL,
[Name] [nvarchar] (150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Value] [nvarchar] (1500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating primary key [PK_ResultsHeader] on [Relab].[ResultsHeader]'
GO
ALTER TABLE [Relab].[ResultsHeader] ADD CONSTRAINT [PK_ResultsHeader] PRIMARY KEY CLUSTERED  ([ID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [Relab].[Results]'
GO
CREATE TABLE [Relab].[Results]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[TestStageID] [int] NOT NULL,
[TestID] [int] NOT NULL,
[TestUnitID] [int] NOT NULL,
[VerNum] [int] NOT NULL,
[StartDate] [datetime] NULL,
[EndDate] [datetime] NULL,
[ResultsXML] [xml] NOT NULL,
[IsProcessed] [bit] NOT NULL CONSTRAINT [DF__Results__IsProce__7C255952] DEFAULT ((0)),
[PassFail] [bit] NULL
)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating primary key [PK_Results] on [Relab].[Results]'
GO
ALTER TABLE [Relab].[Results] ADD CONSTRAINT [PK_Results] PRIMARY KEY CLUSTERED  ([ID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[UsersProductsAudit]'
GO
CREATE TABLE [dbo].[UsersProductsAudit]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[UserName] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[InsertTime] [datetime] NOT NULL CONSTRAINT [DF_UsersProductsAudit_InsertTime] DEFAULT (getutcdate()),
[Action] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ProductID] [int] NOT NULL,
[UserID] [int] NOT NULL
)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating primary key [PK_UsersProductsAudit] on [dbo].[UsersProductsAudit]'
GO
ALTER TABLE [dbo].[UsersProductsAudit] ADD CONSTRAINT [PK_UsersProductsAudit] PRIMARY KEY CLUSTERED  ([ID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[UsersProducts]'
GO
CREATE TABLE [dbo].[UsersProducts]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[UserID] [int] NOT NULL,
[ProductID] [int] NOT NULL,
[LastUser] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating primary key [PK_UsersProducts] on [dbo].[UsersProducts]'
GO
ALTER TABLE [dbo].[UsersProducts] ADD CONSTRAINT [PK_UsersProducts] PRIMARY KEY CLUSTERED  ([ID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[aspnet_PermissionsInRoles]'
GO
CREATE TABLE [dbo].[aspnet_PermissionsInRoles]
(
[PermissionID] [uniqueidentifier] NOT NULL,
[RoleID] [uniqueidentifier] NOT NULL
)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating primary key [PK_aspnet_PermissionsInRoles] on [dbo].[aspnet_PermissionsInRoles]'
GO
ALTER TABLE [dbo].[aspnet_PermissionsInRoles] ADD CONSTRAINT [PK_aspnet_PermissionsInRoles] PRIMARY KEY CLUSTERED  ([PermissionID], [RoleID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[aspnet_Permissions]'
GO
CREATE TABLE [dbo].[aspnet_Permissions]
(
[PermissionID] [uniqueidentifier] NOT NULL CONSTRAINT [DF_aspnet_Permissions_PermissionID] DEFAULT (newid()),
[Permission] [nvarchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ApplicationId] [uniqueidentifier] NULL
)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating primary key [PK_aspnet_Permissions] on [dbo].[aspnet_Permissions]'
GO
ALTER TABLE [dbo].[aspnet_Permissions] ADD CONSTRAINT [PK_aspnet_Permissions] PRIMARY KEY CLUSTERED  ([PermissionID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [dbo].[TargetAccess]'
GO
CREATE TABLE [dbo].[TargetAccess]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[TargetName] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DenyAccess] [bit] NOT NULL CONSTRAINT [DF_TargetAccess_DenyAccess] DEFAULT ((0))
)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating primary key [PK_TargetAccess] on [dbo].[TargetAccess]'
GO
ALTER TABLE [dbo].[TargetAccess] ADD CONSTRAINT [PK_TargetAccess] PRIMARY KEY CLUSTERED  ([ID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding constraints to [dbo].[aspnet_Permissions]'
GO
ALTER TABLE [dbo].[aspnet_Permissions] ADD CONSTRAINT [Permission] UNIQUE NONCLUSTERED  ([Permission])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding constraints to [dbo].[TargetAccess]'
GO
ALTER TABLE [dbo].[TargetAccess] ADD CONSTRAINT [UX_TargetAccess_TargetName] UNIQUE NONCLUSTERED  ([TargetName])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding foreign keys to [dbo].[aspnet_PermissionsInRoles]'
GO
ALTER TABLE [dbo].[aspnet_PermissionsInRoles] ADD CONSTRAINT [FK_aspnet_PermissionsInRoles_aspnet_Permissions] FOREIGN KEY ([PermissionID]) REFERENCES [dbo].[aspnet_Permissions] ([PermissionID])
ALTER TABLE [dbo].[aspnet_PermissionsInRoles] ADD CONSTRAINT [FK_aspnet_PermissionsInRoles_aspnet_Roles] FOREIGN KEY ([RoleID]) REFERENCES [dbo].[aspnet_Roles] ([RoleId])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding foreign keys to [dbo].[aspnet_Permissions]'
GO
ALTER TABLE [dbo].[aspnet_Permissions] ADD CONSTRAINT [FK_aspnet_Permissions_aspnet_Applications] FOREIGN KEY ([ApplicationId]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding foreign keys to [dbo].[UsersProducts]'
GO
ALTER TABLE [dbo].[UsersProducts] ADD CONSTRAINT [FK_UsersProducts_Users] FOREIGN KEY ([UserID]) REFERENCES [dbo].[Users] ([ID])
ALTER TABLE [dbo].[UsersProducts] ADD CONSTRAINT [FK_UsersProducts_Products] FOREIGN KEY ([ProductID]) REFERENCES [dbo].[Products] ([ID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding foreign keys to [Relab].[ResultsHeader]'
GO
ALTER TABLE [Relab].[ResultsHeader] ADD CONSTRAINT [FK_ResultsHeader_Results] FOREIGN KEY ([ResultID]) REFERENCES [Relab].[Results] ([ID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding foreign keys to [Relab].[Results]'
GO
ALTER TABLE [Relab].[Results] ADD CONSTRAINT [FK_Results_TestStages] FOREIGN KEY ([TestStageID]) REFERENCES [dbo].[TestStages] ([ID])
ALTER TABLE [Relab].[Results] ADD CONSTRAINT [FK_Results_Tests] FOREIGN KEY ([TestID]) REFERENCES [dbo].[Tests] ([ID])
ALTER TABLE [Relab].[Results] ADD CONSTRAINT [FK_Results_TestUnits] FOREIGN KEY ([TestUnitID]) REFERENCES [dbo].[TestUnits] ([ID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding foreign keys to [Relab].[ResultsParameters]'
GO
ALTER TABLE [Relab].[ResultsParameters] ADD CONSTRAINT [FK_ResultsParameters_ResultsMeasurements] FOREIGN KEY ([ResultMeasurementID]) REFERENCES [Relab].[ResultsMeasurements] ([ID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding foreign keys to [Relab].[ResultsMeasurements]'
GO
ALTER TABLE [Relab].[ResultsMeasurements] ADD CONSTRAINT [FK_ResultsMeasurements_Lookups_MeasurementType] FOREIGN KEY ([MeasurementTypeID]) REFERENCES [dbo].[Lookups] ([LookupID])
ALTER TABLE [Relab].[ResultsMeasurements] ADD CONSTRAINT [FK_ResultsMeasurements_Lookups_UnitType] FOREIGN KEY ([MeasurementUnitTypeID]) REFERENCES [dbo].[Lookups] ([LookupID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating trigger [dbo].[UsersProductsAuditDelete] on [dbo].[UsersProducts]'
GO


CREATE TRIGGER [dbo].[UsersProductsAuditDelete]
   ON  [dbo].[UsersProducts]
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
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating trigger [dbo].[UsersProductsAuditInsertUpdate] on [dbo].[UsersProducts]'
GO


CREATE TRIGGER [dbo].[UsersProductsAuditInsertUpdate]
   ON  [dbo].[UsersProducts]
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
	insert into UsersProductsaudit (
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
ALTER TABLE Jobs Add ProcedureLocation nvarchar(400) NULL
GO
alter table JobsAudit Add ProcedureLocation nvarchar(400) NULL
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[JobsAuditInsertUpdate]
   ON  dbo.Jobs
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
	   select JobName, WILocation, Comment, ProcedureLocation from Inserted
	   except
	   select JobName, WILocation, Comment, ProcedureLocation from Deleted
	) a

	if ((@count) >0)
	begin
		insert into jobsaudit (
			JobId, 
			JobName, 
			WILocation, 
			Comment, 
			UserName,
			jobsaudit.Action, ProcedureLocation)
		Select 
			ID, 
			JobName, 
			WILocation, 
			Comment, 
			LastUser,
			@Action, ProcedureLocation from inserted
	END
END
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[JobsAuditDelete]
   ON  dbo.Jobs
    for  delete
AS 
BEGIN
 SET NOCOUNT ON;
 
  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here
	
insert into jobsaudit (
JobId, 
JobName, 
WILocation,
Comment, 
UserName,
Action, ProcedureLocation)
 Select 
 ID, 
JobName,
WILocation,
Comment, 
LastUser,
'D', ProcedureLocation from deleted

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
COMMIT TRANSACTION
END
ELSE PRINT 'The database update failed'
GO
DROP TABLE #tmpErrors
GO