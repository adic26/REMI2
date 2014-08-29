CREATE PROCEDURE [dbo].[remispTrackingLocationTypePermissionsSelectListForUser]
/*	'===============================================================
	'   NAME:                	remispTrackingLocationTypePermissionsSelectListForUser
	'   DATE CREATED:       	9 Sep 2011
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves a list of the permissions for each tracking location type for a given user from table: TrackingLocationTypes
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/
	@username nvarchar(255)
	
	AS
	
	SELECT 
	tlt.ID, 
	tlt.TrackingLocationTypeName,
	tlt.ID as TrackingLocationTypeID, 
	tltp.PermissionBitMask, 
	tltp.ConcurrencyID 
	
	from TrackingLocationTypes as tlt
	left outer join TrackingLocationTypePermissions as tltp on (tltp.TrackingLocationTypeID = tlt.ID and tltp.Username = @username)
	
	where (tlt.TrackingLocationFunction != 6 and tlt.TrackingLocationFunction  != 3 and tlt.TrackingLocationFunction != 1)
