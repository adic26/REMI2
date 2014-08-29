CREATE TABLE [dbo].[TrackingLocationsHostsConfiguration](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[TrackingLocationHostID] [int] NOT NULL,
	[ParentID] [int] NULL,
	[ViewOrder] [int] NULL,
	[NodeName] [nvarchar](200) NOT NULL,
	[LastUser] [nvarchar](255) NULL,
	TrackingLocationProfileID INT NULL,
 CONSTRAINT [PK_TrackingLocationsHostsConfiguration] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
GRANT ALTER ON dbo.TrackingLocationsHostsConfiguration TO remi
GO
GRANT INSERT ON dbo.TrackingLocationsHostsConfiguration TO remi
GO