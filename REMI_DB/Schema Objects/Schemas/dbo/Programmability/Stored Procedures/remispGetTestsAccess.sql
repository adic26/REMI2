ALTER PROCEDURE [dbo].[remispGetTestsAccess] @TestID INT = 0
AS
BEGIN
	SELECT 0 AS TestAccessID, '' AS TestName, '' As Department
	UNION
	SELECT ta.TestAccessID, t.TestName, l.[Values] As Department
	FROM TestsAccess ta
		INNER JOIN Tests t ON t.ID=ta.TestID
		INNER JOIN Lookups l ON l.LookupID=ta.LookupID
	WHERE (@TestID > 0 AND ta.TestID=@TestID) OR (@TestID = 0)
	ORDER BY 1
END
GO
GRANT EXECUTE ON [dbo].[remispGetJobAccess] TO REMI
GO