CREATE TABLE [dbo].[UserDetails](
	[UserDetailsID] [int] IDENTITY(1,1) NOT NULL,
	[UserID] [int] NOT NULL,
	[LookupID] [int] NOT NULL,
	[IsDefault] [bit] NULL,
	[IsAdmin] [bit] NULL,
	[IsProductManager] [bit] NULL,
	[LastUser] [nvarchar](255) NULL,
	IsTSDContact BIT DEFAULT(0) NULL,
 CONSTRAINT [PK_UserDetails] PRIMARY KEY CLUSTERED 
(
	[UserDetailsID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[UserDetails]  WITH CHECK ADD  CONSTRAINT [FK_UserDetails_Lookups] FOREIGN KEY([LookupID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO

ALTER TABLE [dbo].[UserDetails] CHECK CONSTRAINT [FK_UserDetails_Lookups]
GO

ALTER TABLE [dbo].[UserDetails]  WITH CHECK ADD  CONSTRAINT [FK_UserDetails_Users] FOREIGN KEY([UserID])
REFERENCES [dbo].[Users] ([ID])
GO
ALTER TABLE [dbo].[UserDetails] CHECK CONSTRAINT [FK_UserDetails_Users]
GO
ALTER TABLE [dbo].[UserDetails] ADD  DEFAULT ((0)) FOR [IsDefault]
GO
ALTER TABLE [dbo].[UserDetails] ADD  DEFAULT ((0)) FOR [IsAdmin]
GO
ALTER TABLE [dbo].[UserDetails] ADD  DEFAULT ((0)) FOR [IsProductManager]
GO