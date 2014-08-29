CREATE TABLE [dbo].[TestRecordsAudit] (
    [ID]            INT             IDENTITY (1, 1) NOT NULL,
    [TestRecordId]  INT             NOT NULL,
    [TestUnitID]    INT             NOT NULL,
    [TestName]      NVARCHAR (255)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [TestStageName] NVARCHAR (255)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [JobName]       NVARCHAR (255)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [Status]        INT             NOT NULL,
    [FailDocNumber] NVARCHAR (100)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [RelabVersion]  INT             NULL,
    [Comment]       NVARCHAR (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [UserName]      NVARCHAR (255)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [Action]        CHAR (1)        COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [InsertTime]    DATETIME        NULL,
    [ResultSource]  INT             NULL,
	[TestID]		INT				NULL,
	[TestStageID]	INT				NULL,
	FunctionalType	INT				NULL
);

