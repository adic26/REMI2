ALTER TABLE [dbo].[ProductManagersAudit]
    ADD CONSTRAINT [DF_ProductManagersAudit_InsertTime] DEFAULT (getutcdate()) FOR [InsertTime];

