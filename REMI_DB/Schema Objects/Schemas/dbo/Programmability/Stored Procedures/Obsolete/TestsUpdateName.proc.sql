alter procedure TestsUpdateName
@oldName varchar(400),
@NewName varchar(400)
as
PRINT 'Updating Tests'
update Tests set TestName = @NewName where TestName = @oldName;
PRINT 'Updating Testunits'
update Testunits set CurrentTestName = @NewName where CurrentTestName = @oldName;
PRINT 'Updating TestRecords'
update TestRecords set TestName = @NewName where TestName = @oldName;
PRINT 'Updating TestExceptions'
update TestExceptions set Value = @NewName where Value = @oldName AND LookupID=5 AND ISNUMERIC(Value) < 1 ;--meaning we update only the text values