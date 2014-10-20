ALTER PROCEDURE [dbo].[remispTestsSelectByBatchUnitStage] @RequestNumber NVARCHAR(11), @BatchUnitNumber INT, @TestStageID INT
AS
BEGIN
	SELECT t.Comment,t.ConcurrencyID,t.Duration,t.ID,t.LastUser,t.ResultBasedOntime,t.TestName,t.TestType,t.WILocation, dbo.remifnTestCanDelete(t.ID) AS CanDelete, t.IsArchived,
		(SELECT TestStageName FROM TestStages WHERE TestID=t.ID) As TestStage, (SELECT JobName FROM Jobs WHERE ID IN (SELECT JobID FROM TestStages WHERE TestID=t.ID)) As JobName,
		t.Owner, t.Trainee, t.DegradationVal
	FROM Tests t
		INNER JOIN vw_GetTaskInfo v ON v.qranumber=@RequestNumber AND testunitsfortest LIKE '%' + CONVERT(NVARCHAR, @BatchUnitNumber) + ',%'
			AND v.TestStageID=@TestStageID AND v.TestID=t.ID
	ORDER BY TestName;
	
	SELECT t.id, tlt.id, tlt.TrackingLocationTypeName    
	FROM trackinglocationtypes as tlt, TrackingLocationsForTests as tlfort, Tests as t
		INNER JOIN vw_GetTaskInfo v ON v.qranumber=@RequestNumber AND testunitsfortest LIKE '%' + CONVERT(NVARCHAR, @BatchUnitNumber) + ',%'
			AND v.TestStageID=@TestStageID AND v.TestID=t.ID
	WHERE tlfort.testid = t.id and tlt.ID = tlfort.TrackingLocationtypeID
	ORDER BY tlt.TrackingLocationTypeName asc
END
GO
GRANT EXECUTE ON [remispTestsSelectByBatchUnitStage] TO REMI
GO