SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE remispSaveStationConfiguration @HostConfigID INT, @parentID INT, @ViewOrder INT, @NodeName NVARCHAR(200), @HostID INT, @LastUser NVARCHAR(255), @PluginID INT
AS
BEGIN
	IF (@PluginID = 0)
		SET @PluginID = NULL

	If ((@HostConfigID IS NULL OR @HostConfigID = 0 OR NOT EXISTS (SELECT 1 FROM TrackingLocationsHostsConfiguration WHERE TrackingLocationHostID=@HostID)) AND @NodeName IS NOT NULL AND LTRIM(RTRIM(@NodeName)) <> '')
	BEGIN
		INSERT INTO TrackingLocationsHostsConfiguration (ParentId, ViewOrder, NodeName, TrackingLocationHostID, LastUser, TrackingLocationProfileID)
		VALUES (CASE WHEN @parentID = 0 THEN NULL ELSE @parentID END, @ViewOrder, @NodeName, @HostID, @LastUser, @PluginID)
		
		SET @HostConfigID = SCOPE_IDENTITY()
	END
	ELSE IF (@HostConfigID > 0)
	BEGIN
		UPDATE TrackingLocationsHostsConfiguration
		SET ParentId=CASE WHEN @parentID = 0 THEN NULL ELSE @parentID END, ViewOrder=@ViewOrder, NodeName=@NodeName, LastUser=@LastUser, TrackingLocationProfileID=@PluginID
		WHERE ID=@HostConfigID
	END
END
GO
GRANT EXECUTE ON remispSaveStationConfiguration TO REMI
GO