CREATE TABLE [dbo].[Jobs] (
    [ID]                      INT             IDENTITY (1, 1) NOT NULL,
    [JobName]                 NVARCHAR (400)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [WILocation]              NVARCHAR (400)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [Comment]                 NVARCHAR (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [LastUser]                NVARCHAR (255)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [ConcurrencyID]           TIMESTAMP       NOT NULL,
    [OperationsTest]          BIT             NOT NULL,
    [MechanicalTest]          BIT             NOT NULL,
    [TechnicalOperationsTest] BIT             NOT NULL,
	[ProcedureLocation]              NVARCHAR (400)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[IsActive]	BIT	DEFAULT(1)	NULL,
	[NoBSN]	BIT	DEFAULT(0)	NULL,
	[ContinueOnFailures]	BIT	DEFAULT(0)	NULL,
);

