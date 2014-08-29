ALTER PROCEDURE [dbo].[remispBatchesByProductView] @AccessoryGroupID INT =null, @TestCentreLocation nvarchar(200) = null
AS
select results.*, (ExpectedDuration - CurrentTestTime) as RemainingHours, DATEADD(HOUR,(ExpectedDuration - CurrentTestTime),GETUTCDATE()) as CanBeRemovedAt 
from 
(
	SELECT b.QRANumber as QRANumber, 
		tu.BatchUnitNumber,
		tu.AssignedTo,
		tl.TrackingLocationName,
		b.JobName,
		b.AccessoryGroupID,
		b.ProductTypeID,
		l2.[Values] As AccessoryGroupName,
		p.ProductGroupName,
		l.[Values] As ProductType,
		b.TestStageName,
		dtl.InTime,
		tr.id as TestRecordID ,                     
		case when (select Duration from BatchSpecificTestDurations 
		where TestID = t.id and BatchID = b.ID) is not null then 
		(select Duration from BatchSpecificTestDurations  
		where TestID = t.id and BatchID = b.ID) else t.Duration end as ExpectedDuration,
		(Select sum(datediff(Minute,dtl.intime,
		(case when (dtl.OutTime IS null) then GETUTCDATE() else dtl.outtime  end )) / 60.0)
		 from Testrecordsxtrackinglogs as trXtl, DeviceTrackingLog as dtl 
		 where trXtl.TestRecordID = tr.ID and dtl.ID = trXtl.TrackingLogID) as CurrentTestTime,
		 b.RQID AS ReqID
	FROM Batches AS b 
		INNER JOIN Jobs as j on b.jobname = j.JobName 
		inner join TestStages as ts on j.ID = ts.JobID
		inner join tests as t on ((ts.TestStagetype = 2 and t.id = ts.TestID )or (ts.teststagetype != 2 and t.testtype = ts.TestStageType)) 
		inner join DeviceTrackingLog AS dtl
		INNER JOIN TrackingLocations AS tl ON dtl.TrackingLocationID = tl.ID
		INNER JOIN TrackingLocationTypes as tlt on tl.TrackingLocationTypeID = tlt.id 
		inner join TestUnits AS tu ON dtl.TestUnitID = tu.ID on tu.CurrentTestName = t.TestName and b.id = tu.batchid 
		inner join testrecords as tr on tr.TestUnitID = tu.id and tr.TestName = t.TestName and tr.TestStageName = t.TestName
		inner join Products p on p.ID=b.ProductID
		LEFT OUTER JOIN Lookups l ON l.Type='ProductType' AND b.ProductTypeID=l.LookupID  
		LEFT OUTER JOIN Lookups l2 ON l2.Type='AccessoryType' AND b.AccessoryGroupID=l2.LookupID  
	WHERE (b.TestCenterLocation = @TestCentreLocation or @TestCentreLocation is null) and  (b.AccessoryGroupID = @AccessoryGroupID or @AccessoryGroupID is null) 
		and (b.BatchStatus = 2) --in progress batches
) as results
order by RemainingHours asc
GO
GRANT EXECUTE ON remispBatchesByProductView TO Remi
GO