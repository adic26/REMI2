CREATE TABLE [dbo].[ApplicationLog] (
    [Id]        INT            IDENTITY (1, 1) NOT NULL,
    [Date]      DATETIME       NOT NULL,
    [Thread]    VARCHAR (255)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [LogLevel]  VARCHAR (50)   COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [Logger]    VARCHAR (255)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [Message]   VARCHAR (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [Exception] VARCHAR (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
);

