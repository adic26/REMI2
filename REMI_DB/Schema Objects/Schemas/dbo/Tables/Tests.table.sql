CREATE TABLE [dbo].[Tests] (
    [ID]                INT             IDENTITY (1, 1) NOT NULL,
    [TestName]          NVARCHAR (400)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [Duration]          REAL            NOT NULL,
    [TestType]          INT             NOT NULL,
    [WILocation]        NVARCHAR (800)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [Comment]           NVARCHAR (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [ConcurrencyID]     TIMESTAMP       NOT NULL,
    [LastUser]          NVARCHAR (255)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [ResultBasedOntime] BIT             NULL,
	[IsArchived]	BIT	DEFAULT(0)	NULL,
	Owner NVARCHAR(255) NULL,
	Trainee NVARCHAR(255) NULL,
	DegradationVal DECIMAL(10,3) NULL,
);

