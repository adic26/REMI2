ALTER TABLE [dbo].[TrackingLocations]
    ADD CONSTRAINT [FK_TrackingLocations_TrackingLocationTypes] FOREIGN KEY ([TrackingLocationTypeID]) REFERENCES [dbo].[TrackingLocationTypes] ([ID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

