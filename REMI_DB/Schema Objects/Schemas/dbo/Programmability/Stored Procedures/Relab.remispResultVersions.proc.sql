ALTER PROCEDURE Relab.remispResultVersions  @TestID INT, @BatchID INT
AS
BEGIN
	SELECT tu.BatchUnitNumber, ts.TestStageName As TestStage, rxml.ResultXML, rxml.StationName, rxml.StartDate, rxml.EndDate, ISNULL(rxml.lossFile,'') AS lossFile, 
		CASE WHEN rxml.isProcessed = 1 THEN 'Yes' ELSE 'No' END As Processed, rxml.VerNum
	FROM Relab.Results r WITH(NOLOCK)
		INNER JOIN TestUnits tu WITH(NOLOCK) ON r.TestUnitID=tu.ID
		INNER JOIN Relab.ResultsXML rxml WITH(NOLOCK) ON r.ID=rxml.ResultID
		INNER JOIN TestStages ts WITH(NOLOCK) ON ts.ID=r.TestStageID
	WHERE r.TestID=@TestID AND tu.BatchID=@BatchID
END
GO
GRANT EXECUTE ON [Relab].[remispResultVersions] TO Remi
GO
