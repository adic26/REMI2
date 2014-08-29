ALTER TABLE [dbo].[BatchComments]
    ADD CONSTRAINT [FK_BatchComments_Batches] FOREIGN KEY ([BatchID]) REFERENCES [dbo].[Batches] ([ID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

