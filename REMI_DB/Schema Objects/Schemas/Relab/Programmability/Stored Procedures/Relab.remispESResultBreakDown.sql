ALTER PROCEDURE [Relab].[remispESResultBreakDown] @RequestNumber NVARCHAR(11)
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @BatchID INT
	DECLARE @UnitRows VARCHAR(8000)
	DECLARE @sql VARCHAR(8000)
	DECLARE @BatchUnitNumber INT
	DECLARE @UnitCount INT
	DECLARE @RowID INT
	DECLARE @ID INT
	SELECT @BatchID = ID FROM Batches WHERE QRANumber=@RequestNumber

	SELECT r.TestUnitID, r.TestID, r.TestStageID, tu.BatchUnitNumber, t.TestName, ts.TestStageName,
		(CASE WHEN PassFail  = 1 THEN 'Pass' WHEN PassFail = 0 THEN 'Fail' ELSE NULL END) AS Result,
		(CASE WHEN (SELECT COUNT(*) FROM Relab.ResultsMeasurementsFiles rmf INNER JOIN Relab.ResultsMeasurements rm ON rm.ID=rmf.ResultMeasurementID WHERE rm.ResultID=r.ID) > 0 THEN 1 ELSE 0 END) AS HasFiles
	FROM Batches b 
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.BatchID=b.ID
		INNER JOIN Relab.Results r WITH(NOLOCK) ON r.TestUnitID=tu.ID
		INNER JOIN Tests t WITH(NOLOCK) ON t.ID=r.TestID
		INNER JOIN TestStages ts WITH(NOLOCK) ON ts.ID=r.TestStageID
	WHERE b.ID=@BatchID AND ts.TestStageName NOT IN ('Analysis')
	ORDER BY tu.BatchUnitNumber, t.TestName, ts.TestStageName
	
	SET NOCOUNT OFF
END
GO
GRANT EXECUTE ON [Relab].[remispESResultBreakDown] TO Remi
GO