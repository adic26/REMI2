ALTER TABLE [dbo].[JobsAudit]
    ADD CONSTRAINT [DF_JobsAudit_InsertTime] DEFAULT (getutcdate()) FOR [InsertTime];

