CREATE TABLE [dbo].[TestsAccess](
	[TestAccessID] [int] IDENTITY(1,1) NOT NULL,
	[TestID] [int] NOT NULL,
	[LookupID] [int] NOT NULL,
 CONSTRAINT [PK_TestsAccess] PRIMARY KEY CLUSTERED 
(
	[TestAccessID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[TestsAccess]  WITH CHECK ADD  CONSTRAINT [FK_TestsAccess_Tests] FOREIGN KEY([TestID])
REFERENCES [dbo].[Tests] ([ID])
GO

ALTER TABLE [dbo].[TestsAccess] CHECK CONSTRAINT [FK_TestsAccess_Tests]
GO

ALTER TABLE [dbo].[TestsAccess]  WITH CHECK ADD  CONSTRAINT [FK_TestsAccess_Lookups] FOREIGN KEY([LookupID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO

ALTER TABLE [dbo].[TestsAccess] CHECK CONSTRAINT [FK_TestsAccess_Lookups]
GO


