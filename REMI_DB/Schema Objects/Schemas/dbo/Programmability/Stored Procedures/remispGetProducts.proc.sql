ALTER PROCEDURE [dbo].[remispGetProducts] @ByPassProductCheck INT, @UserID INT, @ShowArchived INT
AS
BEGIN
	DECLARE @TrueBit BIT
	SET @TrueBit = CONVERT(BIT, 1)

	SELECT ID, ProductGroupName
	FROM Products
	WHERE (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND Products.ID IN (SELECT ProductID FROM UsersProducts WHERE UserID=@UserID)))
		AND
		(
			(@ShowArchived = 1)
			OR
			(@ShowArchived = 0 AND IsActive = @TrueBit)
		)
	ORDER BY ProductGroupname
END
GO
GRANT EXECUTE ON remispGetProducts TO Remi
GO