CREATE TABLE [dbo].[Lookups](
	[LookupID] [int] NOT NULL,
	[LookupTypeID] [int] NOT NULL,
	[Values] [nvarchar](150) NOT NULL,
	[IsActive] [int] NOT NULL,
	[Description] [NVARCHAR](200) NULL,
	[ParentID] [int] NULL)
GO
ALTER TABLE [dbo].[Lookups] ADD  DEFAULT ((1)) FOR [IsActive]
GO