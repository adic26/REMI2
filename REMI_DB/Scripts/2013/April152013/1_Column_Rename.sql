begin tran

exec sp_rename 'Batches.TestCenterLocation', '_TestCenterLocation', 'COLUMN'
GO
exec sp_rename 'BatchesAudit.TestCenterLocation', '_TestCenterLocation', 'COLUMN'
GO

exec sp_rename 'TrackingLocations.GeoLocationName', '_GeoLocationName', 'COLUMN'
GO
exec sp_rename 'TrackingLocationsAudit.GeoLocationName', '_GeoLocationName', 'COLUMN'
GO

rollback tran