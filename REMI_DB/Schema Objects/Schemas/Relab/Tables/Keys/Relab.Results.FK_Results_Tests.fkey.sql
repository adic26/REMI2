ALTER TABLE [Relab].[Results]  WITH CHECK ADD  CONSTRAINT [FK_Results_Tests] FOREIGN KEY([TestID])
REFERENCES [dbo].[Tests] ([ID])
GO

ALTER TABLE [Relab].[Results] CHECK CONSTRAINT [FK_Results_Tests]
GO


