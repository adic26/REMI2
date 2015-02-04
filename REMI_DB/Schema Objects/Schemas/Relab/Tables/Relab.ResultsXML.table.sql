CREATE TABLE [Relab].[ResultsXML](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ResultID] [int] NOT NULL,
	[ResultXML] [xml] NOT NULL,
	[VerNum] [int] NOT NULL,
	[isProcessed] [int] NULL,
	[StationName] [nvarchar](400) NULL,
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL,
	[lossFile] [xml] NULL,
	rv ROWVERSION,
 CONSTRAINT [PK_Relab.ResultXML] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]