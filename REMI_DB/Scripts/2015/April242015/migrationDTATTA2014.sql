begin tran
--EXISTING TESTRECORDS
UPDATE tr
set tr.Comment=f.FAILURE_COMMENT
from  dbo._Failures2014_2 f with(nolock)
left outer join dbo._attachments2014_2 a with(nolock) on f.F_ID=a.f_id
left outer join dbo._FailureModes fm with(nolock) on fm.FM_ID=f.FM_ID
left outer join dbo._FailureModes fmp with(nolock) on fmp.FM_ID=fm.PARENT_FM_ID
left outer join dbo._FailureModes fmp2 with(nolock) on fmp2.FM_ID=fmp.PARENT_FM_ID
left outer join dbo._FailureModes fmp3  with(nolock) on fmp3.FM_ID=fmp2.PARENT_FM_ID
left outer join dbo._FailureModes fmp4 with(nolock) on fmp4.FM_ID=fmp3.PARENT_FM_ID
inner join Batches b with(nolock) on f.DESCRIPTION=b.QRANumber
inner join TestUnits tu with(nolock) on tu.BatchUnitNumber=f.UNIT_NUMBER and b.ID=tu.BatchID
inner join Jobs j with(nolock) on j.JobName=b.JobName
inner join TestStages ts with(nolock) on ts.JobID=j.ID and ts.TestStageName like convert(nvarchar,f.DROP_NUM) + ' %' and ts.TestStageName like '%' + convert(nvarchar,f.[TYPE]) + '%'
inner join Tests t with(nolock) on ts.TestID=t.id
inner join TestRecords tr with(nolock) on tr.TestUnitID=tu.ID and tr.TestStageID=ts.ID and tr.TestID=t.id
where f.DESCRIPTION NOT IN (SELECT DESCRIPTION from _Failures2014_1 with(nolock))
and exists (select 1 from TestRecords tr with(nolock) where tr.TestUnitID=tu.ID and tr.TestStageID=ts.ID and tr.TestID=t.id)

print '1'

-- NEW TEST RECORDS
INSERT INTO TestRecords (TestUnitID, Status, FailDocNumber, TestStageName, JobName, TestName, RelabVersion, LastUser, Comment,ResultSource, FailDocRQID, TestID, TestStageID, FunctionalType)
select distinct 
	tu.ID as TestUnitID,
	1 as Status,
	null as FailDocNumber,
	ts.TestStageName as TestStageName,
	b.JobName as JobName,
	t.TestName as TestName,
	1 as RelabVersion,
	'REMI' as LastUser,
	(select top 1 f2.FAILURE_COMMENT from _Failures2014_2 f2 where f2.UNIT_NUMBER=f.UNIT_NUMBER and f2.DROP_NUM=f.DROP_NUM and f2.JU_ID=f.JU_ID) as Comment,
	3 as ResultSource,
	null as FailDocRQID,
	t.ID as TestID,
	ts.ID as TestStageID,
	NULL as FunctionalType
FROM dbo._Failures2014_2 f with(nolock)
left outer join dbo._attachments2014_2 a on f.F_ID=a.f_id
left outer join dbo._FailureModes fm with(nolock) on fm.FM_ID=f.FM_ID
left outer join dbo._FailureModes fmp with(nolock) on fmp.FM_ID=fm.PARENT_FM_ID
left outer join dbo._FailureModes fmp2 with(nolock) on fmp2.FM_ID=fmp.PARENT_FM_ID
left outer join dbo._FailureModes fmp3 with(nolock) on fmp3.FM_ID=fmp2.PARENT_FM_ID
left outer join dbo._FailureModes fmp4 with(nolock) on fmp4.FM_ID=fmp3.PARENT_FM_ID
inner join Batches b with(nolock) on f.DESCRIPTION=b.QRANumber
inner join TestUnits tu with(nolock) on tu.BatchUnitNumber=f.UNIT_NUMBER and b.ID=tu.BatchID
inner join Jobs j with(nolock) on j.JobName=b.JobName
inner join TestStages ts with(nolock) on ts.JobID=j.ID and ts.TestStageName like convert(nvarchar,f.DROP_NUM) + ' %' and ts.TestStageName like '%' + convert(nvarchar,f.[TYPE]) + '%'
inner join Tests t with(nolock) on ts.TestID=t.id
where f.DESCRIPTION NOT IN (SELECT DESCRIPTION from _Failures2014_1 with(nolock))
and not exists (select 1 from TestRecords tr with(nolock) where tr.TestUnitID=tu.ID and tr.TestStageID=ts.ID and tr.TestID=t.id)
 
print '2'
 INSERT INTO TestRecords (TestUnitID, Status, FailDocNumber, TestStageName, JobName, TestName, RelabVersion, LastUser, Comment,ResultSource, FailDocRQID, TestID, TestStageID, FunctionalType)
 select distinct 
	tu.ID as TestUnitID,
	1 as Status,
	null as FailDocNumber,
	ts.TestStageName as TestStageName,
	b.JobName as JobName,
	ISNULL((select top 1 testname from testrecords r with(nolock) where r.testunitid=tu.id and r.teststagename like '%post%'),'Functional') as testname,
	1 as RelabVersion,
	'REMI' as LastUser,
	(select top 1 f2.FAILURE_COMMENT from _Failures2014_2 f2 with(nolock) where f2.UNIT_NUMBER=f.UNIT_NUMBER and f2.DROP_NUM=f.DROP_NUM and f2.JU_ID=f.JU_ID) as Comment,
	3 as ResultSource,
	null as FailDocRQID,
	ISNULL((select top 1 testid from testrecords r with(nolock) where r.testunitid=tu.id and r.teststagename like '%post%'),1280) as TestID,
	ts.ID as TestStageID,
	NULL as FunctionalType
FROM dbo._Failures2014_2 f with(nolock)
left outer join dbo._attachments2014_2 a with(nolock) on f.F_ID=a.f_id
left outer join dbo._FailureModes fm with(nolock) on fm.FM_ID=f.FM_ID
left outer join dbo._FailureModes fmp with(nolock) on fmp.FM_ID=fm.PARENT_FM_ID
left outer join dbo._FailureModes fmp2 with(nolock) on fmp2.FM_ID=fmp.PARENT_FM_ID
left outer join dbo._FailureModes fmp3 with(nolock) on fmp3.FM_ID=fmp2.PARENT_FM_ID
left outer join dbo._FailureModes fmp4 with(nolock) on fmp4.FM_ID=fmp3.PARENT_FM_ID
inner join Batches b with(nolock) on f.DESCRIPTION=b.QRANumber
inner join TestUnits tu with(nolock) on tu.BatchUnitNumber=f.UNIT_NUMBER and b.ID=tu.BatchID
inner join Jobs j with(nolock) on j.JobName=b.JobName
inner join TestStages ts with(nolock) on ts.JobID=j.ID and ts.TestStageName='baseline'
where f.DESCRIPTION NOT IN (SELECT DESCRIPTION from _Failures2014_1 with(nolock)) and f.DROP_NUM=0
and not exists (select 1 from TestRecords tr with(nolock) where tr.TestUnitID=tu.ID and tr.TestStageID=ts.ID
	and tr.TestID = isnull((select top 1 testid from testrecords r with(nolock) where r.testunitid=tu.id and r.teststagename like '%post%'),1280))
 
 -- TOP LEVEL RESULTS
 
print '3'
IF NOT EXISTS (select r.*
	from Relab.Results r with(nolock)
	where  exists (select ts.ID
	from dbo._Failures2014_2 f
	left outer join dbo._attachments2014_2 a with(nolock) on f.F_ID=a.f_id
	left outer join dbo._FailureModes fm with(nolock) on fm.FM_ID=f.FM_ID
	left outer join dbo._FailureModes fmp with(nolock) on fmp.FM_ID=fm.PARENT_FM_ID
	left outer join dbo._FailureModes fmp2 with(nolock) on fmp2.FM_ID=fmp.PARENT_FM_ID
	left outer join dbo._FailureModes fmp3 with(nolock) on fmp3.FM_ID=fmp2.PARENT_FM_ID
	left outer join dbo._FailureModes fmp4 with(nolock) on fmp4.FM_ID=fmp3.PARENT_FM_ID
	inner join Batches b with(nolock) on f.DESCRIPTION=b.QRANumber
	inner join TestUnits tu with(nolock) on tu.BatchUnitNumber=f.UNIT_NUMBER and b.ID=tu.BatchID
	inner join Jobs j with(nolock) on j.JobName=b.JobName
	inner join TestStages ts with(nolock) on ts.JobID=j.ID and ts.TestStageName like convert(nvarchar,f.DROP_NUM) + ' %' and ts.TestStageName like '%' + convert(nvarchar,f.[TYPE]) + '%'
	inner join Tests t with(nolock) on ts.TestID=t.id
	where f.DESCRIPTION NOT IN (SELECT DESCRIPTION from _Failures2014_1) and r.TestID=t.ID and r.TestStageID=ts.ID and r.TestUnitID=tu.ID))
	BEGIN
		insert into Relab.Results(TestStageID,TestID,TestUnitID,PassFail)
			select distinct ts.ID as TestStageID,t.ID as TestID,tu.ID as TestUnitID,0 as PassFail
			from dbo._Failures2014_2 f with(nolock)
			left outer join dbo._attachments2014_2 a with(nolock) on f.F_ID=a.f_id
			left outer join dbo._FailureModes fm with(nolock) on fm.FM_ID=f.FM_ID
			left outer join dbo._FailureModes fmp with(nolock) on fmp.FM_ID=fm.PARENT_FM_ID
			left outer join dbo._FailureModes fmp2 with(nolock) on fmp2.FM_ID=fmp.PARENT_FM_ID
			left outer join dbo._FailureModes fmp3 with(nolock) on fmp3.FM_ID=fmp2.PARENT_FM_ID
			left outer join dbo._FailureModes fmp4 with(nolock) on fmp4.FM_ID=fmp3.PARENT_FM_ID
			inner join Batches b with(nolock) on f.DESCRIPTION=b.QRANumber
			inner join TestUnits tu with(nolock) on tu.BatchUnitNumber=f.UNIT_NUMBER and b.ID=tu.BatchID
			inner join Jobs j with(nolock) on j.JobName=b.JobName
			inner join TestStages ts with(nolock) on ts.JobID=j.ID and ts.TestStageName like convert(nvarchar,f.DROP_NUM) + ' %' and ts.TestStageName like '%' + convert(nvarchar,f.[TYPE]) + '%'
			inner join Tests t with(nolock) on ts.TestID=t.id
			where f.DESCRIPTION NOT IN (SELECT DESCRIPTION from _Failures2014_1)	
	END 
	
	IF NOT EXISTS (select r.*
	from Relab.Results r with(nolock)
	where  exists (select ts.ID
	from dbo._Failures2014_2 f with(nolock)
	left outer join dbo._attachments2014_2 a with(nolock) on f.F_ID=a.f_id
	left outer join dbo._FailureModes fm with(nolock) on fm.FM_ID=f.FM_ID
	left outer join dbo._FailureModes fmp with(nolock) on fmp.FM_ID=fm.PARENT_FM_ID
	left outer join dbo._FailureModes fmp2 with(nolock) on fmp2.FM_ID=fmp.PARENT_FM_ID
	left outer join dbo._FailureModes fmp3 with(nolock) on fmp3.FM_ID=fmp2.PARENT_FM_ID
	left outer join dbo._FailureModes fmp4 with(nolock) on fmp4.FM_ID=fmp3.PARENT_FM_ID
	inner join Batches b with(nolock) on f.DESCRIPTION=b.QRANumber
	inner join TestUnits tu with(nolock) on tu.BatchUnitNumber=f.UNIT_NUMBER and b.ID=tu.BatchID
	inner join Jobs j with(nolock) on j.JobName=b.JobName
	inner join TestStages ts with(nolock) on ts.JobID=j.ID and ts.TestStageName='baseline'
	where f.DESCRIPTION NOT IN (SELECT DESCRIPTION from _Failures2014_1)
		and r.TestID=ISNULL((select top 1 testid from testrecords r where r.testunitid=tu.id and r.teststagename like '%post%'),1280) and r.TestStageID=ts.ID and r.TestUnitID=tu.ID))
	BEGIN
		insert into Relab.Results(TestStageID,TestID,TestUnitID,PassFail)
			select distinct ts.ID as TestStageID,
			ISNULL((select top 1 testid from testrecords r where r.testunitid=tu.id and r.teststagename like '%post%'),1280) as TestID,tu.ID as TestUnitID,0 as PassFail
			from dbo._Failures2014_2 f with(nolock)
			left outer join dbo._attachments2014_2 a with(nolock) on f.F_ID=a.f_id
			left outer join dbo._FailureModes fm with(nolock) on fm.FM_ID=f.FM_ID
			left outer join dbo._FailureModes fmp with(nolock) on fmp.FM_ID=fm.PARENT_FM_ID
			left outer join dbo._FailureModes fmp2 with(nolock) on fmp2.FM_ID=fmp.PARENT_FM_ID
			left outer join dbo._FailureModes fmp3 with(nolock) on fmp3.FM_ID=fmp2.PARENT_FM_ID
			left outer join dbo._FailureModes fmp4 with(nolock) on fmp4.FM_ID=fmp3.PARENT_FM_ID
			inner join Batches b with(nolock) on f.DESCRIPTION=b.QRANumber
			inner join TestUnits tu with(nolock) on tu.BatchUnitNumber=f.UNIT_NUMBER and b.ID=tu.BatchID
			inner join Jobs j with(nolock) on j.JobName=b.JobName
			inner join TestStages ts with(nolock) on ts.JobID=j.ID and ts.TestStageName='baseline'
			where f.DESCRIPTION NOT IN (SELECT DESCRIPTION from _Failures2014_1)	
		END
	
print '4'
	
	--lets build our result table to reference the resultid
	select r.*
	into #results
	from Relab.Results r with(nolock)
	where  exists (select ts.ID
	from dbo._Failures2014_2 f with(nolock)
	left outer join dbo._attachments2014_2 a with(nolock) on f.F_ID=a.f_id
	left outer join dbo._FailureModes fm with(nolock) on fm.FM_ID=f.FM_ID
	left outer join dbo._FailureModes fmp with(nolock) on fmp.FM_ID=fm.PARENT_FM_ID
	left outer join dbo._FailureModes fmp2 with(nolock) on fmp2.FM_ID=fmp.PARENT_FM_ID
	left outer join dbo._FailureModes fmp3 with(nolock) on fmp3.FM_ID=fmp2.PARENT_FM_ID
	left outer join dbo._FailureModes fmp4 with(nolock) on fmp4.FM_ID=fmp3.PARENT_FM_ID
	inner join Batches b with(nolock) on f.DESCRIPTION=b.QRANumber
	inner join TestUnits tu with(nolock) on tu.BatchUnitNumber=f.UNIT_NUMBER and b.ID=tu.BatchID
	inner join Jobs j with(nolock) on j.JobName=b.JobName
	inner join TestStages ts with(nolock) on ts.JobID=j.ID and ts.TestStageName like convert(nvarchar,f.DROP_NUM) + ' %' and ts.TestStageName like '%' + convert(nvarchar,f.[TYPE]) + '%'
	inner join Tests t with(nolock) on ts.TestID=t.id
	where f.DESCRIPTION NOT IN (SELECT DESCRIPTION from _Failures2014_1) and r.TestID=t.ID and r.TestStageID=ts.ID and r.TestUnitID=tu.ID)

--what is our measurementtypeid's
--	gets our measurementy types to compare in lookups table against lookuptypeid 7
	select distinct
	case 
		when fmp4.DESCRIPTION IS NOT NULL then REPLACE(LTRIM(RTRIM(fmp4.DESCRIPTION)), ' \ ', '\') +'\' else ''
	end +
	case 
		when fmp3.DESCRIPTION IS NOT NULL then REPLACE(LTRIM(RTRIM(fmp3.DESCRIPTION)), ' \ ', '\') +'\' else ''
	end +
	case 
		when fmp2.DESCRIPTION IS NOT NULL then REPLACE(LTRIM(RTRIM(fmp2.DESCRIPTION)), ' \ ', '\') +'\' else ''
	end +
	case 
		when fmp.DESCRIPTION IS NOT NULL then REPLACE(LTRIM(RTRIM(fmp.DESCRIPTION)), ' \ ', '\') +'\' else ''
	end +
	case 
		when fm.DESCRIPTION IS NOT NULL then REPLACE(LTRIM(RTRIM(fm.DESCRIPTION)), ' \ ', '\') else ''
	end
	as lookupname
	
	into #newmeasurementtypes
	from dbo._Failures2014_2 f with(nolock)
	left outer join dbo._attachments2014_2 a with(nolock) on f.F_ID=a.f_id
	left outer join dbo._FailureModes fm with(nolock) on fm.FM_ID=f.FM_ID
	left outer join dbo._FailureModes fmp with(nolock) on fmp.FM_ID=fm.PARENT_FM_ID
	left outer join dbo._FailureModes fmp2 with(nolock) on fmp2.FM_ID=fmp.PARENT_FM_ID
	left outer join dbo._FailureModes fmp3 with(nolock) on fmp3.FM_ID=fmp2.PARENT_FM_ID
	left outer join dbo._FailureModes fmp4 with(nolock) on fmp4.FM_ID=fmp3.PARENT_FM_ID
	inner join Batches b  with(nolock) on f.DESCRIPTION=b.QRANumber
	inner join TestUnits tu with(nolock) on tu.BatchUnitNumber=f.UNIT_NUMBER and b.ID=tu.BatchID
	inner join Jobs j with(nolock) on j.JobName=b.JobName
	inner join TestStages ts  with(nolock) on ts.JobID=j.ID and ts.TestStageName like convert(nvarchar,f.DROP_NUM) + ' %' and ts.TestStageName like '%' + convert(nvarchar,f.[TYPE]) + '%'
	inner join Tests t with(nolock) on ts.TestID=t.id
	inner join #results r with(nolock) on r.TestID=t.ID and r.TestStageID=ts.ID and r.TestUnitID=tu.ID
	where f.DESCRIPTION NOT IN (SELECT DESCRIPTION from _Failures2014_1)
	
print '5'
	
	--select distinct nm.* from #newmeasurementtypes nm
	--take #newmeasurementtypes and see if exists and if not insert
	--select * from Lookups where LookupTypeID=7 and [Values] in (select nm.lookupname from #newmeasurementtypes nm)
	begin
		DECLARE @MaxID INT
		SELECT @MaxID = MAX(LookupID)+1 FROM Lookups with(nolock)
		
		
		insert into Lookups(LookupID,[Values],IsActive,Description,ParentID,LookupTypeID)
		SELECT distinct ((ROW_NUMBER() OVER (ORDER BY lookupname)) + @MaxID) AS LookupID,		
			nm.lookupname as [Values],1 as IsActive,'Migrated from old DTATTA' as Description,NULL as ParentID,7 as LookupTypeID
		from #newmeasurementtypes nm with(nolock)
		where nm.lookupname NOT IN (select [values] from Lookups  with(nolock) where LookupTypeID=7)
	end
	
print '6'
	select r.*
	into #results2
	from Relab.Results r with(nolock)
	where  exists (select ts.ID
	from dbo._Failures2014_2 f with(nolock)
	left outer join dbo._attachments2014_2 a with(nolock) on f.F_ID=a.f_id
	left outer join dbo._FailureModes fm with(nolock) on fm.FM_ID=f.FM_ID
	left outer join dbo._FailureModes fmp with(nolock) on fmp.FM_ID=fm.PARENT_FM_ID
	left outer join dbo._FailureModes fmp2 with(nolock) on fmp2.FM_ID=fmp.PARENT_FM_ID
	left outer join dbo._FailureModes fmp3 with(nolock) on fmp3.FM_ID=fmp2.PARENT_FM_ID
	left outer join dbo._FailureModes fmp4 with(nolock) on fmp4.FM_ID=fmp3.PARENT_FM_ID
	inner join Batches b with(nolock) on f.DESCRIPTION=b.QRANumber
	inner join TestUnits tu with(nolock) on tu.BatchUnitNumber=f.UNIT_NUMBER and b.ID=tu.BatchID
	inner join Jobs j with(nolock) on j.JobName=b.JobName
	inner join TestStages ts with(nolock) on ts.JobID=j.ID and ts.TestStageName = 'baseline'
	where f.DESCRIPTION NOT IN (SELECT DESCRIPTION from _Failures2014_1)
		and r.TestID=isnull((select top 1 testid from testrecords r where r.testunitid=tu.id and r.teststagename like '%post%'),1280)
		and r.TestStageID=ts.ID and r.TestUnitID=tu.ID)	
	
	select distinct
	case 
		when fmp4.DESCRIPTION IS NOT NULL then REPLACE(LTRIM(RTRIM(fmp4.DESCRIPTION)), ' \ ', '\') +'\' else ''
	end +
	case 
		when fmp3.DESCRIPTION IS NOT NULL then REPLACE(LTRIM(RTRIM(fmp3.DESCRIPTION)), ' \ ', '\') +'\' else ''
	end +
	case 
		when fmp2.DESCRIPTION IS NOT NULL then REPLACE(LTRIM(RTRIM(fmp2.DESCRIPTION)), ' \ ', '\') +'\' else ''
	end +
	case 
		when fmp.DESCRIPTION IS NOT NULL then REPLACE(LTRIM(RTRIM(fmp.DESCRIPTION)), ' \ ', '\') +'\' else ''
	end +
	case 
		when fm.DESCRIPTION IS NOT NULL then REPLACE(LTRIM(RTRIM(fm.DESCRIPTION)), ' \ ', '\') else ''
	end
	as lookupname
	
	into #newmeasurementtypes2
	from dbo._Failures2014_2 f with(nolock)
	left outer join dbo._attachments2014_2 a with(nolock) on f.F_ID=a.f_id
	left outer join dbo._FailureModes fm with(nolock) on fm.FM_ID=f.FM_ID
	left outer join dbo._FailureModes fmp with(nolock) on fmp.FM_ID=fm.PARENT_FM_ID
	left outer join dbo._FailureModes fmp2 with(nolock) on fmp2.FM_ID=fmp.PARENT_FM_ID
	left outer join dbo._FailureModes fmp3 with(nolock) on fmp3.FM_ID=fmp2.PARENT_FM_ID
	left outer join dbo._FailureModes fmp4 with(nolock) on fmp4.FM_ID=fmp3.PARENT_FM_ID
	inner join Batches b with(nolock) on f.DESCRIPTION=b.QRANumber
	inner join TestUnits tu with(nolock) on tu.BatchUnitNumber=f.UNIT_NUMBER and b.ID=tu.BatchID
	inner join Jobs j with(nolock) on j.JobName=b.JobName
	inner join TestStages ts with(nolock) on ts.JobID=j.ID and ts.TestStageName ='baseline'
	inner join #results2 r with(nolock) on r.TestID=ISNULL((select top 1 testid from testrecords r where r.testunitid=tu.id and r.teststagename like '%post%'),1280)
			 and r.TestStageID=ts.ID and r.TestUnitID=tu.ID
	where f.DESCRIPTION NOT IN (SELECT DESCRIPTION from _Failures2014_1)
	
		DECLARE @MaxID2 INT
		SELECT @MaxID2 = MAX(LookupID)+1 FROM Lookups
	
		insert into Lookups(LookupID,[Values],IsActive,Description,ParentID,LookupTypeID)
	SELECT distinct ((ROW_NUMBER() OVER (ORDER BY lookupname)) + @MaxID2) AS LookupID,		
		nm.lookupname as [Values],1 as IsActive,'Migrated from old DTATTA' as Description,NULL as ParentID,7 as LookupTypeID
	from #newmeasurementtypes2 nm  with(nolock)
	where nm.lookupname NOT IN (select [values] from Lookups where LookupTypeID=7)

print '7'
	--now our lookups exists rebring in the query above 
	--inner join values to isnull(fmp4.DESCRIPTION,'') + '\' + isnull(fmp3.DESCRIPTION,'') + '\' + isnull(fmp2.DESCRIPTION,'') + '\' + isnull(fmp.DESCRIPTION,'') + '\' + isnull(fm.DESCRIPTION,'')
	--build measurement rows by adding records insert MeasurementTypeID
	--ID , ResultID from #results,lookups, na , na , 'False',684,0,1,0,NULL,Failure_Description,'REMI',null
	begin
		insert into Relab.ResultsMeasurements(
		ResultID,
		MeasurementTypeID,
		LowerLimit,
		UpperLimit,
		MeasurementValue,
		MeasurementUnitTypeID,
		PassFail,
		ReTestNum,
		Archived,
		XMLID,
		Comment,
		Description,
		LastUser,
		DegradationVal)		
		select distinct  
		r.ID as ResultID,
		l.LookupID as MeasurementTypeID,
		'N/A' as LowerLimit,
		'N/A' as UpperLimit,
		'False' as MeasurementValue,
		684 as MeasurementUnitTypeID,
		0 as PassFail,
		1 as ReTestNum,
		0 as Archived,
		NULL as XMLID,
		f.FAILURE_COMMENT as Comment,
		NULL as Description,
		'REMI' as LastUser,
		null as DegradationVal
		from dbo._Failures2014_2 f with(nolock)
		left outer join dbo._attachments2014_2 a with(nolock) on f.F_ID=a.f_id
		left outer join dbo._FailureModes fm with(nolock) on fm.FM_ID=f.FM_ID
		left outer join dbo._FailureModes fmp with(nolock) on fmp.FM_ID=fm.PARENT_FM_ID
		left outer join dbo._FailureModes fmp2 with(nolock) on fmp2.FM_ID=fmp.PARENT_FM_ID
		left outer join dbo._FailureModes fmp3 with(nolock) on fmp3.FM_ID=fmp2.PARENT_FM_ID
		left outer join dbo._FailureModes fmp4  with(nolock) on fmp4.FM_ID=fmp3.PARENT_FM_ID
		inner join Batches b with(nolock) on f.DESCRIPTION=b.QRANumber
		inner join TestUnits tu with(nolock) on tu.BatchUnitNumber=f.UNIT_NUMBER and b.ID=tu.BatchID
		inner join Jobs j with(nolock) on j.JobName=b.JobName
		inner join TestStages ts with(nolock) on ts.JobID=j.ID and ts.TestStageName like convert(nvarchar,f.DROP_NUM) + ' %' and ts.TestStageName like '%' + convert(nvarchar,f.[TYPE]) + '%'
		inner join Tests t with(nolock) on ts.TestID=t.id
		inner join #results r with(nolock) on r.TestID=t.ID and r.TestStageID=ts.ID and r.TestUnitID=tu.ID
		inner join Lookups l with(nolock) on l.[Values] = 
			case 
				when fmp4.DESCRIPTION IS NOT NULL then REPLACE(LTRIM(RTRIM(fmp4.DESCRIPTION)), ' \ ', '\') +'\' else ''
			end +
			case 
				when fmp3.DESCRIPTION IS NOT NULL then REPLACE(LTRIM(RTRIM(fmp3.DESCRIPTION)), ' \ ', '\') +'\' else ''
			end +
			case 
				when fmp2.DESCRIPTION IS NOT NULL then REPLACE(LTRIM(RTRIM(fmp2.DESCRIPTION)), ' \ ', '\') +'\' else ''
			end +
			case 
				when fmp.DESCRIPTION IS NOT NULL then REPLACE(LTRIM(RTRIM(fmp.DESCRIPTION)), ' \ ', '\') +'\' else ''
			end +
			case 
				when fm.DESCRIPTION IS NOT NULL then REPLACE(LTRIM(RTRIM(fm.DESCRIPTION)), ' \ ', '\') else ''
			end --insert case statement
		where f.DESCRIPTION NOT IN (SELECT DESCRIPTION from _Failures2014_1)
	end
	
	begin	
		insert into Relab.ResultsMeasurements(
				ResultID,
				MeasurementTypeID,
				LowerLimit,
				UpperLimit,
				MeasurementValue,
				MeasurementUnitTypeID,
				PassFail,
				ReTestNum,
				Archived,
				XMLID,
				Comment,
				Description,
				LastUser,
				DegradationVal)
		select distinct  
				r.ID as ResultID,
				l.LookupID as MeasurementTypeID,
				'N/A' as LowerLimit,
				'N/A' as UpperLimit,
				'False' as MeasurementValue,
				684 as MeasurementUnitTypeID,
				0 as PassFail,
				1 as ReTestNum,
				0 as Archived,
				NULL as XMLID,
				f.FAILURE_COMMENT as Comment,
				NULL as Description,
				'REMI' as LastUser,
				null as DegradationVal
				from dbo._Failures2014_2 f with(nolock)
				left outer join dbo._attachments2014_2 a with(nolock) on f.F_ID=a.f_id
				left outer join dbo._FailureModes fm with(nolock) on fm.FM_ID=f.FM_ID
				left outer join dbo._FailureModes fmp with(nolock) on fmp.FM_ID=fm.PARENT_FM_ID
				left outer join dbo._FailureModes fmp2 with(nolock) on fmp2.FM_ID=fmp.PARENT_FM_ID
				left outer join dbo._FailureModes fmp3 with(nolock) on fmp3.FM_ID=fmp2.PARENT_FM_ID
				left outer join dbo._FailureModes fmp4 with(nolock) on fmp4.FM_ID=fmp3.PARENT_FM_ID
				inner join Batches b with(nolock) on f.DESCRIPTION=b.QRANumber
				inner join TestUnits tu with(nolock) on tu.BatchUnitNumber=f.UNIT_NUMBER and b.ID=tu.BatchID
				inner join Jobs j with(nolock) on j.JobName=b.JobName
				inner join TestStages ts with(nolock) on ts.JobID=j.ID and ts.TestStageName ='baseline'
				inner join #results2 r with(nolock) on r.TestID=ISNULL((select top 1 testid from testrecords r where r.testunitid=tu.id and r.teststagename like '%post%'),1280)
					and r.TestStageID=ts.ID and r.TestUnitID=tu.ID
				inner join Lookups l with(nolock) on l.[Values] = 
					case 
						when fmp4.DESCRIPTION IS NOT NULL then REPLACE(LTRIM(RTRIM(fmp4.DESCRIPTION)), ' \ ', '\') +'\' else ''
					end +
					case 
						when fmp3.DESCRIPTION IS NOT NULL then REPLACE(LTRIM(RTRIM(fmp3.DESCRIPTION)), ' \ ', '\') +'\' else ''
					end +
					case 
						when fmp2.DESCRIPTION IS NOT NULL then REPLACE(LTRIM(RTRIM(fmp2.DESCRIPTION)), ' \ ', '\') +'\' else ''
					end +
					case 
						when fmp.DESCRIPTION IS NOT NULL then REPLACE(LTRIM(RTRIM(fmp.DESCRIPTION)), ' \ ', '\') +'\' else ''
					end +
					case 
						when fm.DESCRIPTION IS NOT NULL then REPLACE(LTRIM(RTRIM(fm.DESCRIPTION)), ' \ ', '\') else ''
					end --insert case statement
				where f.DESCRIPTION NOT IN (SELECT DESCRIPTION from _Failures2014_1) and f.DROP_NUM=0
	end
		
print '8'
	insert into Relab.ResultsMeasurementsFiles(ResultMeasurementID,[File],ContentType,FileName)
	select  rm.ID as ResultMeasurementID, a.CONTENT as '[File]',a.AT_TYPE as ContentType,a.['HTTP://HWQAWEB/RELAB_ALPHA/DOCS/'||A.PATH] as 'FileName'
	from dbo._Failures2014_2 f with(nolock)
	left outer join dbo._attachments2014_2 a with(nolock) on f.F_ID=a.f_id
	left outer join dbo._FailureModes fm with(nolock) on fm.FM_ID=f.FM_ID
	left outer join dbo._FailureModes fmp with(nolock) on fmp.FM_ID=fm.PARENT_FM_ID
	left outer join dbo._FailureModes fmp2 with(nolock) on fmp2.FM_ID=fmp.PARENT_FM_ID
	left outer join dbo._FailureModes fmp3 with(nolock) on fmp3.FM_ID=fmp2.PARENT_FM_ID
	left outer join dbo._FailureModes fmp4 with(nolock) on fmp4.FM_ID=fmp3.PARENT_FM_ID
	inner join Batches b with(nolock) on f.DESCRIPTION=b.QRANumber
	inner join TestUnits tu with(nolock) on tu.BatchUnitNumber=f.UNIT_NUMBER and b.ID=tu.BatchID
	inner join Jobs j with(nolock) on j.JobName=b.JobName
	inner join TestStages ts with(nolock) on ts.JobID=j.ID and ts.TestStageName like convert(nvarchar,f.DROP_NUM) + ' %' and ts.TestStageName like '%' + convert(nvarchar,f.[TYPE]) + '%'
	inner join Tests t with(nolock) on ts.TestID=t.id
	inner join #results r with(nolock) on r.TestID=t.ID and r.TestStageID=ts.ID and r.TestUnitID=tu.ID
	inner join Lookups l with(nolock) on l.[Values] = 
		case 
		when fmp4.DESCRIPTION IS NOT NULL then REPLACE(LTRIM(RTRIM(fmp4.DESCRIPTION)), ' \ ', '\') +'\' else ''
	end +
	case 
		when fmp3.DESCRIPTION IS NOT NULL then REPLACE(LTRIM(RTRIM(fmp3.DESCRIPTION)), ' \ ', '\') +'\' else ''
	end +
	case 
		when fmp2.DESCRIPTION IS NOT NULL then REPLACE(LTRIM(RTRIM(fmp2.DESCRIPTION)), ' \ ', '\') +'\' else ''
	end +
	case 
		when fmp.DESCRIPTION IS NOT NULL then REPLACE(LTRIM(RTRIM(fmp.DESCRIPTION)), ' \ ', '\') +'\' else ''
	end +
	case 
		when fm.DESCRIPTION IS NOT NULL then REPLACE(LTRIM(RTRIM(fm.DESCRIPTION)), ' \ ', '\') else ''
	end 
	inner join Relab.ResultsMeasurements rm with(nolock) on rm.ResultID = r.ID AND rm.MeasurementTypeID=l.LookupID
	where f.DESCRIPTION NOT IN (SELECT DESCRIPTION from _Failures2014_1)
	and a.CONTENT is not null
	
	insert into Relab.ResultsMeasurementsFiles(ResultMeasurementID,[File],ContentType,FileName)
	select  rm.ID as ResultMeasurementID, a.CONTENT as '[File]',a.AT_TYPE as ContentType,a.['HTTP://HWQAWEB/RELAB_ALPHA/DOCS/'||A.PATH] as 'FileName'
	from dbo._Failures2014_2 f with(nolock)
	left outer join dbo._attachments2014_2 a with(nolock) on f.F_ID=a.f_id
	left outer join dbo._FailureModes fm with(nolock) on fm.FM_ID=f.FM_ID
	left outer join dbo._FailureModes fmp with(nolock) on fmp.FM_ID=fm.PARENT_FM_ID
	left outer join dbo._FailureModes fmp2 with(nolock) on fmp2.FM_ID=fmp.PARENT_FM_ID
	left outer join dbo._FailureModes fmp3 with(nolock) on fmp3.FM_ID=fmp2.PARENT_FM_ID
	left outer join dbo._FailureModes fmp4 with(nolock) on fmp4.FM_ID=fmp3.PARENT_FM_ID
	inner join Batches b with(nolock) on f.DESCRIPTION=b.QRANumber
	inner join TestUnits tu with(nolock) on tu.BatchUnitNumber=f.UNIT_NUMBER and b.ID=tu.BatchID
	inner join Jobs j with(nolock) on j.JobName=b.JobName
	inner join TestStages ts with(nolock) on ts.JobID=j.ID and ts.TestStageName ='baseline'
	inner join #results2 r with(nolock) on r.TestID=ISNULL((select top 1 testid from testrecords r where r.testunitid=tu.id and r.teststagename like '%post%'),1280)
				 and r.TestStageID=ts.ID and r.TestUnitID=tu.ID
	inner join Lookups l with(nolock) on l.[Values] = 
		case 
		when fmp4.DESCRIPTION IS NOT NULL then REPLACE(LTRIM(RTRIM(fmp4.DESCRIPTION)), ' \ ', '\') +'\' else ''
	end +
	case 
		when fmp3.DESCRIPTION IS NOT NULL then REPLACE(LTRIM(RTRIM(fmp3.DESCRIPTION)), ' \ ', '\') +'\' else ''
	end +
	case 
		when fmp2.DESCRIPTION IS NOT NULL then REPLACE(LTRIM(RTRIM(fmp2.DESCRIPTION)), ' \ ', '\') +'\' else ''
	end +
	case 
		when fmp.DESCRIPTION IS NOT NULL then REPLACE(LTRIM(RTRIM(fmp.DESCRIPTION)), ' \ ', '\') +'\' else ''
	end +
	case 
		when fm.DESCRIPTION IS NOT NULL then REPLACE(LTRIM(RTRIM(fm.DESCRIPTION)), ' \ ', '\') else ''
	end 
	inner join Relab.ResultsMeasurements rm with(nolock) on rm.ResultID = r.ID AND rm.MeasurementTypeID=l.LookupID
	where f.DESCRIPTION NOT IN (SELECT DESCRIPTION from _Failures2014_1) and f.DROP_NUM=0
	and a.CONTENT is not null

update Relab.ResultsMeasurements set Comment=replace(Comment,'''','') where Comment like '%''%'
	
print '9'
	drop table #results
	drop table #newmeasurementtypes
	drop table #results2
	drop table #newmeasurementtypes2

update tr
set TestStageID=ts.ID
from TestRecords tr with(nolock)
	inner join Jobs j with(nolock) on j.JobName=tr.JobName
	inner join TestStages ts with(nolock) on ts.TestStageName=tr.TestStageName and ts.JobID=j.id and ts.TestStageType=1
where tr.TestStageID is null

update tr
set tr.TestID=ts.TestID, tr.TestStageID=ts.ID
from TestRecords tr with(nolock)
	inner join Jobs j with(nolock) on j.JobName=tr.JobName
	inner join TestStages ts with(nolock) on ts.TestStageName=tr.TestStageName and ts.JobID=j.id and ts.TestStageType=2
	inner join Tests t with(nolock) on t.TestName=tr.TestName and t.ID=ts.testid
where tr.TestStageID is null


rollback tran