ALTER TABLE [Relab].[ResultsMeasurements]  WITH CHECK ADD  CONSTRAINT [FK_ResultsMeasurements_ResultsXML_XMLID] FOREIGN KEY([XMLID])
REFERENCES [Relab].[ResultsXML] ([ID])
GO
ALTER TABLE [Relab].[ResultsMeasurements] CHECK CONSTRAINT [FK_ResultsMeasurements_ResultsXML_XMLID]
GO