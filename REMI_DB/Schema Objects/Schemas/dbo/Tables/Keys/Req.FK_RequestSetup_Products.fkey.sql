ALTER TABLE [Req].[RequestSetup]  WITH CHECK ADD  CONSTRAINT [FK_RequestSetup_Products] FOREIGN KEY([ProductID])
REFERENCES [dbo].[Products] ([ID])
GO

ALTER TABLE [Req].[RequestSetup] CHECK CONSTRAINT [FK_RequestSetup_Products]
GO