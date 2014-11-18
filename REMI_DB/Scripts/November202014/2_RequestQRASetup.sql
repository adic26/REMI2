begin tran
GO
ALTER TABLE Req.RequestType ADD IsExternal BIT DEFAULT(0) NOT NULL
go

DECLARE @NextLookupID INT
DECLARE @TypeID INT
DECLARE @RequestTypeID INT
DECLARE @DropDownID INT
DECLARE @TextBoxID INT
DECLARE @LookupTypeID INT
DECLARE @LinkID INT
DECLARE @DateTimeID INT

UPDATE Req.RequestType SET IsExternal=1 WHERE DBType <> 'SQL'

SELECT @NextLookupID = MAX(LookupID)+1 FROM Lookups

INSERT INTO LookupType (Name) VALUES ('Yes/No')
INSERT INTO LookupType (Name) VALUES ('Revision')
INSERT INTO LookupType (Name) VALUES ('ReportType')
INSERT INTO LookupType (Name) VALUES ('Status')

SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='RequestType'
SELECT @TypeID=LookupID FROM Lookups WHERE LookupTypeID=@LookupTypeID AND [Values]='QRA'
SELECT @RequestTypeID = RequestTypeID FROM Req.RequestType WHERE TypeID=@TypeID

SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='FieldTypes'

INSERT INTO Lookups (LookupID, LookupTypeID, ParentID, [Values],Description, IsActive)
VALUES (@NextLookupID, @LookupTypeID, null, 'Link', NULL, 1)
SET @NextLookupID = @NextLookupID +1
INSERT INTO Lookups (LookupID, LookupTypeID, ParentID, [Values],Description, IsActive)
VALUES (@NextLookupID, @LookupTypeID, null, 'DateTime', NULL, 1)

SELECT @DropDownID=LookupID FROM Lookups WHERE LookupTypeID=@LookupTypeID AND [Values]='DropDown'
SELECT @TextBoxID=LookupID FROM Lookups WHERE LookupTypeID=@LookupTypeID AND [Values]='TextBox'
SELECT @LinkID=LookupID FROM Lookups WHERE LookupTypeID=@LookupTypeID AND [Values]='Link'
SELECT @DateTimeID=LookupID FROM Lookups WHERE LookupTypeID=@LookupTypeID AND [Values]='DateTime'

SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='Yes/No'

SET @NextLookupID = @NextLookupID +1
INSERT INTO Lookups (LookupID, LookupTypeID, ParentID, [Values],Description, IsActive)
VALUES (@NextLookupID, @LookupTypeID, null, 'Yes', NULL, 1)
SET @NextLookupID = @NextLookupID +1
INSERT INTO Lookups (LookupID, LookupTypeID, ParentID, [Values],Description, IsActive)
VALUES (@NextLookupID, @LookupTypeID, null, 'No', NULL, 1)
SET @NextLookupID = @NextLookupID +1

SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='Revision'

INSERT INTO Lookups (LookupID, LookupTypeID, ParentID, [Values],Description, IsActive)
VALUES (@NextLookupID, @LookupTypeID, null, 'M1', NULL, 1)
SET @NextLookupID = @NextLookupID +1
INSERT INTO Lookups (LookupID, LookupTypeID, ParentID, [Values],Description, IsActive)
VALUES (@NextLookupID, @LookupTypeID, null, 'M1.5', NULL, 1)
SET @NextLookupID = @NextLookupID +1
INSERT INTO Lookups (LookupID, LookupTypeID, ParentID, [Values],Description, IsActive)
VALUES (@NextLookupID, @LookupTypeID, null, 'M2', NULL, 1)
SET @NextLookupID = @NextLookupID +1
INSERT INTO Lookups (LookupID, LookupTypeID, ParentID, [Values],Description, IsActive)
VALUES (@NextLookupID, @LookupTypeID, null, 'M2.5', NULL, 1)
SET @NextLookupID = @NextLookupID +1
INSERT INTO Lookups (LookupID, LookupTypeID, ParentID, [Values],Description, IsActive)
VALUES (@NextLookupID, @LookupTypeID, null, 'M3', NULL, 1)
SET @NextLookupID = @NextLookupID +1
INSERT INTO Lookups (LookupID, LookupTypeID, ParentID, [Values],Description, IsActive)
VALUES (@NextLookupID, @LookupTypeID, null, 'M3.5', NULL, 1)
SET @NextLookupID = @NextLookupID +1
INSERT INTO Lookups (LookupID, LookupTypeID, ParentID, [Values],Description, IsActive)
VALUES (@NextLookupID, @LookupTypeID, null, 'M4', NULL, 1)
SET @NextLookupID = @NextLookupID +1
INSERT INTO Lookups (LookupID, LookupTypeID, ParentID, [Values],Description, IsActive)
VALUES (@NextLookupID, @LookupTypeID, null, 'M4.5', NULL, 1)
SET @NextLookupID = @NextLookupID +1
INSERT INTO Lookups (LookupID, LookupTypeID, ParentID, [Values],Description, IsActive)
VALUES (@NextLookupID, @LookupTypeID, null, 'M5', NULL, 1)
SET @NextLookupID = @NextLookupID +1
INSERT INTO Lookups (LookupID, LookupTypeID, ParentID, [Values],Description, IsActive)
VALUES (@NextLookupID, @LookupTypeID, null, 'M5.5', NULL, 1)
SET @NextLookupID = @NextLookupID +1
INSERT INTO Lookups (LookupID, LookupTypeID, ParentID, [Values],Description, IsActive)
VALUES (@NextLookupID, @LookupTypeID, null, 'M6', NULL, 1)
SET @NextLookupID = @NextLookupID +1

SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='ReportType'

INSERT INTO Lookups (LookupID, LookupTypeID, ParentID, [Values],Description, IsActive)
VALUES (@NextLookupID, @LookupTypeID, null, 'Carrier', NULL, 1)
SET @NextLookupID = @NextLookupID +1
INSERT INTO Lookups (LookupID, LookupTypeID, ParentID, [Values],Description, IsActive)
VALUES (@NextLookupID, @LookupTypeID, null, 'Core', NULL, 1)
SET @NextLookupID = @NextLookupID +1
INSERT INTO Lookups (LookupID, LookupTypeID, ParentID, [Values],Description, IsActive)
VALUES (@NextLookupID, @LookupTypeID, null, 'Extended', NULL, 1)
SET @NextLookupID = @NextLookupID +1

SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='Status'

INSERT INTO Lookups (LookupID, LookupTypeID, ParentID, [Values],Description, IsActive)
VALUES (@NextLookupID, @LookupTypeID, null, 'Submitted', NULL, 1)
SET @NextLookupID = @NextLookupID +1
INSERT INTO Lookups (LookupID, LookupTypeID, ParentID, [Values],Description, IsActive)
VALUES (@NextLookupID, @LookupTypeID, null, 'Assigned', NULL, 1)
SET @NextLookupID = @NextLookupID +1
INSERT INTO Lookups (LookupID, LookupTypeID, ParentID, [Values],Description, IsActive)
VALUES (@NextLookupID, @LookupTypeID, null, 'Received', NULL, 1)
SET @NextLookupID = @NextLookupID +1
INSERT INTO Lookups (LookupID, LookupTypeID, ParentID, [Values],Description, IsActive)
VALUES (@NextLookupID, @LookupTypeID, null, 'Verified', NULL, 1)
SET @NextLookupID = @NextLookupID +1
INSERT INTO Lookups (LookupID, LookupTypeID, ParentID, [Values],Description, IsActive)
VALUES (@NextLookupID, @LookupTypeID, null, 'PM Review', NULL, 1)
SET @NextLookupID = @NextLookupID +1
INSERT INTO Lookups (LookupID, LookupTypeID, ParentID, [Values],Description, IsActive)
VALUES (@NextLookupID, @LookupTypeID, null, 'Completed', NULL, 1)
SET @NextLookupID = @NextLookupID +1
INSERT INTO Lookups (LookupID, LookupTypeID, ParentID, [Values],Description, IsActive)
VALUES (@NextLookupID, @LookupTypeID, null, 'Canceled', NULL, 1)
SET @NextLookupID = @NextLookupID +1
INSERT INTO Lookups (LookupID, LookupTypeID, ParentID, [Values],Description, IsActive)
VALUES (@NextLookupID, @LookupTypeID, null, 'Closed - Pass', NULL, 1)
SET @NextLookupID = @NextLookupID +1
INSERT INTO Lookups (LookupID, LookupTypeID, ParentID, [Values],Description, IsActive)
VALUES (@NextLookupID, @LookupTypeID, null, 'Closed - Fail', NULL, 1)
SET @NextLookupID = @NextLookupID +1
INSERT INTO Lookups (LookupID, LookupTypeID, ParentID, [Values],Description, IsActive)
VALUES (@NextLookupID, @LookupTypeID, null, 'Closed - No Result', NULL, 1)

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Request Status',null,@DropDownID,null,0,1,1,@LookupTypeID,1)

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Requestor',null,@TextBoxID,null,0,1,2,NULL,1)

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Received Date',null,@DateTimeID,null,0,1,3,NULL,1)

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Executive Summary',null,@TextBoxID,null,0,1,4,NULL,1)

SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='TestCenter'

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Test Centre Location',null,@DropDownID,null,0,1,5,@LookupTypeID,1)

SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='Department'

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Department',null,@DropDownID,null,0,1,6,@LookupTypeID,1)

SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='RequestPurpose'

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Purpose',null,@DropDownID,null,0,1,7,@LookupTypeID,1)

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Requested Test',null,@DropDownID,null,0,1,8,NULL,1)

SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='Priority'

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Priority',null,@DropDownID,null,0,1,9,@LookupTypeID,1)

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Reason For Request',null,@TextBoxID,null,0,1,10,NULL,1)

SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='Yes/No'

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Is Report Required',null,@DropDownID,null,0,1,11,@LookupTypeID,1)

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Report Required by',null,@DateTimeID,null,0,1,12,NULL,1)

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'FA Required',null,@DropDownID,null,0,1,13,@LookupTypeID,1)

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Sample Available Date',null,@DateTimeID,null,0,1,14,NULL,1)

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Return Material?',null,@DropDownID,null,0,1,15,@LookupTypeID,1)

SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='ProductType'

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Product Type',null,@DropDownID,null,0,1,16,@LookupTypeID,1)

SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='AccessoryType'

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Accessory Group',null,@DropDownID,null,0,1,17,@LookupTypeID,1)

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Product Group',null,@DropDownID,null,0,1,18,NULL,1)

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Assembly  Number',null,@TextBoxID,null,0,1,19,NULL,1)

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Assembly  Revision',null,@TextBoxID,null,0,1,20,NULL,1)

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'POP Number',null,@TextBoxID,null,0,1,21,NULL,1)

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'POP Revision',null,@TextBoxID,null,0,1,22,NULL,1)

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Part Name Under Test',null,@TextBoxID,null,0,1,23,NULL,1)

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Part Number',null,@TextBoxID,null,0,1,24,NULL,1)

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Manufacturer of Part Under Test',null,@TextBoxID,null,0,1,25,NULL,1)

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'BSN/PIN',null,@TextBoxID,null,0,1,26,NULL,1)

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'CPR',null,@TextBoxID,null,0,1,27,NULL,1)

SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='Revision'

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Mechanical Tools',null,@DropDownID,null,0,1,28,@LookupTypeID,1)

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Sample Size',null,@TextBoxID,null,0,1,29,NULL,1)

SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='Yes/No'

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Include in TEMPO',null,@DropDownID,null,0,1,30,@LookupTypeID,1)

SELECT @LookupTypeID = LookupTypeID FROM LookupType WHERE Name='ReportType'

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Report Type',null,@DropDownID,null,0,1,31,@LookupTypeID,1)

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Request Link',null,@LinkID,null,0,1,32,NULL,1)

insert into Req.ReqFieldSetup (RequestTypeID,Name,Description,FieldTypeID,FieldValidationID,Archived,IsRequired,DisplayOrder,OptionsTypeID, ColumnOrder)
values (@RequestTypeID,'Drop/Tumble Link',null,@LinkID,null,0,1,33,NULL,1)

DELETE rt FROM Req.RequestType rt INNER JOIN Lookups l ON l.LookupID=rt.TypeID WHERE [Values] IN ('SCM','RIT')

ROLLBACK TRAN