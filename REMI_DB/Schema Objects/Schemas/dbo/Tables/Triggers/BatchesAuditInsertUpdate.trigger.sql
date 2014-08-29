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
	   select QRAnumber, Priority, BatchStatus, JobName, ProductTypeID, AccessoryGroupID, TeststageName, TestCenterLocationID, RequestPurpose, TestStagecompletionStatus, Comment, RFBands, ProductID, IsMQual, ExecutiveSummary, MechanicalTools, [Order] from Inserted
	   except
	   select QRAnumber, Priority, BatchStatus, JobName, ProductTypeID, AccessoryGroupID, TeststageName, TestCenterLocationID, RequestPurpose, TestStagecompletionStatus, Comment, RFBands, ProductID, IsMQual, ExecutiveSummary, MechanicalTools, [Order] from Deleted
	) a

	if ((@count) >0)
	begin
		insert into batchesaudit (BatchId, QRAnumber, Priority, BatchStatus, JobName, ProductTypeID,AccessoryGroupID,TeststageName, TestCenterLocationID,
			RequestPurpose, TestStagecompletionStatus, Comment, UserName, RFBands, ProductID, batchesaudit.Action, IsMQual, ExecutiveSummary, MechanicalTools, [Order])
		Select ID, QRAnumber, Priority, BatchStatus, JobName, ProductTypeID, AccessoryGroupID, TeststageName, TestCenterLocationID, RequestPurpose, 
			TestStagecompletionStatus, Comment, LastUser, RFBands, productID, @Action, IsMQual, ExecutiveSummary, MechanicalTools, [Order] 
		from inserted
	END
END