CREATE TABLE [dbo].[TrackingLocationTypesAudit] (
    [ID]                       INT             IDENTITY (1, 1) NOT NULL,
    [TrackingLocationTypeId]   INT             NOT NULL,
    [TrackingLocationTypeName] NVARCHAR (400)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [TrackingLocationFunction] INT             NOT NULL,
    [WILocation]               NVARCHAR (800)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [UnitCapacity]             INT             NOT NULL,
    [UserName]                 NVARCHAR (255)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [Comment]                  NVARCHAR (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [InsertTime]               DATETIME        NOT NULL,
    [Action]                   CHAR (1)        COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
);

