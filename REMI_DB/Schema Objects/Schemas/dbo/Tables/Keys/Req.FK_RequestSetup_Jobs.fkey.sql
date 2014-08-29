ALTER TABLE [Req].[RequestSetup]  WITH CHECK ADD  CONSTRAINT [FK_RequestSetup_Jobs] FOREIGN KEY([JobID])
REFERENCES [dbo].[Jobs] ([ID])
GO

ALTER TABLE [Req].[RequestSetup] CHECK CONSTRAINT [FK_RequestSetup_Jobs]
GO