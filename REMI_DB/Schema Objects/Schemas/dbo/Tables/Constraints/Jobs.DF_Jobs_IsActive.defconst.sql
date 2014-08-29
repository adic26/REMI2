ALTER TABLE [dbo].[Jobs] ADD  CONSTRAINT [DF_Jobs_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
