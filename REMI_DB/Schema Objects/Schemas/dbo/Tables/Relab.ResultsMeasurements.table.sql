CREATE TABLE [Relab].[ResultsMeasurements](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ResultID] [int] NOT NULL,
	[MeasurementTypeID] [int] NOT NULL,
	[LowerLimit] [nvarchar](255) NULL,
	[UpperLimit] [nvarchar](255) NULL,
	[MeasurementValue] [nvarchar](500) NOT NULL,
	[MeasurementUnitTypeID] [int] NULL,
	[PassFail] [bit] NOT NULL,
	[ReTestNum] [int] NOT NULL,
	[Archived] [bit] NOT NULL,
	[XMLID] [int] NULL,
	[Comment] [nvarchar](400) NULL,
	Description NVARCHAR(800) NULL,
	LastUser NVARCHAR(255) NULL,
	DegradationVal DECIMAL(10,3) NULL,
 CONSTRAINT [PK_ResultsMeasurements] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]