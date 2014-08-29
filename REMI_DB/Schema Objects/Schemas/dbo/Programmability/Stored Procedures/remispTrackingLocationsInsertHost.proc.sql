ALTER PROCEDURE [dbo].[remispTrackingLocationsInsertHost]
@ID int OUTPUT,
@HostName nvarchar(255),
@UserName nvarchar(255),
@Status int
AS
IF (LTRIM(RTRIM(@HostName)) = '')
BEGIN
	IF NOT EXISTS (SELECT 1 FROM TrackingLocationsHosts WHERE TrackingLocationID=@ID AND HostName=@HostName)
		BEGIN
			INSERT INTO TrackingLocationsHosts (TrackingLocationID, HostName, LastUser, Status) VALUES (@ID, @HostName, @UserName, @Status)
		END
	ELSE
		BEGIN
			UPDATE TrackingLocationsHosts
			SET Status=@Status
			WHERE TrackingLocationID=@ID AND HostName=@HostName
		END
END
SELECT @ID
GO
GRANT EXECUTE ON remispTrackingLocationsInsertHost TO Remi
GO