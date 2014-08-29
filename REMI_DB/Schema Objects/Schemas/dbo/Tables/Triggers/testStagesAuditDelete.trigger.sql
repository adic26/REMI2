-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[testStagesAuditDelete]
   ON  [dbo].[TestStages]
    for  delete
AS 
BEGIN
 SET NOCOUNT ON;
 
  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here
	
insert into testStagesaudit (
	TeststageId, 
	TestStageName, 
	TestStageType,
	JobID, 
	Comment,
	testid,
	UserName,
	ProcessOrder,
	IsArchived,
	Action)
	Select 
	Id, 
	TestStageName, 
	TestStageType,
	JobID, 
	Comment, 
	testid,
	LastUser,
	ProcessOrder,
	IsArchived,
'D' from deleted

END
