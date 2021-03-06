﻿ALTER PROCEDURE Relab.remispGetMeasurementsByTest @BatchIDs NVARCHAR(MAX), @TestID INT, @ShowOnlyFailValue INT = 0
AS
BEGIN
	DECLARE @batches TABLE(ID INT)
	INSERT INTO @batches SELECT s FROM dbo.Split(',',@BatchIDs)
	DECLARE @Count INT
	
	SELECT @Count = COUNT(*) FROM @batches
	
	SELECT DISTINCT m.MeasurementTypeID, Lookups.[Values] As Measurement
	FROM TestUnits tu WITH(NOLOCK)
		INNER JOIN Relab.Results r WITH(NOLOCK) ON r.TestUnitID=tu.ID
		INNER JOIN Relab.ResultsMeasurements m WITH(NOLOCK) on m.ResultID=r.ID 
		INNER JOIN Lookups WITH(NOLOCK) ON m.MeasurementTypeID=Lookups.LookupID
		INNER JOIN @batches b ON tu.BatchID=b.ID
	WHERE r.TestID=@TestID AND 
		(
			ISNUMERIC(m.MeasurementValue)=1 OR LOWER(m.MeasurementValue) IN ('true', 'pass', 'fail', 'false')
		)
		AND
		(
			(@ShowOnlyFailValue = 1 AND m.PassFail=0)
			OR
			(@ShowOnlyFailValue = 0)
		)
	GROUP BY m.MeasurementTypeID, Lookups.[Values]
	HAVING COUNT(DISTINCT b.ID) >= @Count
END
GO
GRANT EXECUTE ON Relab.remispGetMeasurementsByTest TO REMI
GO