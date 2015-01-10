ALTER TABLE [Req].[RequestSetup]  WITH CHECK ADD  CONSTRAINT [FK_RequestSetup_Tests] FOREIGN KEY([TestID])
REFERENCES [dbo].[Tests] ([ID])
GO

ALTER TABLE [Req].[RequestSetup] CHECK CONSTRAINT [FK_RequestSetup_Tests]
GO