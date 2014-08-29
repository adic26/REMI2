CREATE TABLE [dbo].[TestStages] (
    [ID]            INT             IDENTITY (1, 1) NOT NULL,
    [TestStageName] NVARCHAR (400)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [TestStageType] INT             NOT NULL,
    [JobID]         INT             NOT NULL,
    [LastUser]      NVARCHAR (255)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [Comment]       NVARCHAR (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [ConcurrencyID] TIMESTAMP       NOT NULL,
    [TestID]        INT             NULL,
    [ProcessOrder]  INT             NULL,
	[IsArchived]	BIT	DEFAULT(0)	NULL
);

