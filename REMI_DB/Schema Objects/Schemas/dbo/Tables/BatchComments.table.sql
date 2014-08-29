CREATE TABLE [dbo].[BatchComments] (
    [ID]        INT            IDENTITY (1, 1) NOT NULL,
    [Text]      NVARCHAR (MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [LastUser]  NVARCHAR (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [DateAdded] DATETIME       NOT NULL,
    [BatchID]   INT            NOT NULL,
    [Active]    BIT            NOT NULL
);

