begin tran
go
EXEC sp_rename 'dbo.Products.TSDContact', '_TSDContact', 'COLUMN'
GO
ALTER TABLE dbo.UserDetails ADD IsTSDContact BIT DEFAULT(0) NULL
GO
update UserDetails set IsTSDContact=0

UPDATE ud
SET ud.IsTSDContact=1
FROM UserDetails ud
inner join Users u on ud.UserID=u.ID
inner join Products p on ud.LookupID=p.LookupID AND p._TSDContact=u.LDAPLogin
WHERE ISNULL(_TSDContact,'') <> '' and p.LookupID in (select LookupID from UserDetails where UserID=u.id)

INSERT INTO UserDetails (LookupID,LastUser,IsTSDContact,UserID)
select p.LookupID, u.LDAPLogin, 1, u.ID
from Products p
inner join Users u on p._TSDContact=u.LDAPLogin
where ISNULL(_TSDContact,'') <> ''
and LookupID not in (select LookupID from UserDetails where UserID=u.id)
GO
ALTER PROCEDURE remispGetUserDetails @UserID INT
AS
BEGIN
	SELECT lt.Name, l.[Values], l.LookupID, ISNULL(ud.IsDefault, 0) AS IsDefault, ud.IsProductManager, ud.IsTSDContact
	FROM UserDetails ud
		INNER JOIN Lookups l ON l.LookupID=ud.LookupID
		INNER JOIN LookupType lt ON lt.LookupTypeID=l.LookupTypeID
	WHERE ud.UserID=@UserID
	ORDER BY lt.Name, l.[Values]
END
GO
GRANT EXECUTE ON remispGetUserDetails TO REMI
GO
DROP TABLE dbo._UsersProducts
DROP TABLE dbo._UsersProductsAudit
GO
ALTER TABLE dbo.Products DROP COLUMN _ProductGroupName
ALTER TABLE dbo.Products DROP COLUMN _IsActive
GO
CREATE PROCEDURE Relab.remispGetObservationParameters @MeasurementID INT
AS
BEGIN
	select [Relab].[ResultsObservation] (@MeasurementID) AS Observation
END
GO
GRANT EXECUTE ON Relab.remispGetObservationParameters TO REMI
GO






ALTER TABLE LookupType ADD IsSecureType BIT DEFAULT(0)
UPDATE LookupType SET IsSecureType=1 WHERE Name='Products'
GO
ALTER TABLE ProductSettings ADD LookupID INT
GO
UPDATE ps
SET ps.LookupID=p.LookupID
FROM ProductSettings ps
INNER JOIN Products p ON ps.ProductID=p.ID
GO
ALTER TABLE ProductSettings ALTER COLUMN LookupID INT NOT NULL
ALTER TABLE [dbo].[ProductSettings]  WITH CHECK ADD  CONSTRAINT [FK_ProductSettings_Lookups] FOREIGN KEY([LookupID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO
ALTER TABLE [dbo].[ProductSettings] CHECK CONSTRAINT [FK_ProductSettings_Lookups]
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_ProductSettings_Products]') AND parent_object_id = OBJECT_ID(N'[dbo].[ProductSettings]'))
ALTER TABLE [dbo].[ProductSettings] DROP CONSTRAINT [FK_ProductSettings_Products]
GO
ALTER TABLE ProductSettings DROP COLUMN ProductID
GO
ALTER TABLE ProductSettingsAudit ADD LookupID INT 
UPDATE ps
SET ps.LookupID=p.LookupID
FROM ProductSettingsAudit ps
INNER JOIN Products p ON ps.ProductID=p.ID
GO
ALTER TABLE ProductSettingsAudit DROP COLUMN ProductID
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[ProductSettingsAuditInsertUpdate]
   ON  [dbo].[ProductSettings]
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
   select LookupID, KeyName, ValueText, DefaultValue from Inserted
   except
   select LookupID, KeyName, ValueText, DefaultValue from Deleted
) a

if ((@count) >0)
begin
	insert into ProductSettingsAudit (
			ProductSettingsId, 
		LookupID,
		KeyName, 
		ValueText,
		DefaultValue,	
		Action)
		Select 
		Id, 
		LookupID,
		KeyName, 
		DefaultValue,
		ValueText,	
	@action from inserted
END
END
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[ProductSettingsAuditDelete]
   ON  [dbo].[ProductSettings]
    for  delete
AS 
BEGIN
 SET NOCOUNT ON;
 
  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here
	
insert into ProductSettingsAudit (
	ProductSettingsId, 
	LookupID,
	KeyName, 
	ValueText,	
	DefaultValue,
	Action)
	Select 
	Id, 
	LookupID,
	KeyName, 
	ValueText,
	DefaultValue,
'D' from deleted

END
GO
drop procedure remispSaveProduct
GO
update l
set l.description = p.QAPLocation
from Products p
inner join Lookups l on l.LookupID=p.LookupID
where ISNULL(QAPLocation,'') <> ''
GO
alter table products drop column _TSDContact
GO
alter table products drop column QAPLocation
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_ProductTestReady_Products]') AND parent_object_id = OBJECT_ID(N'[dbo].[ProductTestReady]'))
ALTER TABLE [dbo].[ProductTestReady] DROP CONSTRAINT [FK_ProductTestReady_Products]
GO
ALTER TABLE dbo.ProductTestReady ADD LookupID INT NULL
GO
ALTER TABLE [dbo].[ProductTestReady]  WITH CHECK ADD  CONSTRAINT [FK_ProductTestReady_Lookups] FOREIGN KEY([LookupID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO
ALTER TABLE [dbo].[ProductTestReady] CHECK CONSTRAINT [FK_ProductTestReady_Lookups]
GO
UPDATE ptr
SET ptr.LookupID = p.LookupID
FROM ProductTestReady ptr
inner join Products p on ptr.ProductID=p.id
GO
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[ProductTestReady]') AND name = N'IX_ProductTestReady_PTS')
DROP INDEX [IX_ProductTestReady_PTS] ON [dbo].[ProductTestReady] WITH ( ONLINE = OFF )
GO
CREATE NONCLUSTERED INDEX [IX_ProductTestReady_PTS] ON [dbo].[ProductTestReady] 
(
	[LookupID] ASC,
	[TestID] ASC,
	[PSID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
alter table producttestready drop column ProductID
GO
drop procedure remispGetProductIDByName
GO
drop procedure remispGetProductNameByID
GO
EXEC sp_rename 'dbo.Batches.ProductID', '_ProductID', 'COLUMN'
GO
ALTER TABLE Batches ADD ProductID INT NULL
GO
UPDATE b
SET b.ProductID=p.LookupID
FROM Batches b
INNER JOIN Products p ON p.ID=b._ProductID
GO
ALTER TABLE Batches ALTER COLUMN ProductID INT NOT NULL
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Batches_Products]') AND parent_object_id = OBJECT_ID(N'[dbo].[Batches]'))
ALTER TABLE [dbo].[Batches] DROP CONSTRAINT [FK_Batches_Products]
GO
ALTER TABLE [dbo].[Batches]  WITH CHECK ADD  CONSTRAINT [FK_Batches_Products] FOREIGN KEY([ProductID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO
ALTER TABLE [dbo].[Batches] CHECK CONSTRAINT [FK_Batches_Products]
GO
drop procedure remispGetFastScanData
GO
EXEC sp_rename 'Req.RequestSetup.ProductID', '_ProductID', 'COLUMN'
GO
ALTER TABLE Req.RequestSetup ADD LookupID INT NULL
GO
update s
set s.LookupID=p.LookupID
FROM Req.RequestSetup s
inner join Products p on s._ProductID=p.id
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[Req].[FK_RequestSetup_Products]') AND parent_object_id = OBJECT_ID(N'[Req].[RequestSetup]'))
ALTER TABLE [Req].[RequestSetup] DROP CONSTRAINT [FK_RequestSetup_Products]
GO
ALTER TABLE [Req].[RequestSetup]  WITH CHECK ADD  CONSTRAINT [FK_RequestSetup_Products] FOREIGN KEY([LookupID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO
ALTER TABLE [Req].[RequestSetup] CHECK CONSTRAINT [FK_RequestSetup_Products]
GO
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[Req].[RequestSetup]') AND name = N'IX_JobProductTestStageBatch')
DROP INDEX [IX_JobProductTestStageBatch] ON [Req].[RequestSetup] WITH ( ONLINE = OFF )
GO
CREATE NONCLUSTERED INDEX [IX_JobProductTestStageBatch] ON [Req].[RequestSetup] 
(
	[JobID] ASC,
	[LookupID] ASC,
	[TestStageID] ASC,
	[TestID] ASC,
	[BatchID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
EXEC sp_rename 'BatchesAudit.ProductID', '_ProductID', 'COLUMN'
GO
ALTER TABLE dbo.BatchesAudit ADD ProductID INT NULL
GO
UPDATE TOP (1000000) b
SET b.ProductID=p.LookupID
FROM BatchesAudit b
INNER JOIN Products p ON p.ID=b._ProductID
where b.ProductID is null
GO
EXEC sp_rename 'dbo.ProductLookups.ProductID', '_ProductID', 'COLUMN'
GO
ALTER TABLE dbo.ProductLookups ADD ProductID INT NULL
GO
UPDATE pl
SET pl.ProductID=p.LookupID
FROM ProductLookups pl
INNER JOIN Products p ON p.ID=pl._ProductID
GO
alter table productlookups alter column ProductID int not null
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_ProductLookups_Products]') AND parent_object_id = OBJECT_ID(N'[dbo].[ProductLookups]'))
ALTER TABLE [dbo].[ProductLookups] DROP CONSTRAINT [FK_ProductLookups_Products]
GO
ALTER TABLE [dbo].[ProductLookups]  WITH CHECK ADD  CONSTRAINT [FK_ProductLookups_Products] FOREIGN KEY([ProductID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO
ALTER TABLE [dbo].[ProductLookups] CHECK CONSTRAINT [FK_ProductLookups_Products]
GO
EXEC sp_rename 'dbo.Calibration.ProductID', '_ProductID', 'COLUMN'
GO
alter table calibration add LookupID INT NULL
GO
UPDATE c
SET c.LookupID=p.LookupID
FROM Calibration c
INNER JOIN Products p ON p.ID=c._ProductID
GO
alter table calibration alter column LookupID INT NOT NULL
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Calibration_Products]') AND parent_object_id = OBJECT_ID(N'[dbo].[Calibration]'))
ALTER TABLE [dbo].[Calibration] DROP CONSTRAINT [FK_Calibration_Products]
GO
ALTER TABLE [dbo].[Calibration]  WITH CHECK ADD  CONSTRAINT [FK_Calibration_Products] FOREIGN KEY([LookupID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO
ALTER TABLE [dbo].[Calibration] CHECK CONSTRAINT [FK_Calibration_Products]
GO
alter table calibration drop column _ProductID
GO
alter table Req.RequestSetup drop column _ProductID
GO
EXEC sp_rename 'dbo.ProductConfigurationUpload.ProductID', '_ProductID', 'COLUMN'
GO
alter table ProductConfigurationUpload add LookupID INT NULL
GO
UPDATE c
SET c.LookupID=p.LookupID
FROM ProductConfigurationUpload c
INNER JOIN Products p ON p.ID=c._ProductID
GO
alter table ProductConfigurationUpload alter column LookupID INT NOT NULL
GO
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[ProductConfigurationUpload]') AND name = N'ProductConfigurationUpload_ProductID_TestID_PCName')
ALTER TABLE [dbo].[ProductConfigurationUpload] DROP CONSTRAINT [ProductConfigurationUpload_ProductID_TestID_PCName]
GO
ALTER TABLE [dbo].[ProductConfigurationUpload] ADD  CONSTRAINT [ProductConfigurationUpload_ProductID_TestID_PCName] UNIQUE NONCLUSTERED 
(
	[LookupID] ASC,
	[TestID] ASC,
	[PCName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_ProductConfigurationUpload_Products]') AND parent_object_id = OBJECT_ID(N'[dbo].[ProductConfigurationUpload]'))
ALTER TABLE [dbo].[ProductConfigurationUpload] DROP CONSTRAINT [FK_ProductConfigurationUpload_Products]
GO
ALTER TABLE [dbo].[ProductConfigurationUpload]  WITH CHECK ADD  CONSTRAINT [FK_ProductConfigurationUpload_Products] FOREIGN KEY([LookupID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO
ALTER TABLE [dbo].[ProductConfigurationUpload] CHECK CONSTRAINT [FK_ProductConfigurationUpload_Products]
GO
alter table ProductConfigurationUpload drop column _ProductID
GO
EXEC sp_rename 'dbo.Products', '_Products'
GO
rollback tran