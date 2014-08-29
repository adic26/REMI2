ALTER procedure remispTrackingLocationsGetSpecificLocationForUsersTestCenter @username nvarchar(255), @locationname nvarchar(500)
AS
declare @selectedID int

select top(1) @selectedID = tl.ID 
from TrackingLocations as tl
	INNER JOIN Lookups l ON l.Type='TestCenter' AND tl.TestCenterLocationID=l.LookupID
	INNER JOIN Users as u ON u.TestCentreID = l.lookUpID
	INNER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
where TrackingLocationName = @locationname and u.LDAPLogin = @username

return @selectedid
GO
GRANT EXECUTE ON remispTrackingLocationsGetSpecificLocationForUsersTestCenter TO Remi
GO