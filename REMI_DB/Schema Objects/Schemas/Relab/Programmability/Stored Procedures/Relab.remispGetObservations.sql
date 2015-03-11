ALTER PROCEDURE Relab.remispGetObservations @BatchID INT
AS
BEGIN
	SELECT b.QRANumber, tu.BatchUnitNumber, (SELECT TOP 1 ts2.TestStageName
								FROM Relab.Results r2
									INNER JOIN TestStages ts2 ON ts2.ID=r2.TestStageID AND ts2.TestStageType=2
								WHERE r2.TestUnitID=r.TestUnitID
								ORDER BY ts2.ProcessOrder DESC
								) AS MaxStage, 
			ts.TestStageName, [Relab].[ResultsObservation] (m.ID) AS Observation, 
			(SELECT T.c.value('@Description', 'varchar(MAX)')
			FROM jo.Definition.nodes('/Orientations/Orientation') T(c)
			WHERE T.c.value('@Unit', 'varchar(MAX)') = tu.BatchUnitNumber AND ts.TestStageName LIKE T.c.value('@Drop', 'varchar(MAX)') + ' %') AS Orientation, 
			m.Comment, (CASE WHEN (SELECT COUNT(*) FROM Relab.ResultsMeasurementsFiles rmf WHERE rmf.ResultMeasurementID=m.ID) > 0 THEN 1 ELSE 0 END) AS HasFiles, m.ID AS MeasurementID
	FROM Relab.ResultsMeasurements m
		INNER JOIN Relab.Results r ON r.ID=m.ResultID
		INNER JOIN TestUnits tu ON r.TestUnitID=tu.ID
		INNER JOIN TestStages ts ON ts.ID=r.TestStageID
		INNER JOIN Tests t ON t.ID=r.TestID
		INNER JOIN Lookups lm ON lm.LookupID=m.MeasurementTypeID
		INNER JOIN Batches b ON b.ID=tu.BatchID
		LEFT OUTER JOIN JobOrientation jo ON jo.ID=b.OrientationID
	WHERE MeasurementTypeID IN (SELECT LookupID FROM Lookups WHERE LookupTypeID=7 AND [values] = 'Observation')
		AND b.ID=@BatchID
	ORDER BY tu.BatchUnitNumber, ts.ProcessOrder
END
GO
GRANT EXECUTE ON Relab.remispGetObservations TO REMI
GO