ALTER PROCEDURE [dbo].[remispTrackingLocationsHostID] @ComputerName NVARCHAR(255), @TrackingLocationID INT
AS
BEGIN
	DECLARE @ID INT
	SET @ID = 0

	SELECT @ID=ID FROM TrackingLocationsHosts WHERE HostName=@ComputerName AND TrackingLocationID=@TrackingLocationID

	Return @ID
END
GRANT EXECUTE ON remispTrackingLocationsHostID TO Remi
GO