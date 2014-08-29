ALTER TABLE [dbo].[UserTraining]  WITH CHECK ADD  CONSTRAINT [FK_UserTraining_Lookups] FOREIGN KEY([LookupID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO

ALTER TABLE [dbo].[UserTraining] CHECK CONSTRAINT [FK_UserTraining_Lookups]
GO