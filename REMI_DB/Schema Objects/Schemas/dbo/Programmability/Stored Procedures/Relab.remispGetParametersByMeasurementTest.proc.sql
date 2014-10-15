ALTER PROCEDURE Relab.remispGetParametersByMeasurementTest @BatchIDs NVARCHAR(MAX), @TestID INT, @MeasurementTypeID INT, @ParameterName NVARCHAR(255) = NULL, @ShowOnlyFailValue INT = 0, @TestStageIDs NVARCHAR(MAX) = NULL
AS
BEGIN
	DECLARE @batches TABLE(ID INT)
	DECLARE @stages TABLE(ID INT)
	INSERT INTO @batches SELECT s FROM dbo.Split(',',@BatchIDs)
	INSERT INTO @stages SELECT s FROM dbo.Split(',',@TestStageIDs)
	
	DECLARE @Count INT

	select * from @batches
	
	SELECT @Count = COUNT(*) FROM @batches

	IF (@Count = 0)
	BEGIN
	PRINT 'in'
		SELECT DISTINCT Relab.ResultsParametersNameComma(m.ID, CASE WHEN @ParameterName IS NOT NULL THEN 'V' ELSE 'N' END) AS ParameterName
			FROM TestUnits tu WITH(NOLOCK)
				INNER JOIN Relab.Results r WITH(NOLOCK) ON r.TestUnitID=tu.ID
				INNER JOIN Relab.ResultsMeasurements m WITH(NOLOCK) on m.ResultID=r.ID 
				INNER JOIN @stages ts ON r.TestStageID=ts.ID
			WHERE m.MeasurementTypeID=@MeasurementTypeID AND r.TestID=@TestID AND m.Archived=0
				AND 
				(
					(@ParameterName IS NOT NULL AND Relab.ResultsParametersNameComma(m.ID, 
													CASE WHEN @ParameterName IS NOT NULL THEN 'N' ELSE 'V' END)=@ParameterName
					) 
					OR 
					(@ParameterName IS NULL)
				)
				AND
				(
					(@ShowOnlyFailValue = 1 AND m.PassFail=0)
					OR
					(@ShowOnlyFailValue = 0)
				)
				AND Relab.ResultsParametersNameComma(m.ID, CASE WHEN @ParameterName IS NOT NULL THEN 'V' ELSE 'N' END) IS NOT NULL
			GROUP BY Relab.ResultsParametersNameComma(m.ID, CASE WHEN @ParameterName IS NOT NULL THEN 'V' ELSE 'N' END)
	END
	ELSE
		BEGIN	
			SELECT distinct Relab.ResultsParametersNameComma(m.ID, CASE WHEN @ParameterName IS NOT NULL THEN 'V' ELSE 'N' END) AS ParameterName
			FROM TestUnits tu WITH(NOLOCK)
				INNER JOIN Relab.Results r WITH(NOLOCK) ON r.TestUnitID=tu.ID
				INNER JOIN @batches b ON tu.BatchID=b.ID
				INNER JOIN Relab.ResultsMeasurements m WITH(NOLOCK) on m.ResultID=r.ID 
			WHERE m.MeasurementTypeID=@MeasurementTypeID AND r.TestID=@TestID AND m.Archived=0
				AND 
				(
					(@ParameterName IS NOT NULL AND Relab.ResultsParametersNameComma(m.ID, 
													CASE WHEN @ParameterName IS NOT NULL THEN 'N' ELSE 'V' END)=@ParameterName
					) 
					OR 
					(@ParameterName IS NULL)
				)
				AND
				(
					(@ShowOnlyFailValue = 1 AND m.PassFail=0)
					OR
					(@ShowOnlyFailValue = 0)
				)
				AND Relab.ResultsParametersNameComma(m.ID, CASE WHEN @ParameterName IS NOT NULL THEN 'V' ELSE 'N' END) IS NOT NULL  
			GROUP BY Relab.ResultsParametersNameComma(m.ID, CASE WHEN @ParameterName IS NOT NULL THEN 'V' ELSE 'N' END)
			HAVING COUNT(DISTINCT b.ID) >= @Count
		END
END
GO
GRANT EXECUTE ON Relab.remispGetParametersByMeasurementTest TO REMI
GO