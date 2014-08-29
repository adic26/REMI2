CREATE TABLE [Relab].[ResultsParameters](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ResultMeasurementID] [int] NOT NULL,
	[ParameterName] [nvarchar](255) NOT NULL,
	[Value] [nvarchar](250) NOT NULL,
 CONSTRAINT [PK_ResultsParameters] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]