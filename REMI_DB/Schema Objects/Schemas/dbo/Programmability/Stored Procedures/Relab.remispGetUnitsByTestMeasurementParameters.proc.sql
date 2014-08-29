ALTER PROCEDURE Relab.remispGetUnitsByTestMeasurementParameters @BatchIDs NVARCHAR(MAX), @TestID INT, @MeasurementTypeID INT, @ParameterName NVARCHAR(255)=null, @ParameterValue NVARCHAR(255)=null, @GetStages BIT = 0, @ShowOnlyFailValue INT = 0
AS
BEGIN
	CREATE Table #batches(id int) 
	DECLARE @Count INT
	DECLARE @FalseBit BIT
	EXEC(@BatchIDs)
	SET @FalseBit = CONVERT(BIT, 0)
	
	SELECT DISTINCT CASE WHEN @GetStages = 1 THEN ts.ID ELSE tu.ID END AS ID, tu.BatchID, CASE WHEN @GetStages = 1 THEN SUBSTRING(j.JobName, 0, CHARINDEX(' ', j.Jobname, 0)) + ' ' + ts.TestStageName ELSE CONVERT(VARCHAR, tu.batchUnitNumber) END AS Name, Batches.QRANumber
	FROM TestUnits tu WITH(NOLOCK)
		INNER JOIN Relab.Results r WITH(NOLOCK) ON r.TestUnitID=tu.ID
		INNER JOIN Relab.ResultsMeasurements m WITH(NOLOCK) on m.ResultID=r.ID 
		LEFT OUTER JOIN Relab.ResultsParameters p WITH(NOLOCK) ON m.ID=p.ResultMeasurementID
		INNER JOIN #batches b WITH(NOLOCK) ON tu.BatchID=b.ID
		INNER JOIN TestStages ts WITH(NOLOCK) ON ts.ID = r.TestStageID AND LTRIM(RTRIM(ts.TestStageName)) <> 'calibration'
		INNER JOIN Jobs j WITH(NOLOCK) ON j.ID=ts.JobID
		INNER JOIN Batches WITH(NOLOCK) ON b.id = Batches.ID
	WHERE m.MeasurementTypeID=@MeasurementTypeID AND r.TestID=@TestID AND m.Archived=@FalseBit		
		AND 
		(
			(@ParameterName IS NOT NULL AND Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN @ParameterName IS NOT NULL THEN 'N' ELSE 'V' END)=@ParameterName
				AND 
				(
					(@ParameterValue IS NOT NULL AND  Relab.ResultsParametersNameComma(p.ResultMeasurementID, CASE WHEN @ParameterValue IS NOT NULL THEN 'V' ELSE 'N' END)=@ParameterValue) 
					OR 
					(@ParameterValue IS NULL)
				)
			) 
			OR 
			(@ParameterName IS NULL)
		)
		AND
		(
			(@ShowOnlyFailValue = 1 AND m.PassFail=@FalseBit)
			OR
			(@ShowOnlyFailValue = 0)
		)
	GROUP BY CASE WHEN @GetStages = 1 THEN ts.ID ELSE tu.ID END, tu.BatchID, CASE WHEN @GetStages = 1 THEN SUBSTRING(j.JobName, 0, CHARINDEX(' ', j.Jobname, 0)) + ' ' + ts.TestStageName ELSE CONVERT(VARCHAR, tu.batchUnitNumber) END, Batches.QRANumber
	
	DROP TABLE #batches
END
GO
GRANT EXECUTE ON Relab.remispGetUnitsByTestMeasurementParameters TO REMI
GO