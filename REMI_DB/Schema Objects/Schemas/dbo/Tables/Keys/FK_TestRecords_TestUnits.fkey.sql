ALTER TABLE [dbo].[TestRecords]
    ADD CONSTRAINT [FK_TestRecords_TestUnits] FOREIGN KEY ([TestUnitID]) REFERENCES [dbo].[TestUnits] ([ID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

