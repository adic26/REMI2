begin tran
exec sp_RENAME 'ProductManagersAudit.productGroupName' , '_productGroupName', 'COLUMN'
GO
exec sp_RENAME 'ProductManagers.productGroup' , '_productGroup', 'COLUMN'
GO
exec sp_RENAME 'Batches.[ProductGroupName]' , '_ProductGroupName', 'COLUMN'
GO
exec sp_RENAME 'BatchesAudit.[ProductGroupName]' , '_ProductGroupName', 'COLUMN'
GO
exec sp_RENAME 'ProductSettingsAudit.productGroupName' , '_productGroupName', 'COLUMN'
GO
exec sp_RENAME 'ProductSettings.productGroupName' , '_productGroupName', 'COLUMN'
GO
exec sp_RENAME 'ProductConfigurationAudit.productGroupName' , '_productGroupName', 'COLUMN'
GO
exec sp_RENAME 'ProductConfiguration.productGroupName' , '_productGroupName', 'COLUMN'

rollback tran