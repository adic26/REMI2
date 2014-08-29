ALTER PROCEDURE remispGetSimilarStationConfiguration @HostID INT
AS
BEGIN
	SELECT sc.TrackingLocationHostID AS ID, tl.TrackingLocationName + ' - ' + l.[Values] AS TrackingLocationName
	FROM TrackingLocationsHostsConfiguration sc
		INNER JOIN TrackingLocationsHosts tlh on sc.TrackingLocationHostID = tlh.ID
		INNER JOIN TrackingLocations tl ON tlh.TrackingLocationID=tl.ID
		INNER JOIN Lookups l on l.LookupID = tl.TestCenterLocationID
	WHERE tl.TrackingLocationTypeID = (SELECT TrackingLocationTypeID FROM TrackingLocations tl2 INNER JOIN TrackingLocationsHosts tlh2 ON tl2.ID=tlh2.TrackingLocationID WHERE tlh2.ID=@HostID)
	GROUP BY sc.TrackingLocationHostID, tl.TrackingLocationName, l.[Values]
END
GO
GRANT EXECUTE ON remispGetSimilarStationConfiguration TO REMI
GO