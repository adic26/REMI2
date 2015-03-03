begin tran

ALTER TABLE [dbo].[Users] ADD
[IsActive] [int] NOT NULL CONSTRAINT [DF__Users__IsActive__21ABE3BC] DEFAULT ((1)),
[DefaultPage] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
GO
ALTER TABLE [dbo].[UsersAudit] ADD
[IsActive] [int] NULL ,
[DefaultPage] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
GO

update UsersAudit set IsActive=1
update Users set IsActive=1

alter table UsersAudit alter column IsActive INT NOT NULL
alter table Users alter column IsActive INT NOT NULL

rollback tran