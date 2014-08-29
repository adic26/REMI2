ALTER TABLE [dbo].[TestExceptions] ADD  CONSTRAINT [DF_TestExceptions_InsertTime]  DEFAULT (getutcdate()) FOR [InsertTime]
