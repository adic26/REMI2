ALTER TABLE [dbo].[BatchSpecificTestDurations]
    ADD CONSTRAINT [FK_BatchSpecificTestDurations_Tests] FOREIGN KEY ([TestID]) REFERENCES [dbo].[Tests] ([ID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

