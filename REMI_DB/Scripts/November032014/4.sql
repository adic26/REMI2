/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        CI0000001593275.REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 10/29/2014 2:56:56 PM

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
PRINT N'Dropping foreign keys from [Req].[ReqFieldSetup]'
GO
ALTER TABLE [Req].[ReqFieldSetup] DROP CONSTRAINT[FK_ReqFieldSetup_FieldValidationID]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Dropping foreign keys from [Req].[RequestType]'
GO
ALTER TABLE [Req].[RequestType] DROP CONSTRAINT[FK_RequestType_Lookups]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Dropping constraints from [Req].[RequestType]'
GO
ALTER TABLE [Req].[RequestType] DROP CONSTRAINT [DF__RequestTy__HasIn__357DD23F]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Dropping constraints from [Req].[RequestType]'
GO
ALTER TABLE [Req].[RequestType] DROP CONSTRAINT [DF__RequestTy__CanRe__3671F678]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Dropping constraints from [Req].[RequestType]'
GO
ALTER TABLE [Req].[RequestType] DROP CONSTRAINT [DF__RequestTy__HasAp__37661AB1]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Req].[RequestType]'
GO
ALTER TABLE [Req].[RequestType] ALTER COLUMN [HasIntegration] [bit] NOT NULL
ALTER TABLE [Req].[RequestType] ALTER COLUMN [CanReport] [bit] NOT NULL
ALTER TABLE [Req].[RequestType] ALTER COLUMN [HasApproval] [bit] NOT NULL
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Req].[ReqFieldSetup]'
GO
ALTER TABLE [Req].[ReqFieldSetup] ADD
[OptionsTypeID] [int] NULL
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
ALTER TABLE [Req].[ReqFieldSetup] ALTER COLUMN [FieldValidationID] [int] NULL
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [Req].[RequestFieldSetup]'
GO
create PROCEDURE [Req].[RequestFieldSetup] @RequestID INT, @IncludeArchived BIT = 0
AS
BEGIN
	SELECT rfs.ReqFieldSetupID, lrt.[Values] AS RequestType, rfs.Name, lft.[Values] AS FieldType, rfs.FieldTypeID, 
		lvt.[Values] AS ValidationType, rfs.FieldValidationID, ISNULL(rfs.IsRequired, 0) AS IsRequired, rfs.DisplayOrder, 
		ISNULL(rfs.Archived, 0) AS Archived, rfs.Description, rfs.OptionsTypeID, rt.RequestTypeID AS RequestID
	FROM Req.ReqFieldSetup rfs
		INNER JOIN Lookups lft ON lft.LookupID=rfs.FieldTypeID
		LEFT OUTER JOIN Lookups lvt ON lvt.LookupID=rfs.FieldValidationID
		INNER JOIN Req.RequestType rt ON rt.RequestTypeID=rfs.RequestTypeID
		INNER JOIN Lookups lrt ON lrt.LookupID=rt.TypeID
	WHERE rfs.RequestTypeID=@RequestID AND 
		(
			(@IncludeArchived = 1)
			OR
			(@IncludeArchived = 0 AND ISNULL(rfs.Archived, 0) = 0)
		)
	ORDER BY ISNULL(rfs.DisplayOrder, 0) ASC
END
GO
GRANT EXECUTE ON [Req].[RequestFieldSetup] TO REMI
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding constraints to [Req].[RequestType]'
GO
ALTER TABLE [Req].[RequestType] ADD CONSTRAINT [DF__RequestTy__HasIn__272FB2E8] DEFAULT ((0)) FOR [HasIntegration]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
ALTER TABLE [Req].[RequestType] ADD CONSTRAINT [DF__RequestTy__CanRe__2823D721] DEFAULT ((0)) FOR [CanReport]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
ALTER TABLE [Req].[RequestType] ADD CONSTRAINT [DF__RequestTy__HasAp__2917FB5A] DEFAULT ((0)) FOR [HasApproval]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding foreign keys to [Req].[ReqFieldSetup]'
GO
ALTER TABLE [Req].[ReqFieldSetup] ADD CONSTRAINT [FK_ReqFieldSetup_FieldValidationID] FOREIGN KEY ([FieldValidationID]) REFERENCES [dbo].[Lookups] ([LookupID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding foreign keys to [Req].[RequestType]'
GO
ALTER TABLE [Req].[RequestType] ADD CONSTRAINT [FK_RequestType_RequestTypeID] FOREIGN KEY ([RequestTypeID]) REFERENCES [dbo].[Lookups] ([LookupID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering permissions on [Req].[RequestFieldSetup]'
GO
GRANT EXECUTE ON  [Req].[RequestFieldSetup] TO [remi]
GO
exec sp_rename 'Req.ReqFieldSetup.RequestID', 'RequestTypeID', 'COLUMN'
go
exec sp_rename 'Req.RequestType.RequestTypeID', 'TypeID', 'COLUMN'
go
exec sp_rename 'Req.RequestType.ID', 'RequestTypeID', 'COLUMN'
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[Req].[FK_RequestType_RequestTypeID]') AND parent_object_id = OBJECT_ID(N'[Req].[RequestType]'))
ALTER TABLE [Req].[RequestType] DROP CONSTRAINT [FK_RequestType_RequestTypeID]
GO
ALTER TABLE [Req].[RequestType]  WITH CHECK ADD  CONSTRAINT [FK_RequestType_TypeID] FOREIGN KEY([TypeID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO
ALTER TABLE [Req].[RequestType] CHECK CONSTRAINT [FK_RequestType_TypeID]
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