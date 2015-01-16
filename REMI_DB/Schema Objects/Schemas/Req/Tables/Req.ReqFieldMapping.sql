CREATE TABLE [Req].[ReqFieldMapping](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[RequestTypeID] [int] NOT NULL,
	[IntField] [nvarchar](150) NOT NULL,
	[ExtField] [nvarchar](150) NOT NULL,
	[IsActive] [bit] NOT NULL,
 CONSTRAINT [PK_ReqFieldMapping] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [Req].[ReqFieldMapping]  WITH CHECK ADD  CONSTRAINT [FK_ReqFieldMapping_RequestType] FOREIGN KEY([RequestTypeID])
REFERENCES [Req].[RequestType] ([RequestTypeID])
GO

ALTER TABLE [Req].[ReqFieldMapping] CHECK CONSTRAINT [FK_ReqFieldMapping_RequestType]
GO

ALTER TABLE [Req].[ReqFieldMapping] ADD  CONSTRAINT [DF_ReqFieldMapping_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
