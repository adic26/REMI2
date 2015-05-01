ALTER TABLE [dbo].[ProductSettings]  WITH CHECK ADD  CONSTRAINT [FK_ProductSettings_Products] FOREIGN KEY([LookupID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO

ALTER TABLE [dbo].[ProductSettings] CHECK CONSTRAINT [FK_ProductSettings_Products]
GO