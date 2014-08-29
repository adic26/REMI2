CREATE TABLE [dbo].[BatchSpecificTestDurationsAudit] (
    [ID]                          INT            IDENTITY (1, 1) NOT NULL,
    [BatchSpecificTestDurationID] INT            NOT NULL,
    [BatchId]                     INT            NOT NULL,
    [TestID]                      INT            NOT NULL,
    [Duration]                    REAL           NOT NULL,
    [UserName]                    NVARCHAR (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [InsertTime]                  DATETIME       NOT NULL,
    [Action]                      CHAR (1)       COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [Comment]                     NVARCHAR (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
);

