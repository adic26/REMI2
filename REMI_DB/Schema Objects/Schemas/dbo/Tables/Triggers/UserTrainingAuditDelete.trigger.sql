CREATE TRIGGER [dbo].[UserTrainingAuditDelete]
   ON  [dbo].[UserTraining]
    for  delete
AS 
BEGIN
 SET NOCOUNT ON;
 
  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here
	
insert into UserTrainingAudit (TrainingID, LookupID, UserID, LevelLookupID, ConfirmDate, Action, UserName)
	Select ID, LookupID, UserID, LevelLookupID, ConfirmDate, 'D', UserAssigned
	from deleted

END