begin tran

alter table batches add TestCenterLocationID INT NULL
GO
alter table batchesAudit add TestCenterLocationID INT NULL
GO
alter table Lookups add IsActive INT NULL DEFAULT(1)
GO
UPDATE Lookups SET IsActive=1
GO
alter table Lookups alter column IsActive INT NOT NULL 
GO
alter table ProductConfigValues Add [IsAttribute] BIT NULL DEFAULT(0)
GO
alter table ProductConfigValuesAudit Add [IsAttribute] BIT NULL 
GO
alter table TrackingLocations Add [Decommissioned] BIT NULL DEFAULT(0)
GO
alter table TrackingLocations Add [TestCenterLocationID] INT NULL
GO
alter table TrackingLocationsAudit Add [TestCenterLocationID] INT NULL
GO
alter table BatchesAudit alter column _TestCenterLocation nvarchar(255) NULL
GO
alter table TrackingLocationsAudit alter column _GeoLocationName nvarchar(255) NULL
GO
alter table Batches alter column _TestCenterLocation nvarchar(400) NULL
GO
alter table TrackingLocations alter column _GeoLocationName nvarchar(200) NULL
GO

CREATE TABLE [dbo].[ProductConfigurationUpload](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ProductConfigXML] [xml] NOT NULL,
	[IsProcessed] [bit] NOT NULL,
	[ProductID] [int] NOT NULL,
	[TestID] [int] NOT NULL,
	[LastUser] [nvarchar](255) NOT NULL,
 CONSTRAINT [PK_ProductConfigurationUpload] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[ProductConfigurationUpload] ADD  CONSTRAINT [ProductConfigurationUpload_isProcessed]  DEFAULT ((0)) FOR [IsProcessed]
GO



rollback tran