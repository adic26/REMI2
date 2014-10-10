ALTER FUNCTION [Relab].[ResultsParametersNameComma](@ResultMeasurementID INT, @Display NVARCHAR(1))
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @listStr NVARCHAR(MAX)
	SELECT @listStr = COALESCE(@listStr+', ' ,'') + CASE WHEN @Display = 'V' THEN LTRIM(RTRIM(Value)) ELSE LTRIM(RTRIM(ParameterName)) END
	FROM Relab.ResultsParameters
	WHERE Relab.ResultsParameters.ResultMeasurementID=@ResultMeasurementID AND ParameterName <> 'Command'
	ORDER BY ParameterName ASC
	
	Return @listStr
END
GO