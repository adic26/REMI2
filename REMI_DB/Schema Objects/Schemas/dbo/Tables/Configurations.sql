CREATE TABLE [dbo].[Configurations](
	[ConfigID] [int] IDENTITY(1,1) NOT NULL,
	[ModeID] [int] NOT NULL,
	[Version] [nvarchar](50) NOT NULL,
	[ConfigTypeID] [int] NOT NULL,
	[Name] [nvarchar](150) NOT NULL,
	[Definition] [xml] NOT NULL,
 CONSTRAINT [PK_Configurations] PRIMARY KEY CLUSTERED 
(
	[ConfigID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Configurations]  WITH CHECK ADD  CONSTRAINT [FK_Configurations_Lookups] FOREIGN KEY([ConfigTypeID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO
ALTER TABLE [dbo].[Configurations] CHECK CONSTRAINT [FK_Configurations_Lookups]
GO
ALTER TABLE [dbo].[Configurations]  WITH CHECK ADD  CONSTRAINT [FK_Configurations_Lookups1] FOREIGN KEY([ModeID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO
ALTER TABLE [dbo].[Configurations] CHECK CONSTRAINT [FK_Configurations_Lookups1]
GO