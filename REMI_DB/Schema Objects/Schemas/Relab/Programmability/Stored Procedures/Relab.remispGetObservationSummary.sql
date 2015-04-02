ALTER PROCEDURE Relab.remispGetObservationSummary @BatchID INT
AS
BEGIN
	DECLARE @RowID INT
	DECLARE @ID INT
	DECLARE @BatchUnitNumber INT
	Declare @ObservationLookupID INT
	DECLARE @query NVARCHAR(4000)
	CREATE TABLE #Observations (Observation NVARCHAR(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL, UnitsAffected INT)

	SELECT @ObservationLookupID = LookupID FROM Lookups WITH(NOLOCK) WHERE LookupTypeID=7 AND [values] = 'Observation'

	SELECT ROW_NUMBER() OVER (ORDER BY tu.ID) AS RowID, tu.BatchUnitNumber, tu.ID
	INTO #units
	FROM TestUnits tu WITH(NOLOCK)
	WHERE BatchID=@BatchID

	SELECT m.ID AS MeasurementID, tu.ID AS TestUnitID, tu.batchunitnumber, ts.ProcessOrder, ts.TestStageName, Relab.ResultsObservation (m.ID) AS Observation
	INTO #temp
	FROM Relab.ResultsMeasurements m WITH(NOLOCK)
		INNER JOIN Relab.Results r WITH(NOLOCK) ON r.ID=m.ResultID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON r.TestUnitID=tu.ID
		INNER JOIN TestStages ts WITH(NOLOCK) ON ts.ID=r.TestStageID
		INNER JOIN Tests t WITH(NOLOCK) ON t.ID=r.TestID
		INNER JOIN Lookups lm WITH(NOLOCK) ON lm.LookupID=m.MeasurementTypeID
		INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID
		LEFT OUTER JOIN JobOrientation jo WITH(NOLOCK) ON jo.ID=b.OrientationID
	WHERE MeasurementTypeID = @ObservationLookupID AND b.ID=@BatchID AND ISNULL(m.Archived, 0) = 0
		
	INSERT INTO #Observations
	SELECT Observation, COUNT(DISTINCT TestUnitID) AS UnitsAffected
	FROM #temp WITH(NOLOCK)
	GROUP BY Observation
	
	SELECT @RowID = MIN(RowID) FROM #units
				
	WHILE (@RowID IS NOT NULL)
	BEGIN
		SET @query = ''
		SELECT @BatchUnitNumber=BatchUnitNumber, @ID=ID FROM #units WITH(NOLOCK) WHERE RowID=@RowID
		
		EXECUTE ('ALTER TABLE #Observations ADD [' + @BatchUnitNumber + '] NVARCHAR(10) NULL')
		
		SET @query = 'UPDATE #Observations SET [' + CONVERT(VARCHAR,@BatchUnitNumber) + '] = ISNULL((
			SELECT TOP 1 REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(TestStageName,''''),''drops'',''''),''drop'',''''),''tumbles'',''''),''tumble'','''')
			FROM #temp WITH(NOLOCK)
			WHERE batchunitnumber=' + CONVERT(VARCHAR,@BatchUnitNumber) + ' 
				AND #temp.Observation = #Observations.Observation
			ORDER BY ProcessOrder ASC
		), ''-'')'
		
		EXECUTE (@query)
			
		SELECT @RowID = MIN(RowID) FROM #units WITH(NOLOCK) WHERE RowID > @RowID
	END
	
	DECLARE @units NVARCHAR(4000)
	SELECT @units = ISNULL(STUFF((
	SELECT '], [' + CONVERT(VARCHAR, tu.BatchUnitNumber)
	FROM TestUnits tu WITH(NOLOCK)
	WHERE BatchID=@BatchID
	FOR XML PATH('')), 1, 2, '') + ']','[na]')
	
	SET @query = 'SELECT Observation, ' + @units + ', UnitsAffected FROM #Observations'
	EXECUTE (@query)

	DROP TABLE #temp
	DROP TABLE #Observations
	DROP TABLE #units
END
GO
GRANT EXECUTE ON Relab.remispGetObservationSummary TO REMI
GO