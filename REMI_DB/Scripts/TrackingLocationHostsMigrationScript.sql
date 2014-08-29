BEGIN TRAN

TRUNCATE TABLE TrackingLocationsHosts

insert into TrackingLocationsHosts (TrackingLocationID, HostName, LastUser)
select ID, _HostName,LastUser
from TrackingLocations 
where _HostName IS NOT NULL


ROLLBACK TRAN