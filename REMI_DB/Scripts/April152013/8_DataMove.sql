begin tran

insert into Lookups (LookupID,Type,[Values], IsActive) values (75, 'TestCenter','Cambridge',1)
insert into Lookups (LookupID,Type,[Values], IsActive) values (76, 'TestCenter','Bochum',1)
insert into Lookups (LookupID,Type,[Values], IsActive) values (77, 'TestCenter','Sunrise',	1)
insert into Lookups (LookupID,Type,[Values], IsActive) values (78, 'TestCenter','Rolling Meadows',1)
insert into Lookups (LookupID,Type,[Values], IsActive) values (79, 'TestCenter','Waterloo',0)

select * into _productconfigvalues from productconfigvalues
select * into _ProductConfiguration from ProductConfiguration

delete  from productconfigvalues
delete  from ProductConfiguration
DBCC CHECKIDENT (ProductConfiguration, reseed, 1)
DBCC CHECKIDENT (productconfigvalues, reseed, 1)

update Batches
set TestCenterLocationID=(select lookupID FROM Lookups WHERE Type='TestCenter' and [Values]=ltrim(rtrim(Batches._TestCenterLocation)))
where _TestCenterLocation is not null AND LTRIM(RTRIM(_TestCenterLocation)) <> ''
GO

update TrackingLocations
set TestCenterLocationID=(select lookupID FROM Lookups WHERE Type='TestCenter' and [Values]=ltrim(rtrim(TrackingLocations._GeoLocationName)))
where _GeoLocationName is not null AND LTRIM(RTRIM(_GeoLocationName)) <> ''
GO

update TrackingLocationsAudit
set TestCenterLocationID=(select lookupID FROM Lookups WHERE Type='TestCenter' and [Values]=ltrim(rtrim(TrackingLocationsAudit._GeoLocationName)))
where _GeoLocationName is not null AND LTRIM(RTRIM(_GeoLocationName)) <> ''
GO
update BatchesAudit set TestCenterLocationID=75, ProductID=326 where ID=766676
GO
update BatchesAudit
set TestCenterLocationID=(select lookupID FROM Lookups WHERE Type='TestCenter' and [Values]=ltrim(rtrim(BatchesAudit._TestCenterLocation)))
where _TestCenterLocation is not null AND LTRIM(RTRIM(_TestCenterLocation)) <> ''
GO

rollback tran