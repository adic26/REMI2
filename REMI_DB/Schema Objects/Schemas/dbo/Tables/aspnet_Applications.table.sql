﻿CREATE TABLE [dbo].[aspnet_Applications] (
    [ApplicationName]        NVARCHAR (256)   COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [LoweredApplicationName] NVARCHAR (256)   COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [ApplicationId]          UNIQUEIDENTIFIER DEFAULT (newid()) NOT NULL,
    [Description]            NVARCHAR (256)   COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    PRIMARY KEY NONCLUSTERED ([ApplicationId] ASC) WITH (ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF) ON [PRIMARY],
    UNIQUE NONCLUSTERED ([ApplicationName] ASC) WITH (ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF) ON [PRIMARY],
    UNIQUE NONCLUSTERED ([LoweredApplicationName] ASC) WITH (ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF) ON [PRIMARY]
);

