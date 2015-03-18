begin tran

DECLARE @NextLookupID INT
DECLARE @TypeID INT
DECLARE @RequestTypeID INT
DECLARE @DropDownID INT
DECLARE @TextBoxID INT
DECLARE @LookupTypeID INT
DECLARE @LinkID INT
DECLARE @DateTimeID INT

SELECT @NextLookupID = MAX(LookupID)+1 FROM Lookups
SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='RequestType'

IF NOT EXISTS (SELECT 1 FROM Lookups WHERE LookupTypeID=@LookupTypeID AND [Values]='RFC')
BEGIN
	INSERT INTO Lookups (LookupID, [Values], LookupTypeID, IsActive) VALUES (@NextLookupID, 'RFC', @LookupTypeID, 1)
END

SELECT @TypeID=LookupID FROM Lookups WHERE LookupTypeID=@LookupTypeID AND [Values]='RFC'

IF NOT EXISTS (SELECT 1 FROM Req.RequestType WHERE TypeID=@TypeID)
BEGIN
	INSERT INTO Req.RequestType (DBType,IsExternal,RequestConnectName,TypeID,CanReport,HasApproval,HasIntegration)
	VALUES ('SQL', 0, 'REMIDBConnectionString',@TypeID,0,0,1)
END

SELECT @RequestTypeID = RequestTypeID FROM Req.RequestType WHERE TypeID=@TypeID

SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='FieldTypes'

SELECT @DropDownID=LookupID FROM Lookups WHERE LookupTypeID=@LookupTypeID AND [Values]='DropDown'
SELECT @TextBoxID=LookupID FROM Lookups WHERE LookupTypeID=@LookupTypeID AND [Values]='TextBox'
SELECT @LinkID=LookupID FROM Lookups WHERE LookupTypeID=@LookupTypeID AND [Values]='Link'
SELECT @DateTimeID=LookupID FROM Lookups WHERE LookupTypeID=@LookupTypeID AND [Values]='DateTime'

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Requestor',null,@TextBoxID,null,0,1,1,NULL,1)

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Received Date',null,@DateTimeID,null,0,1,2,NULL,1)

SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='TestCenter'
insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Test Centre Location',null,@DropDownID,null,0,1,3,@LookupTypeID,1)

SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='Department'
insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Department',null,@DropDownID,null,0,1,4,@LookupTypeID,1)

SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='RequestPurpose'
insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Purpose',null,@DropDownID,null,0,1,5,@LookupTypeID,1)

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Requested Test',null,@DropDownID,null,0,1,6,NULL,1)

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Reason For Request',null,@TextBoxID,null,0,1,7,NULL,1)

SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='ProductType'
insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Product Type',null,@DropDownID,null,0,1,8,@LookupTypeID,1)

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Product Group',null,@DropDownID,null,0,1,9,NULL,1)

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Part Name Under Test',null,@TextBoxID,null,0,1,10,NULL,1)

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Part Number',null,@TextBoxID,null,0,1,11,NULL,1)

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Manufacturer of Part Under Test',null,@TextBoxID,null,0,1,12,NULL,1)

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'CPR',null,@TextBoxID,null,0,1,13,NULL,1)

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Sample Size',null,@TextBoxID,null,0,1,14,NULL,1)

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Firmware',null,@TextBoxID,null,0,1,15,NULL,1)

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'HWTCM #',null,@DropDownID,null,0,1,16,NULL,1)

SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='Revision'
insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Revision',null,@DropDownID,null,0,1,17,@LookupTypeID,1)

SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='Status'
insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Request Status',null,@DropDownID,null,0,1,18,@LookupTypeID,1)

SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='AccessoryType'
insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Accessory Type',null,@DropDownID,null,1,1,19,@LookupTypeID,1)

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'ReportRequiredBy',null,@DateTimeID,null,1,1,20,null,1)

SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='Priority'
insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Priority',null,@DropDownID,null,0,1,21,@LookupTypeID,1)

INSERT INTO Req.ReqFieldMapping (RequestTypeID, IntField, ExtField, IsActive) VALUES (@RequestTypeID, 'Requestor', 'Requestor', 1)
INSERT INTO Req.ReqFieldMapping (RequestTypeID, IntField, ExtField, IsActive) VALUES (@RequestTypeID, 'DateCreated', 'Received Date', 1)
INSERT INTO Req.ReqFieldMapping (RequestTypeID, IntField, ExtField, IsActive) VALUES (@RequestTypeID, 'TestCenterLocation', 'Test Centre Location', 1)
INSERT INTO Req.ReqFieldMapping (RequestTypeID, IntField, ExtField, IsActive) VALUES (@RequestTypeID, 'Department', 'Department', 1)
INSERT INTO Req.ReqFieldMapping (RequestTypeID, IntField, ExtField, IsActive) VALUES (@RequestTypeID, 'RequestPurpose', 'Purpose', 1)
INSERT INTO Req.ReqFieldMapping (RequestTypeID, IntField, ExtField, IsActive) VALUES (@RequestTypeID, 'RequestedTest', 'Requested Test', 1)
INSERT INTO Req.ReqFieldMapping (RequestTypeID, IntField, ExtField, IsActive) VALUES (@RequestTypeID, 'ReasonForRequest', 'Reason For Request', 1)
INSERT INTO Req.ReqFieldMapping (RequestTypeID, IntField, ExtField, IsActive) VALUES (@RequestTypeID, 'ProductType', 'Product Type', 1)
INSERT INTO Req.ReqFieldMapping (RequestTypeID, IntField, ExtField, IsActive) VALUES (@RequestTypeID, 'ProductGroup', 'Product Group', 1)
INSERT INTO Req.ReqFieldMapping (RequestTypeID, IntField, ExtField, IsActive) VALUES (@RequestTypeID, 'CPRNumber', 'CPR', 1)
INSERT INTO Req.ReqFieldMapping (RequestTypeID, IntField, ExtField, IsActive) VALUES (@RequestTypeID, 'SampleSize', 'Sample Size', 1)
INSERT INTO Req.ReqFieldMapping (RequestTypeID, IntField, ExtField, IsActive) VALUES (@RequestTypeID, 'MechanicalTools', 'Revision', 1)
INSERT INTO Req.ReqFieldMapping (RequestTypeID, IntField, ExtField, IsActive) VALUES (@RequestTypeID, 'RequestStatus', 'Request Status', 1)
INSERT INTO Req.ReqFieldMapping (RequestTypeID, IntField, ExtField, IsActive) VALUES (@RequestTypeID, 'AccessoryGroup', 'Accessory Type', 1)
INSERT INTO Req.ReqFieldMapping (RequestTypeID, IntField, ExtField, IsActive) VALUES (@RequestTypeID, 'ReportRequiredBy', 'ReportRequiredBy', 1)
INSERT INTO Req.ReqFieldMapping (RequestTypeID, IntField, ExtField, IsActive) VALUES (@RequestTypeID, 'Priority', 'Priority', 1)

EXEC Req.RequestFieldSetup @RequestTypeID, 0, ''

COMMIT TRAN