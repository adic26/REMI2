-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[TrackingLocationTypesAuditInsertUpdate]
   ON  dbo.TrackingLocationTypes
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
   select TrackingLocationTypeName, TrackingLocationFunction, WILocation, UnitCapacity, Comment from Inserted
   except
   select TrackingLocationTypeName, TrackingLocationFunction, WILocation, UnitCapacity, Comment from Deleted
) a

if ((@count) >0)
begin
	insert into TrackingLocationTypesaudit (
		TrackingLocationTypeId, 
		TrackingLocationTypeName, 
		TrackingLocationFunction,
		WILocation, 
		UnitCapacity,
		Comment,
		Username,
		Action)
		Select 
		Id, 
		TrackingLocationTypeName, 
		TrackingLocationFunction,
		WILocation, 
		UnitCapacity,
		Comment,
		lastuser,
	@action from inserted
END
END