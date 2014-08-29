ALTER TABLE [dbo].[UsersAudit]
    ADD CONSTRAINT [DF_UsersAudit_InsertTime] DEFAULT (getutcdate()) FOR [InsertTime];

