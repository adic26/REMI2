ALTER PROCEDURE [dbo].[remispTrackingLocationsDeleteSingleItem]
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
	@ID int,
	@UserName nvarchar(255)
	AS
	UPDATE TrackingLocations
	SET LastUser=@userName
	WHERE ID = @ID

	UPDATE TrackingLocationsHosts
	SET LastUser=@userName
	WHERE TrackingLocationID = @ID
	
	DELETE FROM TrackingLocationsHosts WHERE TrackingLocationID=@ID
	DELETE FROM TrackingLocations where ID=@ID