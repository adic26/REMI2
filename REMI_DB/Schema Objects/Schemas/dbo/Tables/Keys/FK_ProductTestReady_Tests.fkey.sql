ALTER TABLE [dbo].[ProductTestReady]  WITH CHECK ADD  CONSTRAINT [FK_ProductTestReady_Tests] FOREIGN KEY([TestID])
REFERENCES [dbo].[Tests] ([ID])
GO

ALTER TABLE [dbo].[ProductTestReady] CHECK CONSTRAINT [FK_ProductTestReady_Tests]
GO

