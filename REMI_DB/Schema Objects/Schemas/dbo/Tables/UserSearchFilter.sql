CREATE TABLE [dbo].[UserSearchFilter](
	[UserID] [int] NOT NULL,
	[RequestTypeID] [int] NOT NULL,
	[ColumnName] [nvarchar](255) NOT NULL,
	[FilterType] [int] NOT NULL,
	[SortOrder] [int] NOT NULL,
 CONSTRAINT [PK_UserSearchFilter] PRIMARY KEY CLUSTERED 
(
	[UserID] ASC,
	[RequestTypeID] ASC,
	[ColumnName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[UserSearchFilter]  WITH CHECK ADD  CONSTRAINT [FK_UserSearchFilter_RequestType] FOREIGN KEY([RequestTypeID])
REFERENCES [Req].[RequestType] ([RequestTypeID])
GO

ALTER TABLE [dbo].[UserSearchFilter] CHECK CONSTRAINT [FK_UserSearchFilter_RequestType]
GO

ALTER TABLE [dbo].[UserSearchFilter]  WITH CHECK ADD  CONSTRAINT [FK_UserSearchFilter_Users] FOREIGN KEY([UserID])
REFERENCES [dbo].[Users] ([ID])
GO

ALTER TABLE [dbo].[UserSearchFilter] CHECK CONSTRAINT [FK_UserSearchFilter_Users]
GO