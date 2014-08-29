CREATE TABLE [dbo].[TrackingLocationsHostsConfigurationAudit](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[TrackingConfigID] [int] NOT NULL,
	[TrackingLocationHostID] [int] NOT NULL,
	[ParentID] [int] NULL,
	[ViewOrder] [int] NULL,
	[NodeName] [nvarchar](200) NOT NULL,
	[UserName] [nvarchar](255) NULL,
	[InsertTime] [datetime] NOT NULL,
	[Action] [char](1) NOT NULL,
 CONSTRAINT [PK_TrackingLocationsHostsConfigurationAudit] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].TrackingLocationsHostsConfigurationAudit 
ADD  CONSTRAINT [DF_TrackingLocationsHostsConfigurationAudit_InsertTime]  DEFAULT (getutcdate()) FOR [InsertTime]
GO
