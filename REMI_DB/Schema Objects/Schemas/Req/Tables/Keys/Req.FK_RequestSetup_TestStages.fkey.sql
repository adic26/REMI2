ALTER TABLE [Req].[RequestSetup]  WITH CHECK ADD  CONSTRAINT [FK_RequestSetup_TestStages] FOREIGN KEY([TestStageID])
REFERENCES [dbo].[TestStages] ([ID])
GO

ALTER TABLE [Req].[RequestSetup] CHECK CONSTRAINT [FK_RequestSetup_TestStages]
GO