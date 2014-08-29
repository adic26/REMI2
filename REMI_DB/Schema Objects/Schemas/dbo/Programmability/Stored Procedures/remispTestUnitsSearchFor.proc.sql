ALTER PROCEDURE [dbo].[remispTestUnitsSearchFor] @QRANumber nvarchar(11) = null
AS
BEGIN
	SELECT 
		tu.ID,
		tu.batchid, 
		tu.BSN, 
		tu.BatchUnitNumber, 
		tu.CurrentTestStageName, 
		tu.CurrentTestName, 
		tu.AssignedTo,
		tu.ConcurrencyID,
		tu.LastUser,
		tu.Comment,
		b.QRANumber,
		dtl.ConcurrencyID as dtlCID,
		dtl.ID as dtlID,
		dtl.InTime as dtlInTime,
		dtl.InUser as dtlInUser,
		dtl.OutTime as dtlouttime,
		dtl.OutUser as dtloutuser,
		tl.TrackingLocationName,
		tl.ID as dtlTLID,
		b.TestCenterLocationID,
		ts.ID AS CurrentTestStageID,
		ISNULL(j.NoBSN, 0) As NoBSN
	FROM TestUnits as tu WITH(NOLOCK) 
		INNER JOIN Batches as b WITH(NOLOCK) on b.ID = tu.batchid
		LEFT OUTER JOIN devicetrackinglog as dtl WITH(NOLOCK) on dtl.TestUnitID =tu.id 
			AND dtl.id = (SELECT  top(1)  DeviceTrackingLog.ID from DeviceTrackingLog WITH(NOLOCK) WHERE (TestUnitID = tu.id) ORDER BY devicetrackinglog.intime desc)
		LEFT OUTER JOIN TrackingLocations as tl WITH(NOLOCK) on dtl.TrackingLocationID = tl.ID
		INNER JOIN Jobs j ON j.JobName=b.JobName
		LEFT OUTER JOIN TestStages ts ON ts.TestStageName=tu.CurrentTestStageName AND ts.JobID=j.ID
	 where b.ID = tu.BatchID and (b.QRANumber = @qranumber)
END
GO
GRANT EXECUTE ON remispTestUnitsSearchFor TO REMI
GO