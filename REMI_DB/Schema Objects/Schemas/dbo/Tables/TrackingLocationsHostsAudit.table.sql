CREATE TABLE [dbo].[TrackingLocationsHostsAudit](
	[TrackingLocationID] [int] NOT NULL,
	[HostName] [nvarchar](255) NOT NULL,
	[Action] [nchar](1) NOT NULL,
	[InsertTime] [datetime] NOT NULL,
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[UserName] [nvarchar](255) NOT NULL,
	 CONSTRAINT [PK_TrackingLocationsHostsAudit] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)
	)
	GO
	ALTER TABLE [dbo].[TrackingLocationsHostsAudit] ADD  CONSTRAINT [DF_TrackingLocationsHostAudit_InsertTime]  DEFAULT (getutcdate()) FOR [InsertTime]
GO