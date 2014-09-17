ALTER TABLE [dbo].[JobOrientation]  WITH CHECK ADD  CONSTRAINT [FK_JobOrientation_Jobs] FOREIGN KEY([JobID])
REFERENCES [dbo].[Jobs] ([ID])
GO

ALTER TABLE [dbo].[JobOrientation] CHECK CONSTRAINT [FK_JobOrientation_Jobs]
GO