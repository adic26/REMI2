BEGIN TRAN

ALTER TABLE Products ADD LookupID INT
go
DECLARE @LookupTypeID INT
DECLARE @MaxLookupID INT

SELECT @MaxLookupID = MAX(LookupID)+1 FROM Lookups

IF NOT EXISTS (SELECT LookupTypeID FROM LookupType WHERE Name='Products')
BEGIN
	INSERT INTO LookupType (Name) VALUES ('Products')
END

SELECT @LookupTypeID=LookupTypeID FROM LookupType WHERE Name='Products'

INSERT INTO Lookups (LookupID, LookupTypeID, IsActive, [Values])
SELECT @MaxLookupID + ROW_NUMBER() OVER (ORDER BY ID) AS RowID, @LookupTypeID AS LookupTypeID, p.IsActive, ProductGroupName
FROM Products p

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF__Products__IsActi__37D02F05]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[Products] DROP CONSTRAINT [DF__Products__IsActi__37D02F05]
END

UPDATE p
SET p.LookupID=l.LookupID
FROM Lookups l
inner join Products p on p.ProductGroupName=l.[Values]
WHERE l.LookupTypeID=@LookupTypeID

update Req.ReqFieldSetup set OptionsTypeID=@LookupTypeID where Name like '%Product Group%'

ALTER TABLE Products ALTER COLUMN LookupID INT NOT NULL

IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[Products]') AND name = N'UIX_Products_ProductGroupName')
DROP INDEX [UIX_Products_ProductGroupName] ON [dbo].[Products] WITH ( ONLINE = OFF )
GO

IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[Products]') AND name = N'IX_Products_PG_IsActive')
DROP INDEX [IX_Products_PG_IsActive] ON [dbo].[Products] WITH ( ONLINE = OFF )
GO
/****** Object:  Index [IX_Products_PG_IsActive]    Script Date: 01/27/2015 15:19:35 ******/
CREATE NONCLUSTERED INDEX [IX_Products_PG_IsActive] ON [dbo].[Products] 
(
	[LookupID] ASC
)
INCLUDE ( [ID]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

declare @lookupid int
select @lookupid = lookupid from Lookups where [Values]='TextArea'

update Req.ReqFieldSetup set FieldTypeID=@lookupid where Name like '%execut%' or Name like '%reason%'

update Req.ReqFieldSetup set Name='Job' where Name ='Requested Test'

update Req.ReqFieldMapping set ExtField='Job' where IntField='requestedtest'

update Req.ReqFieldSetup 
set ParentReqFieldSetupID = (select ReqFieldSetupID from Req.ReqFieldSetup s where s.RequestTypeID=Req.ReqFieldSetup.RequestTypeID and s.Name='Product Type')
where Name like '%access%' and Archived=0

insert into LookupsHierarchy (ParentLookupTypeID, ChildLookupTypeID, ParentLookupID,ChildLookupID,RequestTypeID)
values (12,	1,	71,	0,	1)
insert into LookupsHierarchy (ParentLookupTypeID, ChildLookupTypeID, ParentLookupID,ChildLookupID,RequestTypeID)
values (12,	1,	70,	0,	1)
insert into LookupsHierarchy (ParentLookupTypeID, ChildLookupTypeID, ParentLookupID,ChildLookupID,RequestTypeID)
values (12,	1,	72,	0,	1)
insert into LookupsHierarchy (ParentLookupTypeID, ChildLookupTypeID, ParentLookupID,ChildLookupID,RequestTypeID)
values (12,	1,	73,	0,	1)

ALTER TABLE dbo.UserDetails ADD IsAdmin BIT DEFAULT(0) NULL

go
EXEC sp_RENAME 'Products.ProductGroupName' , '_ProductGroupName', 'COLUMN'
EXEC sp_RENAME 'Products.IsActive' , '_IsActive', 'COLUMN'
go

ALTER TABLE Products ALTER COLUMN _ProductGroupName NVARCHAR(150) NULL
go
ALTER TABLE Products ALTER COLUMN _IsActive BIT NULL
go

ROLLBACK TRAN