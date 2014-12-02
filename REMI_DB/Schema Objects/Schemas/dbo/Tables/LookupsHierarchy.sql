CREATE TABLE [dbo].[LookupsHierarchy](
	[LookupsHierarchyID] [int] IDENTITY(1,1) NOT NULL,
	[ParentLookupTypeID] [int] NOT NULL,
	[ChildLookupTypeID] [int] NOT NULL,
	[ParentLookupID] [int] NOT NULL,
	[ChildLookupID] [int] NOT NULL,
	[RequestTypeID] [int] NOT NULL,
 CONSTRAINT [PK_LookupsHierarchy] PRIMARY KEY CLUSTERED 
(
	[LookupsHierarchyID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[LookupsHierarchy]  WITH CHECK ADD  CONSTRAINT [FK_LookupsHierarchy_Lookups] FOREIGN KEY([ParentLookupID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO

ALTER TABLE [dbo].[LookupsHierarchy] CHECK CONSTRAINT [FK_LookupsHierarchy_Lookups]
GO

ALTER TABLE [dbo].[LookupsHierarchy]  WITH CHECK ADD  CONSTRAINT [FK_LookupsHierarchy_Lookups1] FOREIGN KEY([ChildLookupID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO

ALTER TABLE [dbo].[LookupsHierarchy] CHECK CONSTRAINT [FK_LookupsHierarchy_Lookups1]
GO

ALTER TABLE [dbo].[LookupsHierarchy]  WITH CHECK ADD  CONSTRAINT [FK_LookupsHierarchy_LookupType] FOREIGN KEY([ParentLookupTypeID])
REFERENCES [dbo].[LookupType] ([LookupTypeID])
GO

ALTER TABLE [dbo].[LookupsHierarchy] CHECK CONSTRAINT [FK_LookupsHierarchy_LookupType]
GO

ALTER TABLE [dbo].[LookupsHierarchy]  WITH CHECK ADD  CONSTRAINT [FK_LookupsHierarchy_LookupType1] FOREIGN KEY([ChildLookupTypeID])
REFERENCES [dbo].[LookupType] ([LookupTypeID])
GO

ALTER TABLE [dbo].[LookupsHierarchy] CHECK CONSTRAINT [FK_LookupsHierarchy_LookupType1]
GO

ALTER TABLE [dbo].[LookupsHierarchy]  WITH CHECK ADD  CONSTRAINT [FK_LookupsHierarchy_RequestType] FOREIGN KEY([RequestTypeID])
REFERENCES [Req].[RequestType] ([RequestTypeID])
GO

ALTER TABLE [dbo].[LookupsHierarchy] CHECK CONSTRAINT [FK_LookupsHierarchy_RequestType]
GO