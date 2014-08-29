-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[TestRecordsAuditDelete]
   ON  [dbo].[TestRecords]
    for  delete
AS 
BEGIN
 SET NOCOUNT ON;
 
  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here
	
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
	ResultSource,
	Action, TestID, TestStageID)
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
	ResultSource,
'D', TestID, TestStageID from deleted

END
