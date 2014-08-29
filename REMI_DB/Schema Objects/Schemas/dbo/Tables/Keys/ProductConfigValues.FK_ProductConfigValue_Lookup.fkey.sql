ALTER TABLE [dbo].[ProductConfigValues]  WITH CHECK ADD  CONSTRAINT [FK_ProductConfigValue_Lookup] FOREIGN KEY([LookupID])
REFERENCES [dbo].[Lookups] ([LookupID])