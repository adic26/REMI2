/*
Run this script on:

        sql51ykf\ha6.remi    -  This database will be modified

to synchronize it with:

        (local).REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 9/23/2014 8:07:30 AM

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
exec sp_rename 'Req.ReqFieldMapping.ReqTypeID', 'RequestID', 'COLUMN'
GO
alter table Req.RequestType alter column DBType nvarchar(50) NOT NULL
GO
ALTER TABLE Req.RequestType ADD HasIntegration BIT DEFAULT(0) NOT NULL
GO
ALTER TABLE Req.RequestType ADD CanReport BIT DEFAULT(0) NOT NULL
GO
ALTER TABLE Req.RequestType ADD HasApproval BIT DEFAULT(0) NOT NULL
GO
CREATE TABLE [Req].[ReqFieldSetup](
	[ReqFieldSetupID] [int] IDENTITY(1,1) NOT NULL,
	[RequestID] [int] NOT NULL,
	[Name] [nvarchar](150) NOT NULL,
	[Description] [nvarchar](350) NULL,
	[FieldTypeID] [int] NOT NULL,--Dropdown, text, check, radio
	[FieldValidationID] [int] NOT NULL, --This maps to my lookup table and the lookups are defined as Int, double
	[Archived] [bit] NOT NULL,
	[IsRequired] [bit] NOT NULL,
	[DisplayOrder] [int] NOT NULL,
 CONSTRAINT [PK_ReqFieldSetup] PRIMARY KEY CLUSTERED 
(
	[ReqFieldSetupID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [Req].[ReqFieldSetup]  WITH CHECK ADD  CONSTRAINT [FK_ReqFieldSetup_FieldTypeID] FOREIGN KEY([FieldTypeID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO
ALTER TABLE [Req].[ReqFieldSetup] CHECK CONSTRAINT [FK_ReqFieldSetup_FieldTypeID]
GO
ALTER TABLE [Req].[ReqFieldSetup]  WITH CHECK ADD  CONSTRAINT [FK_ReqFieldSetup_FieldValidationID] FOREIGN KEY([FieldValidationID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO
ALTER TABLE [Req].[ReqFieldSetup] CHECK CONSTRAINT [FK_ReqFieldSetup_FieldValidationID]
GO
ALTER TABLE [Req].[ReqFieldSetup]  WITH CHECK ADD  CONSTRAINT [FK_ReqFieldSetup_RequestType] FOREIGN KEY([RequestID])
REFERENCES [Req].[RequestType] ([ID])
GO
ALTER TABLE [Req].[ReqFieldSetup] CHECK CONSTRAINT [FK_ReqFieldSetup_RequestType]
GO
ALTER TABLE [Req].[ReqFieldSetup] ADD  CONSTRAINT [DF_ReqFieldSetup_Archived]  DEFAULT ((0)) FOR [Archived]
GO
ALTER TABLE [Req].[ReqFieldSetup] ADD  CONSTRAINT [DF_ReqFieldSetup_IsRequired]  DEFAULT ((0)) FOR [IsRequired]
GO
CREATE TABLE [Req].[ReqFieldSetupRole](
	[ReqFieldSetupRoleID] [int] IDENTITY(1,1) NOT NULL,
	[ReqFieldSetupID] [int] NOT NULL,
	[RoleID] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_ReqFieldSetupRole] PRIMARY KEY CLUSTERED 
(
	[ReqFieldSetupRoleID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [Req].[ReqFieldSetupRole]  WITH CHECK ADD  CONSTRAINT [FK_ReqFieldSetupRole_aspnet_Roles] FOREIGN KEY([RoleID])
REFERENCES [dbo].[aspnet_Roles] ([RoleId])
GO
ALTER TABLE [Req].[ReqFieldSetupRole] CHECK CONSTRAINT [FK_ReqFieldSetupRole_aspnet_Roles]
GO
ALTER TABLE [Req].[ReqFieldSetupRole]  WITH CHECK ADD  CONSTRAINT [FK_ReqFieldSetupRole_ReqFieldSetup] FOREIGN KEY([ReqFieldSetupID])
REFERENCES [Req].[ReqFieldSetup] ([ReqFieldSetupID])
GO
ALTER TABLE [Req].[ReqFieldSetupRole] CHECK CONSTRAINT [FK_ReqFieldSetupRole_ReqFieldSetup]
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