CREATE NONCLUSTERED INDEX [IX_ResultsInformation_IsArchived] ON Relab.[ResultsInformation] ( [IsArchived] ) INCLUDE ([ID], [XMLID], [Name]);
