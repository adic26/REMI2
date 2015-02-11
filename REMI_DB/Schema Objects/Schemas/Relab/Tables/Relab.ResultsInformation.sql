CREATE TABLE [Relab].[ResultsInformation](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[XMLID] [int] NOT NULL,
	[Name] [nvarchar](255) NOT NULL,
	[Value] [nvarchar](500) NOT NULL,
	[IsArchived] [bit] NOT NULL,
	[rv] [timestamp] NOT NULL,
	[ConfigID] [int] NULL,
 CONSTRAINT [PK_ResultsInformation] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [Relab].[ResultsInformation]  WITH CHECK ADD  CONSTRAINT [FK_ResultsInformation_ResultsXML] FOREIGN KEY([XMLID])
REFERENCES [Relab].[ResultsXML] ([ID])
GO

ALTER TABLE [Relab].[ResultsInformation] CHECK CONSTRAINT [FK_ResultsInformation_ResultsXML]
GO

ALTER TABLE [Relab].[ResultsInformation] ADD  CONSTRAINT [DF_ResultsInformation_IsArchived]  DEFAULT ((0)) FOR [IsArchived]
GO
