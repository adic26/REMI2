begin tran
go
ALTER TABLE dbo.ProductConfigurationUpload Add PCName NVARCHAR(200)
ALTER TABLE ProductConfiguration ADD UploadID INT
ALTER TABLE ProductConfigurationAudit ADD UploadID INT
ALTER TABLE [dbo].ProductConfiguration  WITH CHECK ADD  CONSTRAINT [FK_ProductConfigurationUpload_ID] FOREIGN KEY([UploadID])
REFERENCES [dbo].ProductConfigurationUpload ([ID])
go
UPDATE ProductConfigurationUpload SET PCName='ProductConfiguration' WHERE PCName IS NULL
UPDATE pc
SET pc.UploadID=pcu.ID
FROM ProductConfiguration pc
INNER JOIN ProductConfigurationUpload pcu ON pcu.TestID=pc.TestID and pcu.ProductID=pc.ProductID

UPDATE pc
SET pc.UploadID=pcu.ID
FROM ProductConfigurationAudit pc
INNER JOIN ProductConfigurationUpload pcu ON pcu.TestID=pc.TestID and pcu.ProductID=pc.ProductID

INSERT INTO ProductConfigurationUpload (IsProcessed, LastUser, PCName, ProductConfigXML, ProductID, TestID)
SELECT DISTINCT 1 as IsProcessed, LastUser AS LastUser, 'ProductConfiguration' AS PCName, '' AS ProductConfigXML, ProductID AS ProductID, TestID AS TestID
from ProductConfiguration
WHERE UploadID IS NULL AND NOT EXISTS (SELECT * FROM ProductConfigurationUpload u where ProductConfiguration.ProductID=u.ProductID and ProductConfiguration.TestID=u.TestID)

UPDATE pc
SET pc.UploadID=pcu.ID
FROM ProductConfiguration pc
INNER JOIN ProductConfigurationUpload pcu ON pcu.TestID=pc.TestID and pcu.ProductID=pc.ProductID
WHERE UploadID IS NULL

UPDATE pc
SET pc.UploadID=pcu.ID
FROM ProductConfigurationAudit pc
INNER JOIN ProductConfigurationUpload pcu ON pcu.TestID=pc.TestID and pcu.ProductID=pc.ProductID
WHERE UploadID IS NULL

go
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_ProductConfiguration_Tests]') AND parent_object_id = OBJECT_ID(N'[dbo].[ProductConfiguration]'))
	ALTER TABLE [dbo].[ProductConfiguration] DROP CONSTRAINT [FK_ProductConfiguration_Tests]
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[ProductConfiguration]') AND name = N'DBA_ProductConfiguration_TestID')
	DROP INDEX [DBA_ProductConfiguration_TestID] ON [dbo].[ProductConfiguration] WITH ( ONLINE = OFF )
ALTER TABLE dbo.ProductConfiguration DROP COLUMN TestID
ALTER TABLE dbo.ProductConfigurationAudit DROP COLUMN TestID
go
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_ProductConfiguration_Products]') AND parent_object_id = OBJECT_ID(N'[dbo].[ProductConfiguration]'))
	ALTER TABLE [dbo].[ProductConfiguration] DROP CONSTRAINT [FK_ProductConfiguration_Products]
ALTER TABLE dbo.ProductConfiguration DROP COLUMN ProductID
ALTER TABLE dbo.ProductConfigurationAudit DROP COLUMN ProductID
go
alter TRIGGER [dbo].[ProductConfigurationAuditInsertUpdate]
   ON  [dbo].[ProductConfiguration]
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
   select ParentID, ViewOrder, NodeName, UploadID from Inserted
   except
   select ParentID, ViewOrder, NodeName, UploadID from Deleted
) a

if ((@count) >0)
begin
	insert into ProductConfigurationAudit (productConfigID, ParentID, ViewOrder, NodeName, UploadID, Action, UserName)
	Select ID, ParentID, ViewOrder, NodeName, UploadID, @action, LastUser
	from inserted
END
END
GO
alter TRIGGER [dbo].[ProductConfigurationAuditDelete]
   ON  [dbo].[ProductConfiguration]
    for  delete
AS 
BEGIN
 SET NOCOUNT ON;
 
  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here
	
insert into ProductConfigurationAudit (ProductConfigID, ParentID, ViewOrder, NodeName, UploadID, Action, UserName)
Select ID, ParentID, ViewOrder, NodeName, UploadID, 'D', LastUser
from deleted
END
GO
alter table productconfigurationupload alter column PCName NVARCHAR(200) NOT NULL
GO
ALTER TABLE [ProductConfigurationUpload] ADD CONSTRAINT ProductConfigurationUpload_ProductID_TestID_PCName UNIQUE (ProductID, TestID, PCName); 
GO
CREATE TABLE [dbo].[ProductConfigurationVersion](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[UploadID] [int] NOT NULL,
	[PCXML] [xml] NOT NULL,
	[LastUser] [nvarchar](255) NOT NULL,
	[VersionNum] [int] NOT NULL,
 CONSTRAINT [PK_ProductConfigurationVersion] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[ProductConfigurationVersion]  WITH CHECK ADD  CONSTRAINT [FK_ProductConfigurationVersion_ProductConfigurationUpload] FOREIGN KEY([UploadID])
REFERENCES [dbo].[ProductConfigurationUpload] ([ID])
GO

ALTER TABLE [dbo].[ProductConfigurationVersion] CHECK CONSTRAINT [FK_ProductConfigurationVersion_ProductConfigurationUpload]
GO

INSERT INTO ProductConfigurationVersion (PCXML, UploadID, VersionNum, LastUser)
SELECT ProductConfigXML AS PCXML, ID AS UploadID, 1 AS VersionNum, LastUser FROM ProductConfigurationUpload
GO
alter table ProductConfigurationUpload drop column ProductConfigXML
Go

select * from ProductConfiguration where UploadID is null
rollback tran
