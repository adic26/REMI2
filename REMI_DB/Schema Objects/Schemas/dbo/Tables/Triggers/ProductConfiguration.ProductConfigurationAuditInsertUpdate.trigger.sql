alter TRIGGER [dbo].[ProductConfigurationAuditInsertUpdate]
   ON  [dbo].[ProductConfiguration]
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
   select ParentID, ViewOrder, NodeName, UploadID from Inserted
   except
   select ParentID, ViewOrder, NodeName, UploadID from Deleted
) a

if ((@count) >0)
begin
	insert into ProductConfigurationAudit (productConfigID, ParentID, ViewOrder, NodeName, UploadID, Action, UserName)
	Select ID, ParentID, ViewOrder, NodeName, UploadID, @action, LastUser
	from inserted
END
END