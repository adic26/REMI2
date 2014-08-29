ALTER TABLE [dbo].[TestRecords]  WITH CHECK ADD  CONSTRAINT [FK_TestRecords_Tests] FOREIGN KEY([TestID])
REFERENCES [dbo].[Tests] ([ID])
GO
ALTER TABLE [dbo].[TestRecords] CHECK CONSTRAINT [FK_TestRecords_Tests]
GO