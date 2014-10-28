ALTER procedure [dbo].[remispGetEnvironmentalStressSchedule] @startDate as datetime = null, @tltID as int = null, @GeoLocationID INT=null
AS
if @startdate is null
begin
	set @startdate = getutcdate()
end

select tl.trackinglocationname,dtl.intime,dtl.inuser, l.[Values] AS geolocationname,(select qranumber from batches, testunits where testunits.id = dtl.testunitid 
and batches.id = testunits.batchid) as QRANumber,tu.batchunitnumber, 
(Select DATEADD(hour, tests.duration, dtl.intime) from tests where testname = tu.currenttestname) as outtime
from DeviceTrackingLog as dtl
INNER JOIN TrackingLocations as tl ON dtl.trackinglocationid = tl.id
INNER JOIN TrackingLocationTypes as tlt ON tl.TrackingLocationTypeID = tlt.ID
INNER JOIN testunits as tu ON tu.id = dtl.testunitid 
INNER JOIN Lookups l ON l.LookupID=tl.TestCenterLocationID
where dtl.OutTime is null  
and tlt.TrackingLocationFunction = 4 and (tlt.ID = @tltID or @tltid is null) 
and (tl.TestCenterLocationID = @GeoLocationID or @GeoLocationID is null)
GO
GRANT EXECUTE ON remispGetEnvironmentalStressSchedule TO Remi
GO