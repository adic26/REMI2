ALTER TABLE [dbo].[TrackingLocationTypePermissions]
    ADD CONSTRAINT [FK_TrackingLocationTypePermissions_TrackingLocationTypes] FOREIGN KEY ([TrackingLocationTypeID]) REFERENCES [dbo].[TrackingLocationTypes] ([ID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

