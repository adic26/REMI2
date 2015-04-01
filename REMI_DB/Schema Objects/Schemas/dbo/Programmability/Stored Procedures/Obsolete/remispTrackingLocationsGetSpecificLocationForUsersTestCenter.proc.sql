ALTER procedure remispTrackingLocationsGetSpecificLocationForUsersTestCenter @username nvarchar(255), @locationname nvarchar(500)
AS
	DECLARE @selectedID INT

	SELECT TOP(1) @selectedID = tl.ID 
	FROM TrackingLocations as tl
		INNER JOIN Lookups l ON tl.TestCenterLocationID=l.LookupID
		INNER JOIN Users u ON u.LDAPLogin = @username
		INNER JOIN UserDetails ud ON ud.UserID=u.ID AND ud.LookupID=l.LookupID
		INNER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
	WHERE TrackingLocationName = @locationname

	SELECT @selectedid AS TrackingLocationID
GO
GRANT EXECUTE ON remispTrackingLocationsGetSpecificLocationForUsersTestCenter TO Remi
GO