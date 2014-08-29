ALTER PROCEDURE remispDeleteStationConfigurationHeader @HostConfigID INT, @LastUser NVARCHAR(255), @ProfileID INT
AS
BEGIN
	IF (EXISTS (SELECT 1 FROM TrackingLocationsHostsConfiguration WHERE ID=@HostConfigID AND TrackingLocationProfileID=@ProfileID) AND NOT EXISTS (SELECT 1 FROM dbo.TrackingLocationsHostsConfigValues WHERE TrackingConfigID=@HostConfigID))
	BEGIN
		DELETE FROM TrackingLocationsHostsConfiguration WHERE ID=@HostConfigID AND TrackingLocationProfileID=@ProfileID
	END
END
GO
GRANT EXECUTE ON remispDeleteStationConfigurationHeader TO REMI
GO