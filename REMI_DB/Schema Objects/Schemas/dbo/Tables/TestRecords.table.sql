CREATE TABLE [dbo].[TestRecords] (
    [ID]            INT             IDENTITY (1, 1) NOT NULL,
    [TestUnitID]    INT             NOT NULL,
    [TestName]      NVARCHAR (400)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [TestStageName] NVARCHAR (400)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [JobName]       NVARCHAR (400)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [Status]        INT             NOT NULL,
    [FailDocNumber] NVARCHAR (500)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [ConcurrencyID] TIMESTAMP       NOT NULL,
    [Comment]       NVARCHAR (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [RelabVersion]  INT             NULL,
    [LastUser]      NVARCHAR (255)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [ResultSource]  INT             NULL,
    [FailDocRQID]   INT             NULL,
	[TestID]		INT				NULL,
	[TestStageID]	INT				NULL,
	FunctionalType	INT				NULL
);

