ALTER PROCEDURE Relab.remispGetObservationSummary @BatchID INT
AS
BEGIN
	DECLARE @RowID INT
	DECLARE @ID INT
	DECLARE @BatchUnitNumber INT
	DECLARE @query NVARCHAR(4000)
	CREATE TABLE #Observations (Observation NVARCHAR(255) NOT NULL)

	SELECT ROW_NUMBER() OVER (ORDER BY tu.ID) AS RowID, tu.BatchUnitNumber, tu.ID
	INTO #units
	FROM TestUnits tu WITH(NOLOCK)
	WHERE BatchID=@BatchID

	INSERT INTO #Observations
	SELECT DISTINCT lm.[Values] AS Observation
	FROM Relab.ResultsMeasurements m
		INNER JOIN Relab.Results r ON r.ID=m.ResultID
		INNER JOIN TestUnits tu ON r.TestUnitID=tu.ID
		INNER JOIN TestStages ts ON ts.ID=r.TestStageID
		INNER JOIN Tests t ON t.ID=r.TestID
		INNER JOIN Lookups lm ON lm.LookupID=m.MeasurementTypeID
		INNER JOIN Batches b ON b.ID=tu.BatchID
		INNER JOIN JobOrientation jo ON jo.ID=b.OrientationID
		LEFT OUTER JOIN Relab.ResultsMeasurementsFiles mf ON mf.ResultMeasurementID=m.ID
	WHERE MeasurementTypeID IN (SELECT LookupID FROM Lookups WHERE LookupTypeID=7 AND [values] like '%\%') AND b.ID=@BatchID

	SELECT @RowID = MIN(RowID) FROM #units
				
	WHILE (@RowID IS NOT NULL)
	BEGIN
		SET @query = ''
		SELECT @BatchUnitNumber=BatchUnitNumber, @ID=ID FROM #units WITH(NOLOCK) WHERE RowID=@RowID
		
		EXECUTE ('ALTER TABLE #Observations ADD [' + @BatchUnitNumber + '] NVARCHAR(10) NULL')
		
		SET @query = 'UPDATE #Observations SET [' + CONVERT(VARCHAR,@BatchUnitNumber) + '] = ISNULL((
			SELECT TOP 1 REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(ts.TestStageName,''''),''drops'',''''),''drop'',''''),''tumbles'',''''),''tumble'','''')
			FROM Relab.ResultsMeasurements m
				INNER JOIN Relab.Results r ON r.ID=m.ResultID
				INNER JOIN TestUnits tu ON r.TestUnitID=tu.ID
				INNER JOIN TestStages ts ON ts.ID=r.TestStageID
				INNER JOIN Tests t ON t.ID=r.TestID
				INNER JOIN Lookups lm ON lm.LookupID=m.MeasurementTypeID
				INNER JOIN Batches b ON b.ID=tu.BatchID
				INNER JOIN JobOrientation jo ON jo.ID=b.OrientationID
				LEFT OUTER JOIN Relab.ResultsMeasurementsFiles mf ON mf.ResultMeasurementID=m.ID
			WHERE MeasurementTypeID IN (SELECT LookupID FROM Lookups WHERE LookupTypeID=7 
				AND [values] = #Observations.Observation) AND b.ID=' + CONVERT(VARCHAR, @BatchID) + ' 
				AND tu.batchunitnumber=' + CONVERT(VARCHAR,@BatchUnitNumber) + ' 
			ORDER BY ts.ProcessOrder ASC
		), 0)'
		
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