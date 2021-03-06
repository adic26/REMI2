﻿CREATE TRIGGER [dbo].[UserTrainingAuditInsertUpdate]
   ON  [dbo].[UserTraining]
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

select @count= count(*) from
(
   select LookupID, UserID, LevelLookupID, ConfirmDate from Inserted
   except
   select LookupID, UserID, LevelLookupID, ConfirmDate from Deleted
) a

if ((@count) >0)
begin
	insert into UserTrainingAudit (TrainingID, LookupID, UserID, LevelLookupID, ConfirmDate, Action, UserName)
	SELECT ID, LookupID, UserID, LevelLookupID, ConfirmDate, @action, UserAssigned from inserted
END
END