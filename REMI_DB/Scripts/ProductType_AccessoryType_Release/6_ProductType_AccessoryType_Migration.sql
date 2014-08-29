begin tran

DECLARE @productLookupID INT
DECLARE @accessoryGroupID INT

SELECT @accessoryGroupID = LookupID FROM Lookups WHERE Type='Exceptions' AND [Values]='AccessoryGroupName'
SELECT @productLookupID = LookupID FROM Lookups WHERE Type='Exceptions' AND [Values]='ProductType'

UPDATE Lookups SET [Values]='ProductTypeID' WHERE Type='Exceptions' AND [Values]='ProductType'
UPDATE Lookups SET [Values]='AccessoryGroupID' WHERE Type='Exceptions' AND [Values]='AccessoryGroupName'

UPDATE TestExceptions
SET Value=(SELECT LookupID FROM Lookups WHERE Type='ProductType' AND [Values]=TestExceptions.Value), LastUser='ogaudreault'
WHERE LookupID=@productLookupID

UPDATE TestExceptions
SET Value=(SELECT LookupID FROM Lookups WHERE Type='AccessoryType' AND [Values]=TestExceptions.Value), LastUser='ogaudreault'
WHERE LookupID=@accessoryGroupID


update Batches
set batches.ProductTypeID=Lookups.LookupID
from Batches
inner join Lookups on Lookups.Type='ProductType' and Lookups.[Values]=batches._ProductType
where Batches._ProductType IS NOT NULL


update Batches
set batches.AccessoryGroupID=Lookups.LookupID
from Batches
inner join Lookups on Lookups.Type='AccessoryType' and Lookups.[Values]=batches._AccessoryGroupName
where Batches._AccessoryGroupName IS NOT NULL AND LTRIM(RTRIM(_AccessoryGroupName)) <> ''




rollback tran