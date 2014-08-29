ALTER TABLE [dbo].[TrackingLocationsForTests]
    ADD CONSTRAINT [FK_TrackingLocationsForTests_TrackingLocationTypes] FOREIGN KEY ([TrackingLocationtypeID]) REFERENCES [dbo].[TrackingLocationTypes] ([ID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

