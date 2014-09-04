ALTER TABLE [dbo].[JobOrientation]  WITH CHECK ADD  CONSTRAINT [FK_JobOrientation_Lookups] FOREIGN KEY([ProductTypeID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO

ALTER TABLE [dbo].[JobOrientation] CHECK CONSTRAINT [FK_JobOrientation_Lookups]
GO