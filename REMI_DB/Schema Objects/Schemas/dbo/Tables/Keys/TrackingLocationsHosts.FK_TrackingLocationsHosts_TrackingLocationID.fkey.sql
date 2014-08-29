ALTER TABLE [dbo].[TrackingLocationsHosts]  WITH CHECK ADD  CONSTRAINT [FK_TrackingLocationsHosts_TrackingLocationID] FOREIGN KEY([TrackingLocationID])
REFERENCES [dbo].[TrackingLocations] ([ID])