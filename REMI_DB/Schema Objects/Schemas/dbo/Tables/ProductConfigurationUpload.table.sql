CREATE TABLE [dbo].[ProductConfigurationUpload](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[IsProcessed] [bit] NOT NULL,
	[LookupID] [int] NOT NULL,
	[TestID] [int] NOT NULL,
	[LastUser] [nvarchar](255) NOT NULL,
	[PCName] [nvarchar](200) NULL,
 CONSTRAINT [PK_ProductConfigurationUpload] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[ProductConfigurationUpload]  WITH CHECK ADD  CONSTRAINT [FK_ProductConfigurationUpload_Products] FOREIGN KEY([LookupID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO

ALTER TABLE [dbo].[ProductConfigurationUpload] CHECK CONSTRAINT [FK_ProductConfigurationUpload_Products]
GO

ALTER TABLE [dbo].[ProductConfigurationUpload]  WITH CHECK ADD  CONSTRAINT [FK_ProductConfigurationUpload_Tests] FOREIGN KEY([TestID])
REFERENCES [dbo].[Tests] ([ID])
GO

ALTER TABLE [dbo].[ProductConfigurationUpload] CHECK CONSTRAINT [FK_ProductConfigurationUpload_Tests]
GO