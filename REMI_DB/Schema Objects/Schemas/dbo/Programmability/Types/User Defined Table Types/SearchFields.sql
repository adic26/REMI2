CREATE TYPE [dbo].[SearchFields] AS TABLE(
	[TableType] [nvarchar](25) NOT NULL,
	[ID] [int] NOT NULL,
	[SearchTerm] [nvarchar](255) NOT NULL,
	[ColumnName] [nvarchar](255) NULL
)