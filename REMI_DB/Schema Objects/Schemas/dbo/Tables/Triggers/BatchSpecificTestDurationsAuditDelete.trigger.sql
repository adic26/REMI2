-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER [dbo].[BatchSpecificTestDurationsAuditDelete]
   ON  dbo.BatchSpecificTestDurations
    for  delete
AS 
BEGIN
 SET NOCOUNT ON;
 
  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here
	
insert into BatchSpecificTestDurationsaudit (
BatchSpecificTestDurationID, 
	BatchID, 
	TestID,
	Duration, 
	Comment,
	UserName,
	Action)
	Select 
	Id, 
	BatchID, 
	TestID,
	Duration,
	Comment, 
	LastUser,
'D' from deleted

END
