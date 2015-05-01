-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[RFBandsAuditInsertUpdate]
   ON  [dbo].[RFBands]
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
   select ProductGroupName, RFBands from Inserted
   except
   select ProductGroupName, RFBands from Deleted
) a

if ((@count) >0)
begin
	insert into RFBandsaudit (
		ProductGroupName,
		RFBands,
		UserName,
		Action)
		Select 
		ProductGroupName,
		RFBands,
		lastuser,
	@action from inserted
END

END
