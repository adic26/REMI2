ALTER PROCEDURE [dbo].[remispGetProducts] @ByPassProductCheck INT, @UserID INT, @ShowArchived INT
AS
BEGIN
	DECLARE @TrueBit BIT
	SET @TrueBit = CONVERT(BIT, 1)

	SELECT ID, lp.[values] AS ProductGroupName
	FROM Products p WITH(NOLOCK)
		INNER JOIN Lookups lp WITH(NOLOCK) on lp.LookupID=p.LookupID
	WHERE (@ByPassProductCheck = 1 OR (@ByPassProductCheck = 0 AND lp.LookupID IN (SELECT LookupID FROM UserDetails WITH(NOLOCK) WHERE UserID=@UserID)))
		AND
		(
			(@ShowArchived = 1)
			OR
			(@ShowArchived = 0 AND lp.IsActive = @TrueBit)
		)
	ORDER BY ProductGroupname
END
GO
GRANT EXECUTE ON remispGetProducts TO Remi
GO