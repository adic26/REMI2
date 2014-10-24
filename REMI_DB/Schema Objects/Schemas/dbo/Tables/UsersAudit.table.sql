CREATE TABLE [dbo].[UsersAudit] (
    [ID]          INT            IDENTITY (1, 1) NOT NULL,
    [UserID]      INT            NOT NULL,
    [LDAPLogin]   NVARCHAR (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [BadgeNumber] INT            NULL,
    [UserName]    NVARCHAR (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [InsertTime]  DATETIME       NOT NULL,
    [Action]      CHAR (1)       COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [TestCentreID] INT NULL,
	[IsActive] [int] NULL,
	DefaultPage nvarchar(255) NULL,
	ByPassProduct INT NULL,
	DepartmentID INT NULL
);

