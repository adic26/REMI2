CREATE PROCEDURE [dbo].[remispTrackingLocationTypesSelectSingleItem]
	
	
	/*	=============================================================
	'   NAME:                	remispTrackingLocationTypesSelectSingleItem
	'   DATE CREATED:       	09 April 2009
	'   CREATED BY:          	Darragh O Riordan
	'   FUNCTION:            	Retrieves 1 item from table: TrackingLocationTypes
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/

	@ID int

	AS

	SELECT
	tlt.Comment,
	tlt.ConcurrencyID,
	tlt.ID,tlt.LastUser,
	tlt.TrackingLocationFunction,
	tlt.TrackingLocationTypeName,
	tlt.UnitCapacity,
	tlt.WILocation 
	FROM 
		TrackingLocationTypes as tlt
	WHERE 
		ID = @ID
