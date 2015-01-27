ALTER PROCEDURE remispGetSimilarTestConfiguration @productID INT, @TestID INT
AS
BEGIN
	SELECT pc.ProductID AS ID, lp.[Values] AS ProductGroupName
	FROM ProductConfigurationUpload pc
		INNER JOIN Products p on pc.ProductID = p.ID
		INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
	WHERE pc.TestID=@TestID AND pc.ProductID <> @productID
	GROUP BY pc.ProductID, lp.[Values]
END
GO
GRANT EXECUTE ON remispGetSimilarTestConfiguration TO REMI
GO