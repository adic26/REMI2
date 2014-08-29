CREATE TABLE [dbo].[TrackingLocations] (
    [ID]                     INT             IDENTITY (1, 1) NOT NULL,
    [TrackingLocationName]   NVARCHAR (400)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [TrackingLocationTypeID] INT             NOT NULL,
    [TestCenterLocationID]   INT  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [Comment]                NVARCHAR (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [ConcurrencyID]          TIMESTAMP       NOT NULL,
    [LastUser]               NVARCHAR (255)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	IsMultiDeviceZone		BIT		DEFAULT(0) NOT NULL,
	Decommissioned		BIT		DEFAULT(0) NOT NULL,
	Status				INT			NULL
);

