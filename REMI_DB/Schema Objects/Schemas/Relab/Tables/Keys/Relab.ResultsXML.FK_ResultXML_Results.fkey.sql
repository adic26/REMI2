﻿ALTER TABLE [Relab].[ResultsXML]  WITH CHECK ADD  CONSTRAINT [FK_ResultXML_Results] FOREIGN KEY([ResultID])
REFERENCES [Relab].[Results] ([ID])
GO

ALTER TABLE [Relab].[ResultsXML] CHECK CONSTRAINT [FK_ResultXML_Results]
GO