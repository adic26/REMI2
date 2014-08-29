ALTER FUNCTION Relab.ResultsParametersComma(@ResultMeasurementID INT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @listStr NVARCHAR(MAX)
	SELECT @listStr = COALESCE(@listStr+', ' ,'') + LTRIM(RTRIM(ParameterName)) + ': ' + LTRIM(RTRIM(Value))
	FROM Relab.ResultsParameters
	WHERE Relab.ResultsParameters.ResultMeasurementID=@ResultMeasurementID
	ORDER BY ParameterName, Value ASC
	
	Return @listStr
END
GO
GRANT EXECUTE ON Relab.ResultsParametersComma TO Remi
GO