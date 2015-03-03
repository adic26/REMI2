UPDATE Tests
SET TestName='Functional Test'
where TestName='MFI Functional'
go
UPDATE TestUnits SET CurrentTestName='Functional Test' WHERE CurrentTestName='MFI Functional'
go
UPDATE top (10000) TestRecords
SET TestName='Functional Test'
WHERE TestName='MFI Functional'
go
update Tests set IsArchived=1 where TestName='SFI Functional' Or TestName='Functional Test'
go
declare @maxid int
select @maxid = MAX(lookupid) +1 from Lookups

insert into Lookups (LookupID, Type, [Values], IsActive)
values (@maxid, 'AccFunctionalMatrix','Functioning', 1)
go
Alter table testrecords add FunctionalType Int null
go
Alter table testrecordsaudit add FunctionalType Int null
go
update TOP (20000) TestRecords
set FunctionalType=1
where TestName='SFI Functional' and FunctionalType IS NULL
go
update TOP (20000) TestRecords
set FunctionalType=2
where TestName='Functional Test' and FunctionalType IS NULL
go
update TOP (20000) TestRecords
set FunctionalType=3
from TestRecords
inner join TestUnits tu on TestRecords.TestUnitID=tu.ID
inner join Batches b on tu.BatchID=b.id
where TestName='Functional Test' and FunctionalType <> 3 and b.ProductTypeID = 69
go
insert into tests (TestName, Duration,TestType, WILocation,Comment, LastUser, ResultBasedOntime, IsArchived)
values ('Functional',0,1,NULL,null,'ogaudreault',0,0)
go