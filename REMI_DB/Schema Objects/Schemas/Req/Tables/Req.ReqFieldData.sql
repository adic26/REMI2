CREATE TABLE [Req].[ReqFieldData](
	[RequestID] [int] NOT NULL,
	[ReqFieldSetupID] [int] NOT NULL,
	[Value] [nvarchar](4000) NOT NULL,
	[LastUser] [nvarchar](255) NULL,
	[InsertTime] [datetime] NULL,
	[rv] [timestamp] NOT NULL,
	[ReqFieldDataID] [int] IDENTITY(1,1) NOT NULL,
 CONSTRAINT [PK_ReqFieldData] PRIMARY KEY CLUSTERED 
(
	[ReqFieldDataID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [Req].[ReqFieldData]  WITH CHECK ADD  CONSTRAINT [FK_ReqFieldData_ReqFieldSetup] FOREIGN KEY([ReqFieldSetupID])
REFERENCES [Req].[ReqFieldSetup] ([ReqFieldSetupID])
GO

ALTER TABLE [Req].[ReqFieldData] CHECK CONSTRAINT [FK_ReqFieldData_ReqFieldSetup]
GO

ALTER TABLE [Req].[ReqFieldData]  WITH CHECK ADD  CONSTRAINT [FK_ReqFieldData_Request] FOREIGN KEY([RequestID])
REFERENCES [Req].[Request] ([RequestID])
GO

ALTER TABLE [Req].[ReqFieldData] CHECK CONSTRAINT [FK_ReqFieldData_Request]
GO