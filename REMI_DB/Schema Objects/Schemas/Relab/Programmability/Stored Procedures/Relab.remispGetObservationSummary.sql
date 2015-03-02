ALTER PROCEDURE Relab.remispGetObservationSummary @BatchID INT
AS
BEGIN
	DECLARE @RowID INT
	DECLARE @ID INT
	DECLARE @BatchUnitNumber INT
	DECLARE @query NVARCHAR(4000)
	CREATE TABLE #Observations (Observation NVARCHAR(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL)

	SELECT ROW_NUMBER() OVER (ORDER BY tu.ID) AS RowID, tu.BatchUnitNumber, tu.ID
	INTO #units
	FROM TestUnits tu WITH(NOLOCK)
	WHERE BatchID=@BatchID

	INSERT INTO #Observations
	SELECT DISTINCT Relab.ResultsObservation (m.ID) AS Observation
	FROM Relab.ResultsMeasurements m WITH(NOLOCK)
		INNER JOIN Relab.Results r WITH(NOLOCK) ON r.ID=m.ResultID
		INNER JOIN TestUnits tu WITH(NOLOCK) ON r.TestUnitID=tu.ID
		INNER JOIN TestStages ts WITH(NOLOCK) ON ts.ID=r.TestStageID
		INNER JOIN Tests t WITH(NOLOCK) ON t.ID=r.TestID
		INNER JOIN Lookups lm WITH(NOLOCK) ON lm.LookupID=m.MeasurementTypeID
		INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID
		LEFT OUTER JOIN JobOrientation jo WITH(NOLOCK) ON jo.ID=b.OrientationID
		LEFT OUTER JOIN Relab.ResultsMeasurementsFiles mf WITH(NOLOCK) ON mf.ResultMeasurementID=m.ID
	WHERE MeasurementTypeID IN (SELECT LookupID FROM Lookups WHERE LookupTypeID=7 AND [values] = 'Observation') AND b.ID=@BatchID

	SELECT @RowID = MIN(RowID) FROM #units
				
	WHILE (@RowID IS NOT NULL)
	BEGIN
		SET @query = ''
		SELECT @BatchUnitNumber=BatchUnitNumber, @ID=ID FROM #units WITH(NOLOCK) WHERE RowID=@RowID
		
		EXECUTE ('ALTER TABLE #Observations ADD [' + @BatchUnitNumber + '] NVARCHAR(10) NULL')
		
		SET @query = 'UPDATE #Observations SET [' + CONVERT(VARCHAR,@BatchUnitNumber) + '] = ISNULL((
			SELECT TOP 1 REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(ts.TestStageName,''''),''drops'',''''),''drop'',''''),''tumbles'',''''),''tumble'','''')
			FROM Relab.ResultsMeasurements m WITH(NOLOCK)
				INNER JOIN Relab.Results r WITH(NOLOCK) ON r.ID=m.ResultID
				INNER JOIN TestUnits tu WITH(NOLOCK) ON r.TestUnitID=tu.ID
				INNER JOIN TestStages ts WITH(NOLOCK) ON ts.ID=r.TestStageID
				INNER JOIN Tests t WITH(NOLOCK) ON t.ID=r.TestID
				INNER JOIN Lookups lm WITH(NOLOCK) ON lm.LookupID=m.MeasurementTypeID
				INNER JOIN Batches b WITH(NOLOCK) ON b.ID=tu.BatchID
				LEFT OUTER JOIN JobOrientation jo WITH(NOLOCK) ON jo.ID=b.OrientationID
				LEFT OUTER JOIN Relab.ResultsMeasurementsFiles mf WITH(NOLOCK) ON mf.ResultMeasurementID=m.ID
			WHERE MeasurementTypeID IN (SELECT LookupID FROM Lookups WHERE LookupTypeID=7 
				AND [values] = ''Observation'') AND b.ID=' + CONVERT(VARCHAR, @BatchID) + ' 
				AND tu.batchunitnumber=' + CONVERT(VARCHAR,@BatchUnitNumber) + ' 
				AND Relab.ResultsObservation (m.ID) = #Observations.Observation
			ORDER BY ts.ProcessOrder ASC
		), ''-'')'
		
		EXECUTE (@query)
			
		SELECT @RowID = MIN(RowID) FROM #units WITH(NOLOCK) WHERE RowID > @RowID
	END

	SELECT * FROM #Observations

	DROP TABLE #Observations
	DROP TABLE #units
END
GO
GRANT EXECUTE ON Relab.remispGetObservationSummary TO REMI
GO