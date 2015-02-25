ALTER TABLE [dbo].[BatchesJira]  WITH CHECK ADD  CONSTRAINT [FK_BatchesJira_Batches] FOREIGN KEY([BatchID])
REFERENCES [dbo].[Batches] ([ID])