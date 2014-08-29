ALTER PROCEDURE [dbo].[remispTrackingLocationsDeleteHost]
/*	'===============================================================
	'   NAME:                	remispTrackingLocationsDeleteSingleItem
	'   DATE CREATED:       	20 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Deletes an item from table: TrackingLocations      
	'   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
	@ID int, @HostName nvarchar(255),
	@UserName nvarchar(255)
	AS
	UPDATE TrackingLocationsHosts
	SET LastUser=@userName
	WHERE TrackingLocationID = @ID AND HostName=@HostName
	
	DELETE FROM TrackingLocationsHosts WHERE TrackingLocationID=@ID AND HostName=@HostName

GO
GRANT EXECUTE ON remispTrackingLocationsDeleteHost TO Remi