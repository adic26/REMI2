ALTER PROCEDURE [dbo].[remispTestsSelectListByType] @TestType int, @IncludeArchived BIT = 0
AS
BEGIN
	SELECT t.Comment,t.ConcurrencyID,t.Duration,t.ID,t.LastUser,t.ResultBasedOntime,t.TestName,t.TestType,t.WILocation, dbo.remifnTestCanDelete(t.ID) AS CanDelete, t.IsArchived,
		(SELECT TestStageName FROM TestStages WHERE TestID=t.ID) As TestStage, (SELECT JobName FROM Jobs WHERE ID IN (SELECT JobID FROM TestStages WHERE TestID=t.ID)) As JobName,
		t.Owner, t.Trainee, t.DegradationVal
	FROM Tests t
	WHERE TestType = @TestType 
		AND
		(
			(@IncludeArchived = 0 AND ISNULL(t.IsArchived, 0) = 0)
			OR
			(@IncludeArchived = 1)
		)
	ORDER BY TestName;
	
	SELECT t.id, tlt.id, tlt.TrackingLocationTypeName    
	FROM trackinglocationtypes as tlt, TrackingLocationsForTests as tlfort, Tests as t
	WHERE tlfort.testid = t.id and tlt.ID = tlfort.TrackingLocationtypeID
		AND t.TestType = @TestType
	ORDER BY tlt.TrackingLocationTypeName asc
END
GO
GRANT EXECUTE ON remispTestsSelectListByType TO REMI
GO