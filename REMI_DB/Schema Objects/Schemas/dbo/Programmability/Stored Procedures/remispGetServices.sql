ALTER PROCEDURE dbo.remispGetServices
AS
BEGIN
	SELECT s.ServiceID, s.ServiceName, ISNULL(s.IsActive, 1) AS IsActive
	FROM dbo.Services s
END
GO
GRANT EXECUTE ON dbo.remispGetServices TO REMI
GO