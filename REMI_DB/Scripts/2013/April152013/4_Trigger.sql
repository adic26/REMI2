begin tran
GO
ALTER TRIGGER [dbo].[BatchesAuditDelete]
   ON  [dbo].[Batches]
    for  delete
AS 
BEGIN
 SET NOCOUNT ON;

	Declare @Insert Bit
	Declare @Delete Bit
	Declare @Action char(1)

  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here

insert into batchesaudit (
BatchId, 
QRAnumber, 
Priority, 
BatchStatus, 
JobName, 
--ProductGroupName,
ProductTypeID,
AccessoryGroupID,
TeststageName, 
Comment, 
TestCenterLocationID,
RequestPurpose,
TestStagecompletionStatus,
UserName,
RFBands,
productid,
Action)
 Select 
 ID, 
 QRAnumber, 
 Priority, 
BatchStatus, 
JobName,  
--ProductGroupName,
ProductTypeID,
AccessoryGroupID,
TeststageName, 
Comment, 
TestCenterLocationID,
RequestPurpose,
TestStagecompletionStatus,
LastUser,
RFBands,productid,
'D' from deleted

END
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[BatchesAuditInsertUpdate]
   ON  [dbo].[Batches]
    after insert,update
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
	   select QRAnumber, Priority, BatchStatus, JobName, ProductTypeID, AccessoryGroupID, TeststageName, TestCenterLocationID, RequestPurpose, TestStagecompletionStatus, Comment, RFBands, ProductID from Inserted
	   except
	   select QRAnumber, Priority, BatchStatus, JobName, ProductTypeID, AccessoryGroupID, TeststageName, TestCenterLocationID, RequestPurpose, TestStagecompletionStatus, Comment, RFBands, ProductID from Deleted
	) a

	if ((@count) >0)
	begin
		insert into batchesaudit (
			BatchId, 
			QRAnumber, 
			Priority, 
			BatchStatus, 
			JobName, 
			ProductTypeID,
			AccessoryGroupID,
			TeststageName, 
			TestCenterLocationID,
			RequestPurpose,
			TestStagecompletionStatus,
			Comment, 
			UserName,
			RFBands,
			ProductID,
			batchesaudit.Action)
		Select 
			ID, 
			QRAnumber, 
			Priority, 
			BatchStatus, 
			JobName,  
			ProductTypeID,
			AccessoryGroupID,
			TeststageName, 
			TestCenterLocationID,
			RequestPurpose,
			TestStagecompletionStatus,
			Comment, 
			LastUser,
			RFBands,
			productID,
			@Action from inserted
	END
END
GO
ALTER TRIGGER [dbo].[ProductConfigValuesAuditDelete]
   ON  [dbo].[ProductConfigValues]
    for  delete
AS 
BEGIN
 SET NOCOUNT ON;

  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here

insert into ProductConfigValuesAudit (ProductConfigValueID, Value, LookupID, ProductGroupID, Action, UserName, IsAttribute)
Select ID, Value, LookupID, ProductConfigID, 'D', LastUser, IsAttribute
from deleted

END

GO
ALTER TRIGGER [dbo].[ProductConfigValuesAuditInsertUpdate]
   ON  [dbo].[ProductConfigValues]
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
   select Value, LookupID, ProductConfigID, IsAttribute from Inserted
   except
   select Value, LookupID, ProductConfigID, IsAttribute from Deleted
) a

if ((@count) >0)
begin
	insert into ProductConfigValuesAudit (ProductConfigValueID, Value, LookupID, ProductGroupID, Action, UserName, IsAttribute)
	Select ID, Value, LookupID, ProductConfigID, @action, LastUser, IsAttribute
	from inserted
END
END
GO
ALTER TRIGGER [dbo].[TrackingLocationsAuditDelete]
   ON  dbo.TrackingLocations
    for  delete
AS 
BEGIN
 SET NOCOUNT ON;

  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here

insert into TrackingLocationsaudit (
	TrackingLocationId, 
	TrackingLocationName, 
	TrackingLocationTypeID,
	TestCenterLocationID, 
	--Status,
	Comment,
	--HostName,
	Username,
	Action)
	Select 
	Id, 
	TrackingLocationName, 
	TrackingLocationTypeID,
	TestCenterLocationID, 
	--Status,
	Comment,
	--HostName,
	lastuser,
'D' from deleted

END
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[TrackingLocationsAuditInsertUpdate]
   ON  dbo.TrackingLocations
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
   select TrackingLocationName, TrackingLocationTypeID, TestCenterLocationID, Comment from Inserted
   except
   select TrackingLocationName, TrackingLocationTypeID, TestCenterLocationID, Comment from Deleted
) a

if ((@count) >0)
begin
	insert into TrackingLocationsaudit (
		TrackingLocationId, 
		TrackingLocationName, 
		TrackingLocationTypeID,
		TestCenterLocationID, 
		--Status,
		Comment,
		--HostName,
		Username,
		Action)
		Select 
		Id, 
		TrackingLocationName, 
		TrackingLocationTypeID,
		TestCenterLocationID, 
		--Status,
		Comment,
		--HostName,
		lastuser,
	@action from inserted
END
END
GO




rollback tran