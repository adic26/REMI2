ALTER TABLE [dbo].[Calibration] ADD CONSTRAINT [FK_Calibration_Products] FOREIGN KEY ([ProductID]) REFERENCES [dbo].[Products] ([ID])
go
ALTER TABLE [dbo].[Calibration] CHECK CONSTRAINT [FK_Calibration_Products]
GO