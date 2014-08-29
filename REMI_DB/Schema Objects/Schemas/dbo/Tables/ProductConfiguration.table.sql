CREATE TABLE [dbo].[ProductConfiguration](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ParentId] [int] NULL,
	[ViewOrder] [int] NULL,
	[NodeName] [nvarchar](200) NOT NULL,
	[LastUser] [nvarchar](255) NOT NULL,
	[UploadID] [int] NULL,
 CONSTRAINT [PK_ProductCOnfiguration] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = ON, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 75) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[ProductConfiguration]  WITH CHECK ADD  CONSTRAINT [FK_ProductConfigurationUpload_ID] FOREIGN KEY([UploadID])
REFERENCES [dbo].[ProductConfigurationUpload] ([ID])
GO

ALTER TABLE [dbo].[ProductConfiguration] CHECK CONSTRAINT [FK_ProductConfigurationUpload_ID]
GO
GRANT ALTER ON dbo.ProductConfiguration TO remi
go
GRANT INSERT ON dbo.ProductConfiguration TO remi
go