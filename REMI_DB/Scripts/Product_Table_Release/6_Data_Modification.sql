BEGIN TRAN

DBCC CHECKIDENT (Products, reseed, 0)
GO

INSERT INTO Products (ProductGroupName)
SELECT DISTINCT _ProductGroupName
FROM Batches
WHERE LTRIM(RTRIM(_ProductGroupName)) <> ''
ORDER BY _ProductGroupName

IF NOT EXISTS (select 1 from Products where ProductGroupName='Rainier R094')
	insert into Products (ProductGroupName) values ('Rainier R094')
	
IF NOT EXISTS (select 1 from Products where ProductGroupName='Monaco R028')
	insert into Products (ProductGroupName,isactive) values ('Monaco R028',0)
	
IF NOT EXISTS (select 1 from Products where ProductGroupName='Quark 2 plus  Family')
	insert into Products (ProductGroupName,isactive) values ('Quark 2 plus  Family',0)

SET IDENTITY_INSERT Products ON

INSERT INTO Products(ID,ProductGroupName,IsActive) VALUES (0,'N/A',0)

SET IDENTITY_INSERT Products OFF

UPDATE ProductManagersAudit
SET ProductID=Products.ID
FROM ProductManagersAudit
	INNER JOIN Products ON ltrim(rtrim(ProductManagersAudit._productGroupName))=ltrim(rtrim(Products.ProductGroupName))

UPDATE ProductManagers
SET ProductID=Products.ID
FROM ProductManagers
	INNER JOIN Products ON ltrim(rtrim(ProductManagers._productGroup))=ltrim(rtrim(Products.ProductGroupName))

UPDATE ProductSettingsAudit
SET ProductID=Products.ID
FROM ProductSettingsAudit
	INNER JOIN Products ON ltrim(rtrim(ProductSettingsAudit._productGroupName))=ltrim(rtrim(Products.ProductGroupName))

UPDATE ProductSettings
SET ProductID=Products.ID
FROM ProductSettings
	INNER JOIN Products ON ltrim(rtrim(ProductSettings._productGroupName))=ltrim(rtrim(Products.ProductGroupName))

UPDATE ProductConfiguration
SET ProductID=Products.ID
FROM ProductConfiguration
	INNER JOIN Products ON ltrim(rtrim(ProductConfiguration._productGroupName))=ltrim(rtrim(Products.ProductGroupName))

UPDATE ProductConfigurationAudit
SET ProductID=Products.ID
FROM ProductConfigurationAudit
	INNER JOIN Products ON ltrim(rtrim(ProductConfigurationAudit._productGroupName))=ltrim(rtrim(Products.ProductGroupName))

print 'update to update batchesaudit'
UPDATE BatchesAudit
SET ProductID=Products.ID
FROM BatchesAudit
	INNER JOIN Products ON ltrim(rtrim(BatchesAudit._productGroupName))=ltrim(rtrim(Products.ProductGroupName))
where ProductID IS NULL

print 'update to update batches'
UPDATE Batches
SET ProductID=Products.ID
FROM Batches
	INNER JOIN Products ON ltrim(rtrim(Batches._productGroupName))=ltrim(rtrim(Products.ProductGroupName))
where ProductID IS NULL

UPDATE Batches
SET ProductID=(select id from Products where ProductGroupName='Not Product Specific')
where ProductID is null and LTRIM(RTRIM(_productgroupname)) = ''	
	


update ProductManagersAudit set ProductID=0 where ProductID is null
update ProductSettingsAudit set ProductID=0 where ProductID is null
update BatchesAudit set ProductID=0 where ProductID is null


ROLLBACK TRAN