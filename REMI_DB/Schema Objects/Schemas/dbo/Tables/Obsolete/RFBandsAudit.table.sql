CREATE TABLE [dbo].[RFBandsAudit] (
    [ID]               INT            IDENTITY (1, 1) NOT NULL,
    [InsertTime]       DATETIME       NULL,
    [productgroupname] NVARCHAR (400) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [rfBands]          NVARCHAR (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [username]         NVARCHAR (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [Action]           CHAR (1)       COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
);

