ALTER TABLE [dbo].[BatchSpecificTestDurations]
    ADD CONSTRAINT [FK_BatchSpecificTestDurations_Batches] FOREIGN KEY ([BatchID]) REFERENCES [dbo].[Batches] ([ID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

