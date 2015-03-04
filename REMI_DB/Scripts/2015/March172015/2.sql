/*
Run this script on:

        SQLQA10YKF\HAQA1.RemiQA    -  This database will be modified

to synchronize it with:

        (local).REMILocal

You are recommended to back up your database before running this script

Script created by SQL Compare version 10.2.0 from Red Gate Software Ltd at 3/3/2015 9:30:29 PM

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
PRINT N'Altering [Req].[ReqFieldData]'
GO
ALTER TABLE [Req].[ReqFieldData] ADD
[InstanceID] [int] NULL
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [Req].[ReqFieldSetupSibling]'
GO
CREATE TABLE [Req].[ReqFieldSetupSibling]
(
[ReqFieldSiblingID] [int] NOT NULL IDENTITY(1, 1),
[ReqFieldSetupID] [int] NOT NULL,
[DefaultDisplayNum] [int] NOT NULL CONSTRAINT [DF_ReqFieldSetupSibling_DefaultDisplayNum] DEFAULT ((1)),
[MaxDisplayNum] [int] NOT NULL CONSTRAINT [DF_ReqFieldSetupSibling_MaxDisplayNum] DEFAULT ((2))
)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating primary key [PK_ReqFieldSetupSibling] on [Req].[ReqFieldSetupSibling]'
GO
ALTER TABLE [Req].[ReqFieldSetupSibling] ADD CONSTRAINT [PK_ReqFieldSetupSibling] PRIMARY KEY CLUSTERED  ([ReqFieldSiblingID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Req].[RequestFieldSetup]'
GO
ALTER PROCEDURE [Req].[RequestFieldSetup] @RequestTypeID INT, @IncludeArchived BIT = 0, @RequestNumber NVARCHAR(12) = NULL
AS
BEGIN
	DECLARE @RequestID INT
	DECLARE @TrueBit BIT
	DECLARE @FalseBit BIT
	DECLARE @RequestType NVARCHAR(150)
	SET @RequestID = 0
	SET @TrueBit = CONVERT(BIT, 1)
	SET @FalseBit = CONVERT(BIT, 0)

	SELECT @RequestType=lrt.[values] FROM Req.RequestType rt INNER JOIN Lookups lrt ON lrt.LookupID=rt.TypeID WHERE rt.RequestTypeID=@RequestTypeID

	IF (@RequestNumber IS NOT NULL)
		BEGIN
			SELECT @RequestID = RequestID FROM Req.Request WHERE RequestNumber=@RequestNumber
		END
	ELSE
		BEGIN
			SELECT @RequestNumber = REPLACE(RequestNumber, @RequestType + '-' + Right(Year(getDate()),2) + '-', '') + 1 
			FROM Req.Request 
			WHERE RequestNumber LIKE @RequestType + '-' + Right(Year(getDate()),2) + '-%'
			
			IF (LEN(@RequestNumber) < 4)
			BEGIN
				SET @RequestNumber = REPLICATE('0', 4-LEN(@RequestNumber)) + @RequestNumber
			END
		
			IF (@RequestNumber IS NULL)
				SET @RequestNumber = '0001'
		
			SET @RequestNumber = @RequestType + '-' + Right(Year(getDate()),2) + '-' + @RequestNumber
		END
	
	SELECT rfd.ReqFieldSetupID, rfd.InstanceID, rfd.Value
	FROM Req.ReqFieldData rfd WITH(NOLOCK)
		INNER JOIN Req.ReqFieldSetup rfs WITH(NOLOCK) ON rfs.ReqFieldSetupID=rfd.ReqFieldSetupID
		INNER JOIN Req.ReqFieldSetupSibling rfss WITH(NOLOCK) ON rfss.ReqFieldSetupID=rfs.ReqFieldSetupID
	WHERE RequestID = @RequestID

	SELECT rfs.ReqFieldSetupID, @RequestType AS RequestType, rfs.Name, lft.[Values] AS FieldType, rfs.FieldTypeID, 
			lvt.[Values] AS ValidationType, rfs.FieldValidationID, ISNULL(rfs.IsRequired, 0) AS IsRequired, ISNULL(rfs.DisplayOrder, 0) AS DisplayOrder,
			rfs.ColumnOrder, ISNULL(rfs.Archived, 0) AS Archived, rfs.Description, rfs.OptionsTypeID, @RequestTypeID AS RequestTypeID,
			@RequestNumber AS RequestNumber, @RequestID AS RequestID, 
			CASE WHEN rfm.IntField = 'RequestLink' AND Value IS NULL THEN 'http://go/requests/' + @RequestNumber ELSE CASE WHEN ISNULL(rfss.DefaultDisplayNum, 1) = 1 THEN rfd.Value ELSE '' END END AS Value, 
			rfm.IntField, rfm.ExtField,
			CASE WHEN rfm.ID IS NOT NULL THEN 1 ELSE 0 END AS InternalField,
			CASE WHEN @RequestID = 0 THEN CONVERT(BIT, 1) ELSE CONVERT(BIT, 0) END AS NewRequest, rt.IsExternal AS IsFromExternalSystem, rfs.Category,
			rfs.ParentReqFieldSetupID, rt.HasIntegration, rfsp.Name As ParentFieldSetupName, rfs.DefaultValue, 
			ISNULL(rfd.ReqFieldDataID, -1) AS ReqFieldDataID, rt.HasDistribution,
			CASE
				WHEN (SELECT MAX(InstanceID) FROM Req.ReqFieldData d WHERE d.RequestID=@RequestID AND d.ReqFieldSetupID=rfs.ReqFieldSetupID) > ISNULL(rfss.DefaultDisplayNum, 1)
				THEN (SELECT MAX(InstanceID) FROM Req.ReqFieldData d WHERE d.RequestID=@RequestID AND d.ReqFieldSetupID=rfs.ReqFieldSetupID)
				ELSE ISNULL(rfss.DefaultDisplayNum, 1)
				END AS DefaultDisplayNum, 
			ISNULL(rfss.MaxDisplayNum, 1) AS MaxDisplayNum 
	FROM Req.RequestType rt WITH(NOLOCK)
		INNER JOIN Lookups lrt WITH(NOLOCK) ON lrt.LookupID=rt.TypeID
		INNER JOIN Req.ReqFieldSetup rfs WITH(NOLOCK) ON rfs.RequestTypeID=rt.RequestTypeID                  
		INNER JOIN Lookups lft WITH(NOLOCK) ON lft.LookupID=rfs.FieldTypeID
		LEFT OUTER JOIN Lookups lvt WITH(NOLOCK) ON lvt.LookupID=rfs.FieldValidationID
		LEFT OUTER JOIN Req.ReqFieldSetupRole rfsr WITH(NOLOCK) ON rfsr.ReqFieldSetupID=rfs.ReqFieldSetupID
		LEFT OUTER JOIN Req.Request r WITH(NOLOCK) ON RequestNumber=@RequestNumber
		LEFT OUTER JOIN Req.ReqFieldMapping rfm WITH(NOLOCK) ON rfm.RequestTypeID=rt.RequestTypeID AND rfm.ExtField=rfs.Name AND ISNULL(rfm.IsActive, 0) = 1
		LEFT OUTER JOIN Req.ReqFieldSetup rfsp WITH(NOLOCK) ON rfsp.ReqFieldSetupID=rfs.ParentReqFieldSetupID
		LEFT OUTER JOIN Req.ReqFieldSetupSibling rfss WITH(NOLOCK) ON rfss.ReqFieldSetupID=rfs.ReqFieldSetupID
		LEFT OUTER JOIN Req.ReqFieldData rfd WITH(NOLOCK) ON rfd.ReqFieldSetupID=rfs.ReqFieldSetupID AND rfd.RequestID=r.RequestID AND ISNULL(rfd.InstanceID, 1) = 1
	WHERE (lrt.[Values] = @RequestType) AND 
		(
			(@IncludeArchived = @TrueBit)
			OR
			(@IncludeArchived = @FalseBit AND ISNULL(rfs.Archived, @FalseBit) = @FalseBit)
			OR
			(@IncludeArchived = @FalseBit AND rfd.Value IS NOT NULL AND ISNULL(rfs.Archived, @FalseBit) = @TrueBit)
		)
	ORDER BY 22, 9 ASC
END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Req].[ReqFieldDataAudit]'
GO
ALTER TABLE [Req].[ReqFieldDataAudit] ADD
[ReqFieldDataID] [int] NULL,
[InstanceID] [int] NULL
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Req].[vw_RequestDataAudit]'
GO
ALTER VIEW [req].[vw_RequestDataAudit] AS
SELECT r.RequestNumber, fs.Name, fda.Value, fda.UserName, fda.InsertTime, fda.InstanceID AS RecordNum, 
	CASE fda.Action WHEN 'U' THEN 'Updated' WHEN 'D' THEN 'Deleted' WHEN 'I' THEN 'Inserted' END AS Action
FROM Req.ReqFieldDataAudit fda
	INNER JOIN Req.Request r ON fda.RequestID=r.RequestID
	INNER JOIN Req.ReqFieldSetup fs ON fs.ReqFieldSetupID=fda.ReqFieldSetupID
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding foreign keys to [Req].[ReqFieldSetupSibling]'
GO
ALTER TABLE [Req].[ReqFieldSetupSibling] ADD CONSTRAINT [FK_ReqFieldSetupSibling_ReqFieldSetup] FOREIGN KEY ([ReqFieldSetupID]) REFERENCES [Req].[ReqFieldSetup] ([ReqFieldSetupID])
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering trigger [Req].[ReqFieldDataAuditInsertUpdate] on [Req].[ReqFieldData]'
GO
ALTER TRIGGER [Req].[ReqFieldDataAuditInsertUpdate] ON  [Req].[ReqFieldData] after insert, update
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
   select Value, InstanceID from Inserted
   except
   select Value, InstanceID from Deleted
) a

if ((@count) >0)
begin
	insert into Req.ReqFieldDataAudit (RequestID,ReqFieldSetupID,Value,InsertTime,Action, UserName, ReqFieldDataID, InstanceID)
	Select RequestID,ReqFieldSetupID,Value,InsertTime, @action,lastuser, ReqFieldDataID, InstanceID from inserted
END
END

GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating trigger [Req].[ReqFieldDataAuditDelete] on [Req].[ReqFieldData]'
GO
CREATE TRIGGER Req.[ReqFieldDataAuditDelete] ON  Req.ReqFieldData
	for  delete
AS 
BEGIN
	SET NOCOUNT ON;

	If not Exists(Select * From Deleted) 
		return	 --No delete action, get out of here
	
	insert into Req.ReqFieldDataAudit (RequestID,ReqFieldSetupID,Value,InsertTime,Action, UserName, ReqFieldDataID, InstanceID)
	Select RequestID,ReqFieldSetupID,Value,InsertTime, 'D', lastuser, ReqFieldDataID, InstanceID from deleted
END
GO
DELETE FROM Req.ReqFieldMapping WHERE IntField='Select...'
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
IF EXISTS (SELECT * FROM #tmpErrors) ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT>0 BEGIN
PRINT 'The database update succeeded'
COMMIT TRANSACTION
END
ELSE PRINT 'The database update failed'
GO
DROP TABLE #tmpErrors
GO