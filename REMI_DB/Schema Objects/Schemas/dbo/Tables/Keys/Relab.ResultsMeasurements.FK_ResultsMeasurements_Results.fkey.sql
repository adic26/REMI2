ALTER TABLE [Relab].[ResultsMeasurements]  WITH CHECK ADD  CONSTRAINT [FK_ResultsMeasurements_Results] FOREIGN KEY([ResultID])
REFERENCES [Relab].[Results] ([ID])
GO

ALTER TABLE [Relab].[ResultsMeasurements] CHECK CONSTRAINT [FK_ResultsMeasurements_Results]
GO
