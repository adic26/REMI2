ALTER PROCEDURE remispGetSimilarTestConfiguration @LookupID INT, @TestID INT
AS
BEGIN
	SELECT pc.LookupID AS ID, lp.[Values] AS ProductGroupName
	FROM ProductConfigurationUpload pc
		INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=pc.LookupID
	WHERE pc.TestID=@TestID AND pc.LookupID <> @LookupID
	GROUP BY pc.LookupID, lp.[Values]
END
GO
GRANT EXECUTE ON remispGetSimilarTestConfiguration TO REMI
GO