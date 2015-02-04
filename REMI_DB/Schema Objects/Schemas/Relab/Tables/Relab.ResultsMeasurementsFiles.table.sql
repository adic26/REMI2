CREATE TABLE [Relab].[ResultsMeasurementsFiles](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ResultMeasurementID] [int] NULL,
	[File] [varbinary](max) NOT NULL,
	[ContentType] [nvarchar](50) NOT NULL,
	[FileName] [nvarchar](200) NOT NULL,
	rv ROWVERSION,
 CONSTRAINT [PK_ResultsMeasurementsFiles] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]