begin tran
go
create PROCEDURE [dbo].remispGetBatchUnitsInStage @QRANumber nvarchar(11)
AS
BEGIN
	DECLARE @rows VARCHAR(8000)
	DECLARE @sql VARCHAR(8000)
	DECLARE @RowID INT
	DECLARE @TestUnitID INT
	DECLARE @BatchUnitNumber INT
	CREATE TABLE #Testing (TestStageID INT, TestStageName NVARCHAR(400), ProcessOrder INT)

	SELECT @rows=  ISNULL(STUFF(
			( 
			SELECT DISTINCT '],[' + CONVERT(VARCHAR, tu.BatchUnitNumber)
			FROM TestUnits tu
				INNER JOIN Batches b ON b.ID=tu.BatchID
			WHERE b.QRANumber=@QRANumber
			FOR XML PATH('')), 1, 2, '') + ']','[na]')

	INSERT INTO #Testing (TestStageID, TestStageName, ProcessOrder)
	SELECT ID, TestStageName, ProcessOrder
	FROM (
	SELECT ts.ID, ts.TestStageName, ts.ProcessOrder
	FROM TestStages ts WITH(NOLOCK)
		INNER JOIN Jobs j WITH(NOLOCK) ON ts.JobID=j.ID
		INNER JOIN Batches b WITH(NOLOCK) on j.jobname = b.jobname 
		INNER JOIN Tests t WITH(NOLOCK) ON ( ( ts.teststagetype = 2 AND ts.testid = t.id ) OR ts.teststagetype != 2 AND ts.teststagetype = t.testtype )
		INNER JOIN Products p WITH(NOLOCK) ON b.ProductID=p.ID
	WHERE b.QRANumber = @QRANumber AND EXISTS 
		(
			SELECT DISTINCT 1
			FROM Req.RequestSetup rs
			WHERE
				(
					(rs.JobID IS NULL )
					OR
					(rs.JobID IS NOT NULL AND rs.JobID = j.ID)
				)
				AND
				(
					(rs.ProductID IS NULL)
					OR
					(rs.ProductID IS NOT NULL AND rs.ProductID = p.ID)
				)
				AND
				(
					(rs.TestID IS NULL)
					OR
					(rs.TestID IS NOT NULL AND rs.TestID = t.ID)
				)
				AND
				(
					(rs.TestStageID IS NULL)
					OR
					(rs.TestStageID IS NOT NULL AND rs.TestStageID = ts.ID)
				)
				AND
				(
					(rs.BatchID IS NULL) AND NOT EXISTS(SELECT 1 
														FROM Req.RequestSetup rs2 
															INNER JOIN TestStages ts2 ON ts2.ID=rs2.TestStageID AND ts2.TestStageType=ts.TestStageType
														WHERE rs2.BatchID = b.ID )
					OR
					(rs.BatchID IS NOT NULL AND rs.BatchID = b.ID)
				)
		)
	) s
	ORDER BY ProcessOrder

	SET @sql = 'ALTER TABLE #Testing ADD ' + convert(varchar(8000), replace(@rows, ']', '] BIT '))
	EXEC (@sql)

	SELECT ROW_NUMBER() OVER (ORDER BY tu.ID) AS RowID, tu.BatchUnitNumber, tu.ID
	INTO #units
	FROM TestUnits tu WITH(NOLOCK)
		INNER JOIN Batches b ON b.ID=tu.BatchID
	WHERE b.QRANumber=@QRANumber

	SELECT @RowID = MIN(RowID) FROM #units
				
	WHILE (@RowID IS NOT NULL)
	BEGIN
		SELECT @BatchUnitNumber=BatchUnitNumber, @TestUnitID=ID FROM #units WITH(NOLOCK) WHERE RowID=@RowID

		SET @sql = 'UPDATE t SET [' + CONVERT(VARCHAR,@BatchUnitNumber) + '] = 
			(
				SELECT DISTINCT CONVERT(BIT, 1)
				FROM vw_GetTaskInfo ti 
				WHERE ti.QRANumber = ''' + @QRANumber + ''' AND t.TestStageID=ti.TestStageID 
					AND ti.testunitsfortest LIKE ''%' + CONVERT(VARCHAR,@BatchUnitNumber) + ',%''
			)
		FROM #Testing t
	'
		
		print @sql

		EXECUTE (@sql)
		
		SELECT @RowID = MIN(RowID) FROM #units WITH(NOLOCK) WHERE RowID > @RowID

	END


	SELECT * FROM #Testing

	DROP TABLE #Testing
	DROP TABLE #units
END
GO
GRANT EXECUTE ON remispGetBatchUnitsInStage TO REMI
GO
ALTER PROCEDURE [Relab].[remispMeasurementsByReq_Test] @RequestNumber NVARCHAR(11), @TestName NVARCHAR(400)
AS
BEGIN
	SET NOCOUNT ON

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
			LEFT OUTER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON rm.ID=rp.ResultMeasurementID
		WHERE b.QRANumber=@RequestNumber AND rm.Archived=@FalseBit AND t.TestName=@TestName
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
				LEFT OUTER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON rm.ID=rp.ResultMeasurementID
			WHERE b.QRANumber=''' + @RequestNumber + ''' AND rm.Archived=' + @FalseBit + ' AND t.TestName=''' + @TestName + '''
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
		INNER JOIN TestStages ts ON ts.ID=r.TestStageID
		LEFT OUTER JOIN Lookups lu WITH(NOLOCK) ON lu.Type='UnitType' AND lu.LookupID=rm.MeasurementUnitTypeID
		LEFT OUTER JOIN Lookups lt WITH(NOLOCK) ON lt.Type='MeasurementType' AND lt.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Lookups ltsf WITH(NOLOCK) ON ltsf.Type='SFIFunctionalMatrix' AND ltsf.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Lookups ltmf WITH(NOLOCK) ON ltmf.Type='MFIFunctionalMatrix' AND ltmf.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Lookups ltacc WITH(NOLOCK) ON ltacc.Type='AccFunctionalMatrix' AND ltacc.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Relab.ResultsMeasurementsFiles rmf WITH(NOLOCK) ON rmf.ResultMeasurementID=rm.ID
		LEFT OUTER JOIN #parameters p WITH(NOLOCK) ON p.ResultMeasurementID=rm.ID
		LEFT OUTER JOIN Relab.ResultsXML x ON x.ID = rm.XMLID
	WHERE b.QRANumber=@RequestNumber AND rm.Archived=@FalseBit AND t.TestName=@TestName
		AND (ISNULL(ISNULL(ISNULL(lt.[Values], ltsf.[Values]), ltmf.[Values]), ltacc.[Values]) NOT IN ('start', 'Start utc', 'end'))
	ORDER BY tu.BatchUnitNumber, ts.ProcessOrder, rm.ReTestNum

	DROP TABLE #parameters
	SET NOCOUNT OFF
END
go


rollback tran