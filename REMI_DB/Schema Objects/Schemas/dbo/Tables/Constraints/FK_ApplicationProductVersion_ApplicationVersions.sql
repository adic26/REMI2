ALTER TABLE [dbo].[ApplicationProductVersion]  WITH CHECK ADD  CONSTRAINT [FK_ApplicationProductVersion_ApplicationVersions] FOREIGN KEY([AppVersionID])
REFERENCES [dbo].[ApplicationVersions] ([ID])
GO

ALTER TABLE [dbo].[ApplicationProductVersion] CHECK CONSTRAINT [FK_ApplicationProductVersion_ApplicationVersions]
GO