ALTER PROCEDURE Relab.remispResultVersions  @TestID INT, @BatchID INT, @UnitNumber INT = 0, @TestStageID INT = 0
AS
BEGIN
	SELECT tu.BatchUnitNumber, ts.TestStageName As TestStage, rxml.ResultXML, rxml.StationName, rxml.StartDate, rxml.EndDate, ISNULL(rxml.lossFile,'') AS lossFile, 
		CASE WHEN rxml.isProcessed = 1 THEN 'Yes' ELSE 'No' END As Processed, rxml.VerNum, 
		ISNULL(rxml.ProductXML, '') AS ProductXML, ISNULL(rxml.StationXML, '') AS StationXML, ISNULL(rxml.SequenceXML, '') AS SequenceXML,
		ISNULL(rxml.TestXML, '') AS TestXML, CASE WHEN rxml.ErrorOccured = 1 THEN 'Yes' ELSE 'No' END As ErrorOccured
	FROM Relab.Results r WITH(NOLOCK)
		INNER JOIN TestUnits tu WITH(NOLOCK) ON r.TestUnitID=tu.ID
		INNER JOIN Relab.ResultsXML rxml WITH(NOLOCK) ON r.ID=rxml.ResultID
		INNER JOIN TestStages ts WITH(NOLOCK) ON ts.ID=r.TestStageID
	WHERE r.TestID=@TestID AND tu.BatchID=@BatchID
		AND (@UnitNumber = 0 OR tu.BatchUnitNumber=@UnitNumber)
		AND (@TestStageID = 0 OR ts.ID=@TestStageID)
END
GO
GRANT EXECUTE ON [Relab].[remispResultVersions] TO Remi
GO