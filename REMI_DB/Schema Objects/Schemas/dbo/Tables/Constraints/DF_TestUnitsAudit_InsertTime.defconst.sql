ALTER TABLE [dbo].[TestUnitsAudit]
    ADD CONSTRAINT [DF_TestUnitsAudit_InsertTime] DEFAULT (getutcdate()) FOR [InsertTime];

