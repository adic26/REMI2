begin tran


exec sp_RENAME 'Batches.ProductType' , '_ProductType', 'COLUMN'
GO

exec sp_RENAME 'Batches.AccessoryGroupName' , '_AccessoryGroupName', 'COLUMN'
GO
exec sp_RENAME 'BatchesAudit.ProductType' , '_ProductType', 'COLUMN'
GO

exec sp_RENAME 'BatchesAudit.AccessoryGroupName' , '_AccessoryGroupName', 'COLUMN'
GO

rollback tran