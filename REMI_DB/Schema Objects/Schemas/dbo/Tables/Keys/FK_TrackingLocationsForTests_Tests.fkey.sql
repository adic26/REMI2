ALTER TABLE [dbo].[TrackingLocationsForTests]
    ADD CONSTRAINT [FK_TrackingLocationsForTests_Tests] FOREIGN KEY ([TestID]) REFERENCES [dbo].[Tests] ([ID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

