CREATE TABLE [dbo].[UserTraining](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[DateAdded] [datetime] NOT NULL,
	[LookupID] [int] NOT NULL,
	[UserID] [INT] NOT NULL,
	[LevelLookupID] [int] NULL,
	[ConfirmDate] [datetime] NULL,
	[UserAssigned] NVARCHAR(255) NULL,
 CONSTRAINT [PK_UserTraining] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO