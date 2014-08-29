ALTER PROCEDURE [Relab].[remispResultsSummaryExport] @BatchID INT, @ResultID INT = NULL
AS
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #parameters (ResultMeasurementID INT)

	DECLARE @rows VARCHAR(8000)
	DECLARE @sql VARCHAR(8000)
	SELECT @rows=  ISNULL(STUFF(
		( 
		SELECT DISTINCT '],[' + rp.ParameterName
		FROM Relab.Results r WITH(NOLOCK)
			INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
			INNER JOIN Tests t WITH(NOLOCK) ON r.TestID=t.ID
			INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID=r.TestUnitID
			INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID
			INNER JOIN Relab.ResultsMeasurements m WITH(NOLOCK) ON m.ResultID=r.ID
			LEFT OUTER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON m.ID=rp.ResultMeasurementID
		WHERE b.ID=@BatchID AND (@ResultID IS NULL OR (@ResultID IS NOT NULL AND r.ID=@ResultID))
		ORDER BY '],[' +  rp.ParameterName
		FOR XML PATH('')), 1, 2, '') + ']','[na]')

	SET @sql = 'ALTER TABLE #parameters ADD ' + convert(varchar(8000), replace(@rows, ']', '] NVARCHAR(250)'))
	EXEC (@sql)

	IF (@rows != '[na]')
	BEGIN
		SET @sql = 'INSERT INTO #parameters SELECT *
		FROM (
			SELECT rp.ResultMeasurementID, rp.ParameterName, rp.Value
			FROM Relab.Results r WITH(NOLOCK)
				INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
				INNER JOIN Tests t WITH(NOLOCK) ON r.TestID=t.ID
				INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID=r.TestUnitID
				INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID
				INNER JOIN Relab.ResultsMeasurements m WITH(NOLOCK) ON m.ResultID=r.ID
				LEFT OUTER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON m.ID=rp.ResultMeasurementID
			WHERE b.ID=' + CONVERT(VARCHAR, @BatchID) + ' AND (' + CASE WHEN convert(varchar,@ResultID) IS NULL THEN 'NULL' ELSE convert(varchar,@ResultID) END + ' IS NULL OR (' + CASE WHEN convert(varchar,@ResultID) IS NULL THEN 'NULL' ELSE convert(varchar,@ResultID) END + ' IS NOT NULL AND r.ID=' + CASE WHEN @ResultID IS NOT NULL THEN CONVERT(VARCHAR, @ResultID) ELSE 'NULL' END + '))
			) te PIVOT (MAX(Value) FOR ParameterName IN (' + @rows + ')) AS pvt'
		EXEC (@sql)
	END
	ELSE
	BEGIN
		EXEC ('ALTER TABLE #parameters DROP COLUMN na')
	END

	SELECT b.QRANumber, tu.BatchUnitNumber As Unit, tu.BSN, ts.TestStageName AS TestStage, t.TestName, 
		lm.[Values] AS MeasurementType, m.LowerLimit, m.UpperLimit, m.MeasurementValue AS Result, lu.[Values] AS Units,
		CASE WHEN m.PassFail=1 THEN 'Pass' ELSE 'Fail' END AS PassFail, --Relab.ResultsParametersComma(m.ID) AS Parameters, 
		m.ReTestNum, m.Archived, m.Comment, rxml.VerNum AS XMLVersion, rxml.StartDate, rxml.EndDate, rxml.StationName, m.Description, p.*
	FROM Relab.Results r WITH(NOLOCK)
		INNER JOIN TestStages ts WITH(NOLOCK) ON r.TestStageID=ts.ID
		INNER JOIN Tests t WITH(NOLOCK) ON r.TestID=t.ID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON tu.ID=r.TestUnitID
		INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID
		INNER JOIN Relab.ResultsMeasurements m WITH(NOLOCK) ON m.ResultID=r.ID
		LEFT OUTER JOIN Lookups lm WITH(NOLOCK) ON m.MeasurementTypeID=lm.LookupID
		LEFT OUTER JOIN Lookups lu WITH(NOLOCK) ON m.MeasurementUnitTypeID=lu.LookupID
		LEFT OUTER JOIN Relab.ResultsXML rxml WITH(NOLOCK) ON rxml.ID=m.XMLID
		LEFT OUTER JOIN #parameters p WITH(NOLOCK) ON p.ResultMeasurementID=m.ID
	WHERE b.ID=@BatchID AND (@ResultID IS NULL OR (@ResultID IS NOT NULL AND r.ID=@ResultID))
	ORDER BY tu.BatchUnitNumber, ts.TestStageName, TestName
	
	SET NOCOUNT OFF
END
GO
GRANT EXECUTE ON [Relab].[remispResultsSummaryExport] TO Remi
GO