CREATE PROCEDURE [dbo].[remispTestUnitsSelectListByTrackingLocation]
/*	'===============================================================
	'   NAME:                	remispTestUnitsSelectListByTrackingLocation
	'   DATE CREATED:       	30 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves paged data from table: TestUnits OR the number of records in the table
	'   IN:         TrackingLocationID Optional: RecordCount         
	'   OUT: 		List Of: ID, BatchID,InFA, BSN, BatchUnitNumber,  CurrentTestXTestStageID, TestingStatus,AssignmentStatus, TimeofInsert, TimeOfUpdate, InsertUser, UpdateUser, Visible, ConcurrencyID              
	'   VERSION: 1           
	'   COMMENTS:   Modified to only be a COUNT !!         
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/

	@StartRowIndex int = -1,
	@MaximumRows int = -1,
	@RecordCount int = NULL OUTPUT,
	@TrackingLocationID int
	
	AS

	IF (@RecordCount IS NOT NULL)
	BEGIN
		SET @RecordCount = (SELECT     COUNT(*) AS Expr1
		                    FROM         TestUnits AS tu INNER JOIN
		                                          DeviceTrackingLog AS dtl ON tu.ID = dtl.TestUnitID INNER JOIN
		                                          TrackingLocations ON dtl.TrackingLocationID = TrackingLocations.ID
		                    WHERE     (dtl.OutUser IS NULL) AND (TrackingLocations.id = @TrackingLocationID))
		RETURN
	END

	--SELECT 
	--	*    
	--FROM     
	--	(SELECT ROW_NUMBER() OVER (ORDER BY tu.ID) AS Row, 
	--	*
	--FROM TestUnits as tu) AS TestUnitsRows INNER JOIN
	--	                                          DeviceTrackingLog AS dtl ON testunitsrows.ID = dtl.TestUnitID
	--WHERE 
	--	((Row between (@startRowIndex) AND @startRowIndex + @maximumRows - 1) 
	--		OR @startRowIndex = -1 OR @maximumRows = -1) 
	--		AND (dtl.TrackingLocationID = @TrackingLocationID) --the unit is at this location
	--		AND (dtl.OutUser IS NULL) --where the unit is still *IN* the location
	--		ORDER BY BatchID, BatchUnitNumber
