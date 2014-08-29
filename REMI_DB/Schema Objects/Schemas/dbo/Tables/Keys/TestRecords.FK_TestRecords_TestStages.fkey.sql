ALTER TABLE [dbo].[TestRecords]  WITH CHECK ADD  CONSTRAINT [FK_TestRecords_TestStages] FOREIGN KEY([TestStageID])
REFERENCES [dbo].[TestStages] ([ID])
GO

ALTER TABLE [dbo].[TestRecords] CHECK CONSTRAINT [FK_TestRecords_TestStages]
GO