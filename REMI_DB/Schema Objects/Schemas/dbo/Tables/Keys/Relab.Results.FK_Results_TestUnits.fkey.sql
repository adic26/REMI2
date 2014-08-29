ALTER TABLE [Relab].[Results]  WITH CHECK ADD  CONSTRAINT [FK_Results_TestUnits] FOREIGN KEY([TestUnitID])
REFERENCES [dbo].[TestUnits] ([ID])
GO

ALTER TABLE [Relab].[Results] CHECK CONSTRAINT [FK_Results_TestUnits]
GO
