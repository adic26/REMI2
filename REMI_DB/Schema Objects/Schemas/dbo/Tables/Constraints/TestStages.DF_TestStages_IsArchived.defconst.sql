ALTER TABLE [dbo].[TestStages] ADD  CONSTRAINT [DF_TestStages_IsArchived]  DEFAULT ((0)) FOR [IsArchived]
GO
