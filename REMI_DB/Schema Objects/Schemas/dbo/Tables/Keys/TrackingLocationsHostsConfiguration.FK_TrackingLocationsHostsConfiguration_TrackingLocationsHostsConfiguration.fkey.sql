ALTER TABLE [dbo].[TrackingLocationsHostsConfiguration]  WITH CHECK ADD  CONSTRAINT [FK_TrackingLocationsHostsConfiguration_TrackingLocationsHostsConfiguration] FOREIGN KEY([ID])
REFERENCES [dbo].[TrackingLocationsHostsConfiguration] ([ID])
GO

ALTER TABLE [dbo].[TrackingLocationsHostsConfiguration] CHECK CONSTRAINT [FK_TrackingLocationsHostsConfiguration_TrackingLocationsHostsConfiguration]
GO