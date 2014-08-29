CREATE TABLE [dbo].[TrackingLocationsPlugin]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[TrackingLocationID] [int] NOT NULL,
[PluginName] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
)