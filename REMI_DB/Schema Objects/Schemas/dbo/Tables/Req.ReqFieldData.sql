CREATE TABLE [Req].[ReqFieldData]
(
[RequestID] [int] NOT NULL,
[ReqFieldSetupID] [int] NOT NULL,
[Value] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
)
GO
-- Constraints and Indexes

ALTER TABLE [Req].[ReqFieldData] ADD CONSTRAINT [PK_ReqFieldData] PRIMARY KEY CLUSTERED  ([RequestID], [ReqFieldSetupID])
GO
-- Foreign Keys

ALTER TABLE [Req].[ReqFieldData] ADD CONSTRAINT [FK_ReqFieldData_ReqFieldSetup] FOREIGN KEY ([ReqFieldSetupID]) REFERENCES [Req].[ReqFieldSetup] ([ReqFieldSetupID])
GO
ALTER TABLE [Req].[ReqFieldData] ADD CONSTRAINT [FK_ReqFieldData_Request] FOREIGN KEY ([RequestID]) REFERENCES [Req].[Request] ([RequestID])
GO