ALTER PROCEDURE [dbo].[remispTrackingLocationTypePermissionsGetForUserAtLocation]
	/*	=============================================================
	'   NAME:                	remispTrackingLocationTypesPermissionsGetForLocation
	'   DATE CREATED:       	14 Sept 2011
	'   CREATED BY:          	Darragh O Riordan
	'   FUNCTION:            	Retrieves the permissions for a user at a location.
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/
@username nvarchar(255),
@hostname nvarchar(255),
@trackinglocationname nvarchar(255) = null
AS
SELECT tltp.PermissionBitMask
FROM TrackingLocationTypePermissions as tltp
	INNER JOIN TrackingLocationTypes as tlt ON tltp.TrackingLocationTypeID = tlt.ID
	INNER JOIN TrackingLocations as tl ON tlt.ID = tl.TrackingLocationTypeID
	INNER JOIN TrackingLocationsHosts tlh ON tl.ID = tlh.TrackingLocationID
WHERE tlh.HostName = @hostname and tltp.Username = @username and 
	(
		(@trackinglocationname IS NOT NULL AND tl.trackingLocationname = @trackinglocationname)
		OR
		(@trackinglocationname IS NULL)
	)