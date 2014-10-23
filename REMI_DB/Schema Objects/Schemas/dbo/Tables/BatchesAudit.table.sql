﻿CREATE TABLE [dbo].[BatchesAudit] (
    [ID]                        INT             IDENTITY (1, 1) NOT NULL,
    [BatchID]                   INT             NOT NULL,
    [QRANumber]                 NVARCHAR (11)   COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [Priority]                  INT             NOT NULL,
    [BatchStatus]               INT             NOT NULL,
    [JobName]                   NVARCHAR (255)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [TestStageName]             NVARCHAR (255)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [ProductID]         INT COLLATE SQL_Latin1_General_CP1_CI_AS  NULL,
	AccessoryGroupID		INT	NULL,
	ProductTypeID			INT NULL,
    [Comment]                   NVARCHAR (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [UserName]                  NVARCHAR (255)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [InsertTime]                DATETIME        NOT NULL,
    [Action]                    CHAR (1)        COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [TestCenterLocationID]        INT  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [RequestPurpose]            INT             NOT NULL,
    [RFBands]                   NVARCHAR (400)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [TestStageCompletionStatus] INT             NULL,
	[IsMQual]						BIT	NULL,
	ExecutiveSummary NVARCHAR(4000) NULL,
	MechanicalTools NVARCHAR(10) NULL,
	[Order] INT NULL,
	[DepartmentID] INT NULL,
);