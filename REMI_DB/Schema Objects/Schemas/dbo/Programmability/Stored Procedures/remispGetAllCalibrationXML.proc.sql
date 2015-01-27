ALTER PROCEDURE remispGetAllCalibrationXML @ProductID INT, @HostID INT, @TestID INT
AS
BEGIN
	SELECT c.ID, c.HostID, tlh.HostName, c.ProductID, lp.[values] AS ProductGroupName, c.DateCreated, c.[File], c.Name, c.TestID, t.TestName
	FROM Calibration c
		INNER JOIN Products p ON c.ProductID=p.ID
		INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
		INNER JOIN TrackingLocationsHosts tlh ON tlh.ID=c.HostID
		INNER JOIN Tests t ON t.ID=c.TestID
	WHERE c.ProductID=@ProductID AND c.HostID=@HostID AND c.TestID=@TestID
END
GO
GRANT EXECUTE ON remispGetAllCalibrationXML TO REMI
GO