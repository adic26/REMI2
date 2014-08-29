ALTER TABLE [Relab].[ResultsMeasurements]  WITH CHECK ADD  CONSTRAINT [FK_ResultsMeasurements_Lookups_MeasurementType] FOREIGN KEY([MeasurementTypeID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO

ALTER TABLE [Relab].[ResultsMeasurements] CHECK CONSTRAINT [FK_ResultsMeasurements_Lookups_MeasurementType]
GO

