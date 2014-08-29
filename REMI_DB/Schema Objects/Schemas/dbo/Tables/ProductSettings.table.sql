CREATE TABLE [dbo].[ProductSettings] (
    [ID]               INT            IDENTITY (1, 1) NOT NULL,
    [LastUser]         NVARCHAR (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [ProductID] INT COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [KeyName]          NVARCHAR (MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [ValueText]        NVARCHAR (MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [DefaultValue]     NVARCHAR (MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
);

