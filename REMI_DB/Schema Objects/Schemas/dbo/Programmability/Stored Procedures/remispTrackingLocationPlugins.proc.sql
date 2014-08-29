ALTER PROCEDURE [dbo].[remispTrackingLocationPlugins] @TrackingLocationID INT
AS
BEGIN
	SELECT *, (CASE WHEN (SELECT COUNT(ID) FROM TrackingLocationsHostsConfiguration WHERE TrackingLocationProfileID = tlp.ID) > 0 THEN 0 ELSE 1 END) AS CanDelete
	FROM TrackingLocationsPlugin tlp
	WHERE tlp.TrackingLocationID=@TrackingLocationID
END
GO
GRANT EXECUTE ON remispTrackingLocationPlugins TO REMI
GO