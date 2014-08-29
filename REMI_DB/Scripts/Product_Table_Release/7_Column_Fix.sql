begin tran

alter table Batches alter column ProductID INT NOT NULL
alter table ProductConfiguration alter column ProductID INT NOT NULL
alter table ProductConfigurationAudit alter column ProductID INT NOT NULL
alter table ProductSettings alter column ProductID INT NOT NULL
alter table ProductManagers alter column ProductID INT NOT NULL

alter table BatchesAudit alter column ProductID INT NOT NULL
alter table ProductSettingsAudit alter column ProductID INT NOT NULL
alter table ProductManagersAudit alter column ProductID INT NOT NULL

rollback tran