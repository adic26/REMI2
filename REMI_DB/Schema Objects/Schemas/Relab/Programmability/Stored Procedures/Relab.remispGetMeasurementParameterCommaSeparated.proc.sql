ALTER PROCEDURE Relab.remispGetMeasurementParameterCommaSeparated @MeasurementID INT
AS
BEGIN
	select Relab.ResultsParametersNameComma(@MeasurementID,'N') AS ParameterName, Relab.ResultsParametersNameComma(@MeasurementID,'V') AS ParameterValue
END
GO
GRANT EXECUTE ON Relab.remispGetMeasurementParameterCommaSeparated TO REMI
GO
grant execute on relab.ResultsParametersNameComma to REMI
GO