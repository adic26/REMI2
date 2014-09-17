CREATE TABLE [dbo].[JobOrientation](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[JobID] [int] NOT NULL,
	[ProductTypeID] [int] NOT NULL,
	[NumUnits] [int] NOT NULL,
	[NumDrops] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[Description] [nvarchar](250) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Definition] [xml] NOT NULL,
	[Name] [nvarchar](150) NOT NULL,
 CONSTRAINT [PK_JobOrientation] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[JobOrientation] ADD  CONSTRAINT [DF_JobOrientation_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[JobOrientation] ADD  CONSTRAINT [DF_JobOrientation_CreatedDate]  DEFAULT (getutcdate()) FOR [CreatedDate]
GO