ALTER PROCEDURE remispGetAllCalibrationXML @LookupID INT, @HostID INT, @TestID INT
AS
BEGIN
	SELECT c.ID, c.HostID, tlh.HostName, c.LookupID AS ProductID, p.[values] AS ProductGroupName, c.DateCreated, c.[File], c.Name, c.TestID, t.TestName
	FROM Calibration c
		INNER JOIN Lookups p WITH(NOLOCK) on p.LookupID=c.LookupID
		INNER JOIN TrackingLocationsHosts tlh ON tlh.ID=c.HostID
		INNER JOIN Tests t ON t.ID=c.TestID
	WHERE c.LookupID=@LookupID AND c.HostID=@HostID AND c.TestID=@TestID
END
GO
GRANT EXECUTE ON remispGetAllCalibrationXML TO REMI
GO