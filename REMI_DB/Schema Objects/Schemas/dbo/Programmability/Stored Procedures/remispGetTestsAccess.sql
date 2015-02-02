ALTER PROCEDURE [dbo].[remispGetTestsAccess] @TestID INT = 0
AS
BEGIN
	SELECT ta.TestAccessID, t.TestName, l.[Values] As Department
	FROM TestsAccess ta
		INNER JOIN Tests t ON t.ID=ta.TestID
		INNER JOIN Lookups l ON l.LookupID=ta.LookupID
	WHERE (@TestID > 0 AND ta.TestID=@TestID) OR (@TestID = 0)
	ORDER BY t.TestName
END
GO
GRANT EXECUTE ON [dbo].[remispGetJobAccess] TO REMI
GO