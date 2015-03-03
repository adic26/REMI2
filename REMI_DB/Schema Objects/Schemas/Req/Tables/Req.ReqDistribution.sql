CREATE TABLE [Req].[ReqDistribution](
	[DistributionID] [int] IDENTITY(1,1) NOT NULL,
	[RequestID] [int] NOT NULL,
	[UserName] [nvarchar](255) NOT NULL,
 CONSTRAINT [PK_ReqDistribution] PRIMARY KEY CLUSTERED 
(
	[DistributionID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [Req].[ReqDistribution]  WITH CHECK ADD  CONSTRAINT [FK_ReqDistribution_Request] FOREIGN KEY([RequestID])
REFERENCES [Req].[Request] ([RequestID])
GO

ALTER TABLE [Req].[ReqDistribution] CHECK CONSTRAINT [FK_ReqDistribution_Request]
GO
