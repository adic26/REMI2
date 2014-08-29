ALTER TABLE [dbo].[TrackingLocationsHostsConfigValues]  WITH CHECK ADD  CONSTRAINT [FK_TrackingLocationsHostsConfigValues_TrackingLocationsHostsConfiguration] FOREIGN KEY([TrackingConfigID])
REFERENCES [dbo].[TrackingLocationsHostsConfiguration] ([ID])
GO

ALTER TABLE [dbo].[TrackingLocationsHostsConfigValues] CHECK CONSTRAINT [FK_TrackingLocationsHostsConfigValues_TrackingLocationsHostsConfiguration]
GO