CREATE TABLE [dbo].[DeviceTrackingLog] (
    [ID]                 INT            IDENTITY (1, 1) NOT NULL,
    [TestUnitID]         INT            NOT NULL,
    [TrackingLocationID] INT            NOT NULL,
    [InTime]             DATETIME       NULL,
    [InUser]             NVARCHAR (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [OutTime]            DATETIME       NULL,
    [OutUser]            NVARCHAR (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [ConcurrencyID]      TIMESTAMP      NOT NULL
);

