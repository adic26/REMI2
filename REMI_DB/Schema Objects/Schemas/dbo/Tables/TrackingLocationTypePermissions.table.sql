CREATE TABLE [dbo].[TrackingLocationTypePermissions] (
    [ID]                     INT            IDENTITY (1, 1) NOT NULL,
    [ConcurrencyID]          TIMESTAMP      NOT NULL,
    [LastUser]               NVARCHAR (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [TrackingLocationTypeID] INT            NOT NULL,
    [PermissionBitMask]      INT            NOT NULL,
    [Username]               NVARCHAR (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
);

