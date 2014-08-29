CREATE TABLE [dbo].[UserTrainingAudit](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[TrainingID] [int] NOT NULL,
	[LookupID] [int] NOT NULL,
	[UserID] [int] NOT NULL,
	[LevelLookupID] [int] NULL,
	[ConfirmDate] [datetime] NULL,
	[Action] [char](1) NOT NULL,
	[InsertTime] [datetime] NOT NULL,
	[UserName] [nvarchar](255) NOT NULL,
 CONSTRAINT [PK_UserTrainingAudit] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]