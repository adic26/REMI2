CREATE TABLE [Relab].[ResultsMeasurementsAudit](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ResultMeasurementID] [int] NOT NULL,
	[PassFail] [bit] NULL,
	[Comment] [nvarchar](400) NULL,
	[LastUser] [nvarchar](255) NULL,
	[DateEntered] [datetime] NULL,
 CONSTRAINT [PK_ResultsMeasurementsAudit] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [Relab].[ResultsMeasurementsAudit]  WITH CHECK ADD  CONSTRAINT [FK_ResultsMeasurementsAudit_ResultsMeasurements] FOREIGN KEY([ResultMeasurementID])
REFERENCES [Relab].[ResultsMeasurements] ([ID])
GO

ALTER TABLE [Relab].[ResultsMeasurementsAudit] CHECK CONSTRAINT [FK_ResultsMeasurementsAudit_ResultsMeasurements]
GO

ALTER TABLE [Relab].[ResultsMeasurementsAudit] ADD  DEFAULT (getdate()) FOR [DateEntered]
GO
