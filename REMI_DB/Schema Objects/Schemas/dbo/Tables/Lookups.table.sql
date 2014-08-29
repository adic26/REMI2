CREATE TABLE [dbo].[Lookups](
	[LookupID] [int] NOT NULL,
	[Type] [nvarchar](150) NOT NULL,
	[Values] [nvarchar](150) NOT NULL,
	[IsActive] [int] NOT NULL,)
GO
ALTER TABLE [dbo].[Lookups] ADD  DEFAULT ((1)) FOR [IsActive]
GO