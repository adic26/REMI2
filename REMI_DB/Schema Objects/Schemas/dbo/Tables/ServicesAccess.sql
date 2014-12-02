CREATE TABLE [dbo].[ServicesAccess](
	[ServiceAccessID] [int] IDENTITY(1,1) NOT NULL,
	[ServiceID] [int] NOT NULL,
	[LookupID] [int] NOT NULL,
 CONSTRAINT [PK_ServicesAccess] PRIMARY KEY CLUSTERED 
(
	[ServiceAccessID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[ServicesAccess]  WITH CHECK ADD  CONSTRAINT [FK_ServicesAccess_Lookups] FOREIGN KEY([LookupID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO

ALTER TABLE [dbo].[ServicesAccess] CHECK CONSTRAINT [FK_ServicesAccess_Lookups]
GO

ALTER TABLE [dbo].[ServicesAccess]  WITH CHECK ADD  CONSTRAINT [FK_ServicesAccess_Services] FOREIGN KEY([ServiceID])
REFERENCES [dbo].[Services] ([ServiceID])
GO

ALTER TABLE [dbo].[ServicesAccess] CHECK CONSTRAINT [FK_ServicesAccess_Services]
GO
