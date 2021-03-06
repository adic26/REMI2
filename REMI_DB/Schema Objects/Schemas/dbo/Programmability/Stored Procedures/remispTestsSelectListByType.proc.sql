﻿ALTER PROCEDURE [dbo].[remispTestsSelectListByType] @TestType int, @IncludeArchived BIT = 0, @UserID INT, @RequestTypeID INT
AS
BEGIN
	CREATE TABLE #Tests (TestID INT)
	
	IF (@UserID = 0)
	BEGIN
		INSERT INTO #Tests (TestID)
		SELECT t.ID AS TestID
		FROM Tests t
	END
	ELSE
	BEGIN
		INSERT INTO #Tests (TestID)
		SELECT DISTINCT ta.TestID
		FROM UserDetails ud
			INNER JOIN Lookups l ON l.LookupID=ud.LookupID
			INNER JOIN LookupType lt ON lt.LookupTypeID=l.LookupTypeID
			INNER JOIN TestsAccess ta ON ta.LookupID=ud.LookupID
			INNER JOIN Req.RequestTypeAccess rta ON rta.LookupID = ta.LookupID
		WHERE lt.Name='Department' AND (@RequestTypeID = 0 OR rta.RequestTypeID=@RequestTypeID) AND (@UserID = 0 OR ud.UserID=@UserID)
	END
	
	SELECT t.Comment,t.ConcurrencyID,t.Duration,t.ID,t.LastUser,t.ResultBasedOntime,t.TestName,t.TestType,t.WILocation, dbo.remifnTestCanDelete(t.ID) AS CanDelete, t.IsArchived,
		(SELECT TestStageName FROM TestStages WHERE TestID=t.ID) As TestStage, (SELECT JobName FROM Jobs WHERE ID IN (SELECT JobID FROM TestStages WHERE TestID=t.ID)) As JobName,
		t.Owner, t.Trainee, t.DegradationVal
	FROM Tests t
	WHERE TestType = @TestType
		AND ((@TestType = 1 AND t.ID IN (SELECT tt.TestID FROM #Tests tt) ) OR @TestType <> 1)
		AND
		(
			(@IncludeArchived = 0 AND ISNULL(t.IsArchived, 0) = 0)
			OR
			(@IncludeArchived = 1)
		)
	ORDER BY TestName
	
	SELECT t.id, tlt.id, tlt.TrackingLocationTypeName    
	FROM trackinglocationtypes as tlt, TrackingLocationsForTests as tlfort, Tests as t
	WHERE tlfort.testid = t.id and tlt.ID = tlfort.TrackingLocationtypeID
		AND t.TestType = @TestType
	ORDER BY tlt.TrackingLocationTypeName asc
	
	DROP TABLE #Tests
END
GO
GRANT EXECUTE ON remispTestsSelectListByType TO REMI
GO