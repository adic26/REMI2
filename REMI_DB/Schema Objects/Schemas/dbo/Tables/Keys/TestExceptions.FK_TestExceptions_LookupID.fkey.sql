ALTER TABLE [dbo].[TestExceptions]
    ADD CONSTRAINT [FK_TestExceptions_LookupID] FOREIGN KEY ([LookupID]) REFERENCES [dbo].[Lookups] ([LookupID]);