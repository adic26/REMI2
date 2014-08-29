CREATE PROCEDURE [dbo].[remispTestUnitsInChamberView]
/*	'===============================================================
	'   NAME:                	remispBatchesSelectChamberTable
	'   DATE CREATED:       	15 April 2011
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retreives the test units in chamber
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/

	@TestCentreLocation nvarchar(200) =null

	AS
select results.*
,(ExpectedDuration - CurrentTestTime) as RemainingHours, DATEADD(HOUR,(ExpectedDuration - CurrentTestTime),GETUTCDATE()) as CanBeRemovedAt 
from (
SELECT 	   b.QRANumber as QRANumber, 
                      tu.BatchUnitNumber,
                      tu.AssignedTo,
                      tl.TrackingLocationName,
                      b.JobName,
                      b.TestStageName,
                      dtl.InTime
                      ,tr.id as TestRecordID                      
                      ,case when (select Duration from BatchSpecificTestDurations  where TestID = t.id and BatchID = b.ID) is not null then (select Duration from BatchSpecificTestDurations  where TestID = t.id and BatchID = b.ID) else t.Duration end as ExpectedDuration,
                      (Select sum(datediff(Minute,dtl.intime,
(case when (dtl.OutTime IS null) then GETUTCDATE() else dtl.outtime  end )) / 60.0)
	 from Testrecordsxtrackinglogs as trXtl, DeviceTrackingLog as dtl 
	 where trXtl.TestRecordID = tr.ID and dtl.ID = trXtl.TrackingLogID) as CurrentTestTime 
                 
                      
FROM         Batches AS b INNER JOIN
	Jobs as j on b.jobname = j.JobName inner join
	TestStages as ts on j.ID = ts.JobID  inner join
	Tests as t on ts.TestID = t.ID inner join
    DeviceTrackingLog AS dtl INNER JOIN
    TrackingLocations AS tl ON dtl.TrackingLocationID = tl.ID INNER JOIN
    TrackingLocationTypes as tlt on tl.TrackingLocationTypeID = tlt.id inner join
    TestUnits AS tu ON dtl.TestUnitID = tu.ID on tu.CurrentTestName = t.TestName and b.id = tu.batchid--batches where there's a tracking log
    ,testrecords as tr              
WHERE   (b.TestCenterLocation = @TestCentreLocation or @TestCentreLocation is null) 
 and tr.TestUnitID = tu.id and tr.TestName = t.TestName and tr.TestStageName = t.TestName
and j.TechnicalOperationsTest = 1 and j.MechanicalTest=0 and  tlt.TrackingLocationFunction= 4  
and t.ResultBasedOntime = 1 AND dtl.OutTime IS NULL AND dtl.OutUser IS NULL

) as results

order by RemainingHours asc

