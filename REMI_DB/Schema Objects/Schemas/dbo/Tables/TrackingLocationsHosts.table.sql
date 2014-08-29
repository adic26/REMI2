CREATE TABLE [dbo].[TrackingLocationsHosts](
	[TrackingLocationID] [int] NOT NULL,
	[HostName] [nvarchar](255) NOT NULL,
	[LastUser] [nvarchar](255) NOT NULL,
	[Status] [int] NULL,
	[ID] [int] IDENTITY(1,1) NOT NULL
	)
