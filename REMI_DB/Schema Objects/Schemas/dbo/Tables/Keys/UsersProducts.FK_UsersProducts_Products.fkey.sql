ALTER TABLE [dbo].[UsersProducts]  WITH CHECK ADD  CONSTRAINT [FK_UsersProducts_Products] FOREIGN KEY([ProductID])
REFERENCES [dbo].[Products] ([ID])
GO

ALTER TABLE [dbo].[UsersProducts] CHECK CONSTRAINT [FK_UsersProducts_Products]
GO