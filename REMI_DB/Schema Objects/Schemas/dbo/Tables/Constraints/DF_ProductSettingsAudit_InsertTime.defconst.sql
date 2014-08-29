ALTER TABLE [dbo].[ProductSettingsAudit]
    ADD CONSTRAINT [DF_ProductSettingsAudit_InsertTime] DEFAULT (getutcdate()) FOR [InsertTime];

