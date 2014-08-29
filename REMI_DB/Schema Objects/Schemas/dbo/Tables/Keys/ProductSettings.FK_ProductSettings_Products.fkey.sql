ALTER TABLE [dbo].[ProductSettings]  WITH CHECK ADD  CONSTRAINT [FK_ProductSettings_Products] FOREIGN KEY([ProductID])
REFERENCES [dbo].[Products] ([ID])
GO

ALTER TABLE [dbo].[ProductSettings] CHECK CONSTRAINT [FK_ProductSettings_Products]
GO