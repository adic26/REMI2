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
