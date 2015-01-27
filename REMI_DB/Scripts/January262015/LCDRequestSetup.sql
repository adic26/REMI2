begin tran

DECLARE @NextLookupID INT
DECLARE @TypeID INT
DECLARE @RequestTypeID INT
DECLARE @LookupTypeID INT
DECLARE @TSDRequestTypeID INT

SELECT @NextLookupID = MAX(LookupID)+1 FROM Lookups
SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='RequestType'

IF NOT EXISTS (SELECT 1 FROM Lookups WHERE LookupTypeID=@LookupTypeID AND [Values]='LCD')
BEGIN
	INSERT INTO Lookups (LookupID, [Values], LookupTypeID, IsActive) VALUES (@NextLookupID, 'LCD', @LookupTypeID, 1)
END

SELECT @TypeID=LookupID FROM Lookups WHERE LookupTypeID=@LookupTypeID AND [Values]='LCD'

IF NOT EXISTS (SELECT 1 FROM Req.RequestType WHERE TypeID=@TypeID)
BEGIN
	INSERT INTO Req.RequestType (DBType,IsExternal,RequestConnectName,TypeID,CanReport,HasApproval,HasIntegration)
	VALUES ('SQL', 0, 'REMIDBConnectionString',@TypeID,0,0,1)
END

SELECT @RequestTypeID = RequestTypeID FROM Req.RequestType WHERE TypeID=@TypeID
SELECT @TSDRequestTypeID = RequestTypeID FROM Req.RequestType WHERE TypeID IN (SELECT LookupID FROM Lookups WHERE [Values]='TSD')

INSERT INTO Req.ReqFieldSetup ([RequestTypeID],[Name],[Description],[FieldTypeID],[FieldValidationID],[Archived],[IsRequired],[DisplayOrder],[OptionsTypeID]
	,[ColumnOrder],[Category],[ParentReqFieldSetupID])
SELECT @RequestTypeID as [RequestTypeID],[Name],[Description],[FieldTypeID],[FieldValidationID],[Archived],[IsRequired],[DisplayOrder],[OptionsTypeID]
	,[ColumnOrder],[Category],[ParentReqFieldSetupID]
FROM Req.ReqFieldSetup
WHERE RequestTypeID=@TSDRequestTypeID

INSERT INTO Req.ReqFieldMapping (RequestTypeID, IntField, ExtField,IsActive)
SELECT @RequestTypeID AS RequestTypeID, IntField, ExtField,IsActive
FROM Req.ReqFieldMapping
WHERE RequestTypeID=@TSDRequestTypeID

INSERT INTO Req.RequestTypeAccess (RequestTypeID,LookupID, IsActive)
VALUES (@RequestTypeID, @TypeID, 1)

EXEC Req.RequestFieldSetup @RequestTypeID, 0, ''

ROLLBACK TRAN