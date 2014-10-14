ALTER PROCEDURE [Relab].[remispMeasurementsByReq_Test] @RequestNumber NVARCHAR(11), @TestIDs NVARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @tests TABLE(ID INT)
	INSERT INTO @tests SELECT s FROM dbo.Split(',',@TestIDs)
	DECLARE @FalseBit BIT
	DECLARE @TrueBit BIT
	CREATE TABLE #parameters (ResultMeasurementID INT)
	SET @FalseBit = CONVERT(BIT, 0)
	SET @TrueBit = CONVERT(BIT, 1)

	DECLARE @rows VARCHAR(8000)
	DECLARE @sql VARCHAR(8000)
	SELECT @rows=  ISNULL(STUFF(
		( 
		SELECT DISTINCT '],[' + rp.ParameterName
		FROM Relab.ResultsMeasurements rm WITH(NOLOCK)
			INNER JOIN Relab.Results r ON r.ID=rm.ResultID
			INNER JOIN TestUnits tu ON tu.ID = r.TestUnitID
			INNER JOIN Batches b ON b.ID=tu.BatchID
			INNER JOIN Tests t ON t.ID=r.TestID
			INNER JOIN @tests tst ON t.ID=tst.ID
			LEFT OUTER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON rm.ID=rp.ResultMeasurementID
<<<<<<< HEAD
		WHERE b.QRANumber=@RequestNumber AND rm.Archived=@FalseBit AND t.TestName=@TestName
=======
		WHERE b.QRANumber=@RequestNumber AND rm.Archived=@FalseBit AND rp.ParameterName <> 'Command'
>>>>>>> 129ca9c... v2.1.5401.17948
		ORDER BY '],[' +  rp.ParameterName
		FOR XML PATH('')), 1, 2, '') + ']','[na]')

	SET @sql = 'ALTER TABLE #parameters ADD ' + convert(varchar(8000), replace(@rows, ']', '] NVARCHAR(250)'))
	EXEC (@sql)

	IF (@rows != '[na]')
	BEGIN
		EXEC ('INSERT INTO #parameters SELECT *
		FROM (
			SELECT rp.ResultMeasurementID, rp.ParameterName, rp.Value
			FROM Relab.ResultsMeasurements rm WITH(NOLOCK)
				INNER JOIN Relab.Results r ON r.ID=rm.ResultID
				INNER JOIN TestUnits tu ON tu.ID = r.TestUnitID
				INNER JOIN Batches b ON b.ID=tu.BatchID
				INNER JOIN Tests t ON t.ID=r.TestID
				INNER JOIN @tests tst ON t.ID=tst.ID
				LEFT OUTER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON rm.ID=rp.ResultMeasurementID
<<<<<<< HEAD
			WHERE b.QRANumber=''' + @RequestNumber + ''' AND rm.Archived=' + @FalseBit + ' AND t.TestName=''' + @TestName + '''
=======
			WHERE b.QRANumber=''' + @RequestNumber + ''' AND rm.Archived=' + @FalseBit + ' AND rp.ParameterName <> ''Command'' 
>>>>>>> 129ca9c... v2.1.5401.17948
			) te PIVOT (MAX(Value) FOR ParameterName IN (' + @rows + ')) AS pvt')
	END
	ELSE
	BEGIN
		EXEC ('ALTER TABLE #parameters DROP COLUMN na')
	END

	SELECT t.TestName, ts.TestStageName, tu.BatchUnitNumber, ISNULL(ISNULL(ISNULL(lt.[Values], ltsf.[Values]), ltmf.[Values]), ltacc.[Values]) As Measurement, 
		LowerLimit AS [Lower Limit], UpperLimit AS [Upper Limit], MeasurementValue AS Result, lu.[Values] As Unit, 
		CASE WHEN rm.PassFail=1 THEN 'Pass' ELSE 'Fail' END AS [Pass/Fail], rm.ReTestNum AS [Test Num],
		ISNULL(rmf.[File], 0) AS [Image], ISNULL(UPPER(SUBSTRING(rmf.ContentType,2,LEN(rmf.ContentType))), 'PNG') AS ContentType, p.*
	FROM Relab.ResultsMeasurements rm WITH(NOLOCK)
		INNER JOIN Relab.Results r ON r.ID=rm.ResultID
		INNER JOIN TestUnits tu ON tu.ID = r.TestUnitID
		INNER JOIN Batches b ON b.ID=tu.BatchID
		INNER JOIN Tests t ON t.ID=r.TestID
		INNER JOIN @tests tst ON t.ID=tst.ID
		INNER JOIN TestStages ts ON ts.ID=r.TestStageID
		LEFT OUTER JOIN Lookups lu WITH(NOLOCK) ON lu.Type='UnitType' AND lu.LookupID=rm.MeasurementUnitTypeID
		LEFT OUTER JOIN Lookups lt WITH(NOLOCK) ON lt.Type='MeasurementType' AND lt.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Lookups ltsf WITH(NOLOCK) ON ltsf.Type='SFIFunctionalMatrix' AND ltsf.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Lookups ltmf WITH(NOLOCK) ON ltmf.Type='MFIFunctionalMatrix' AND ltmf.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Lookups ltacc WITH(NOLOCK) ON ltacc.Type='AccFunctionalMatrix' AND ltacc.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Relab.ResultsMeasurementsFiles rmf WITH(NOLOCK) ON rmf.ResultMeasurementID=rm.ID
		LEFT OUTER JOIN #parameters p WITH(NOLOCK) ON p.ResultMeasurementID=rm.ID
		LEFT OUTER JOIN Relab.ResultsXML x ON x.ID = rm.XMLID
	WHERE b.QRANumber=@RequestNumber AND rm.Archived=@FalseBit
		AND (ISNULL(ISNULL(ISNULL(lt.[Values], ltsf.[Values]), ltmf.[Values]), ltacc.[Values]) NOT IN ('start', 'Start utc', 'end'))
	ORDER BY tu.BatchUnitNumber, ts.ProcessOrder, rm.ReTestNum

	DROP TABLE #parameters
	SET NOCOUNT OFF
END
GO
GRANT EXECUTE ON [Relab].[remispMeasurementsByReq_Test] TO Remi
GO