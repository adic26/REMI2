ALTER PROCEDURE Relab.remispGetObservationParameters @MeasurementID INT
AS
BEGIN
	select [Relab].[ResultsObservation] (@MeasurementID) AS Observation
END
GO
GRANT EXECUTE ON Relab.remispGetObservationParameters TO REMI
GO