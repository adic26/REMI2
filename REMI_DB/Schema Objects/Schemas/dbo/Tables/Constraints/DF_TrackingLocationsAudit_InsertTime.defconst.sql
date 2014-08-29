ALTER TABLE [dbo].[TrackingLocationsAudit]
    ADD CONSTRAINT [DF_TrackingLocationsAudit_InsertTime] DEFAULT (getutcdate()) FOR [InsertTime];

