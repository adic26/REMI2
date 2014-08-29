ALTER PROCEDURE remispGetSimilarTestConfiguration @productID INT, @TestID INT
AS
BEGIN
	SELECT pc.ProductID AS ID, p.ProductGroupName
	FROM ProductConfigurationUpload pc
		INNER JOIN Products p on pc.ProductID = p.ID
	WHERE pc.TestID=@TestID AND pc.ProductID <> @productID
	GROUP BY pc.ProductID, p.ProductGroupName
END
GO
GRANT EXECUTE ON remispGetSimilarTestConfiguration TO REMI
GO