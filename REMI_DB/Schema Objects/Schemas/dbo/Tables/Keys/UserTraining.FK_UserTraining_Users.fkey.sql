ALTER TABLE [dbo].[UserTraining]  WITH CHECK ADD  CONSTRAINT [FK_UserTraining_Users] FOREIGN KEY([UserID])
REFERENCES [dbo].[Users] ([ID])
GO

ALTER TABLE [dbo].[UserTraining] CHECK CONSTRAINT [FK_UserTraining_Users]
GO