-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[ProductSettingsAuditInsertUpdate]
   ON  [dbo].[ProductSettings]
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
   select LookupID, KeyName, ValueText, DefaultValue from Inserted
   except
   select LookupID, KeyName, ValueText, DefaultValue from Deleted
) a

if ((@count) >0)
begin
	insert into ProductSettingsAudit (
			ProductSettingsId, 
		LookupID,
		KeyName, 
		ValueText,
		DefaultValue,	
		Action)
		Select 
		Id, 
		LookupID,
		KeyName, 
		DefaultValue,
		ValueText,	
	@action from inserted
END
END
