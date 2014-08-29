CREATE TABLE [dbo].[Users] (
    [ID]            INT            IDENTITY (1, 1) NOT NULL,
    [LDAPLogin]     NVARCHAR (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [BadgeNumber]   INT            NULL,
    [ConcurrencyID] TIMESTAMP      NOT NULL,
    [LastUser]      NVARCHAR (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [TestCentreID]  INT NULL,
	[IsActive] [int] NOT NULL,
	DefaultPage nvarchar(255) NULL,
	ByPassProduct INT NULL
);
GO
ALTER TABLE [dbo].[Users] ADD  DEFAULT ((1)) FOR [IsActive]
GO