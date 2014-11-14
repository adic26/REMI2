ALTER PROCEDURE dbo.[remispTests] @TrackingLocationID INT, @JobID INT
AS
BEGIN	
	SELECT test.TestName, test.ProcessOrder
	INTO #tests
	FROM (
	SELECT t.TestName, ts.ProcessOrder
	FROM Tests t
	INNER JOIN TrackingLocationsForTests tlft ON t.ID = tlft.TestID
	INNER JOIN TrackingLocationTypes tlt ON tlt.ID = tlft.TrackingLocationtypeID
	INNER JOIN TrackingLocations tl ON tl.TrackingLocationTypeID = tlt.ID
	INNER JOIN TestStages ts ON ts.TestID = t.ID AND ts.JobID=@jobID AND t.TestType NOT IN (1, 3)
	WHERE ISNULL(t.IsArchived, 0)=0 AND tl.ID = @TrackingLocationID
	UNION
	SELECT t2.TestName, 0 AS ProcessOrder
	FROM Tests t2
	INNER JOIN TrackingLocationsForTests tlft ON t2.ID = tlft.TestID
	INNER JOIN TrackingLocationTypes tlt ON tlt.ID = tlft.TrackingLocationtypeID
	INNER JOIN TrackingLocations tl ON tl.TrackingLocationTypeID = tlt.ID
	WHERE ISNULL(t2.IsArchived, 0)=0 AND tl.ID = @TrackingLocationID AND t2.TestType IN (1, 3)
	) test
	ORDER BY test.ProcessOrder
	
	SELECT TestName FROM #tests
	
	DROP TABLE #tests
END
GO
GRANT EXECUTE ON dbo.[remispTests] TO Remi
GO