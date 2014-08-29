ALTER TABLE [dbo].[ProductManagers]  WITH CHECK ADD  CONSTRAINT [FK_ProductManagers_Users] FOREIGN KEY([UserID])
REFERENCES [dbo].[Users] ([ID])
GO

ALTER TABLE [dbo].[ProductManagers] CHECK CONSTRAINT [FK_ProductManagers_Users]
GO