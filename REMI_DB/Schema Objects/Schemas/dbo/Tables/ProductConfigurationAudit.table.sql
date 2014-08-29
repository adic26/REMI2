CREATE TABLE [dbo].[ProductConfigurationAudit](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ProductConfigID] [int] NOT NULL,
	[ParentId] [int] NULL,
	[ViewOrder] [int] NULL,
	[NodeName] [nvarchar](200) NOT NULL,
	[InsertTime] [datetime] NOT NULL,
	[Action] [char](1) NOT NULL,
	[UserName] [nvarchar](255) NOT NULL,
	[UploadID] [int] NULL,
 CONSTRAINT [PK_ProductConfigurationAudit] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[ProductConfigurationAudit] ADD  CONSTRAINT [DF_ProductConfigurationAudit_InsertTime]  DEFAULT (getutcdate()) FOR [InsertTime]
GO