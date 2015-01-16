CREATE TABLE [Relab].[ResultsStatus](
	[ResultStatusID] [int] IDENTITY(1,1) NOT NULL,
	[BatchID] [int] NOT NULL,
	[PassFail] [int] NULL,
	[ApprovedBy] [nvarchar](255) NULL,
	[ApprovedDate] [datetime] NULL,
 CONSTRAINT [PK_ResultsStatus] PRIMARY KEY CLUSTERED 
(
	[ResultStatusID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]