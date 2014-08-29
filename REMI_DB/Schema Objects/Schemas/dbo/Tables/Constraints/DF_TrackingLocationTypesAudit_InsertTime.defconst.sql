ALTER TABLE [dbo].[TrackingLocationTypesAudit]
    ADD CONSTRAINT [DF_TrackingLocationTypesAudit_InsertTime] DEFAULT (getutcdate()) FOR [InsertTime];

