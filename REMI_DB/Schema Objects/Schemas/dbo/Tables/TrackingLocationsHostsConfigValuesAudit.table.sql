CREATE TABLE [dbo].[TrackingLocationsHostsConfigValuesAudit](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[HostConfigID] INT NOT NULL,
	[Value] [nvarchar](250) NOT NULL,
	[LookupID] [int] NOT NULL,
	[TrackingConfigID] [int] NOT NULL,
	[LastUser] [nvarchar](255) NOT NULL,
	[IsAttribute] [bit] NOT NULL,
	[Action] CHAR(1) NOT NULL,
	InsertTime DateTime NOT NULL
 CONSTRAINT [PK_TrackingLocationsHostsConfigValuesAudit] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[TrackingLocationsHostsConfigValuesAudit] ADD  CONSTRAINT [DF_TrackingLocationsHostsConfigValuesAudit_InsertTime]  DEFAULT (getutcdate()) FOR [InsertTime]
GO