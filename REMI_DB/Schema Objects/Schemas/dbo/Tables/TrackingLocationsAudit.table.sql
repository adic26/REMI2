CREATE TABLE [dbo].[TrackingLocationsAudit] (
    [ID]                     INT             IDENTITY (1, 1) NOT NULL,
    [TrackingLocationId]     INT             NOT NULL,
    [TrackingLocationName]   NVARCHAR (255)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [TrackingLocationTypeID] INT             NOT NULL,
    [TestCenterLocationID]   INT COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [Comment]                NVARCHAR (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [UserName]               NVARCHAR (255)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [InsertTime]             DATETIME        NOT NULL,
    [Action]                 CHAR (1)        COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	IsMultiDeviceZone		BIT		DEFAULT(0) NOT NULL
);

