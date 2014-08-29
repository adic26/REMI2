ALTER TABLE [dbo].[TestStagesAudit]
    ADD CONSTRAINT [DF_TestStagesAudit_InsertTime] DEFAULT (getutcdate()) FOR [InsertTime];

