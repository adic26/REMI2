ALTER PROCEDURE [dbo].[remispBatchesSelectBatchesNotInREMSTAR]
AS
select QRANumber, BatchUnitNumber, tl.TrackingLocationName,dtl.InTime, dtl.InUser,
ISNULL(
			(SELECT AssignedTo 
			FROM TaskAssignments ta WITH(NOLOCK)
				--We need to compare TestStageName because there can be multiple TestStages for 1 batch where the TestStageName can be different. See BatchID 10965 as an example
				INNER JOIN TestStages ts WITH(NOLOCK) ON ta.TaskID = ts.ID AND ts.TestStageName=b.TestStageName 
				--To keep things consistent we are testing based on the JobName because it has the possibility to change but no records currently found in such a case.
				INNER JOIN Jobs j WITH(NOLOCK) ON j.ID = ts.JobID AND j.JobName = b.JobName
			WHERE ta.BatchID = b.ID and ta.Active=1), 
			(SELECT AssignedTo 
			FROM TaskAssignments ta WITH(NOLOCK)
			WHERE ta.Active=1 AND ISNULL(ta.taskID,0) = 0 AND ta.BatchID = b.ID)
		) as ActiveTaskAssignee
FROM TestUnits tu WITH(NOLOCK)
	INNER JOIN Batches b WITH(NOLOCK) ON b.ID = tu.BatchID 
	INNER JOIN DeviceTrackingLog dtl WITH(NOLOCK) ON tu.ID = dtl.TestUnitID
	INNER JOIN TrackingLocations tl WITH(NOLOCK) ON dtl.TrackingLocationID = tl.id
	INNER JOIN TrackingLocationTypes tlt WITH(NOLOCK) ON tlt.ID = tl.TrackingLocationTypeID AND tlt.ID != 103 --external location
where dtl.OutTime is null and dtl.ID = (select max(id) from DeviceTrackingLog where DeviceTrackingLog.testunitid = tu.id)
	and tl.TestCenterLocationID = 76
	and tl.id NOT IN(25,81)
order by QRANumber, BatchUnitNumber, dtl.InTime
GO
GRANT EXECUTE ON remispBatchesSelectBatchesNotInREMSTAR TO Remi
GO