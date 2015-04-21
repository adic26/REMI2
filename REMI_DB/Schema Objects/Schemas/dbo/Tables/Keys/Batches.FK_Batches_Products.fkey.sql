ALTER TABLE [dbo].[Batches]  WITH CHECK ADD  CONSTRAINT [FK_Batches_Products] FOREIGN KEY([ProductID])
REFERENCES [dbo].[LOokups] ([LookupID])
GO

ALTER TABLE [dbo].[Batches] CHECK CONSTRAINT [FK_Batches_Products]
GO