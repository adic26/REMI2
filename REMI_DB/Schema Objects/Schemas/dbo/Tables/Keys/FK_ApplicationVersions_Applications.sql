ALTER TABLE [dbo].[ApplicationVersions]  WITH CHECK ADD  CONSTRAINT [FK_ApplicationVersions_Applications] FOREIGN KEY([AppID])
REFERENCES [dbo].[Applications] ([ID])