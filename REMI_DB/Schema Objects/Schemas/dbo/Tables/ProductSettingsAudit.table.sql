CREATE TABLE [dbo].[ProductSettingsAudit] (
    [ID]                INT            IDENTITY (1, 1) NOT NULL,
    [ProductSettingsID] INT            NOT NULL,
    [Action]            CHAR (1)       COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [InsertTime]        DATETIME2 (7)  NOT NULL,
    [LookupID]  INT COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [KeyName]           NVARCHAR (MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [ValueText]         NVARCHAR (MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [DefaultValue]      NVARCHAR (MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
);

