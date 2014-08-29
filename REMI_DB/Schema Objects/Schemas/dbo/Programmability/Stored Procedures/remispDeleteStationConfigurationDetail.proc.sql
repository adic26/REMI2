CREATE PROCEDURE remispDeleteStationConfigurationDetail @ConfigID INT, @LastUser NVARCHAR(255)
AS
BEGIN
	IF EXISTS (SELECT 1 FROM TrackingLocationsHostsConfigValues WHERE ID=@ConfigID)
	BEGIN
		DELETE FROM dbo.TrackingLocationsHostsConfigValues WHERE ID=@ConfigID
	END
END
GO
GRANT EXECUTE ON remispDeleteStationConfigurationDetail TO REMI
GO