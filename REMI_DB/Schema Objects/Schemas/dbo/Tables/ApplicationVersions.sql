CREATE TABLE [dbo].[ApplicationVersions](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[AppID] [int] NOT NULL,
	[VerNum] [nvarchar](150) NOT NULL,
	[ApplicableToAll] [bit] NOT NULL,
 CONSTRAINT [PK_ApplicationVersions] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ApplicationVersions] CHECK CONSTRAINT [FK_ApplicationVersions_Applications]
GO
ALTER TABLE [dbo].[ApplicationVersions] ADD  CONSTRAINT [DF_ApplicationVersions_ApplicableToAll]  DEFAULT ((0)) FOR [ApplicableToAll]
GO