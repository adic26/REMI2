CREATE PROCEDURE [dbo].[remispTestsRemoveTrackingLocationForTest]
/*	'===============================================================
	'   NAME:                	remispTestsremoveTrackingLocationForTest
	'   DATE CREATED:       	12 Nov 2009
	'   CREATED BY:          	Darragh O Riordan
	'   FUNCTION:            	removes an item from table: TrackingLocationForTests
	'   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
	@TestID int,
	@TrackingLocationTypeID int

as

delete from TrackingLocationsForTests where testid = @testid and TrackingLocationtypeID = @TrackingLocationtypeid
	





