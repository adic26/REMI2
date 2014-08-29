ALTER TABLE [dbo].[Batches]  WITH CHECK ADD  CONSTRAINT [FK_Batches_TestCenterLocation] FOREIGN KEY([TestCenterLocationID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO

ALTER TABLE [dbo].[Batches] CHECK CONSTRAINT [FK_Batches_TestCenterLocation]
GO
