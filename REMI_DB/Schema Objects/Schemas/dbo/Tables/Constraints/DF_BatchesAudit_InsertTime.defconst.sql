ALTER TABLE [dbo].[BatchesAudit]
    ADD CONSTRAINT [DF_BatchesAudit_InsertTime] DEFAULT (getutcdate()) FOR [InsertTime];

