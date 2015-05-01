ALTER TABLE [dbo].[UsersProducts]  WITH CHECK ADD  CONSTRAINT [FK_UsersProducts_Users] FOREIGN KEY([UserID])
REFERENCES [dbo].[Users] ([ID])
GO

ALTER TABLE [dbo].[UsersProducts] CHECK CONSTRAINT [FK_UsersProducts_Users]
GO
