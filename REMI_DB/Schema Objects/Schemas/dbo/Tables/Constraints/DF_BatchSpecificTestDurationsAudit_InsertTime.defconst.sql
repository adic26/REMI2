ALTER TABLE [dbo].[BatchSpecificTestDurationsAudit]
    ADD CONSTRAINT [DF_BatchSpecificTestDurationsAudit_InsertTime] DEFAULT (getutcdate()) FOR [InsertTime];

