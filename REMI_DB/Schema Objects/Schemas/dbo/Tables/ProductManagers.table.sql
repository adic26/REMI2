CREATE TABLE [dbo].[ProductManagers] (
    [ID]           INT            IDENTITY (1, 1) NOT NULL,
    [ProductID] INT COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [LastUser]     NVARCHAR (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[UserID] [int] NOT NULL
);

