ALTER TABLE [dbo].[TaskAssignments]
    ADD CONSTRAINT [FK_TaskAssignment_Batches] FOREIGN KEY ([BatchID]) REFERENCES [dbo].[Batches] ([ID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

