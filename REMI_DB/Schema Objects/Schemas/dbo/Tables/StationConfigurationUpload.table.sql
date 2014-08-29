CREATE TABLE [dbo].[StationConfigurationUpload](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[StationConfigXML] [xml] NOT NULL,
	[IsProcessed] [bit] NOT NULL,
	[TrackingLocationHostID] [int] NOT NULL,
	[LastUser] [nvarchar](255) NOT NULL,
	[TrackingLocationPluginID] [int] NULL,
 CONSTRAINT [PK_StationConfigurationUpload] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO