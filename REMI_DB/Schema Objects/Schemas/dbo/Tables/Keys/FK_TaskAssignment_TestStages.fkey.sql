ALTER TABLE [dbo].[TaskAssignments]
    ADD CONSTRAINT [FK_TaskAssignment_TestStages] FOREIGN KEY ([TaskID]) REFERENCES [dbo].[TestStages] ([ID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

