CREATE TABLE [dbo].[ProductManagersAudit] (
    [ID]                 INT            IDENTITY (1, 1) NOT NULL,
    [ProductID]   NVARCHAR (800) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [ProductManagerName] NVARCHAR (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [InsertTime]         DATETIME       NOT NULL,
    [Action]             CHAR (1)       COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[UserID] [int] NOT NULL
);

