CREATE procedure [dbo].[remiPROCESSDetectBadAdditions]

@fix bit = null

as

select * from batches where (select COUNT (*) from TestUnits where BatchID = Batches.ID) <=0;
select b.qranumber, tu.* from TestUnits as tu, Batches as b where (select COUNT (*) from DeviceTrackingLog where TestUnitID = tu.ID) <=0 and b.ID = tu.BatchID;
select QRANumber, JobName from Batches where (select id from jobs where jobs.JobName = Batches.JobName )is null
