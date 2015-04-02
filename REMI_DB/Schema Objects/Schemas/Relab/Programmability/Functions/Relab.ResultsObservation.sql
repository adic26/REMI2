ALTER FUNCTION [Relab].[ResultsObservation](@ResultMeasurementID INT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @listStr NVARCHAR(MAX)
	DECLARE @obs TABLE(Value NVARCHAR(250), ParameterName NVARCHAR(255))
	
	INSERT INTO @obs (Value, ParameterName)
	SELECT Value, ParameterName
	FROM Relab.ResultsParameters WITH(NOLOCK)
	WHERE Relab.ResultsParameters.ResultMeasurementID=@ResultMeasurementID
	
	SELECT @listStr = Value
	FROM @obs
	WHERE ParameterName = 'Top Observation'
	
	SELECT @listStr = COALESCE(@listStr+'\' ,'') + LTRIM(RTRIM(Value))
	FROM @obs
	WHERE ParameterName LIKE '%Sub O%'
	ORDER BY ParameterName, Value ASC
	
	Return @listStr
END