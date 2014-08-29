ALTER TABLE [dbo].[TestRecordsXTrackingLogs]
    ADD CONSTRAINT [FK_TestRecordsXTrackingLogs_TestRecords] FOREIGN KEY ([TestRecordID]) REFERENCES [dbo].[TestRecords] ([ID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

