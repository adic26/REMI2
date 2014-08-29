ALTER TABLE [dbo].[DeviceTrackingLog]
    ADD CONSTRAINT [FK_DeviceTrackingLog_TrackingLocations] FOREIGN KEY ([TrackingLocationID]) REFERENCES [dbo].[TrackingLocations] ([ID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

