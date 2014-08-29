CREATE TABLE [dbo].[ProductTestReady](
	[ProductID] [int] NOT NULL,
	[TestID] [int] NOT NULL,
	[PSID] [int] NOT NULL,
	[Comment] [ntext] NULL,
	[IsReady] [int] NULL,
	[ID] [int] IDENTITY(1,1) NOT NULL,
	IsNestReady [int] NULL,
	);