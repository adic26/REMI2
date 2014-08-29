ALTER TABLE [dbo].[TestExceptionsAudit]
    ADD CONSTRAINT [DF_TestUnitTestExceptionsAudit_InsertTime] DEFAULT (getutcdate()) FOR [InsertTime];

