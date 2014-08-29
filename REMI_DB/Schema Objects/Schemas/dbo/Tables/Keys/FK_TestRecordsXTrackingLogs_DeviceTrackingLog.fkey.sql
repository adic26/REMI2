ALTER TABLE [dbo].[TestRecordsXTrackingLogs]
    ADD CONSTRAINT [FK_TestRecordsXTrackingLogs_DeviceTrackingLog] FOREIGN KEY ([TrackingLogID]) REFERENCES [dbo].[DeviceTrackingLog] ([ID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

