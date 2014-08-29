create procedure TestRecordsAuditViewRecords

@qranumber nvarchar(11)

as

select tu.batchunitnumber, tra.* from TestRecordsAudit as tra, TestUnits as tu, Batches as b 
where tra.TestUnitID = tu.ID and tu.BatchID = b.ID and b.QRANumber = @qranumber
order by TestStageName, TestName