ALTER TABLE [dbo].[TestsAudit]
    ADD CONSTRAINT [DF_TestsAudit_InsertTime] DEFAULT (getutcdate()) FOR [InsertTime];

