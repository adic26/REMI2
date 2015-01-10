ALTER TABLE [Relab].[ResultsStatus]  WITH CHECK ADD  CONSTRAINT [FK_ResultsStatus_Batches] FOREIGN KEY([BatchID])
REFERENCES [dbo].[Batches] ([ID])
GO

ALTER TABLE [Relab].[ResultsStatus] CHECK CONSTRAINT [FK_ResultsStatus_Batches]
GO
