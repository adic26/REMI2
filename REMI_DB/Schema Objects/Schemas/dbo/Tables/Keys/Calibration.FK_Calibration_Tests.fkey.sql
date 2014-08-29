ALTER TABLE [dbo].[Calibration] ADD CONSTRAINT [FK_Calibration_Tests] FOREIGN KEY ([TestID]) REFERENCES [dbo].[Tests] ([ID])
go
ALTER TABLE [dbo].[Calibration] CHECK CONSTRAINT [FK_Calibration_Tests]
GO