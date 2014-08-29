CREATE PROCEDURE [dbo].[remispTrackingLocationTypesDeleteSingleItem]
/*	'===============================================================
	'   NAME:                	remispTrackingLocationTypesDeleteSingleItem
	'   DATE CREATED:       	19 April 2009
	'   CREATED BY:          	Darragh O Riordan
	'   FUNCTION:            	Deletes an item from table: TrackingLocationTypes
	'   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
	@ID int,
	@UserName nvarchar(255)
	
	AS

	update 
		TrackingLocationTypes
		set lastuser = @UserName
	WHERE 
		ID = @ID
		delete from TrackingLocationsForTests where TrackingLocationtypeID = @id
delete from TrackingLocationTypes where ID = @id