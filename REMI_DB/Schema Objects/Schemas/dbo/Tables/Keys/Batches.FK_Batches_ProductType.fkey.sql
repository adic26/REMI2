ALTER TABLE [dbo].[Batches]  WITH CHECK ADD  CONSTRAINT [FK_Batches_ProductType] FOREIGN KEY([ProductTypeID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO

ALTER TABLE [dbo].[Batches] CHECK CONSTRAINT [FK_Batches_ProductType]
GO
