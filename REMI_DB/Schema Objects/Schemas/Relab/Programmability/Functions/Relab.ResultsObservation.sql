ALTER FUNCTION [Relab].[ResultsObservation](@ResultMeasurementID INT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @listStr NVARCHAR(MAX)
	
	SELECT @listStr = Value
	FROM Relab.ResultsParameters
	WHERE Relab.ResultsParameters.ResultMeasurementID=@ResultMeasurementID AND ParameterName = 'Top Observation'
	
	SELECT @listStr = COALESCE(@listStr+'\' ,'') + LTRIM(RTRIM(Value))
	FROM Relab.ResultsParameters
	WHERE Relab.ResultsParameters.ResultMeasurementID=@ResultMeasurementID AND ParameterName LIKE '%Sub O%'
	ORDER BY ParameterName, Value ASC
	
	Return @listStr
END