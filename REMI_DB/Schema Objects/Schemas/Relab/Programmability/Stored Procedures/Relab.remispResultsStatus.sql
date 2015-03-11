ALTER PROCEDURE [Relab].[remispResultsStatus] @BatchID INT
AS
BEGIN
	DECLARE @Status NVARCHAR(18)
	
	SELECT CASE WHEN r.PassFail = 0 THEN 'Fail' ELSE 'Pass' END AS Result, COUNT(*) AS NumRecords
	INTO #ResultCount
	FROM Relab.Results r
		INNER JOIN TestUnits tu ON tu.ID=r.TestUnitID
	WHERE tu.BatchID=@BatchID
	GROUP BY r.PassFail
	
	SELECT CASE WHEN rs.PassFail = 1 THEN 'Pass' WHEN rs.PassFail=2 THEN 'Fail' ELSE 'No Result' END AS Result, 
		rs.ApprovedBy, rs.ApprovedDate
	INTO #ResultOverride
	FROM Relab.ResultsStatus rs
	WHERE rs.BatchID=@BatchID
	ORDER BY ResultStatusID DESC
	
	IF ((SELECT COUNT(*) FROM #ResultOverride) > 0)
		BEGIN
			SELECT TOP 1 @Status = Result FROM #ResultOverride
		END
	ELSE
		BEGIN
			IF EXISTS ((SELECT 1 FROM #ResultCount WHERE Result='Fail'))
				SET @Status = 'Preliminary Fail'
			ELSE IF EXISTS ((SELECT 1 FROM #ResultCount WHERE Result='Pass'))
				SET @Status = 'Preliminary Pass'
			ELSE
				SET @Status = 'No Result'
		END
	
	SELECT * FROM #ResultCount
	SELECT * FROM #ResultOverride
		
	SELECT @Status AS FinalStatus
	
	DROP TABLE #ResultCount
	DROP TABLE #ResultOverride
END
GO
GRANT EXECUTE ON [Relab].[remispResultsStatus] TO Remi
GO