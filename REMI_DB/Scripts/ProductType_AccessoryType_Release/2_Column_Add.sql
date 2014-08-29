begin tran

alter table Batches add ProductTypeID INT NULL
GO
alter table Batches add AccessoryGroupID INT NULL
GO
alter table BatchesAudit add ProductTypeID INT NULL
GO
alter table BatchesAudit add AccessoryGroupID INT NULL
GO

rollback tran