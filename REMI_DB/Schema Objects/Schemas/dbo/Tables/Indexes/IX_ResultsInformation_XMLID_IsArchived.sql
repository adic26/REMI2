CREATE NONCLUSTERED INDEX [IX_ResultsInformation_XMLID_IsArchived] ON Relab.[ResultsInformation] ( [XMLID], [IsArchived] ) INCLUDE ([ID], [Name]);
