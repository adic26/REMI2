CREATE TABLE [dbo].[TestExceptions](
	[ID] [int] NOT NULL,
	[LookupID] [int] NOT NULL,
	[Value] [nvarchar](150) NOT NULL,
	[ConcurrencyID] [timestamp] NOT NULL,
	[LastUser] [nvarchar](255) NULL,
	[OldID] [int] NULL,
	[InsertTime] [datetime] NULL
	) ON [PRIMARY]

GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'For Tests this could be ID OR TestName. If for ID it should apply to that one TEST. If by TestName then all tests that have that name' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TestExceptions', @level2type=N'COLUMN',@level2name=N'Value'
GO
