CREATE TABLE [dbo].[BatchSpecificTestDurations] (
    [ID]            INT            IDENTITY (1, 1) NOT NULL,
    [BatchID]       INT            NOT NULL,
    [TestID]        INT            NOT NULL,
    [Duration]      REAL           NOT NULL,
    [LastUser]      NVARCHAR (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [ConcurrencyId] TIMESTAMP      NOT NULL,
    [Comment]       NVARCHAR (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
);

