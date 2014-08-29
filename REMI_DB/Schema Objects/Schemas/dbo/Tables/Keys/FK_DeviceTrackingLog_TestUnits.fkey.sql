ALTER TABLE [dbo].[DeviceTrackingLog]
    ADD CONSTRAINT [FK_DeviceTrackingLog_TestUnits] FOREIGN KEY ([TestUnitID]) REFERENCES [dbo].[TestUnits] ([ID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

