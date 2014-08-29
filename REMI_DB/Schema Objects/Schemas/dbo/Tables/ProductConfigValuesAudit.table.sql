CREATE TABLE [dbo].[ProductConfigValuesAudit](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ProductConfigValueID] [int] NOT NULL,
	[Value] [nvarchar](2000) NOT NULL,
	[LookupID] [int] NOT NULL,
	[ProductGroupID] [int] NOT NULL,
	[Action] [char](1) NOT NULL,
	[UserName] [nvarchar](255) NOT NULL,
	[InsertTime] [datetime] NOT NULL,
	[IsAttribute] [bit] NULL,
 CONSTRAINT [PK_ProductConfigValuesAudit] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[ProductConfigValuesAudit] ADD  CONSTRAINT [DF_ProductConfigValuesAudit_InsertTime]  DEFAULT (getutcdate()) FOR [InsertTime]
GO
