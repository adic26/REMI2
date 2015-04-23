ALTER PROCEDURE [Relab].[remispResultsSummary] @BatchID INT
AS
BEGIN
	SELECT r.ID, ts.TestStageName AS Stage, t.TestName AS Test, tu.BatchUnitNumber AS Unit, CASE WHEN PassFail=1 THEN 'Pass' ELSE 'Fail' END AS PassFail,
		ISNULL((SELECT TOP 1 1 FROM Relab.ResultsMeasurements WHERE ResultID=r.ID),0) AS HasMeasurements
	FROM Relab.Results r WITH(NOLOCK)
		INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
		INNER JOIN Tests t WITH(NOLOCK) ON r.TestID=t.ID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID=r.TestUnitID
	WHERE tu.BatchID=@BatchID
	ORDER BY tu.BatchUnitNumber, ts.ProcessOrder, t.TestName
END
GO
GRANT EXECUTE ON [Relab].[remispResultsSummary] TO Remi
GO