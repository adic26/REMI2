ALTER PROCEDURE Relab.[remispGetAllResultsByQRAStage] @BatchID INT, @TestStageID INT
AS
BEGIN
	SELECT r.ID, j.JobName + '-' + ts.TestStageName AS TestStageName, t.TestName, tu.BatchUnitNumber, CASE WHEN PassFail=1 THEN 'Pass' ELSE 'Fail' END AS PassFail, t.ID As TestID, ts.ID As TestStageID,
		ISNULL((SELECT MAX(ISNULL(rxml.VerNum,0)) FROM Relab.ResultsXML rxml WHERE ISNULL(rxml.isProcessed, 0) = 1 AND rxml.ResultID=r.ID),0) AS VerNum
	FROM Relab.Results r WITH(NOLOCK)
		INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
		INNER JOIN Tests t WITH(NOLOCK) ON r.TestID=t.ID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID=r.TestUnitID
		INNER JOIN Jobs j ON j.ID=ts.JobID
	WHERE tu.BatchID=@BatchID AND ts.ID=@TestStageID
	ORDER BY tu.BatchUnitNumber, ts.TestStageName, t.TestName
END
GO
GRANT EXECUTE ON Relab.[remispGetAllResultsByQRAStage] TO REMI
GO