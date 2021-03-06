﻿CREATE TABLE [dbo].[aspnet_Roles] (
    [ApplicationId]   UNIQUEIDENTIFIER NOT NULL,
    [RoleId]          UNIQUEIDENTIFIER DEFAULT (newid()) NOT NULL,
    [RoleName]        NVARCHAR (256)   COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [LoweredRoleName] NVARCHAR (256)   COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [Description]     NVARCHAR (256)   COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	hasProductCheck BIT NULL,
    PRIMARY KEY NONCLUSTERED ([RoleId] ASC) WITH (ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF) ON [PRIMARY],
    FOREIGN KEY ([ApplicationId]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) ON DELETE NO ACTION ON UPDATE NO ACTION
);

