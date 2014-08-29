CREATE TABLE [dbo].[TestsAudit] (
    [ID]                INT             IDENTITY (1, 1) NOT NULL,
    [TestID]            INT             NULL,
    [TestName]          NVARCHAR (400)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [Duration]          REAL            NULL,
    [TestType]          INT             NULL,
    [WILocation]        NVARCHAR (800)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [Comment]           NVARCHAR (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [UserName]          NVARCHAR (255)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [InsertTime]        DATETIME        NULL,
    [Action]            CHAR (1)        COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [ResultBasedOnTime] BIT             NULL,
	DegradationVal DECIMAL(10,3) NULL,
);

