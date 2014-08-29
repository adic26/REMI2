ALTER TABLE [Relab].[Results]  WITH CHECK ADD  CONSTRAINT [FK_Results_TestStages] FOREIGN KEY([TestStageID])
REFERENCES [dbo].[TestStages] ([ID])
GO

ALTER TABLE [Relab].[Results] CHECK CONSTRAINT [FK_Results_TestStages]
GO
