CREATE NONCLUSTERED INDEX [IX_ReqFieldData_ReqFieldSetupID] ON Req.[ReqFieldData] ( [ReqFieldSetupID] ) INCLUDE ([RequestID], [Value]);
