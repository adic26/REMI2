-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[testunitsAuditDelete]
   ON  dbo.TestUnits
    for  delete
AS 
BEGIN
 SET NOCOUNT ON;
 
  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here
	
insert into testunitsaudit (
	TestUnitId, 
	batchid, 
	BSN,
	BatchUnitNumber, 
	CurrentTestName,
	CurrentTestStageName,
	AssignedTo,
	Comment,
	Username,
	Action, IMEI)
	Select 
	Id, 
	batchid, 
	BSN,
	BatchUnitNumber, 
	CurrentTestName,
	CurrentTestStageName,
	AssignedTo,
	Comment,
	lastuser, 'D', IMEI from deleted

END
