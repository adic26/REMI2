ALTER TRIGGER [dbo].[BatchesAuditDelete] ON  [dbo].[Batches]
	for  delete
AS 
BEGIN
	SET NOCOUNT ON;
 
	Declare @Insert Bit
	Declare @Delete Bit
	Declare @Action char(1)

	If not Exists(Select * From Deleted) 
		return	 --No delete action, get out of here
	
	insert into batchesaudit (BatchId, QRAnumber, Priority, BatchStatus, JobName, ProductTypeID, AccessoryGroupID, TeststageName, Comment, TestCenterLocationID, 
		RequestPurpose, TestStagecompletionStatus, UserName, RFBands, productid, Action, IsMQual, ExecutiveSummary, MechanicalTools, [Order])
	Select ID, QRAnumber, Priority, BatchStatus, JobName, ProductTypeID, AccessoryGroupID, TeststageName, Comment, TestCenterLocationID, RequestPurpose,
		TestStagecompletionStatus, LastUser, RFBands,productid, 'D',IsMQual,ExecutiveSummary, MechanicalTools, [Order] 
	from deleted
END