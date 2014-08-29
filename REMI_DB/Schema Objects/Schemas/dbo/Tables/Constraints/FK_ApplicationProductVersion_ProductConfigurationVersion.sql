ALTER TABLE [dbo].[ApplicationProductVersion]  WITH CHECK ADD  CONSTRAINT [FK_ApplicationProductVersion_ProductConfigurationVersion] FOREIGN KEY([PCVID])
REFERENCES [dbo].[ProductConfigurationVersion] ([ID])
GO

ALTER TABLE [dbo].[ApplicationProductVersion] CHECK CONSTRAINT [FK_ApplicationProductVersion_ProductConfigurationVersion]
GO