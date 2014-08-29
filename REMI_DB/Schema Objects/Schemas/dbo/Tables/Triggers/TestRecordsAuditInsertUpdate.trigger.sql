-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[TestRecordsAuditInsertUpdate]
   ON  [dbo].[TestRecords]
    after insert, update
AS 
BEGIN
SET NOCOUNT ON;
 
Declare @action char(1)
DECLARE @count INT
  
--check if this is an insert or an update

If Exists(Select * From Inserted) and Exists(Select * From Deleted) --Update, both tables referenced
begin
	Set @action= 'U'
end
else
begin
	If Exists(Select * From Inserted) --insert, only one table referenced
	Begin
		Set @action= 'I'
	end
	if not Exists(Select * From Inserted) and not Exists(Select * From Deleted)--nothing changed, get out of here
	Begin
		RETURN
	end
end

--Only inserts records into the Audit table if the row was either updated or inserted and values actually changed.
select @count= count(*) from
(
   select TestUnitID, TestName, TestStageName, JobName, Status, FailDocNumber, RelabVersion, Comment, resultsource, TestID, TestStageID from Inserted
   except
   select TestUnitID, TestName, TestStageName, JobName, Status, FailDocNumber, RelabVersion, Comment, resultsource, TestID, TestStageID from Deleted
) a

if ((@count) >0)
begin
	insert into TestRecordsaudit (
		TestRecordId, 
		TestUnitID,
		TestName, 
		TestStageName,
		JobName,
		Status, 
		FailDocNumber,
		RelabVersion,
		Comment,
		UserName,
		resultsource,
		action, TestID, TestStageID)
		Select 
		Id, 
		TestUnitID,
		TestName, 
		TestStageName,
		JobName,
		Status, 
		FailDocNumber,
		RelabVersion,
		Comment, 
		LastUser,
		resultsource,
	@action, TestID, TestStageID from inserted
END

END