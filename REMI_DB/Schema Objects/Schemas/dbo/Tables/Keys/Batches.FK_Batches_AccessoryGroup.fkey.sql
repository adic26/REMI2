ALTER TABLE [dbo].[Batches]  WITH CHECK ADD  CONSTRAINT [FK_Batches_AccessoryGroup] FOREIGN KEY([AccessoryGroupID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO

ALTER TABLE [dbo].[Batches] CHECK CONSTRAINT [FK_Batches_AccessoryGroup]
GO