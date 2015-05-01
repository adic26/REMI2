ALTER TABLE [dbo].[ProductManagers]  WITH CHECK ADD  CONSTRAINT [FK_ProductManagers_Products] FOREIGN KEY([ProductID])
REFERENCES [dbo].[Products] ([ID])
GO

ALTER TABLE [dbo].[ProductManagers] CHECK CONSTRAINT [FK_ProductManagers_Products]
GO