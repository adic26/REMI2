begin tran

declare @maxid int
select @maxid = max(LookupID)+1 from lookups

if not exists (select 1 from Lookups where Type='exceptions' and [values]='ProductID')
begin
	insert into Lookups values (@maxid,'Exceptions','ProductID')
end
else
begin
	select @maxid=lookupid from lookups where Type='exceptions' and [values]='ProductID'
end

select testexceptions.id, @maxid as lookupid, p.ID As Value, 'ogaudreault' as LastUser, NULL as oldid,GETDATE() as inserttime
into #temp
from TestExceptions
inner join Products p on ltrim(rtrim(TestExceptions.Value)) = ltrim(rtrim(p.ProductGroupName))
where LookupID=1



insert into TestExceptions (ID,LookupID,Value,LastUser,OldID,InsertTime)
select id,lookupid,value, lastuser,oldid, inserttime
from #temp

drop table #temp

rollback tran
