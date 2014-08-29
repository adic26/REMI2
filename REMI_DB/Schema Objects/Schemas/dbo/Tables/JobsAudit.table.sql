CREATE TABLE [dbo].[JobsAudit] (
    [ID]         INT             IDENTITY (1, 1) NOT NULL,
    [JobId]      INT             NOT NULL,
    [JobName]    NVARCHAR (400)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [WILocation] NVARCHAR (400)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [Comment]    NVARCHAR (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [UserName]   NVARCHAR (255)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [InsertTime] DATETIME        NOT NULL,
    [Action]     CHAR (1)        COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[IsActive]	BIT				NULL
);

