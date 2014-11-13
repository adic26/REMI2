CREATE TABLE [Req].[ReqFieldDataAudit](
	[ReqFieldDataAuditID] [INT] NOT NULL,
	[RequestID] [int] NOT NULL,
	[ReqFieldSetupID] [int] NOT NULL,
	[Value] [nvarchar](4000) NOT NULL,
	[InsertTime] [DateTime] NOT NULL,
	[Action] [char](1) NOT NULL,
	[UserName] [nvarchar](255) NOT NULL,
 CONSTRAINT [PK_ReqFieldDataAuditID] PRIMARY KEY CLUSTERED 
(
	[ReqFieldDataAuditID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]