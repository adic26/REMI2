ALTER PROCEDURE [dbo].[remispGetJobAccess] @JobID INT = 0
AS
BEGIN
	SELECT 0 AS JobAccessID, '' AS JobName, '' As Department
	UNION
	SELECT ja.JobAccessID, j.JobName, l.[Values] As Department
	FROM JobAccess ja
		INNER JOIN Jobs j ON j.ID=ja.JobID
		INNER JOIN Lookups l ON l.LookupID=ja.LookupID
	WHERE (@JobID > 0 AND ja.JobID=@JobID) OR (@JobID = 0)
	ORDER BY 2
END
GO
GRANT EXECUTE ON [dbo].[remispGetJobAccess] TO REMI
GO