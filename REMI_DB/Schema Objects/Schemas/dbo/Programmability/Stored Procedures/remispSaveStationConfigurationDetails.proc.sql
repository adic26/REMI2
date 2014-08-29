ALTER PROCEDURE remispSaveStationConfigurationDetails @HostConfigID INT, @configID INT, @lookupID INT, @lookupValue NVARCHAR(250), @HostID INT, @LastUser NVARCHAR(255), @IsAttribute BIT = 0
AS
BEGIN	
	If ((@configID IS NULL OR @configID = 0 OR NOT EXISTS (SELECT 1 FROM TrackingLocationsHostsConfigValues WHERE ID=@configID)) AND @lookupValue IS NOT NULL AND LTRIM(RTRIM(@lookupValue)) <> '' AND @LookupID IS NOT NULL AND @LookupID > 0 AND EXISTS(SELECT 1 FROM TrackingLocationsHostsConfiguration WHERE ID=@HostConfigID))
	BEGIN
		INSERT INTO TrackingLocationsHostsConfigValues (Value, LookupID, TrackingConfigID, LastUser, IsAttribute)
		VALUES (@lookupValue, @LookupID, @HostConfigID, @LastUser, ISNULL(@IsAttribute,0))
	END
	ELSE IF (@configID > 0)
	BEGIN
		UPDATE TrackingLocationsHostsConfigValues
		SET Value=@lookupValue, LookupID=@LookupID, LastUser=@LastUser, TrackingConfigID=@HostConfigID, IsAttribute=ISNULL(@IsAttribute,0)
		WHERE ID=@configID
	END
END
GO
GRANT EXECUTE ON remispSaveStationConfigurationDetails TO Remi
GO