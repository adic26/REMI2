ALTER PROCEDURE [dbo].[remispTestUnitsSelectListByLastUser] @UserID INT, @includeCompletedQRA BIT = 1
AS
	DECLARE @username NVARCHAR(255)
	SELECT @username = LDAPLogin FROM Users WHERE ID=@UserID

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
	b.TestCenterLocationID
	from TestUnits as tu, devicetrackinglog as dtl, Batches as b, TrackingLocations as tl  
	where tl.ID = dtl.TrackingLocationID and tu.id = dtl.testunitid and tu.batchid = b.id 
		and inuser = @username and outuser is null
		AND (
				(@includeCompletedQRA = 0 AND b.BatchStatus <> 5)
				OR
				(@includeCompletedQRA = 1)
			)
	order by QRANumber desc, BatchUnitNumber 
GO
GRANT EXECUTE ON remispTestUnitsSelectListByLastUser TO REMI
GO