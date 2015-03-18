ALTER PROCEDURE dbo.remispGetServicesAccessByID @LookupID INT = NULL
AS
BEGIN
	DECLARE @TrueBit BIT
	SET @TrueBit = CONVERT(BIT, 1)
	
	SELECT 0 AS ServiceID, '' AS ServiceName, 0 AS ServiceAccessID, '' AS [Values], 0 AS DepartmentID
	UNION
	SELECT s.ServiceID, s.ServiceName, sa.ServiceAccessID, ld.[Values], ld.LookupID AS DepartmentID
	FROM dbo.Services s
		INNER JOIN dbo.ServicesAccess sa WITH (NOLOCK) ON sa.ServiceID=s.ServiceID
		INNER JOIN Lookups ld WITH(NOLOCK) ON ld.LookupID=sa.LookupID
	WHERE (ISNULL(@LookupID, 0) = 0 OR sa.LookupID=@LookupID) AND ISNULL(s.IsActive, 0) = @TrueBit
END
GO
GRANT EXECUTE ON dbo.remispGetServicesAccessByID TO REMI
GO