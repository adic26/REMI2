begin tran

alter table Batches add ProductID INT NULL
alter table BatchesAudit add ProductID INT NULL
alter table ProductConfiguration add ProductID INT NULL
alter table ProductConfigurationAudit add ProductID INT NULL
alter table ProductSettings add ProductID INT NULL
alter table ProductSettingsAudit add ProductID INT NULL
alter table ProductManagers add ProductID INT NULL
alter table ProductManagersAudit add ProductID INT NULL


rollback tran