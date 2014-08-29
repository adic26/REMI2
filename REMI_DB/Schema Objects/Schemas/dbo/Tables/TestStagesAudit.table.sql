CREATE TABLE [dbo].[TestStagesAudit] (
    [ID]            INT             IDENTITY (1, 1) NOT NULL,
    [TestStageID]   INT             NOT NULL,
    [TestStageName] NVARCHAR (400)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [TestStageType] INT             NOT NULL,
    [JobID]         INT             NOT NULL,
    [TestID]        INT             NULL,
    [Comment]       NVARCHAR (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [UserName]      NVARCHAR (255)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [InsertTime]    DATETIME        NOT NULL,
    [Action]        CHAR (1)        COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [ProcessOrder]  INT             NULL,
	[IsArchived]	BIT				NULL
);

