ALTER TABLE [Relab].[ResultsMeasurementsFiles]  WITH CHECK ADD  CONSTRAINT [FK_ResultsMeasurementsFiles_ResultsMeasurements] FOREIGN KEY([ResultMeasurementID])
REFERENCES [Relab].[ResultsMeasurements] ([ID])
GO

ALTER TABLE [Relab].[ResultsMeasurementsFiles] CHECK CONSTRAINT [FK_ResultsMeasurementsFiles_ResultsMeasurements]
GO
