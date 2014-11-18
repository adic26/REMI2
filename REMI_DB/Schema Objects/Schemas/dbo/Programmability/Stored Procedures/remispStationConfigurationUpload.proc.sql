ALTER PROCEDURE [dbo].remispStationConfigurationUpload @HostID INT, @XML AS NTEXT, @LastUser As NVARCHAR(255), @PluginID INT = 0
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM StationConfigurationUpload WHERE TrackingLocationHostID=@HostID And TrackingLocationPluginID=@PluginID)
		INSERT INTO StationConfigurationUpload (StationConfigXML, TrackingLocationHostID, LastUser, TrackingLocationPluginID) Values (CONVERT(XML, @XML), @HostID, @LastUser, @PluginID)
END
GO
GRANT EXECUTE ON remispStationConfigurationUpload TO REMI
GO