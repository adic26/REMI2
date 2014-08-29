ALTER PROCEDURE [dbo].[remispTrackingLocationsSelectForTest]
/*	'===============================================================
	'   NAME:                	remispTrackingLocationsSelectForTest
	'   DATE CREATED:       	19 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves data from table: TrackingLocations
	'   VERSION: 1           
	'   COMMENTS:            
  	'   MODIFIED ON:         
	'   MODIFIED BY:       
	'   REASON MODIFICATION: 
	'===============================================================*/
	@TestID integer,
	@CurrentTLID int
AS
	declare @currentGeoLocation INT = (select TestCenterLocationID from TrackingLocations where ID = @currentTLID)

	select tl.TrackingLocationName,(SELECT COUNT(dtl.ID)  --available to take units
		                    FROM TestUnits AS tu, DeviceTrackingLog AS dtl 
		                                          where tu.ID = dtl.TestUnitID 
		                                          and dtl.TrackingLocationID = tl.ID 
		                                          and (dtl.OutUser IS NULL)) as CurrentCount , (SELECT top(1) tu.CurrentTestName as CurrentTestName --and currently doing the same test, or not doing any test 
		                    FROM TestUnits AS tu, DeviceTrackingLog AS dtl 
		                                          where tu.ID = dtl.TestUnitID 
		                                          and tu.CurrentTestName is not null
		                                          and dtl.TrackingLocationID = tl.ID 
		                                          and (dtl.OutUser IS NULL)) as currenttestname from TrackingLocations as tl, TrackingLocationTypes as tlt, Tests as t where
tl.TrackingLocationTypeID = (select top(1) tlfort.TrackingLocationtypeID  from TrackingLocationsForTests as tlfort where TestID = @testid)
and tlt.ID = tl.TrackingLocationTypeID
and t.ID = @testid
and tl.ID != @currentTLID
and tl.TestCenterLocationID = @currentGeoLocation --close to us
and  (SELECT     COUNT(dtl.ID)  --available to take units
		                    FROM TestUnits AS tu, DeviceTrackingLog AS dtl 
		                                          where tu.ID = dtl.TestUnitID 
		                                          and dtl.TrackingLocationID = tl.ID 
		                                          and (dtl.OutUser IS NULL)) < tlt.UnitCapacity
and ((SELECT top(1) tu.CurrentTestName as CurrentTestName --and currently doing the same test, or not doing any test 
		                    FROM TestUnits AS tu, DeviceTrackingLog AS dtl 
		                                          where tu.ID = dtl.TestUnitID 
		                                          and tu.CurrentTestName is not null
		                                          and dtl.TrackingLocationID = tl.ID 
		                                          and (dtl.OutUser IS NULL)) = t.TestName or (SELECT top(1) tu.CurrentTestName as CurrentTestName
		                    FROM TestUnits AS tu, DeviceTrackingLog AS dtl 
		                                          where tu.ID = dtl.TestUnitID 
		                                          and tu.CurrentTestName is not null
		                                          and dtl.TrackingLocationID = tl.ID 
		                                          and (dtl.OutUser IS NULL)) is null) order by tl.TrackingLocationName
GO
GRANT EXECUTE ON remispTrackingLocationsSelectForTest TO Remi
GO