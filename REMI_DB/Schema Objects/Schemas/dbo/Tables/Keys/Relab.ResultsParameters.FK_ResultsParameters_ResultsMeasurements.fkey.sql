ALTER TABLE [Relab].[ResultsParameters]  WITH CHECK ADD  CONSTRAINT [FK_ResultsParameters_ResultsMeasurements] FOREIGN KEY([ResultMeasurementID])
REFERENCES [Relab].[ResultsMeasurements] ([ID])
GO

ALTER TABLE [Relab].[ResultsParameters] CHECK CONSTRAINT [FK_ResultsParameters_ResultsMeasurements]
GO
