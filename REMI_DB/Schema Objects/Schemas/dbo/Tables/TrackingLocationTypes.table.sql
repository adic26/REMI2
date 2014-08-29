CREATE TABLE [dbo].[TrackingLocationTypes] (
    [ID]                       INT             IDENTITY (1, 1) NOT NULL,
    [TrackingLocationTypeName] NVARCHAR (400)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [TrackingLocationFunction] INT             NOT NULL,
    [Comment]                  NVARCHAR (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [WILocation]               NVARCHAR (400)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [UnitCapacity]             INT             NOT NULL,
    [ConcurrencyID]            TIMESTAMP       NOT NULL,
    [LastUser]                 NVARCHAR (255)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
);

