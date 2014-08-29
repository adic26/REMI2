begin tran

select *
into _TestExceptionsRemoveProductGroupName
FROM TestExceptions
WHERE LookupID=1
GO
DELETE FROM TestExceptions WHERE LookupID=1
GO
UPDATE Lookups SET IsActive=0 WHERE LookupID=1
GO
DROP INDEX [IX_TestExceptions_LookupID_Val] ON [dbo].[TestExceptions] WITH ( ONLINE = OFF )
GO
alter table TestExceptions alter column Value INT NOT NULL
GO
CREATE NONCLUSTERED INDEX [IX_TestExceptions_LookupID_Val] ON [dbo].[TestExceptions] 
(
	[LookupID] ASC,
	[Value] ASC
)
INCLUDE ( [ID]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
rollback tran