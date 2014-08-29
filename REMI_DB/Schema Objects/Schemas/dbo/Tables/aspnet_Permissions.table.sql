CREATE TABLE [dbo].[aspnet_Permissions](
	[PermissionID] [uniqueidentifier] NOT NULL,
	[Permission] [nvarchar](256) NOT NULL,
	[ApplicationId] [uniqueidentifier] NULL,
 CONSTRAINT [PK_aspnet_Permissions] PRIMARY KEY CLUSTERED 
(
	[PermissionID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY],
 CONSTRAINT [Permission] UNIQUE NONCLUSTERED 
(
	[Permission] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[aspnet_Permissions]  WITH CHECK ADD  CONSTRAINT [FK_aspnet_Permissions_aspnet_Applications] FOREIGN KEY([ApplicationId])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[aspnet_Permissions] CHECK CONSTRAINT [FK_aspnet_Permissions_aspnet_Applications]
GO

ALTER TABLE [dbo].[aspnet_Permissions] ADD  CONSTRAINT [DF_aspnet_Permissions_PermissionID]  DEFAULT (newid()) FOR [PermissionID]
GO


