﻿ALTER TABLE [dbo].[TestStages]
    ADD CONSTRAINT [FK_TestStages_Jobs] FOREIGN KEY ([JobID]) REFERENCES [dbo].[Jobs] ([ID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

