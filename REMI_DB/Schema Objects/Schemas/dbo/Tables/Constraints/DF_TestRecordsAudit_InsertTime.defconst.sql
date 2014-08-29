ALTER TABLE [dbo].[TestRecordsAudit]
    ADD CONSTRAINT [DF_TestRecordsAudit_InsertTime] DEFAULT (getutcdate()) FOR [InsertTime];

