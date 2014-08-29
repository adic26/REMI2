ALTER TABLE [dbo].[ApplicationLog]
    ADD CONSTRAINT [DF_ApplicationLog_Date] DEFAULT (getutcdate()) FOR [Date];

