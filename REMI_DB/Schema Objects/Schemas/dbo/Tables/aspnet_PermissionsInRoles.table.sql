CREATE TABLE [dbo].[aspnet_PermissionsInRoles](
	[PermissionID] [uniqueidentifier] NOT NULL,
	[RoleID] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_aspnet_PermissionsInRoles] PRIMARY KEY CLUSTERED 
(
	[PermissionID] ASC,
	[RoleID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[aspnet_PermissionsInRoles]  WITH CHECK ADD  CONSTRAINT [FK_aspnet_PermissionsInRoles_aspnet_Permissions] FOREIGN KEY([PermissionID])
REFERENCES [dbo].[aspnet_Permissions] ([PermissionID])
GO

ALTER TABLE [dbo].[aspnet_PermissionsInRoles] CHECK CONSTRAINT [FK_aspnet_PermissionsInRoles_aspnet_Permissions]
GO

ALTER TABLE [dbo].[aspnet_PermissionsInRoles]  WITH CHECK ADD  CONSTRAINT [FK_aspnet_PermissionsInRoles_aspnet_Roles] FOREIGN KEY([RoleID])
REFERENCES [dbo].[aspnet_Roles] ([RoleId])
GO

ALTER TABLE [dbo].[aspnet_PermissionsInRoles] CHECK CONSTRAINT [FK_aspnet_PermissionsInRoles_aspnet_Roles]
GO
