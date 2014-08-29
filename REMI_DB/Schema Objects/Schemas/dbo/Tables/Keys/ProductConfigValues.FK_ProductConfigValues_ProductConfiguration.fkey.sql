ALTER TABLE [dbo].[ProductConfigValues]  WITH CHECK ADD  CONSTRAINT [FK_ProductConfigValues_ProductConfiguration] FOREIGN KEY([ProductConfigID])
REFERENCES [dbo].[ProductConfiguration] ([ID])