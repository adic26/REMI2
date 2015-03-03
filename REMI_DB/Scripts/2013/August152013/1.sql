begin tran
go
ALTER PROCEDURE [Relab].[FunctionalMatrixByTestRecord] @TRID INT = NULL, @TestStageID INT, @TestID INT, @BatchID INT, @UnitIDs NVARCHAR(MAX) = NULL, @LookupType NVARCHAR(20)
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @TestUnitID INT
	DECLARE @rows VARCHAR(8000)
	DECLARE @sql VARCHAR(8000)
	CREATE Table #units(id int) 
	
	IF (@TRID IS NOT NULL)
	BEGIN
		SELECT @TestUnitID = TestUnitID FROM TestRecords WHERE ID=@TRID
		INSERT INTO #units VALUES (@TestUnitID)
	END
	ELSE
	BEGIN
		EXEC(@UnitIDs)
	END
	
	SELECT @rows=  ISNULL(STUFF(
		(SELECT DISTINCT '],[' + l.[Values]
		FROM dbo.Lookups l
		WHERE l.IsActive = 1 AND Type=@LookupType
		ORDER BY '],[' +  l.[Values]
		FOR XML PATH('')), 1, 2, '') + ']','[na]')
	
	SET @sql = 'SELECT *
		FROM (
			SELECT l.[Values], tu.ID AS TestUnitID, tu.BatchUnitNumber, 
				CASE 
					WHEN r.ID IS NULL 
					THEN -1
					ELSE (
						SELECT PassFail 
						FROM Relab.ResultsMeasurements rm 
							LEFT OUTER JOIN Lookups lr ON lr.Type=''' + CONVERT(VARCHAR, @LookupType) + ''' AND rm.MeasurementTypeID=lr.LookupID
						WHERE rm.ResultID=r.ID AND lr.[values] = l.[values])
				END As Row
			FROM dbo.Lookups l
			INNER JOIN TestUnits tu ON tu.BatchID = ' + CONVERT(VARCHAR, @BatchID) + ' AND 
				(
					(' + CONVERT(VARCHAR, ISNULL(CONVERT(VARCHAR,@TestUnitID), 'NULL')) + ' IS NULL)
					OR
					(' + CONVERT(VARCHAR, ISNULL(CONVERT(VARCHAR,@TestUnitID), 'NULL')) + ' IS NOT NULL AND tu.ID=' + CONVERT(VARCHAR, ISNULL(CONVERT(VARCHAR,@TestUnitID), 'NULL')) + ')
				)
			INNER JOIN #units ON tu.ID=#units.ID
			LEFT OUTER JOIN Relab.Results r ON r.TestID = ' + CONVERT(VARCHAR, @TestID) + ' AND r.TestStageID = ' + CONVERT(VARCHAR, @TestStageID) + ' 
				AND r.TestUnitID = tu.ID
			WHERE l.IsActive = 1 AND l.Type=''' + CONVERT(VARCHAR, @LookupType) + '''
			) te 
			PIVOT (MAX(row) FOR [Values] IN (' + @rows + ')) AS pvt
			ORDER BY BatchUnitNumber'
	
	PRINT @sql
	EXEC(@sql)
	
	SET NOCOUNT OFF
END
GO
GRANT EXECUTE ON [Relab].[FunctionalMatrixByTestRecord] TO Remi
GO

ALTER PROCEDURE [Relab].[remispResultMeasurements] @ResultID INT, @OnlyFails INT = 0, @IncludeArchived INT = 0
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @ReTestNum INT
	CREATE TABLE #parameters (ResultMeasurementID INT)
	SELECT @ReTestNum= MAX(Relab.ResultsMeasurements.ReTestNum) FROM Relab.ResultsMeasurements WHERE Relab.ResultsMeasurements.ResultID=@ResultID

	DECLARE @rows VARCHAR(8000)
	DECLARE @sql VARCHAR(8000)
	SELECT @rows=  ISNULL(STUFF(
		( 
		SELECT DISTINCT '],[' + rp.ParameterName
		FROM Relab.ResultsMeasurements rm WITH(NOLOCK)
			LEFT OUTER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON rm.ID=rp.ResultMeasurementID
		WHERE ResultID=@ResultID AND ((@IncludeArchived = 0 AND rm.Archived=0) OR (@IncludeArchived=1)) AND ((@OnlyFails = 1 AND PassFail=0) OR (@OnlyFails = 0))
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
				LEFT OUTER JOIN Relab.ResultsParameters rp WITH(NOLOCK) ON rm.ID=rp.ResultMeasurementID
			WHERE ResultID=' + @ResultID + ' AND ((' + @IncludeArchived + ' = 0 AND rm.Archived=0) OR (' + @IncludeArchived + '=1)) 
				AND ((' + @OnlyFails + ' = 1 AND PassFail=0) OR (' + @OnlyFails + ' = 0))
			) te PIVOT (MAX(Value) FOR ParameterName IN (' + @rows + ')) AS pvt')
	END
	ELSE
	BEGIN
		EXEC ('ALTER TABLE #parameters DROP COLUMN na')
	END
	
	SELECT rm.ID, ISNULL(ISNULL(lt.[Values], ltsf.[Values]), ltmf.[Values]) As Measurement, LowerLimit AS [Lower Limit], UpperLimit AS [Upper Limit], MeasurementValue AS Result, lu.[Values] As Unit, 
		CASE WHEN PassFail=1 THEN 'Pass' ELSE 'Fail' END AS [Pass/Fail],
		rm.MeasurementTypeID, rm.ReTestNum AS [Test Num], rm.Archived, rm.XMLID, 
		@ReTestNum AS MaxVersion, 
		rm.Comment,
		ISNULL(rmf.[File], 0) AS [Image], 
		ISNULL(UPPER(SUBSTRING(rmf.ContentType,2,LEN(rmf.ContentType))), 'PNG') AS ContentType, p.*
	FROM Relab.ResultsMeasurements rm WITH(NOLOCK)
		LEFT OUTER JOIN Lookups lu WITH(NOLOCK) ON lu.Type='UnitType' AND lu.LookupID=rm.MeasurementUnitTypeID
		LEFT OUTER JOIN Lookups lt WITH(NOLOCK) ON lt.Type='MeasurementType' AND lt.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Lookups ltsf WITH(NOLOCK) ON ltsf.Type='SFIFunctionalMatrix' AND ltsf.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Lookups ltmf WITH(NOLOCK) ON ltmf.Type='MFIFunctionalMatrix' AND ltmf.LookupID=rm.MeasurementTypeID
		LEFT OUTER JOIN Relab.ResultsMeasurementsFiles rmf ON rmf.ResultMeasurementID=rm.ID
		LEFT OUTER JOIN #parameters p ON p.ResultMeasurementID=rm.ID
	WHERE ResultID=@ResultID AND ((@IncludeArchived = 0 AND rm.Archived=0) OR (@IncludeArchived=1)) AND ((@OnlyFails = 1 AND PassFail=0) OR (@OnlyFails = 0))
	ORDER BY lt.[Values], rm.ReTestNum ASC

	DROP TABLE #parameters
	SET NOCOUNT OFF
END
GO
GRANT EXECUTE ON [Relab].[remispResultMeasurements] TO Remi
GO
rollback tran