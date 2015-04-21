CREATE TABLE [dbo].[Calibration]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[LookupID] [int] NOT NULL,
[HostID] [int] NOT NULL,
[DateCreated] [datetime] NOT NULL,
[Name] [nvarchar] (150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[File] [xml] NOT NULL,
[TestID] [int] NOT NULL,
[LastUser] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
)