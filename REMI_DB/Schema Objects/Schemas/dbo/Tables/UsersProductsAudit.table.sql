CREATE TABLE [dbo].[UsersProductsAudit](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[UserName] [nvarchar](255) NOT NULL,
	[InsertTime] [datetime] NOT NULL,
	[Action] [char](1) NOT NULL,
	[ProductID] [int] NOT NULL,
	[UserID] [int] NOT NULL,
 CONSTRAINT [PK_UsersProductsAudit] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[UsersProductsAudit] ADD  CONSTRAINT [DF_UsersProductsAudit_InsertTime]  DEFAULT (getutcdate()) FOR [InsertTime]
GO
