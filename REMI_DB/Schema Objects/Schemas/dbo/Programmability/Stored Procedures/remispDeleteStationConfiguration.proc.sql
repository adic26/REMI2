ALTER PROCEDURE [dbo].[remispDeleteStationConfiguration] @HostID INT, @LastUser NVARCHAR(255), @PluginID INT
AS
BEGIN
	IF (@PluginID = 0)
		SET @PluginID = NULL

	UPDATE TrackingLocationsHostsConfigValues
	SET LastUser=@LastUser
	WHERE TrackingConfigID IN (SELECT ID FROM TrackingLocationsHostsConfiguration WHERE TrackingLocationHostID=@HostID AND ((@PluginID IS NULL AND TrackingLocationProfileID IS NULL) OR (TrackingLocationProfileID=@PluginID AND @PluginID IS NOT NULL)))
	
	UPDATE TrackingLocationsHostsConfiguration 
	SET LastUser=@LastUser
	WHERE TrackingLocationHostID=@HostID AND ((@PluginID IS NULL AND TrackingLocationProfileID IS NULL) OR (TrackingLocationProfileID=@PluginID AND @PluginID IS NOT NULL))
	
	DELETE FROM TrackingLocationsHostsConfigValues WHERE TrackingConfigID IN (SELECT ID FROM TrackingLocationsHostsConfiguration WHERE TrackingLocationHostID=@HostID AND ((@PluginID IS NULL AND TrackingLocationProfileID IS NULL) OR (TrackingLocationProfileID=@PluginID AND @PluginID IS NOT NULL)))
	DELETE FROM TrackingLocationsHostsConfiguration WHERE TrackingLocationHostID=@HostID AND ((@PluginID IS NULL AND TrackingLocationProfileID IS NULL) OR (TrackingLocationProfileID=@PluginID AND @PluginID IS NOT NULL))
	
	DELETE FROM StationConfigurationUpload WHERE TrackingLocationHostID=@HostID AND ((@PluginID IS NULL AND TrackingLocationPluginID IS NULL) OR (TrackingLocationPluginID=@PluginID AND @PluginID IS NOT NULL))
END
GO
GRANT EXECUTE ON [dbo].[remispDeleteStationConfiguration] TO REMI
GO