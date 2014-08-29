ALTER TABLE [Req].[RequestSetup]  WITH CHECK ADD  CONSTRAINT [FK_RequestSetup_Batches] FOREIGN KEY([BatchID])
REFERENCES [dbo].[Batches] ([ID])
GO

ALTER TABLE [Req].[RequestSetup] CHECK CONSTRAINT [FK_RequestSetup_Batches]
GO