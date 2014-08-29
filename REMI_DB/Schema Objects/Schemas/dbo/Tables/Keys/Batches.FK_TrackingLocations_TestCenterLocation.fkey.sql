ALTER TABLE [dbo].[TrackingLocations]  WITH CHECK ADD  CONSTRAINT [FK_TrackingLocations_TestCenterLocation] FOREIGN KEY([TestCenterLocationID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO

ALTER TABLE [dbo].[TrackingLocations] CHECK CONSTRAINT [FK_TrackingLocations_TestCenterLocation]
GO