begin tran

ALTER TABLE [dbo].[Batches] ADD CONSTRAINT [FK_Batches_AccessoryGroup] FOREIGN KEY ([AccessoryGroupID]) REFERENCES [dbo].[Lookups] ([LookupID])
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Batches_ProductType]') AND parent_object_id = OBJECT_ID(N'[dbo].[Batches]'))
	ALTER TABLE [dbo].[Batches] ADD CONSTRAINT [FK_Batches_ProductType] FOREIGN KEY ([ProductTypeID]) REFERENCES [dbo].[Lookups] ([LookupID])
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Batches_TestCenterLocation]') AND parent_object_id = OBJECT_ID(N'[dbo].[Batches]'))
	ALTER TABLE [dbo].[Batches] ADD CONSTRAINT [FK_Batches_TestCenterLocation] FOREIGN KEY ([TestCenterLocationID]) REFERENCES [dbo].[Lookups] ([LookupID])
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_TrackingLocations_TestCenterLocation]') AND parent_object_id = OBJECT_ID(N'[dbo].[TrackingLocations]'))
	ALTER TABLE [dbo].[TrackingLocations] ADD CONSTRAINT [FK_TrackingLocations_TestCenterLocation] FOREIGN KEY ([TestCenterLocationID]) REFERENCES [dbo].[Lookups] ([LookupID])
GO
DROP INDEX [IX_Batches_BatchStatus] ON [dbo].[Batches] WITH ( ONLINE = OFF )
GO
CREATE NONCLUSTERED INDEX [IX_Batches_BatchStatus] ON [dbo].[Batches] 
(
	[BatchStatus] ASC
)
INCLUDE ( [ID],[ProductID]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

DROP INDEX [actioninserttime] ON [dbo].[BatchesAudit] WITH ( ONLINE = OFF )
GO
CREATE NONCLUSTERED INDEX [actioninserttime] ON [dbo].[BatchesAudit] 
(
	[Action] ASC,
	[InsertTime] ASC
)
INCLUDE ( [QRANumber],[TestCenterLocationID]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

rollback tran