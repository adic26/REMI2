ALTER PROCEDURE [dbo].[remispDeviceTrackingLogDeleteSingleItem] @ID int
AS
BEGIN
	DELETE FROM DeviceTrackingLog WHERE ID = @ID
END
GO
GRANT EXECUTE ON remispDeviceTrackingLogDeleteSingleItem TO REMI
GO