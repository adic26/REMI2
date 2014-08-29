CREATE TABLE [dbo].[ProductConfigurationVersion](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[UploadID] [int] NOT NULL,
	[PCXML] [xml] NOT NULL,
	[LastUser] [nvarchar](255) NOT NULL,
	[VersionNum] [int] NOT NULL,
 CONSTRAINT [PK_ProductConfigurationVersion] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[ProductConfigurationVersion]  WITH CHECK ADD  CONSTRAINT [FK_ProductConfigurationVersion_ProductConfigurationUpload] FOREIGN KEY([UploadID])
REFERENCES [dbo].[ProductConfigurationUpload] ([ID])
GO

ALTER TABLE [dbo].[ProductConfigurationVersion] CHECK CONSTRAINT [FK_ProductConfigurationVersion_ProductConfigurationUpload]
GO