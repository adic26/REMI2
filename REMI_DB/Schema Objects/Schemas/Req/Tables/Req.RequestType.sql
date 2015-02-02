CREATE TABLE [Req].[RequestType](
	[RequestTypeID] [int] IDENTITY(1,1) NOT NULL,
	[TypeID] [int] NOT NULL,
	[RequestConnectName] [nvarchar](150) NOT NULL,
	[DBType] [nvarchar](50) NOT NULL,
	[HasIntegration] [bit] NOT NULL,
	[CanReport] [bit] NOT NULL,
	[HasApproval] [bit] NOT NULL,
	[IsExternal] [bit] NOT NULL,
	rv ROWVERSION,
 CONSTRAINT [PK_RequestType] PRIMARY KEY CLUSTERED 
(
	[RequestTypeID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [Req].[RequestType]  WITH CHECK ADD  CONSTRAINT [FK_RequestType_Lookups] FOREIGN KEY([TypeID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO

ALTER TABLE [Req].[RequestType] CHECK CONSTRAINT [FK_RequestType_Lookups]
GO