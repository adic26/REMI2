/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        ci0000001593275\SQLDeveloper.REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 3/27/2013 10:34:30 AM

*/
SET NUMERIC_ROUNDABORT OFF
GO
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#tmpErrors')) DROP TABLE #tmpErrors
GO
CREATE TABLE #tmpErrors (Error int)
GO
SET XACT_ABORT ON
GO
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO
BEGIN TRANSACTION
GO
PRINT N'Altering [dbo].[vw_ExceptionsPivoted]'
GO
ALTER VIEW [dbo].[vw_ExceptionsPivoted]
AS
SELECT pvt.ID, pvt.[41] AS ProductID, pvt.[1] As ProductGroupName, pvt.[2] AS ReasonForRequest, pvt.[3] AS TestUnitID, pvt.[4] AS TestStageID, pvt.[5] AS Test, pvt.[6] AS ProductTypeID, pvt.[7] AS AccessoryGroupID
FROM 
(SELECT ID, Value, TestExceptions.LookupID as Look
FROM TestExceptions) te
PIVOT (MAX(Value) FOR Look IN ([41],[1],[2],[3],[4],[5],[6],[7])) as pvt
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[vw_ExceptionsAuditPivoted]'
GO

ALTER VIEW [dbo].[vw_ExceptionsAuditPivoted]
AS
SELECT pvt.ID, pvt.[41] AS ProductID, pvt.[1] AS ProductGroupName, pvt.[2] AS ReasonForRequest, pvt.[3] AS TestUnitID, pvt.[4] AS TestStageID, pvt.[5] AS Test, pvt.[6] AS ProductTypeID, pvt.[7] AS AccessoryGroupID
FROM 
(SELECT ID, Value, TestExceptionsAudit.LookupID as Look
FROM TestExceptionsAudit) te
PIVOT (MAX(Value) FOR Look IN ([41],[1],[2],[3],[4],[5],[6],[7])) as pvt 

GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating index [IX_DeviceTrackingLog_Loc_Out] on [dbo].[DeviceTrackingLog]'
GO
CREATE NONCLUSTERED INDEX [IX_DeviceTrackingLog_Loc_Out] ON [dbo].[DeviceTrackingLog] ([TrackingLocationID], [OutTime])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering trigger [dbo].[BatchesAuditDelete] on [dbo].[Batches]'
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
TestCenterLocation,
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
TestCenterLocation,
RequestPurpose,
TestStagecompletionStatus,
LastUser,
RFBands,productid,
'D' from deleted

END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering trigger [dbo].[BatchesAuditInsertUpdate] on [dbo].[Batches]'
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
	   select QRAnumber, Priority, BatchStatus, JobName, ProductTypeID, AccessoryGroupID, TeststageName, TestCenterLocation, RequestPurpose, TestStagecompletionStatus, Comment, RFBands, ProductID from Inserted
	   except
	   select QRAnumber, Priority, BatchStatus, JobName, ProductTypeID, AccessoryGroupID, TeststageName, TestCenterLocation, RequestPurpose, TestStagecompletionStatus, Comment, RFBands, ProductID from Deleted
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
			TestCenterLocation,
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
			TestCenterLocation,
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
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
IF EXISTS (SELECT * FROM #tmpErrors) ROLLBACK TRANSACTION
GO
CREATE NONCLUSTERED INDEX [TestRecordsJobTestStageUnit] ON [dbo].[TestRecords] 
(
	TestUnitID
)
INCLUDE (JobName, TestName, TestStageName)
WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF @@TRANCOUNT>0 BEGIN
PRINT 'The database update succeeded'
COMMIT TRANSACTION
END
ELSE PRINT 'The database update failed'
GO
DROP TABLE #tmpErrors
GO