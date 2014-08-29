ALTER TABLE [dbo].[TrackingLocationsHostsConfigValues]  WITH CHECK ADD  CONSTRAINT [FK_TrackingLocationsHostsConfigValues_Lookups] FOREIGN KEY([LookupID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO
ALTER TABLE [dbo].[TrackingLocationsHostsConfigValues] CHECK CONSTRAINT [FK_TrackingLocationsHostsConfigValues_Lookups]
GO