ALTER TABLE [dbo].[ProductTestReady]  WITH CHECK ADD  CONSTRAINT [FK_ProductTestReady_ProductSettings] FOREIGN KEY([PSID])
REFERENCES [dbo].[ProductSettings] ([ID])
GO

ALTER TABLE [dbo].[ProductTestReady] CHECK CONSTRAINT [FK_ProductTestReady_ProductSettings]
GO