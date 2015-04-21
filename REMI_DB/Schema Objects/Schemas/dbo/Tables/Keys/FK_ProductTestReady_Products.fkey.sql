ALTER TABLE [dbo].[ProductTestReady]  WITH CHECK ADD  CONSTRAINT [FK_ProductTestReady_Products] FOREIGN KEY([LookupID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO
ALTER TABLE [dbo].[ProductTestReady] CHECK CONSTRAINT [FK_ProductTestReady_Products]
GO