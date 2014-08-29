CREATE TABLE [dbo].[ProductConfigValues](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Value] [nvarchar](2000) NOT NULL,
	[LookupID] [int] NOT NULL,
	[ProductConfigID] [int] NOT NULL,
	[LastUser] [nvarchar](255) NOT NULL,
	[IsAttribute] [bit] NULL,
 CONSTRAINT [PK_ProductConfigValues] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = ON, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 75) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[ProductConfigValues] CHECK CONSTRAINT [FK_ProductConfigValue_Lookup]
GO

ALTER TABLE [dbo].[ProductConfigValues] CHECK CONSTRAINT [FK_ProductConfigValues_ProductConfiguration]
GO

ALTER TABLE [dbo].[ProductConfigValues] ADD  DEFAULT ((0)) FOR [IsAttribute]
GO
GRANT ALTER ON dbo.ProductConfigValues TO remi
go
GRANT INSERT ON dbo.ProductConfigValues TO remi
go