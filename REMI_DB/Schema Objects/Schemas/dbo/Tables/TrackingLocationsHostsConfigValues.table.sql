CREATE TABLE [dbo].[TrackingLocationsHostsConfigValues](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Value] [nvarchar](250) NOT NULL,
	[LookupID] [int] NOT NULL,
	[TrackingConfigID] [int] NOT NULL,
	[LastUser] [nvarchar](255) NOT NULL,
	[IsAttribute] [bit] NOT NULL,
 CONSTRAINT [PK_TrackingLocationsHostsConfigValues] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
go
GRANT ALTER ON dbo.TrackingLocationsHostsConfigValues TO remi
go
GRANT INSERT ON dbo.TrackingLocationsHostsConfigValues TO remi
go