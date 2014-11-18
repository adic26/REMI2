CREATE TABLE [dbo].[MenuDepartment](
	[MenuDepartmentID] [int] IDENTITY(1,1) NOT NULL,
	[DepartmentID] [int] NOT NULL,
	[MenuID] [int] NOT NULL,
 CONSTRAINT [PK_MenuDepartment] PRIMARY KEY CLUSTERED 
(
	[MenuDepartmentID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[MenuDepartment]  WITH CHECK ADD  CONSTRAINT [FK_MenuDepartment_Lookups] FOREIGN KEY([DepartmentID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO

ALTER TABLE [dbo].[MenuDepartment] CHECK CONSTRAINT [FK_MenuDepartment_Lookups]
GO

ALTER TABLE [dbo].[MenuDepartment]  WITH CHECK ADD  CONSTRAINT [FK_MenuDepartment_Menu] FOREIGN KEY([MenuID])
REFERENCES [dbo].[Menu] ([MenuID])
GO

ALTER TABLE [dbo].[MenuDepartment] CHECK CONSTRAINT [FK_MenuDepartment_Menu]
GO