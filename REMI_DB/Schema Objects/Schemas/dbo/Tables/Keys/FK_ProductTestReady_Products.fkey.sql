ALTER TABLE [dbo].[ProductTestReady]  WITH CHECK ADD  CONSTRAINT [FK_ProductTestReady_Products] FOREIGN KEY([ProductID])
REFERENCES [dbo].[Products] ([ID])
GO
ALTER TABLE [dbo].[ProductTestReady] CHECK CONSTRAINT [FK_ProductTestReady_Products]
GO