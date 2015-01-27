BEGIN TRAN

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

ALTER TABLE Products ADD LookupID INT

EXEC sp_RENAME 'Products.ProductGroupName' , '_ProductGroupName', 'COLUMN'

UPDATE p
SET p.LookupID=l.LookupID
FROM Lookups l
inner join Products p on p._ProductGroupName=l.[Values]
WHERE l.LookupTypeID=@LookupTypeID


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
	[LookupID] ASC,
	[IsActive] ASC
)
INCLUDE ( [ID]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

ALTER TABLE Products ALTER COLUMN _ProductGroupName NVARCHAR(150) NULL

ROLLBACK TRAN