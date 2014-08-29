CREATE TABLE [dbo].[TestExceptionsAudit](
	[ID] [int] NOT NULL,
	[LookupID] [int] NOT NULL,
	[Value] [nvarchar](150) NOT NULL,
	[UserName] [nvarchar](255) NOT NULL,
	[InsertTime] [datetime] NOT NULL,
	[Action] [char](1) NOT NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'For Tests this could be ID OR TestName. If for ID it should apply to that one TEST. If by TestName then all tests that have that name' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TestExceptionsAudit', @level2type=N'COLUMN',@level2name=N'Value'
GO