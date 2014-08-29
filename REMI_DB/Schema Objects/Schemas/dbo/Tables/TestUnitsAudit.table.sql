CREATE TABLE [dbo].[TestUnitsAudit] (
    [ID]                   INT             IDENTITY (1, 1) NOT NULL,
    [testUnitID]           INT             NOT NULL,
    [BatchID]              INT             NOT NULL,
    [BSN]                  BIGINT          NULL,
    [BatchUnitNumber]      INT             NOT NULL,
    [CurrentTestName]      NVARCHAR (400)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [CurrentTestStageName] NVARCHAR (400)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [AssignedTo]           NVARCHAR (255)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [Comment]              NVARCHAR (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [UserName]             NVARCHAR (255)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [InsertTime]           DATETIME        NOT NULL,
    [Action]               CHAR (1)        COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
);

