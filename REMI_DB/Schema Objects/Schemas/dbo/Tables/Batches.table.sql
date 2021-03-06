﻿CREATE TABLE [dbo].[Batches] (
    [ID]                           INT             IDENTITY (1, 1) NOT NULL,
    [QRANumber]                    NVARCHAR (11)   COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [Priority]                     INT             NOT NULL,
    [BatchStatus]                  INT             NOT NULL,
    [JobName]                      NVARCHAR (400)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [TestStageName]                NVARCHAR (400)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [ProductID]             INT  COLLATE SQL_Latin1_General_CP1_CI_AS  NULL,
	AccessoryGroupID		INT	NULL,
	ProductTypeID			INT NULL,
    [RequestPurpose]               INT             NOT NULL,
    [TestCenterLocationID]           INT  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [Comment]                      NVARCHAR (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [ConcurrencyID]                TIMESTAMP       NOT NULL,
    [LastUser]                     NVARCHAR (255)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [RFBands]                      NVARCHAR (400)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [TestStageCompletionStatus]    INT             NULL,
    [Requestor]                    NVARCHAR (500)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [UnitsToBeReturnedToRequestor] BIT             NULL,
    [ExpectedSampleSize]           INT             NULL,
    [RelabJobID]                   INT             NULL,
    [ReportApprovedDate]           DATETIME        NULL,
    [ReportRequiredBy]             DATETIME        NULL,
    [RQID]                         INT             NULL,
    [PartName]                     NVARCHAR (500)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [AssemblyNumber]               NVARCHAR (500)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [AssemblyRevision]             NVARCHAR (500)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [TRSStatus]                    NVARCHAR (500)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [CPRNumber]                    NVARCHAR (500)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [HWRevision]                   NVARCHAR (500)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [PMNotes]                      NVARCHAR (MAX)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[IsMQual]						BIT	NULL,
	DateCreated					DateTime,
	ExecutiveSummary NVARCHAR(4000) NULL,
	MechanicalTools NVARCHAR(10) NULL,
	[Order] INT NULL DEFAULT(0),
	[DepartmentID] INT NULL,
);

GO
ALTER TABLE [Batches]  WITH CHECK ADD  CONSTRAINT [FK_Batches_Request] FOREIGN KEY([QRANumber])
REFERENCES Req.Request ([RequestNumber])

ALTER TABLE [Batches] CHECK CONSTRAINT [FK_Batches_Request]
GO